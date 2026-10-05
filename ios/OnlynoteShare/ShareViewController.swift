import UIKit
import UniformTypeIdentifiers

@MainActor
final class ShareViewController: UIViewController {
    private let status = UILabel()
    private let saveButton = UIButton(type: .system)
    private let cancelButton = UIButton(type: .system)
    private let spinner = UIActivityIndicatorView(style: .medium)
    private var operation: Task<Void, Never>?
    private var saved = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        let title = UILabel()
        title.text = localized("share_title")
        title.font = .preferredFont(forTextStyle: .title2)
        title.adjustsFontForContentSizeCategory = true
        title.numberOfLines = 0
        status.text = localized("share_explanation")
        status.font = .preferredFont(forTextStyle: .body)
        status.adjustsFontForContentSizeCategory = true
        status.textColor = .secondaryLabel
        status.numberOfLines = 0
        saveButton.setTitle(localized("share_save"), for: .normal)
        saveButton.titleLabel?.font = .preferredFont(forTextStyle: .headline)
        saveButton.titleLabel?.adjustsFontForContentSizeCategory = true
        saveButton.addTarget(self, action: #selector(save), for: .touchUpInside)
        cancelButton.setTitle(localized("share_cancel"), for: .normal)
        cancelButton.titleLabel?.font = .preferredFont(forTextStyle: .body)
        cancelButton.titleLabel?.adjustsFontForContentSizeCategory = true
        cancelButton.addTarget(self, action: #selector(cancel), for: .touchUpInside)
        let stack = UIStackView(arrangedSubviews: [title, status, spinner, saveButton, cancelButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.translatesAutoresizingMaskIntoConstraints = false
        let scroll = UIScrollView()
        scroll.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scroll)
        scroll.addSubview(stack)
        NSLayoutConstraint.activate([
            scroll.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            scroll.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            stack.leadingAnchor.constraint(equalTo: scroll.contentLayoutGuide.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: scroll.contentLayoutGuide.trailingAnchor, constant: -24),
            stack.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 28),
            stack.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24),
            stack.widthAnchor.constraint(equalTo: scroll.frameLayoutGuide.widthAnchor, constant: -48),
            saveButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            cancelButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44)
        ])
    }

    @objc private func save() {
        if saved {
            extensionContext?.completeRequest(returningItems: nil)
            return
        }
        guard operation == nil else { return }
        saveButton.isEnabled = false
        spinner.startAnimating()
        status.text = localized("share_loading")
        operation = Task { [weak self] in
            guard let self else { return }
            do {
                try await stageShare()
                try Task.checkCancellation()
                saved = true
                status.text = localized("share_saved")
                saveButton.setTitle(localized("share_done"), for: .normal)
                cancelButton.isHidden = true
            } catch is CancellationError {
                return
            } catch {
                status.text = localized("share_failed")
            }
            spinner.stopAnimating()
            saveButton.isEnabled = true
            operation = nil
        }
    }

    @objc private func cancel() {
        operation?.cancel()
        extensionContext?.cancelRequest(withError: NSError(domain: NSCocoaErrorDomain, code: NSUserCancelledError))
    }

    private func stageShare() async throws {
        guard let items = extensionContext?.inputItems as? [NSExtensionItem] else {
            throw ShareInbox.InboxError.invalid
        }
        let id = UUID().uuidString.lowercased()
        let root = try ShareInbox.root()
        let staging = root.appendingPathComponent(".pending-\(id)", isDirectory: true)
        try FileManager.default.createDirectory(at: staging, withIntermediateDirectories: true)
        var published = false
        defer { if !published { try? FileManager.default.removeItem(at: staging) } }
        var texts: [String] = []
        var images: [String] = []
        var total: Int64 = 0
        var title = ""
        for item in items {
            try Task.checkCancellation()
            if title.isEmpty { title = item.attributedTitle?.string ?? "" }
            if let text = item.attributedContentText?.string, !text.isEmpty { texts.append(text) }
            for provider in item.attachments ?? [] {
                try Task.checkCancellation()
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    guard images.count < 10 else { throw ShareInbox.InboxError.tooLarge }
                    let imageType = provider.registeredTypeIdentifiers.first {
                        UTType($0)?.conforms(to: .image) == true
                    } ?? UTType.image.identifier
                    let preferredExtension = UTType(imageType)?.preferredFilenameExtension ?? "jpg"
                    let ext = preferredExtension.range(
                        of: "^[a-zA-Z0-9]{1,8}$", options: .regularExpression
                    ) != nil ? preferredExtension : "jpg"
                    let name = "photo-\(images.count).\(ext)"
                    let size = try await copyImage(provider, type: imageType, destination: staging.appendingPathComponent(name))
                    total += size
                    guard total <= ShareInbox.maxTotalBytes else { throw ShareInbox.InboxError.tooLarge }
                    images.append(name)
                } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    let text = try await loadText(provider, type: UTType.url.identifier)
                    if !texts.contains(text) { texts.append(text) }
                } else if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    let text = try await loadText(provider, type: UTType.plainText.identifier)
                    if !texts.contains(text) { texts.append(text) }
                } else {
                    throw ShareInbox.InboxError.unsupported
                }
                guard texts.reduce(0, { $0 + $1.utf16.count }) <= 100000 else {
                    throw ShareInbox.InboxError.tooLarge
                }
            }
        }
        let text = texts.joined(separator: "\n\n").trimmingCharacters(in: .whitespacesAndNewlines)
        guard title.utf16.count <= 1000, text.utf16.count <= 100000,
              !text.isEmpty || !images.isEmpty || !title.isEmpty else { throw ShareInbox.InboxError.tooLarge }
        let entry: [String: Any] = [
            "version": 1, "id": id, "title": title, "text": text,
            "images": images, "createdAt": Date().timeIntervalSince1970
        ]
        let data = try JSONSerialization.data(withJSONObject: entry)
        let entryURL = staging.appendingPathComponent("entry.json")
        try data.write(to: entryURL, options: .atomic)
        let entryHandle = try FileHandle(forWritingTo: entryURL)
        try entryHandle.synchronize()
        try entryHandle.close()
        try Task.checkCancellation()
        try FileManager.default.moveItem(at: staging, to: root.appendingPathComponent(id, isDirectory: true))
        published = true
    }

    /// NSItemProvider's file is temporary and is only valid during the callback.
    /// Copy it before resuming the continuation or completing the extension.
    private func copyImage(_ provider: NSItemProvider, type: String, destination: URL) async throws -> Int64 {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadFileRepresentation(forTypeIdentifier: type) { url, error in
                do {
                    if let error { throw error }
                    guard let url else { throw ShareInbox.InboxError.invalid }
                    let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                    guard size > 0, Int64(size) <= ShareInbox.maxImageBytes else { throw ShareInbox.InboxError.tooLarge }
                    try FileManager.default.copyItem(at: url, to: destination)
                    let handle = try FileHandle(forWritingTo: destination)
                    try handle.synchronize()
                    try handle.close()
                    continuation.resume(returning: Int64(size))
                } catch { continuation.resume(throwing: error) }
            }
        }
    }

    private func loadText(_ provider: NSItemProvider, type: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            provider.loadItem(forTypeIdentifier: type, options: nil) { item, error in
                if let error {
                    continuation.resume(throwing: error)
                } else if let url = item as? URL {
                    continuation.resume(returning: url.absoluteString)
                } else if let text = item as? String {
                    continuation.resume(returning: text)
                } else {
                    continuation.resume(throwing: ShareInbox.InboxError.invalid)
                }
            }
        }
    }

    private func localized(_ key: String) -> String { NSLocalizedString(key, comment: "Share extension") }
    deinit { operation?.cancel() }
}
