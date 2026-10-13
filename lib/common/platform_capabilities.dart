import 'package:flutter/foundation.dart';

/// Features implemented by Onlynote's platform plugins and native bridges.
abstract final class PlatformCapabilities {
  static bool get _mobile =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  static bool get _mobileOrMac =>
      _mobile || (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS);

  static bool get mobileAds => _mobile;
  static bool get homeWidgets => _mobileOrMac;
  static bool get mobileHomeWidgets => _mobile;
  static bool get camera => _mobile;
  static bool get documentScanner => _mobile;
  static bool get sharedNoteInbox => _mobile;
  static bool get appShortcuts => _mobile;

  static bool get photoLibrary => _mobileOrMac;
  static bool get photoText => _mobileOrMac;
  static bool get voiceMemos => _mobileOrMac;

  static bool get appStorePurchases =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.iOS ||
          defaultTargetPlatform == TargetPlatform.macOS);
}
