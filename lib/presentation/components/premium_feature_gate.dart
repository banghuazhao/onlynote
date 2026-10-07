import 'package:flutter/material.dart';
import 'package:onlynote/presentation/screens/settings/premium_screen.dart';
import 'package:onlynote/services/premium_access.dart';

/// Returns true only when the requested action is available after the upgrade.
Future<bool> ensurePremiumAccess(
  BuildContext context,
  PremiumFeature feature, {
  int? currentCount,
  PremiumAccess? access,
}) async {
  final entitlement = access ?? PremiumAccess.instance;
  if (entitlement.allows(feature, currentCount: currentCount)) return true;
  final route = MaterialPageRoute<void>(
    builder: (_) => PremiumScreen(
      purchases: entitlement.purchases,
      feature: feature,
    ),
  );
  await Navigator.of(context).push(route);
  // Finish the reverse animation before a caller opens another sheet or route.
  await route.completed;
  return context.mounted &&
      entitlement.allows(feature, currentCount: currentCount);
}
