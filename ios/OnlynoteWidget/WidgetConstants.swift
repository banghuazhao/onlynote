import Foundation
import SwiftUI

/// Values that have to agree with the Flutter side. Their Dart counterparts
/// live in `lib/Tools/widget_sync.dart` and `lib/Tools/widget_launch.dart`.
enum WidgetConstants {
    static let appGroupId = "group.com.appsbay.onlynote"
    static let payloadKey = "onlynote_widget_payload"
    static let kind = "OnlynoteWidget"

    private static let scheme = "onlynote"

    /// `home_widget` only recognizes an incoming URL as widget-originated when
    /// it carries a `homeWidget` query item, so every link below includes one.
    static func noteURL(id: String) -> URL {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "note"
        components.queryItems = [
            URLQueryItem(name: "id", value: id),
            URLQueryItem(name: "homeWidget", value: "true"),
        ]
        return components.url ?? openAppURL
    }

    static let newNoteURL: URL = {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "new"
        components.queryItems = [URLQueryItem(name: "homeWidget", value: "true")]
        return components.url!
    }()

    static let openAppURL: URL = {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "open"
        components.queryItems = [URLQueryItem(name: "homeWidget", value: "true")]
        return components.url!
    }()

    static let voiceNoteURL: URL = {
        var components = URLComponents()
        components.scheme = scheme
        components.host = "voice"
        components.queryItems = [URLQueryItem(name: "homeWidget", value: "true")]
        return components.url!
    }()
}

/// Brand primitives mirrored from `lib/presentation/theme/colors.dart`.
enum WidgetTheme {
    static let ink = Color(red: 0x29 / 255, green: 0x27 / 255, blue: 0x22 / 255)
    static let amber = Color(red: 0xF4 / 255, green: 0xB9 / 255, blue: 0x42 / 255)
    static let parchment = Color(red: 0xFF / 255, green: 0xF9 / 255, blue: 0xF0 / 255)
    static let night = Color(red: 0x17 / 255, green: 0x16 / 255, blue: 0x12 / 255)

    static let defaultNoteColor = Color(red: 0xD2 / 255, green: 0xD1 / 255, blue: 0xCF / 255)

    static func background(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? night : parchment
    }

    static func primaryText(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? parchment : ink
    }
}
