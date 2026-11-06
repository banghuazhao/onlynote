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
image counts, and file sizes. Use `--devices playphone` to export and validate
only a changed device set, or `--locales zh-Hant` for one language. Unselected
captures are not required, and their JPEG files and manifest entries are preserved.

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

## iPhone Duo screenshots

Duo captures are opt-in; the default capture and preparation commands retain the
original six mobile device classes. The outer display uses 466 × 678 logical
points at 3× (1398 × 2034 pixels), and the inner display uses 669 × 951 at 3×
(2007 × 2853 pixels). Both capture the app's adaptive layout in portrait.

Apple's [App Store Connect API 4.5.1 release notes](https://developer.apple.com/documentation/appstoreconnectapi/app-store-connect-api-4-5-1-release-notes)
introduce the `IPHONE_DUO` Asset Library display class. Duo uploads use library
images and placements rather than an invented legacy `ScreenshotDisplayType`.
The uploader reads [Apple's reference data](https://developer.apple.com/documentation/appstoreconnectapi/get-v1-appassetlibraryrefdata)
at runtime to discover exact image specifications, placement groups, and limits.
The current `IPHONE_DUO_PROFILE` group accepts **10 screenshots total per locale
across both displays**, so this sequence captures five screens for each display:

```sh
flutter test test/presentation/store_screenshots_test.dart --no-pub \
  --dart-define=CAPTURE_STORE_SCREENSHOTS=true \
  --dart-define=STORE_DEVICES=iphone_duo_outer,iphone_duo_inner \
  --dart-define=STORE_SCREENS=home,formattedNote,checklist,cardStyle,starterTemplates \
  --dart-define=STORE_OUTPUT_ROOT=build/store_screenshots/2026-10-25 \
  --concurrency=1
python3 tool/store_screenshots/prepare.py \
  --root build/store_screenshots/2026-10-25 \
  --devices iphone_duo_outer,iphone_duo_inner --count 5
python3 tool/store_screenshots/upload.py validate \
  --root build/store_screenshots/2026-10-25 \
  --devices iphone_duo_outer,iphone_duo_inner --count 5
python3 tool/store_screenshots/upload.py apple --version 1.12.0 \
  --root build/store_screenshots/2026-10-25 \
  --devices iphone_duo_outer,iphone_duo_inner --count 5
```

These commands generate and attach 30 screenshots across English, Simplified
Chinese, and Traditional Chinese, ordered as five outer-display images followed
by five inner-display images. The upload requires an existing editable version;
add `--create-draft` only when a draft should be created. It places screenshots on
that version's localizations and verifies their image specifications, processing
state, and order. It does not submit the version for review.

All new images must finish processing before any existing Duo placements are
replaced. Regular iPhone, iPad, and other placement groups remain untouched. When
uploading only one Duo display, screenshots with unselected image specifications
are retained subject to Apple's shared group limit. Original placement metadata
and image bytes are backed up under `backup/apple-library-<version>`; library
images are retained when placements are replaced.

The command can be rerun after interruption: content hashes in asset reference
names identify reusable committed images, and existing matching placements are
reused before their order is verified. Uncommitted reservations can remain in
the library after an interrupted transfer. The local reservation journal is
`apple-library-reservations.jsonl`, the processing and placement report is
`apple-library-upload-report.json`, and the discovered specification catalog is
`apple-asset-reference.json`. Authentication tokens and signed upload URLs are
never printed.

### October 25, 2026 refresh

Onlynote iOS 1.12.0 was created as an editable App Store draft. All 30 Duo
screenshots were uploaded and read back in the expected order: five outer and
five inner images for each of en-US, zh-Hans, and zh-Hant. Apple reports the
placements as `ACTIVE`; the version remains `PREPARE_FOR_SUBMISSION` with manual
release. The verification report and contact sheets are in
`build/store_screenshots/2026-10-25`.

The signed 1.12.0 (22) IPA was archived and exported with Xcode 27.1 and the
iPhoneOS 27.1 SDK to `build/ios/ipa/onlynote.ipa`. After explicit user approval,
build 22 was uploaded, processed as `VALID`, and attached to the draft. All 19
localized release notes and all 30 ordered Duo screenshots were read back and
verified. The version remains `PREPARE_FOR_SUBMISSION` with manual release and
has not been submitted for review. Build evidence is in
`build/ios/duo-draft-verification.json`; the combined final readback is in
`build/store_screenshots/2026-10-25/completion-summary.json`.

Validation completed: Flutter analysis reported no issues; the full Flutter
suite passed 2,285 tests with the opt-in capture test skipped; all 37 Python
release-tool tests passed. The separate Duo capture run passed all six
device/language cases. The iOS 27.1 simulator build also compiled successfully.
The interactive launch/pose smoke test could not run because Device Hub did
not respond. Resizing and asymmetric safe areas were verified by widget tests;
the launch check should be repeated when Device Hub is available.

## Header and Search Results artwork

The revised artwork for iOS 1.12.0 uses localized headlines beside large captures
of Onlynote's real library and checklist. Editable SVG compositions, opaque RGB
PNG exports, localized copy, and template evidence are saved in
`build/store_assets/2026-10-26-v2`. The earlier language-neutral generated artwork
is retained in `build/store_assets/2026-10-26` as a backup.

| Placement | Final file | Pixels | Art safe area (x, y, width, height) |
| --- | --- | --- | --- |
| Header | `<locale>/header.png` | 3840 × 1646 | 1097, 493, 1646, 661 |
| Search Results | `<locale>/search.png` | 3840 × 2560 | 836, 765, 2168, 1030 |

The safe areas were checked against both the supplied Figma document and Apple's
linked Sketch template on its
[asset best-practices page](https://developer.apple.com/app-store/asset-best-practices/).
They protect the key message and focal content; secondary artwork may fill the
canvas and bleed beyond them, as Apple's own template examples do. The compositor
checks headline/subtitle bounds, glyph coverage, and the main app-content focal
rectangle. Its guide previews are QA aids, not exported artwork or exact device
crop simulations. App Store Connect Preview remains the place to check Apple's
device presentation.

Generate raw production UI captures without the screenshot caption frame, then
compose all existing listing languages:

```sh
flutter test test/presentation/store_screenshots_test.dart --no-pub \
  --dart-define=CAPTURE_STORE_SCREENSHOTS=true \
  --dart-define=STORE_CAPTURE_APP_ONLY=true \
  --dart-define=STORE_DEVICES=iphone_duo_outer,iphone_duo_inner \
  --dart-define=STORE_SCREENS=home,checklist \
  --dart-define=STORE_OUTPUT_ROOT=build/store_assets/2026-10-26/raw-app \
  --concurrency=1
python3 tool/store_screenshots/compose_creative_assets.py --locales all
```

The SVG renderer uses the bundled Node/Sharp runtime and genuine local fonts;
it embeds the production capture PNGs without reconstructing the interface.
Marketing copy in `tool/store_screenshots/creative_copy.json` is translated for
all 19 listing locales; the output directory retains the approved copy snapshot.
UI examples use the
three languages supported by the app: English, Simplified Chinese, and
Traditional Chinese. `creative-manifest.json` maps each locale to its two images;
composition metadata and safe-area checks are recorded separately.

The current live reference data requires PNG for the dedicated header. The
uploader discovers image specifications and `CREATIVE_ASSETS` placement mappings
from Apple rather than guessing IDs.

```sh
python3 tool/store_screenshots/upload_creative_assets.py validate \
  --root build/store_assets/2026-10-26-v2 \
  --manifest build/store_assets/2026-10-26-v2/creative-manifest.json \
  --reference build/store_assets/2026-10-26/apple-creative-reference.json
python3 tool/store_screenshots/upload_creative_assets.py upload \
  --root build/store_assets/2026-10-26-v2 --version 1.12.0 \
  --manifest build/store_assets/2026-10-26-v2/creative-manifest.json --execute
```

By default, the manifest must cover every existing localization; use
`--locales en-US,zh-Hans` to scope a later change. The earlier shared
`--header`/`--search` form is also supported. Identical image bytes are reused
across regional locales. Every image must process successfully before any
placements change. All original creative slots are backed up before the first
replacement, prior library images are retained, and repeated runs reuse content
hashes and placements. The uploader verifies all other screenshot placements,
the build attachment, release setting, and version state after writing. It never
submits a version or creative assets for review. Evidence is recorded in
`apple-creative-upload-report.json` under the selected output root.

The first artwork upload on October 26, 2026 verified 38 placements across all
19 localizations while preserving the 102 screenshot placements, build 22,
manual release, and `PREPARE_FOR_SUBMISSION` state. Its independent readback
remains in the original output directory.

The template-guided revision replaced all 38 placements with the localized
artwork in `build/store_assets/2026-10-26-v2`. All 28 unique images processed
successfully. Independent API readback verified every locale's exact images,
all 19 release notes, the unchanged 102 screenshot placements and their order,
build 22 (`VALID`), manual release, and `PREPARE_FOR_SUBMISSION`. Prior library
images remain available. Evidence is in `apple-creative-final-verification.json`.

App Store Connect Device Preview was also checked in English for both Header
and Search Results on iPhone, Duo outer portrait, and Duo inner landscape; key
text and focal app content remained visible. Details are in `preview-qa.json`.
All 56 Python release-tool tests passed. The revision remains unsubmitted.

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
the uploader uses Asset Library for Duo and retains the legacy API for the
original iPhone/iPad screenshot classes. See
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

## Android acquisition artwork — October 26, 2026

The fresh Publisher API snapshot in
`build/android-growth/2026-10-26/play-baseline.json` is the current asset
baseline. It shows four English screenshots in each device group and one
feature graphic. The Chinese image arrays are empty and inherit the English
default. The original public images, archived in `baseline-assets/`, match
the API SHA256 values. They depict the older 2022 interface; the tablet groups
reuse phone-shaped 1176×2400 captures. The old feature graphic contains four
small screens and a visible success toast. Earlier completion notes above
are historical evidence and do not establish the current live listing.

Generate six current Android screens, with real responsive tablet layouts and
all three supported app interface languages:

```sh
flutter test test/presentation/store_screenshots_test.dart --no-pub \
  --dart-define=CAPTURE_STORE_SCREENSHOTS=true \
  --dart-define=STORE_CAPTURE_APP_ONLY=true \
  --dart-define=STORE_DEVICES=playphone,play7inch_16_9,play10inch_16_9 \
  --dart-define=STORE_LOCALES=en,zh-Hans,zh-Hant \
  --dart-define=STORE_SCREENS=home,checklist,foldersSearch,formattedNote,reminderAgenda,backup \
  --dart-define=STORE_OUTPUT_ROOT=build/android-growth/2026-10-26/raw-app \
  --concurrency=1
```

The active tablet profiles are opt-in: 2304×1296 (1152×648 logical at 2×)
and 3200×1800 (1280×720 logical at 2.5×), both 16:9. Their short logical side
is at least 600 dp. The portrait tablet trials remain available as separate
opt-in profiles, but the final artwork uses landscape to reduce unused space.
Existing default devices and iOS artwork are unchanged. `backup` is an explicit
extra capture of the real production Backup & Restore screen, preserving the
existing eight-screen sequence and filenames. Sample notes and native services
are deterministic fixtures; app screens, controls, typography, and responsive
layout come from production widgets. The fixture suppresses advertising, so
artwork must not claim that Android is ad-free. Native Android widgets require
a genuine native capture and are not simulated in these images.

Build an English preview, then the complete localized artwork:

```sh
python3 tool/store_screenshots/compose_android_assets.py --locales en-US
python3 tool/store_screenshots/compose_android_assets.py --locales all
python3 -W error::ResourceWarning -m unittest discover -s tool/tests -p 'test_compose_android_assets.py'
```

To refresh only the tablets after reviewing phone and feature artwork, pass
`--devices=play7inch_16_9,play10inch_16_9`. Scoped composition merges those
selected groups into the existing manifest and preserves approved phone and
feature graphic image bytes.

The compositor exports under `build/android-growth/2026-10-26/assets/`:

- Six 1080×1920 phone screenshots per language, with one short editable SVG
  headline above the actual Android capture. The tagline region is 15.2%.
- Six tablet images per language and size, exported directly without marketing
  captions, cropping, rescaling, or device frames.
- A separate 1024×500 RGB PNG feature graphic and editable SVG using the real
  Android notes and checklist captures.
- `android-assets-manifest.json` with ordered paths and descriptive alt text,
  `composition-report.json` with source hashes and text metrics, and contact
  sheets for review. Paths in the manifest are relative to its directory.

The first three images show notes, checklists, and folders/search. The remaining
three show formatted notes, reminders, and local backup/export. English,
Simplified Chinese, and Traditional Chinese are separate artwork sets; the
manifest explicitly maps Hong Kong to the same Traditional Chinese files.
These are local
outputs only. Verify the depicted app version before publishing listing assets.

See Google's [preview asset requirements and recommendations](https://support.google.com/googleplay/android-developer/answer/9866151)
for the 1024×500 opaque feature graphic, 9:16/16:9 screenshots, localized overlays,
and priority for actual interface content in the first three screenshots.

Use the scoped listing uploader after reviewing the artwork and Publishing
overview. These are three separate commands; only the last one commits:

```sh
python3 tool/store_screenshots/upload_play_listing.py validate \
  --metadata build/android-growth/2026-10-26/metadata-proposed.json \
  --assets build/android-growth/2026-10-26/assets/android-assets-manifest.json \
  --root build/android-growth/2026-10-26/play-listing

python3 tool/store_screenshots/upload_play_listing.py stage --execute \
  --metadata build/android-growth/2026-10-26/metadata-proposed.json \
  --assets build/android-growth/2026-10-26/assets/android-assets-manifest.json \
  --root build/android-growth/2026-10-26/play-listing

# Review the staged report and Publishing overview before this separate action.
python3 tool/store_screenshots/upload_play_listing.py commit --execute \
  --metadata build/android-growth/2026-10-26/metadata-proposed.json \
  --assets build/android-growth/2026-10-26/assets/android-assets-manifest.json \
  --root build/android-growth/2026-10-26/play-listing
```

`validate` is offline. `stage` updates all 27 supplied text localizations and only
nonempty image arrays in the four permitted formats: phone, seven-inch,
ten-inch, and feature graphic. Omitted/empty arrays preserve existing artwork.
Before the first listing mutation, it saves every listing, track, application
detail, media inventory, and downloaded image bytes for the selected replacement
sets. Downloaded preview bytes retain their own hashes separately from Google's
original upload hashes. Icons, video URLs, other media, and production build 21
must remain unchanged. The ordered image hashes and exact text readback must
match the frozen inputs.

The journal binds one API edit to those exact input files and image bytes;
rerunning `stage` resumes it. API edits have a temporary, server-provided
expiry; check `expiresAtUtc` and `expiryTimeSeconds` in the journal/report
instead of assuming a fixed lifetime. They are temporary API state,
not persistent Console drafts. Coordinate other API writers, resolve unrelated
Console changes first, and avoid Console mutations while an edit is active:
creating another edit with the same API user or changing the Console can
invalidate it. Unknown upload responses are read back before any retry; unknown
commit responses require manual reconciliation.

`commit` repeats the preservation/readback checks and uses
`changesInReviewBehavior=ERROR_IF_IN_REVIEW`, so it refuses to cancel an existing
review. It does not use `changesNotSentForReview` as a draft switch. The manifest's
alt text is retained for review; Google's current Image API has no alt-text
field. Neither action builds or uploads an application binary.

After a successful commit and only when no API edit is active, independently
verify the stored listing with the prepared read-only inspection script:

```sh
python3 build/android-growth/2026-10-26/verify-play-listing-postcommit.py \
  --execute --confirm-no-active-edit
```

It checks the exact frozen plan and preserved baseline in a fresh temporary
edit, saves the snapshot/result, and deletes that edit in `finally`. It refuses
to run unless the uploader journal is `COMMITTED`; it performs no listing
updates or commit. A stored Publisher snapshot confirms API state, while public
store visibility and review status still need a Console check.
