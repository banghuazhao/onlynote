# Onlynote

A minimalist notes & checklist app built with Flutter.

📱 [Download on the App Store](https://apps.apple.com/nz/app/onlynote-check-list-notes-memo/id1616516732)

## Features

- Quick note-taking with rich colors to organize at a glance
- Checklist / todo items inside any note
- One-time, daily, and weekly reminders that open their note when tapped
- Home Screen widgets for pinned and recent notes, with contextual setup guidance
- One-tap image sharing — turn a note into a shareable image
- Multi-select to bulk-delete notes
- Localized in English, Simplified Chinese, and Traditional Chinese
- Local-first storage (no account or sign-in required)

## Premium

On iOS, the free plan includes up to 10 notes, checklists, one-time reminders,
default card styling, up to 3 folders, and up to 3 saved templates. Premium
unlocks unlimited notes, folders and saved templates, repeating reminders,
voice recording, individual card styling, and removes ads with a one-time purchase.

Existing Remove Ads purchases also unlock Premium. Existing folders, templates,
card styles, voice memos, and recurring reminders remain usable; backup restores are never
blocked by plan limits. Platforms without purchase support remain unrestricted.

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

AdMob unit IDs and signing credentials are not committed — see `lib/Tools/ad_ids_release.sample.dart` and `ios/Flutter/Secrets.xcconfig.sample` for the templates used in release builds.

## Project Structure

The app follows a layered architecture:

- `lib/presentation` — screens, widgets, and BLoCs
- `lib/domain` — models and use cases
- `lib/data` — repositories and local data sources
- `lib/di` — dependency injection setup
