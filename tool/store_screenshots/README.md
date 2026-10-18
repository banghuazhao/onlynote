# Store screenshots

The opt-in capture test uses Onlynote's production screens with localized sample
notes and isolated storage/services. Captures are generated directly by Flutter;
the app interface is not painted over or recreated. Brief captions appear above
the app viewport. No credentials or personal notes are included in the images.

## Generate

Supply genuine Montserrat Regular and Bold fonts at
`build/store_screenshots/fonts/Montserrat-Regular.ttf` and
`build/store_screenshots/fonts/Montserrat-Bold.ttf`. The fonts are available from
the [Google Fonts repository](https://github.com/google/fonts/tree/main/ofl/montserrat).
Roboto, Chinese fallback glyphs, and Material icons are loaded locally.

```sh
flutter test test/presentation/store_screenshots_test.dart --no-pub \
  --dart-define=CAPTURE_STORE_SCREENSHOTS=true --concurrency=1
python3 tool/store_screenshots/prepare.py
```

To review a smaller set, add `--dart-define=STORE_DEVICES=iphone6_9`,
`--dart-define=STORE_LOCALES=en`, and/or
`--dart-define=STORE_SCREENS=home,formattedNote,checklist`.

The complete set contains 8 screens in English, Simplified Chinese, and
Traditional Chinese for 6 device classes (144 images). Files and upload reports
are written to the ignored `build/store_screenshots/2026-10-08` directory.
The `upload` subdirectory contains only the ordered JPEG files for each set.
`prepare.py` uses macOS `sips` to produce opaque RGB JPEGs and checks dimensions,
image counts, and file sizes. Use `--devices playphone` to re-export only a changed
device set, or `--locales zh-Hant` for one language, while preserving the other
JPEG files.

| Device | Pixels | Store target |
| --- | --- | --- |
| iPhone large | 1320 × 2868 | `APP_IPHONE_67` |
| iPhone medium | 1206 × 2622 | `APP_IPHONE_61` |
| iPad 13-inch | 2064 × 2752 | `APP_IPAD_PRO_3GEN_129` |
| Android phone | 1080 × 1920 | `phoneScreenshots` |
| Android 7-inch tablet | 1200 × 1920 | `sevenInchScreenshots` |
| Android 10-inch tablet | 1600 × 2560 | `tenInchScreenshots` |

Check [Apple's screenshot specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications/)
and [Google's screenshot guidelines](https://support.google.com/googleplay/android-developer/answer/9866151)
before using the tooling for a later release.

## Mac screenshots

Mac capture is opt-in and uses the production desktop layouts, localized sample
notes, and isolated services. It outputs 2880 × 1800 pixels, one of Apple's
accepted 16:10 Mac sizes. The eight app screens use the existing warm paper
captions. A ninth image places the real library viewport beside real SwiftUI
widget renders; its caption states that desktop widgets require macOS 14 or later.
No desktop or device chrome is drawn around the app.

First generate the native previews with the `RunnerTests` widget snapshot test,
which writes `note-medium.png`, `note-chinese.png`, and `checklist-large.png` to
`build/mac-widget-previews`. The capture harness loads those native renders;
it does not recreate their text or controls.
The Chinese compositions use the genuine Chinese note render; the checklist
remains an English example of the content a user can write.

```sh
flutter test test/presentation/store_screenshots_test.dart --no-pub \
  --dart-define=CAPTURE_STORE_SCREENSHOTS=true \
  --dart-define=STORE_DEVICES=macos \
  --dart-define=STORE_OUTPUT_ROOT=build/store_screenshots/2026-10-14 \
  --concurrency=1
python3 tool/store_screenshots/prepare_macos.py
```

For a first visual check, add `--dart-define=STORE_LOCALES=en` and
`--dart-define=STORE_SCREENS=home,formattedNote,desktopWidgets`. The complete
capture creates nine images for each of English, Simplified Chinese, and
Traditional Chinese. Raw captures are in `macos/<locale>`, upload-ready JPEGs
are in `upload/macos/<locale>`, and `macos-manifest.json` records the ordered
files, dimensions, hashes, and App Store locale mapping. Contact sheets are
saved beside the manifest. Mac exports have their own preparation command;
the earlier mobile screenshot sets remain separate.

## Mac upload and release

The Mac release tools target `MAC_OS` and `APP_DESKTOP` screenshot sets.
Credentials stay outside the repository in
`~/Development/secret/AppStoreConnect_API_keys/asc_token.py`; both tools accept
`--credentials-helper` to select another helper. The release commands below use
the current defaults, version 1.8.0 and build 18; pass `--version` and `--build`
explicitly for a later release. Actions require `--execute`, except `inspect`
and `status`, which read the existing store records.

Build the Flutter release configuration, then archive, export, and verify the
universal Mac app and its widget extension:

```sh
flutter build macos --release --build-name=1.8.0 --build-number=18
python3 tool/build_macos_release.py --execute --skip-flutter-config
```

If automatic export cannot use cloud signing, reuse the archive with installed
Mac App Store application/installer certificates and profiles for both targets:

```sh
python3 tool/build_macos_release.py --execute --export-only --manual-export
```

The build tool exports `build/macos-release/export/Onlynote.pkg`. Upload the
localized listing and prepared screenshots, validate that exact package with
Apple, then upload it:

```sh
python3 tool/release_macos.py inspect
python3 tool/release_macos.py prepare-listing --execute
python3 tool/release_macos.py upload-screenshots --execute
python3 tool/release_macos.py validate-package --package build/macos-release/export/Onlynote.pkg --execute
python3 tool/release_macos.py upload-package --package build/macos-release/export/Onlynote.pkg --execute
python3 tool/release_macos.py status
```

After Apple reports the build as `VALID`, `prepare-review` attaches that build
and verifies the listing, screenshots, encryption declaration, and reviewer
details. `submit-review` sends the Mac version to App Review, with automatic
release after approval. Logs and the resumable journal are in
`build/macos-release`.

```sh
python3 tool/release_macos.py prepare-review --execute
python3 tool/release_macos.py submit-review --execute
python3 tool/release_macos.py status
```

Mac 1.8.0 (18) was uploaded, validated, and submitted on October 14, 2026.
Its 19 localized listings and 27 screenshots were verified. The submission is
**Waiting for Review**, with automatic release after Apple approves it.
The signed package and release evidence are in the ignored `build/macos-release`
directory; screenshot previews are in `build/store_screenshots/2026-10-14`.

## Upload

The uploader loads credential helpers from `~/Development/secret` without
logging their tokens. Override that directory with `--credentials` if needed.
Python dependencies are `requests`, `Pillow`, and the existing credential
helpers' dependencies.

```sh
python3 tool/store_screenshots/upload.py validate
python3 tool/store_screenshots/upload.py apple --version 1.6.0 --create-draft
python3 tool/store_screenshots/upload.py play
```

Apple uploads require an editable version. The Apple action saves original
metadata/images, records reservations, waits for processing, and verifies the
final order. It does not upload a binary or submit a release for review. Legacy
inherited iPhone/iPad screenshots are cleared only within that editable version
so older devices can use the refreshed fallback images.

The Play action uploads and validates an uncommitted API edit, which expires
after roughly an hour. It is not a durable Console draft. To commit that exact
reviewed edit, use the separate command:

```sh
python3 tool/store_screenshots/upload.py play-commit
```

**Committing can send the listing changes for review and publishing.**
`changesNotSentForReview=true` is documented for rejection handling; it is not
a general draft-only switch. `ERROR_IF_IN_REVIEW` preserves an existing review
by returning an error. Check the Play Console publishing overview and coordinate
with the version that will ship the depicted features. For durable pending
changes, upload in the Console and save without sending for review.

Apple's screenshot-set API is deprecated in favor of Asset Library placements;
the uploader currently uses the still-documented legacy API. See
[Apple's migration guide](https://developer.apple.com/documentation/appstoreconnectapi/migrating-to-the-app-asset-library)
and [Google's commit reference](https://developers.google.com/android-publisher/api-ref/rest/v3/edits/commit).

## Completed refresh — October 8, 2026

- Apple: 72 ordered screenshots verified in the editable 1.6.0 draft across
  English, Simplified Chinese, and Traditional Chinese, for both iPhone sizes
  and iPad. The live 1.5.0 screenshot sets were checked and remain unchanged.
- Google Play: 96 placements saved in Console as **Draft changes** for en-US,
  zh-CN, zh-TW, and zh-HK, with 8 screenshots per phone/7-inch/10-inch set.
  Taiwan and Hong Kong reuse the same Traditional Chinese images. All 12 sets
  were checked again after reloading Console; counts and order persisted.
- At the time of the refresh, neither store had been submitted for review or
  published. Play's managed
  publishing setting remains off.

Detailed evidence is in `apple-upload-report.json`,
`apple-live-verification.json`, and `play-console-upload-report.json` under the
ignored output directory. Original screenshots are backed up there as well.
Console upload copies use unique device/language filename prefixes so they can
be searched and reused in the asset library without confusing different sets.

## Release submission — October 10, 2026

The refreshed screenshots were included with Onlynote 1.6.0 (build 16).
App Store submission is waiting for review, with automatic release after
approval and phased release off. Google Play's production release was committed
with status `completed`, 100% rollout, and all 27 localized release notes; the
same commit submitted the saved Console screenshot changes.
