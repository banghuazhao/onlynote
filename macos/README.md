# Onlynote for macOS

The macOS target shares the existing App Store Connect app record with iOS:

- Bundle ID: `com.appsbay.onlynote`
- Development team: the existing iOS team, configured in `Runner/Configs/AppInfo.xcconfig`
- Premium non-consumable: `com.appsbay.onlynote.remove_ads`
- Minimum macOS version: 12.0

## Development

```sh
flutter pub get
flutter run -d macos
```

The Mac app supports the shared notes, checklists, folders, templates, search,
reminders, image import, photo text recognition, voice memos, and backup flows.
It has native app menus, Command-key shortcuts, and right-click note actions.
Backup export uses a Save As dialog on Mac.

Mac builds are ad-free. Premium keeps the existing iOS product ID so customers
can restore a universal purchase. Camera capture, native document scanning,
mobile share extensions, and home-screen widgets are available only on mobile.
Voice transcription requires on-device Speech support for the selected language.
Libraries remain local to each device; `.onlynote` backup files transfer notes
and media between devices. Adding a Mac build does not enable cloud sync.

## Permissions

Both entitlements files enable App Sandbox, outgoing network connections,
user-selected file read/write, and microphone input. Keep those capabilities in
both debug/profile and release configurations. Debug additionally keeps Flutter's
JIT and local development networking entitlements.

Microphone and Speech usage descriptions are in `Runner/Info.plist`. Permissions
are requested when recording or transcription is invoked. Imported images and
recordings are copied into app-managed storage rather than retaining access to
arbitrary external files.

## Release through the existing App Store record

```sh
flutter build macos --release
open macos/Runner.xcworkspace
```

In Xcode, select the Runner scheme and a Mac destination. Verify the existing
Apple development team in Signing & Capabilities, then use Product > Archive
and Distribute App > App Store Connect. Xcode needs a valid Mac signing identity
and the appropriate provisioning profile for that team. A locally built `.app`
alone is not an App Store submission.

In the macOS version of the existing App Store Connect record, set the version
metadata and screenshots, confirm the existing Premium product is available,
and attach the uploaded Mac build. Test purchasing and restoring with the App
Store sandbox before submission, including restoration of the iOS purchase.

Before releasing, check:

- Cold launch, onboarding, and immediate typing followed by Command-Q or window close.
- New note, find, undo/redo, clipboard commands, Settings, and right-click actions.
- Continuous window resizing, large text, and English/Chinese input.
- Image import and photo text search, microphone permission denial, recording,
  playback, and on-device transcription where supported.
- Notification permission denial, one-time/repeating reminders, snooze, and
  notification launches after quitting the app.
- Backup Save As cancellation/failure and phone-to-Mac backup restore with media.
- Offline launch and cached Premium access.
