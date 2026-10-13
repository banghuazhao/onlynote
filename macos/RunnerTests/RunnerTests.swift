import AppKit
import XCTest
@testable import Onlynote

final class RunnerTests: XCTestCase {
  func testPhotoRecognitionRejectsExternalFiles() async {
    let response = await PhotoTextRecognizer().recognize(path: "/private/tmp/external.png")
    XCTAssertEqual(response.status, "failed")
  }

  @MainActor
  func testPhotoRecognitionReadsManagedImage() async throws {
    let documents = try XCTUnwrap(FileManager.default.urls(
      for: .documentDirectory, in: .userDomainMask
    ).first)
    let images = documents.appendingPathComponent("note_images", isDirectory: true)
    try FileManager.default.createDirectory(at: images, withIntermediateDirectories: true)
    let file = images.appendingPathComponent("mac-ocr-test-\(UUID().uuidString).png")
    defer { try? FileManager.default.removeItem(at: file) }

    let bitmap = try XCTUnwrap(NSBitmapImageRep(
      bitmapDataPlanes: nil, pixelsWide: 1200, pixelsHigh: 240,
      bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
      isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ))
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
    NSColor.white.setFill()
    NSBezierPath(rect: NSRect(x: 0, y: 0, width: 1200, height: 240)).fill()
    ("Onlynote Mac Recognition" as NSString).draw(
      at: NSPoint(x: 40, y: 90),
      withAttributes: [.font: NSFont.systemFont(ofSize: 64), .foregroundColor: NSColor.black]
    )
    NSGraphicsContext.restoreGraphicsState()
    let png = try XCTUnwrap(bitmap.representation(using: .png, properties: [:]))
    try png.write(to: file)

    let response = await PhotoTextRecognizer().recognize(path: file.path)
    XCTAssertEqual(response.status, "text")
    XCTAssertTrue(response.text?.contains("Onlynote Mac Recognition") == true)
  }
}
