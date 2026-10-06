import AVFoundation
import CoreImage
@preconcurrency import Flutter
import ImageIO
import UIKit
import UniformTypeIdentifiers
import VisionKit

/// VisionKit owns the camera/review UI. Only immutable pixels cross to the
/// serial storage actor; Flutter callbacks and UIKit stay on the main actor.
@MainActor
final class DocumentScanBridge: NSObject, @MainActor VNDocumentCameraViewControllerDelegate {
    private static var retained: DocumentScanBridge?

    static func register(messenger: FlutterBinaryMessenger) {
        if let retained {
            retained.attach(messenger: messenger)
        } else {
            retained = DocumentScanBridge(messenger: messenger)
        }
    }

    private let store = DocumentScanStore()
    private var channel: FlutterMethodChannel!
    private var scanner: VNDocumentCameraViewController?
    private var activeID: String?
    private var pageLimit = 20
    private var scanResult: FlutterResult?
    private var finishing = false
    private var operation: Task<Void, Never>?

    private init(messenger: FlutterBinaryMessenger) {
        super.init()
        attach(messenger: messenger)
    }

    private func attach(messenger: FlutterBinaryMessenger) {
        channel?.setMethodCallHandler(nil)
        channel = FlutterMethodChannel(
            name: "com.appsbay.onlynote/document_scan", binaryMessenger: messenger
        )
        channel.setMethodCallHandler { [weak self] call, result in
            guard let self else { result(FlutterMethodNotImplemented); return }
            let arguments = call.arguments as? [String: Any] ?? [:]
            switch call.method {
            case "scan":
                guard let rawID = arguments["id"] as? String,
                      let id = DocumentScanStore.canonicalID(rawID),
                      let limit = arguments["pageLimit"] as? Int,
                      (1...20).contains(limit) else {
                    result(["id": arguments["id"] as? String ?? "",
                            "status": "failed", "paths": []])
                    return
                }
                if let activeID = self.activeID {
                    result(DocumentScanResponse(
                        id: id, status: activeID == id ? .pending : .failed
                    ).payload)
                    return
                }
                self.activeID = id
                self.pageLimit = limit
                self.scanResult = result
                self.finishing = false
                self.operation = Task { @MainActor [weak self] in
                    await self?.begin(id: id, limit: limit)
                }
            case "pending":
                Task { @MainActor in
                    do { result(try await self.store.pending().map(\.payload)) }
                    catch {
                        result(FlutterError(code: "document_scan",
                            message: "Saved scans could not be read. Please try again.", details: nil))
                    }
                }
            case "acknowledge":
                guard let rawID = arguments["id"] as? String,
                      let id = DocumentScanStore.canonicalID(rawID) else {
                    result(FlutterError(code: "document_scan", message: "Invalid scan ID.", details: nil))
                    return
                }
                Task { @MainActor in
                    do {
                        try await self.store.acknowledge(id: id)
                        result(nil)
                    } catch {
                        result(FlutterError(code: "document_scan",
                            message: "The scan is retained for retry.", details: nil))
                    }
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }

    private func begin(id: String, limit: Int) async {
        do {
            let saved = try await store.begin(id: id, pageLimit: limit)
            guard activeID == id else { return }
            if saved.status != .pending {
                deliver(saved)
                return
            }
            #if targetEnvironment(simulator)
            await finish(status: .unsupported)
            return
            #else
            guard VNDocumentCameraViewController.isSupported else {
                await finish(status: .unsupported)
                return
            }
            let permission = AVCaptureDevice.authorizationStatus(for: .video)
            if permission == .notDetermined {
                guard await AVCaptureDevice.requestAccess(for: .video) else {
                    await finish(status: .permissionDenied)
                    return
                }
            } else if permission != .authorized {
                await finish(status: .permissionDenied)
                return
            }
            guard activeID == id, let presenter = Self.foregroundPresenter() else {
                await finish(status: .failed)
                return
            }
            let camera = VNDocumentCameraViewController()
            camera.delegate = self
            camera.modalPresentationStyle = .fullScreen
            scanner = camera
            presenter.present(camera, animated: true)
            #endif
        } catch {
            await finish(status: .failed)
        }
    }

    private static func foregroundPresenter() -> UIViewController? {
        guard UIApplication.shared.applicationState == .active,
              let scene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive &&
                    $0.windows.contains(where: { $0.isKeyWindow && !$0.isHidden }) }),
              let window = scene.windows.first(where: { $0.isKeyWindow && !$0.isHidden }),
              var controller = window.rootViewController else { return nil }
        while true {
            if let presented = controller.presentedViewController,
               !presented.isBeingDismissed {
                controller = presented
            } else if let navigation = controller as? UINavigationController,
                      let visible = navigation.visibleViewController {
                controller = visible
            } else if let tabs = controller as? UITabBarController,
                      let selected = tabs.selectedViewController {
                controller = selected
            } else { break }
        }
        guard controller.isViewLoaded, controller.view.window != nil,
              !controller.isBeingDismissed, !controller.isBeingPresented,
              !(controller is UIAlertController) else { return nil }
        return controller
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
        guard controller === scanner, activeID != nil, !finishing else { return }
        finishing = true
        operation = Task { @MainActor [weak self] in
            await self?.finish(status: .cancelled)
        }
    }

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController, didFailWithError error: Error
    ) {
        guard controller === scanner, activeID != nil, !finishing else { return }
        finishing = true
        operation = Task { @MainActor [weak self] in
            guard let self else { return }
            let permission = AVCaptureDevice.authorizationStatus(for: .video)
            await self.finish(status: permission == .denied || permission == .restricted
                ? .permissionDenied : .failed)
        }
    }

    func documentCameraViewController(
        _ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan
    ) {
        guard controller === scanner, activeID != nil, !finishing else { return }
        finishing = true
        operation = Task { @MainActor [weak self] in
            guard let self, let id = self.activeID else { return }
            guard scan.pageCount > 0 else {
                await self.finish(status: .cancelled)
                return
            }
            // VisionKit has no page-limit option. Reject the whole oversized
            // result after native review, rather than dropping any pages.
            guard scan.pageCount <= self.pageLimit else {
                await self.finish(status: .tooManyPages)
                return
            }
            await self.dismissScanner()
            do {
                for index in 0..<scan.pageCount {
                    try Task.checkCancellation()
                    let page = autoreleasepool { () -> DocumentScanPage? in
                        let image = scan.imageOfPage(at: index)
                        guard let pixels = image.cgImage else { return nil }
                        return DocumentScanPage(image: pixels,
                            orientation: Self.exifOrientation(image.imageOrientation))
                    }
                    guard let page else { throw DocumentScanStore.StoreError.invalidImage }
                    try await self.store.writePage(page, id: id, index: index)
                }
                let response = try await self.store.complete(id: id, pageCount: scan.pageCount)
                self.deliver(response)
            } catch is CancellationError {
                await self.finish(status: .cancelled)
            } catch {
                await self.finish(status: .failed)
            }
        }
    }

    private static func exifOrientation(_ orientation: UIImage.Orientation) -> Int32 {
        switch orientation {
        case .up: return 1
        case .upMirrored: return 2
        case .down: return 3
        case .downMirrored: return 4
        case .leftMirrored: return 5
        case .right: return 6
        case .rightMirrored: return 7
        case .left: return 8
        @unknown default: return 1
        }
    }

    private func dismissScanner() async {
        guard let scanner else { return }
        scanner.delegate = nil
        if scanner.presentingViewController != nil, !scanner.isBeingDismissed {
            await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
                scanner.dismiss(animated: true) { continuation.resume() }
            }
        }
        self.scanner = nil
    }

    private func finish(status: DocumentScanStatus) async {
        guard let id = activeID else { return }
        finishing = true
        await dismissScanner()
        do {
            let response = try await store.finish(id: id, status: status)
            deliver(response)
        } catch {
            // A completion event always corresponds to a durable terminal
            // manifest. A storage failure still resolves this caller once.
            deliver(DocumentScanResponse(id: id, status: .failed), emitEvent: false)
        }
    }

    private func deliver(_ response: DocumentScanResponse, emitEvent: Bool = true) {
        guard activeID == response.id else { return }
        let callback = scanResult
        scanResult = nil
        activeID = nil
        finishing = false
        operation = nil
        callback?(response.payload)
        if emitEvent { channel.invokeMethod("scanReady", arguments: response.payload) }
    }
}

private enum DocumentScanStatus: String, Codable, Sendable {
    case pages, cancelled, unsupported, failed, pending
    case tooManyPages = "too_many_pages"
    case permissionDenied = "permission_denied"
}

private struct DocumentScanResponse: Sendable {
    let id: String
    let status: DocumentScanStatus
    var paths: [String] = []

    var payload: [String: Any] { ["id": id, "status": status.rawValue, "paths": paths] }
}

/// CGImage is immutable and declared Sendable by CoreGraphics; UIImage and
/// VisionKit objects are deliberately kept on the main actor.
private struct DocumentScanPage: Sendable {
    let image: CGImage
    let orientation: Int32
}

private actor DocumentScanStore {
    enum StoreError: Error { case invalidID, invalidManifest, invalidImage, pending }

    private struct Manifest: Codable, Sendable {
        let id: String
        var status: DocumentScanStatus
        let pageLimit: Int
        var pageCount = 0
    }

    private let maxPageBytes = 30 * 1024 * 1024
    private let imageContext = CIContext(options: [.cacheIntermediates: false])
    private var root: URL?

    static func canonicalID(_ raw: String) -> String? {
        guard raw.count == 36, let uuid = UUID(uuidString: raw),
              uuid.uuidString.caseInsensitiveCompare(raw) == .orderedSame else { return nil }
        return uuid.uuidString.lowercased()
    }

    /// Runs once per process. An interrupted native capture/encoding has no
    /// committed pages, and becomes a durable cancellation instead of pending.
    private func initialize() throws -> URL {
        if let root { return root }
        guard let support = FileManager.default.urls(
            for: .applicationSupportDirectory, in: .userDomainMask
        ).first else { throw StoreError.invalidManifest }
        let base = support.resolvingSymlinksInPath().standardizedFileURL
        let directory = base.appendingPathComponent("document_scans", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard directory.resolvingSymlinksInPath().path == directory.path else {
            throw StoreError.invalidManifest
        }
        let children = try FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: [.isDirectoryKey, .isSymbolicLinkKey]
        )
        for child in children {
            guard let id = Self.canonicalID(child.lastPathComponent),
                  child.lastPathComponent == id,
                  child.resolvingSymlinksInPath().path == child.path,
                  (try? child.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true else { continue }
            let manifest = try? readManifest(at: child, id: id)
            if manifest == nil || manifest?.status == .pending {
                let cancelled = Manifest(id: id, status: .cancelled,
                    pageLimit: manifest?.pageLimit ?? 20)
                try save(cancelled, directory: child)
                removePageFiles(in: child)
            }
        }
        self.root = directory
        return directory
    }

    private func requestDirectory(id: String, create: Bool = false) throws -> URL {
        guard Self.canonicalID(id) == id else { throw StoreError.invalidID }
        let directory = try initialize().appendingPathComponent(id, isDirectory: true)
        guard directory.resolvingSymlinksInPath().path == directory.path else {
            throw StoreError.invalidID
        }
        if create {
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: false)
        }
        return directory
    }

    private func readManifest(at directory: URL, id: String) throws -> Manifest {
        let file = directory.appendingPathComponent("manifest.json")
        guard file.resolvingSymlinksInPath().path == file.path,
              let size = try file.resourceValues(forKeys: [.fileSizeKey]).fileSize,
              size > 0, size <= 64 * 1024 else { throw StoreError.invalidManifest }
        let manifest = try JSONDecoder().decode(Manifest.self, from: Data(contentsOf: file))
        guard manifest.id == id, (1...20).contains(manifest.pageLimit),
              (0...manifest.pageLimit).contains(manifest.pageCount),
              manifest.status != .pages || manifest.pageCount > 0 else {
            throw StoreError.invalidManifest
        }
        return manifest
    }

    private func save(_ manifest: Manifest, directory: URL) throws {
        let file = directory.appendingPathComponent("manifest.json")
        guard file.resolvingSymlinksInPath().path == file.path else { throw StoreError.invalidManifest }
        try JSONEncoder().encode(manifest).write(to: file, options: .atomic)
    }

    private func response(_ manifest: Manifest, directory: URL) throws -> DocumentScanResponse {
        guard manifest.status == .pages else {
            return DocumentScanResponse(id: manifest.id, status: manifest.status)
        }
        let paths = try (0..<manifest.pageCount).map { index -> String in
            let page = directory.appendingPathComponent("page_\(index).jpg")
            let values = try page.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
            guard page.resolvingSymlinksInPath().path == page.path,
                  values.isRegularFile == true, let size = values.fileSize,
                  size > 0, size <= maxPageBytes else { throw StoreError.invalidManifest }
            return page.path
        }
        return DocumentScanResponse(id: manifest.id, status: .pages, paths: paths)
    }

    func begin(id: String, pageLimit: Int) throws -> DocumentScanResponse {
        let directory = try requestDirectory(id: id)
        if FileManager.default.fileExists(atPath: directory.path) {
            return try response(readManifest(at: directory, id: id), directory: directory)
        }
        let created = try requestDirectory(id: id, create: true)
        let manifest = Manifest(id: id, status: .pending, pageLimit: pageLimit)
        try save(manifest, directory: created)
        return DocumentScanResponse(id: id, status: .pending)
    }

    func writePage(_ page: DocumentScanPage, id: String, index: Int) throws {
        try Task.checkCancellation()
        let directory = try requestDirectory(id: id)
        let manifest = try readManifest(at: directory, id: id)
        guard manifest.status == .pending, (0..<manifest.pageLimit).contains(index) else {
            throw StoreError.invalidManifest
        }
        try autoreleasepool {
            let oriented = CIImage(cgImage: page.image).oriented(forExifOrientation: page.orientation)
            let extent = oriented.extent
            guard extent.width > 0, extent.height > 0,
                  extent.width.isFinite, extent.height.isFinite else { throw StoreError.invalidImage }
            let scale = min(1, 3508 / max(extent.width, extent.height))
            let width = max(1, floor(extent.width * scale))
            let height = max(1, floor(extent.height * scale))
            let transformed = oriented
                .transformed(by: CGAffineTransform(translationX: -extent.minX, y: -extent.minY))
                .transformed(by: CGAffineTransform(scaleX: scale, y: scale))
            guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
                  let pixels = imageContext.createCGImage(transformed,
                    from: CGRect(x: 0, y: 0, width: width, height: height),
                    format: .RGBA8, colorSpace: colorSpace) else { throw StoreError.invalidImage }
            let output = NSMutableData()
            guard let destination = CGImageDestinationCreateWithData(
                output, UTType.jpeg.identifier as CFString, 1, nil
            ) else { throw StoreError.invalidImage }
            CGImageDestinationAddImage(destination, pixels, [
                kCGImageDestinationLossyCompressionQuality: 0.9,
                kCGImagePropertyOrientation: 1,
            ] as CFDictionary)
            guard CGImageDestinationFinalize(destination), output.length > 0,
                  output.length <= maxPageBytes else { throw StoreError.invalidImage }
            try Task.checkCancellation()
            let file = directory.appendingPathComponent("page_\(index).jpg")
            guard file.resolvingSymlinksInPath().path == file.path else { throw StoreError.invalidID }
            try (output as Data).write(to: file, options: .atomic)
        }
    }

    func complete(id: String, pageCount: Int) throws -> DocumentScanResponse {
        let directory = try requestDirectory(id: id)
        var manifest = try readManifest(at: directory, id: id)
        guard manifest.status == .pending, (1...manifest.pageLimit).contains(pageCount) else {
            throw StoreError.invalidManifest
        }
        manifest.status = .pages
        manifest.pageCount = pageCount
        let completed = try response(manifest, directory: directory)
        try save(manifest, directory: directory)
        return completed
    }

    func finish(id: String, status: DocumentScanStatus) throws -> DocumentScanResponse {
        let directory = try requestDirectory(id: id)
        var manifest = try readManifest(at: directory, id: id)
        guard manifest.status == .pending, status != .pending, status != .pages else {
            return try response(manifest, directory: directory)
        }
        manifest.status = status
        manifest.pageCount = 0
        try save(manifest, directory: directory)
        removePageFiles(in: directory)
        return DocumentScanResponse(id: id, status: status)
    }

    func pending() throws -> [DocumentScanResponse] {
        let root = try initialize()
        return try FileManager.default.contentsOfDirectory(
            at: root, includingPropertiesForKeys: nil
        ).sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).compactMap { child in
            guard let id = Self.canonicalID(child.lastPathComponent), child.lastPathComponent == id,
                  child.resolvingSymlinksInPath().path == child.path else { return nil }
            do { return try response(readManifest(at: child, id: id), directory: child) }
            catch { return DocumentScanResponse(id: id, status: .failed) }
        }
    }

    func acknowledge(id: String) throws {
        let directory = try requestDirectory(id: id)
        guard FileManager.default.fileExists(atPath: directory.path) else { return }
        let manifest = try readManifest(at: directory, id: id)
        guard manifest.status != .pending else { throw StoreError.pending }
        try FileManager.default.removeItem(at: directory)
    }

    private func removePageFiles(in directory: URL) {
        for index in 0..<20 {
            let file = directory.appendingPathComponent("page_\(index).jpg")
            guard file.resolvingSymlinksInPath().path == file.path else { continue }
            try? FileManager.default.removeItem(at: file)
        }
    }
}
