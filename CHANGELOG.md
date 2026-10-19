# Changelog

## Unreleased

- Added a visible sort label above the library for non-manual ordering, while keeping Trash's deletion-date order separate.
- Added the existing last-modified timestamp to Note info, using the app language and device clock preference.
- Added a Mac keyboard-shortcuts guide in Settings for note creation, search, editing, and clipboard commands.
- Added the last backup export date, distinguishing backups saved on Mac from backups shared on mobile, while keeping previous status after cancelled or failed exports.
- Localized note-reader dates and times, including the device's 12-hour or 24-hour clock preference.
- Remembered whether completed checklist items are collapsed across notes and launches, while keeping every item visible in exports and search navigation.

## 1.9.0+19

- Added Export notes to Backup & Restore, saving every note, including archived ones, as one zip of Markdown, plain text, or PDF files — one file per note.
- Kept photos and recordings beside their Markdown notes in the export, with links that resolve once the archive is unpacked.
- Reported export progress per note, and finished an export that one unreadable note or missing photo would otherwise have stopped.
- Added Sort by to the library panel, with manual order, last modified, oldest first, and title A–Z or Z–A; the choice is remembered between launches.
- Kept pinned notes above every sort order, and left Trash on most recently deleted first.
- Switched back to manual order when reordering starts, so a dragged arrangement is always the one on screen.

## 1.8.0+18

- Added the native macOS app with resizable layouts, app menus, keyboard shortcuts, and right-click actions.
- Added Mac paper-note and overview widgets with note selection and interactive checklists.
- Added Mac voice memos, photo text recognition, reminders, and backup import and export.
- Added Mac widget setup guidance in English, Simplified Chinese, and Traditional Chinese.

- Added stationery-inspired note themes with app defaults, per-note overrides, and Premium advanced styles.
- Grouped card appearance controls into horizontal Theme, Color, Text, and Layout sections.
- Localized reminder dates on Home cards using the app language and device clock preference.
- Added selected-tag counts, hidden-selection counts, and tag-limit guidance to the library panel.
- Added name search to custom and starter templates.
- Added name search to saved views in the library panel.
- Made Note info available from Trash, including the full stored deletion timestamp.
- Added folder-name search to the folder picker, Manage folders, and Move to folder.
- Added transcript snippets to recording-only history entries using stored text.
- Added clear saved-view limit feedback before naming a new view.
- Added copying full note text, including transcripts, checklist tasks, and reminder text, from the share panel.
- Added localized "Moved to Trash" dates to note cards and note information when deletion metadata is available.
- Added opening folders from Manage folders while preserving the current search, filters, and library scope.
- Added Clear search and Clear filters actions when no notes match, preserving the current folder, Archive, or Trash view and saved views.
- Added a localized count of notes matching the current search, filters, and tags.
- Expanded Note info with photo and recording counts plus total recording time, using attachment metadata without loading media files.
- Added scanned-page counts, checklist completion progress, and remaining-task totals to Note info.
- Added copying unfinished checklist tasks in their original order, including from the note reader.
- Added saved-view descriptions showing the folder, search, filters, tags, and archive scope.
- Added Recordings and Scanned documents filters, including support in saved views and backups.
- Expanded restore previews with the backup date, recording files, saved views, and history-version totals.
- Added removable active filter and tag summaries to Home, including when search is closed.
- Added tag search to the library panel, preserving selected tags hidden by the search.
- Added backup sharing outcome messages for completion, cancellation, failure, and unconfirmed results.

## 1.4.0+14

- Added a Home Screen widget on iOS and Android showing pinned and recent notes, with a quick-add shortcut and deep links into a note.
- Moved the folder filter into the app bar title, freeing a row of vertical space and adding note counts plus rename/delete to the picker.
- Dropped the home banner to a standard 320x50 so it stops eating a note row.
- Added a GDPR/UMP consent flow with a single resolver combining consent and App Tracking Transparency; no ad is requested before that answer exists, and a denial in either prompt forces non-personalized ads.
- Added Settings > Privacy with a privacy policy link and an ad privacy settings entry for changing or withdrawing consent.
- Rewrote the tracking permission explanation to say what the advertising identifier is actually used for.

## 1.3.0+13

- Added folders to organize notes, with create/rename/delete and Settings management.
- Added search to quickly find notes.
- Added Trash with restore and permanent delete.
- Added a short onboarding flow for new users.
- Updated SKAdNetwork identifiers for ad attribution.

## 1.2.0+12

- Added iOS Remove Ads purchase support with restore handling.
- Polished the note editor, cards, settings, and share layouts.
- Improved checklist focus behavior, selection affordances, and animations.
- Modernized release readiness with updated privacy and analyzer cleanup.
