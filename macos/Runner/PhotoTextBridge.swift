// Flutter's Objective-C constants are immutable, but its headers predate
// Sendable annotations. Keep strict checking for Onlynote's own code.
@preconcurrency import FlutterMacOS
import Foundation
import ImageIO
import Vision

/// Only local note-owned files enter Vision. Recognition stays off Flutter's
/// main thread; method-channel results are delivered on the main actor.
enum PhotoTextBridge {
    private static let recognizer = PhotoTextRecognizer()

    @MainActor
    static func register(messenger: FlutterBinaryMessenger) {
        let channel = FlutterMethodChannel(
            name: "com.appsbay.onlynote/photo_text", binaryMessenger: messenger
        )
        channel.setMethodCallHandler { call, result in
            guard call.method == "recognize" else {
                result(FlutterMethodNotImplemented)
                return
            }
            guard let arguments = call.arguments as? [String: Any],
                  let path = arguments["path"] as? String else {
                result(["status": "failed"])
                return
            }
            Task { @MainActor in
                let response = await recognizer.recognize(path: path)
                result(response.payload)
            }
        }
    }
}

struct PhotoTextResponse: Sendable {
    let status: String
    var text: String? = nil

    var payload: [String: Any] {
        var value: [String: Any] = ["status": status]
        if let text { value["text"] = text }
        return value
    }
}

/// Serial actor execution bounds decoded image memory when several extraction
/// requests arrive together. No UI or Flutter closures cross this boundary.
actor PhotoTextRecognizer {
    private let maxFileBytes = 64 * 1024 * 1024
    private let maxTextLength = 100_000

    func recognize(path: String) -> PhotoTextResponse {
        autoreleasepool {
            do {
                guard path.hasPrefix("/"), !path.contains("\0"),
                      let documents = FileManager.default.urls(
                        for: .documentDirectory, in: .userDomainMask
                      ).first else {
                    return PhotoTextResponse(status: "failed")
                }
                let root = documents.appendingPathComponent("note_images", isDirectory: true)
                    .resolvingSymlinksInPath().standardizedFileURL
                let file = URL(fileURLWithPath: path)
                    .resolvingSymlinksInPath().standardizedFileURL
                guard root.path.hasPrefix(documents.resolvingSymlinksInPath().path + "/"),
                      file.deletingLastPathComponent().path == root.path else {
                    return PhotoTextResponse(status: "failed")
                }
                let values = try file.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey])
                guard values.isRegularFile == true,
                      let bytes = values.fileSize,
                      bytes > 0, bytes <= maxFileBytes else {
                    return PhotoTextResponse(status: "failed")
                }
                let sourceOptions = [kCGImageSourceShouldCache: false] as CFDictionary
                guard let source = CGImageSourceCreateWithURL(file as CFURL, sourceOptions),
                      let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                        as? [CFString: Any],
                      let width = properties[kCGImagePropertyPixelWidth] as? NSNumber,
                      let height = properties[kCGImagePropertyPixelHeight] as? NSNumber,
                      width.intValue > 0, height.intValue > 0,
                      width.intValue <= 50_000, height.intValue <= 50_000,
                      width.doubleValue * height.doubleValue <= 250_000_000 else {
                    return PhotoTextResponse(status: "failed")
                }
                // ImageIO downsamples before allocation and applies all EXIF
                // rotations/mirroring once. Vision then receives upright pixels.
                let thumbnailOptions: [CFString: Any] = [
                    kCGImageSourceCreateThumbnailFromImageAlways: true,
                    kCGImageSourceCreateThumbnailWithTransform: true,
                    kCGImageSourceThumbnailMaxPixelSize: 3200,
                    kCGImageSourceShouldCacheImmediately: true,
                ]
                guard let image = CGImageSourceCreateThumbnailAtIndex(
                    source, 0, thumbnailOptions as CFDictionary
                ) else {
                    return PhotoTextResponse(status: "failed")
                }
                let request = VNRecognizeTextRequest()
                request.recognitionLevel = .accurate
                request.usesLanguageCorrection = true
                let supported = try request.supportedRecognitionLanguages()
                let languages = ["en-US", "zh-Hans", "zh-Hant"].filter(supported.contains)
                guard !languages.isEmpty else {
                    return PhotoTextResponse(status: "unsupported")
                }
                request.recognitionLanguages = languages
                if #available(macOS 13.0, *) {
                    request.automaticallyDetectsLanguage = true
                }
                try VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
                    .perform([request])
                let text = (request.results ?? [])
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                guard text.utf16.count <= maxTextLength else {
                    return PhotoTextResponse(status: "failed")
                }
                return text.isEmpty
                    ? PhotoTextResponse(status: "no_text")
                    : PhotoTextResponse(status: "text", text: text)
            } catch {
                return PhotoTextResponse(status: "failed")
            }
        }
    }
}
