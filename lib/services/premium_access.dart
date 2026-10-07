import 'package:onlynote/services/purchase_service.dart';

enum PremiumFeature {
  notes,
  folders,
  templates,
  repeatingReminders,
  individualCardStyle,
  voiceMemos,
}

/// Limits apply to new additions; existing notes and imported data stay usable.
class PremiumAccess {
  PremiumAccess({PurchaseService? purchases})
      : purchases = purchases ?? PurchaseService.instance;

  static final instance = PremiumAccess();
  static const freeFolderLimit = 3;
  static const freeTemplateLimit = 3;
  static const freeNoteLimit = 10;

  final PurchaseService purchases;

  bool get isPremium => purchases.isPremium;

  // Never lock features on platforms where an upgrade cannot be purchased.
  bool get limitsApply => purchases.isSupported && !isPremium;

  bool allows(PremiumFeature feature, {int? currentCount}) {
    if (!limitsApply) return true;
    return switch (feature) {
      PremiumFeature.notes =>
        currentCount != null && currentCount < freeNoteLimit,
      PremiumFeature.folders =>
        currentCount != null && currentCount < freeFolderLimit,
      PremiumFeature.templates =>
        currentCount != null && currentCount < freeTemplateLimit,
      PremiumFeature.repeatingReminders ||
      PremiumFeature.individualCardStyle ||
      PremiumFeature.voiceMemos =>
        false,
    };
  }

  void require(PremiumFeature feature, {int? currentCount}) {
    if (!allows(feature, currentCount: currentCount)) {
      throw PremiumRequired(feature);
    }
  }
}

class PremiumRequired implements Exception {
  const PremiumRequired(this.feature);

  final PremiumFeature feature;
}
