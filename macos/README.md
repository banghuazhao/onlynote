# Onlynote for macOS

The macOS target shares the existing App Store Connect app record with iOS:

- Bundle ID: `com.appsbay.onlynote`
- Development team: the existing iOS team, configured in `Runner/Configs/AppInfo.xcconfig`
- Premium non-consumable: `com.appsbay.onlynote.remove_ads`
- Minimum macOS version: 12.0
- Native desktop/Notification Center widgets: macOS 14.0 or later

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
and mobile share extensions are available only on mobile.
Voice transcription requires on-device Speech support for the selected language.
Libraries remain local to each device; `.onlynote` backup files transfer notes
and media between devices. Adding a Mac build does not enable cloud sync.

## Native Mac widgets

The embedded WidgetKit extension provides two paper widgets in small, medium,
and large sizes:

- **Note** (`OnlynoteWidget`): shows a selected note or **Top note**, the first note
  in your library, including pinned notes and your custom order. Control-click
  the widget and choose Edit Widget to select a note. Paragraph breaks are
  retained; available checklist buttons update its saved items.
- **Overview** (`OnlynoteOverviewWidget`): shows notes in library order and opens the
  selected note in Onlynote.

Open Onlynote once to publish the library, then Control-click the desktop,
choose Edit Widgets, and search for Onlynote. Widgets can also be added through
Edit Widgets at the bottom of Notification Center.

For colored paper on macOS Sonoma, open System Settings > Desktop & Dock >
Widgets and choose **Widget style > Full-color**. On newer macOS versions that
show **Dim widgets on desktop**, choose **Never**. See Apple's widget setup guides
for [Sonoma](https://support.apple.com/guide/mac-help/add-and-customize-widgets-mchl52be5da5/14.0/mac/14.0)
and [Tahoe](https://support.apple.com/guide/mac-help/add-and-customize-widgets-mchl52be5da5/26/mac/26).

The app and extension share `F694X76A5X.com.appsbay.onlynote` on this Mac. The app
atomically writes `onlynote_widget_payload.json`; widget checklist actions write
separate command files, which Onlynote applies and acknowledges on startup,
resume, or a live notification. The extension does not open Hive. This App Group
shares data between the local app and extension; it does not synchronize with an
iPhone or another Mac. If an iPhone-relayed widget is already present, replace it
with the native widget from the Mac installation to show this Mac's library.

For local widget testing, sign **both Runner and the widget extension** with an
actual **Apple Development** identity for the configured team in Xcode. Enable
the same App Group entitlement on both targets. An ad-hoc signature (`-`) can
build the app but does not establish the team identity required for reliable
App Group access and widget registration. Open `Runner.xcworkspace`, select the
Runner scheme, configure Signing & Capabilities for both targets, and run the
signed app before opening the widget gallery. Group-access errors leave the app
usable; the widget remains empty until signing and group access are corrected.

Native widget tests can use a separate signed app and App Group, keeping the
installed library and widget snapshot separate from test data:

```sh
xcodebuild -workspace macos/Runner.xcworkspace -scheme Runner \
  -destination 'platform=macOS' -derivedDataPath build/macos-widget-tests \
  CODE_SIGN_IDENTITY='Apple Development' DEVELOPMENT_TEAM=F694X76A5X \
  ONLYNOTE_APP_BUNDLE_ID=com.appsbay.onlynote.widgettests test
```

The bundle ID override also expands the App Group in both targets' Info.plist
and entitlements. Normal builds retain the existing App Store IDs. When testing
multiple builds with the same bundle ID, unregister older test copies from
LaunchServices so WidgetKit resolves the app containing the current extension.

## Permissions

Both entitlements files enable App Sandbox, outgoing network connections,
user-selected file read/write, and microphone input. Keep those capabilities in
both debug/profile and release configurations. Debug additionally keeps Flutter's
JIT and local development networking entitlements.

Runner and the widget extension also require the matching local App Group
entitlement described above.

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
- Both native widget kinds and all sizes, selected-note changes, checklist
  actions with Onlynote running and quit, cold/warm note links, deleted/archived
  notes, long multiline/Unicode note previews, and Full Color versus dimmed styles.
