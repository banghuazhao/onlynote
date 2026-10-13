import 'package:onlynote/domain/model/note_card_style.dart';

import 'premium_access.dart';

/// Gates newly applied choices while preserving existing imported appearance.
///
/// Global callers resolve a missing proposed theme against their current
/// default first. Per-note callers pass the stored overrides so inheritance
/// does not become an unintended new theme selection.
PremiumFeature? requiredNoteStyleFeature(
  NoteCardStyle before,
  NoteCardStyle after, {
  bool isGlobalDefault = false,
}) {
  if (before.noteTheme != after.noteTheme &&
      after.noteTheme?.isPremium == true) {
    return PremiumFeature.noteThemes;
  }
  if (isGlobalDefault) return null;
  final beforeOverrides = before.copyWith(clearNoteTheme: true);
  final afterOverrides = after.copyWith(clearNoteTheme: true);
  if (beforeOverrides != afterOverrides && !afterOverrides.isDefault) {
    return PremiumFeature.individualCardStyle;
  }
  return null;
}
