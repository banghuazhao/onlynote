# Onlynote

A minimalist notes & checklist app built with Flutter.

📱 [Download on the App Store](https://apps.apple.com/nz/app/onlynote-check-list-notes-memo/id1616516732)

## Features

- Quick note-taking with rich colors to organize at a glance
- Checklist / todo items inside any note
- Today view with today's daily note, due reminders, unfinished-task search, and task completion with Undo
- Markdown file and ZIP import with a note preview, selection, and local photo attachments
- Siri and Shortcuts actions to append to a saved note, today's note, or Inbox on iOS 16+ and macOS 13+
- Links to specific headings, with stable destinations when headings move or are renamed
- Divider lines for organizing longer notes, preserved in backups and document exports
- One-time, daily, and weekly reminders that open their note when tapped
- Mobile Home Screen widgets and native Mac paper widgets for notes and checklists
- One-tap image sharing — turn a note into a shareable image
- Multi-select to bulk-delete notes
- Localized in English, Simplified Chinese, and Traditional Chinese
- Local-first storage (no account or sign-in required)

## Premium

On iOS and macOS, the free plan includes up to 10 notes, checklists, one-time reminders,
default card styling, up to 3 folders, and up to 3 saved templates. Premium
unlocks unlimited notes, folders and saved templates, repeating reminders,
voice recording, individual card styling, and removes ads with a one-time purchase.

Existing Remove Ads purchases also unlock Premium. Existing folders, templates,
card styles, voice memos, and recurring reminders remain usable; backup restores are never
blocked by plan limits. Platforms without purchase support remain unrestricted.

## Import and capture

Open Settings > Import Markdown to choose `.md`, `.markdown`, or ZIP files.
Review and select notes before importing. Supported formatting and local PNG/JPEG images
are retained; unsupported formatting and missing image references remain readable
as text. Imports create new notes and follow the normal free-note limit.

Open Settings > Siri & Shortcuts for setup instructions. The app offers Append
to Today's Note, Append to Note, and Save Text to Inbox actions. To save the
clipboard, pass the output of Shortcuts' Get Clipboard action into Save Text to
Inbox. Actions open Onlynote to finish saving through its editor and autosave
path. If saving is blocked or interrupted, pending text stays available for
retry, copying, or explicit discard in the Siri & Shortcuts guide.

Before release, update the App Store display name and description for the existing
`com.appsbay.onlynote.remove_ads` product to describe Premium and its benefits.
Keep the product ID unchanged so existing customers can restore their purchase.

## Tech Stack

- [Flutter](https://flutter.dev) / Dart
- State management: [flutter_bloc](https://pub.dev/packages/flutter_bloc)
- Routing: [auto_route](https://pub.dev/packages/auto_route)
- Dependency injection: [injectable](https://pub.dev/packages/injectable) + [get_it](https://pub.dev/packages/get_it)
- Local persistence: [Hive](https://pub.dev/packages/hive)
- Immutable models: [freezed](https://pub.dev/packages/freezed)
- Ads: [google_mobile_ads](https://pub.dev/packages/google_mobile_ads)

## Getting Started

```bash
flutter pub get
flutter run
```

## macOS

The native Mac app uses the same `com.appsbay.onlynote` bundle ID and Premium
purchase as iOS. Run `flutter run -d macos` for development and
`flutter build macos --release` for a release build. See
[macOS setup and release](macos/README.md) for signing, permissions, and testing.

Native Mac widgets require macOS 14 or later. Choose a paper widget for a selected
note or an overview of the library. They share a local App Group snapshot with
the Mac app; phone and Mac libraries transfer through backups and do not
automatically synchronize.

AdMob unit IDs and signing credentials are not committed — see `lib/Tools/ad_ids_release.sample.dart` and `ios/Flutter/Secrets.xcconfig.sample` for the templates used in release builds.

## Project Structure

The app follows a layered architecture:

- `lib/presentation` — screens, widgets, and BLoCs
- `lib/domain` — models and use cases
- `lib/data` — repositories and local data sources
- `lib/di` — dependency injection setup
