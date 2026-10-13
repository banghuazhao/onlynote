import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:onlynote/common/platform_capabilities.dart';

/// The single source of truth for "may we track / may we serve personalized
/// ads".
///
/// Two consent signals apply to this app, and the effective answer is the most
/// restrictive of the two regardless of the order the user met them in:
///
///  * **Google UMP** — GDPR/ePrivacy consent. Required wherever the app ships
///    in the EEA, the UK and Switzerland, where AdMob will only serve through a
///    Google-certified CMP. The consent the form gathers is written to the
///    IAB TCF signals that the Mobile Ads SDK reads natively, so the SDK itself
///    decides personalized vs. non-personalized from them — the Dart side must
///    not second-guess that.
///  * **App Tracking Transparency** (iOS) — gates the IDFA. The OS enforces the
///    identifier itself; what it cannot do is stop us asking for a personalized
///    ad anyway, so [nonPersonalizedAds] carries that denial explicitly.
///
/// Nothing else in the app reads ATT or UMP and decides on its own. Ad code
/// waits for [isResolved] before requesting, and passes [nonPersonalizedAds]
/// into every request.
class ConsentGate extends ChangeNotifier {
  ConsentGate._();

  static final ConsentGate instance = ConsentGate._();

  bool _isResolved = false;
  bool _canRequestAds = false;
  bool _allowsPersonalization = false;
  bool _privacyOptionsRequired = false;

  /// The in-flight resolution, so concurrent callers await the *same* pass.
  /// A plain "already running" bool would let the second caller return early
  /// and read the answer before it exists.
  Future<void>? _resolution;

  /// Whether the gate has an answer yet.
  ///
  /// No ad may be requested before this turns true — on every launch, not just
  /// the first, since the stored choice has to be re-applied before the first
  /// request each time.
  bool get isResolved => _isResolved;

  /// Whether an ad request is permitted at all.
  bool get canRequestAds => PlatformCapabilities.mobileAds && _canRequestAds;

  /// The flag every [AdRequest] must carry.
  bool get nonPersonalizedAds => !_allowsPersonalization;

  /// Whether to surface the Settings entry that reopens the UMP privacy form.
  ///
  /// Google reports this as required exactly where the user is legally owed a
  /// way to withdraw, which is where we must offer one.
  bool get isPrivacyOptionsRequired =>
      PlatformCapabilities.mobileAds && _privacyOptionsRequired;

  /// Gathers consent, then initializes the Mobile Ads SDK.
  ///
  /// Safe to call more than once; only the first call does the work. Never
  /// throws — a network failure during the consent update leaves the gate
  /// resolved in its most restrictive state rather than blocking the app.
  Future<void> resolve() => _resolution ??= _resolve();

  Future<void> _resolve() async {
    try {
      if (!PlatformCapabilities.mobileAds) return;
      // Read ATT *without* prompting. A denial recorded on an earlier launch
      // must not be followed by a form that asks to track anyway.
      final priorStatus = await _trackingStatus();

      await _requestConsentInfoUpdate();

      // Google's documented order is UMP first, then ATT. The one case that
      // skips the form is a denial ATT recorded on an earlier launch: a
      // tracking-purposes form must never follow one. Android has no ATT, so
      // the form always runs there — gating this on `notDetermined` instead
      // would silently skip every Android user, who reports `notSupported`.
      final trackingDenied = priorStatus == TrackingStatus.denied ||
          priorStatus == TrackingStatus.restricted;
      if (!trackingDenied) {
        await _showConsentFormIfRequired();
      }

      var status = priorStatus;
      if (status == TrackingStatus.notDetermined) {
        status = await _requestTracking();
      }

      _canRequestAds = await _safely(
        () => ConsentInformation.instance.canRequestAds(),
        orElse: false,
      );

      // On iOS a denial forces non-personalized. Elsewhere there is no ATT and
      // the TCF signals the UMP form wrote govern personalization natively.
      _allowsPersonalization = defaultTargetPlatform != TargetPlatform.iOS ||
          status == TrackingStatus.authorized;

      _privacyOptionsRequired = await _safely(
            () => ConsentInformation.instance
                .getPrivacyOptionsRequirementStatus(),
            orElse: PrivacyOptionsRequirementStatus.unknown,
          ) ==
          PrivacyOptionsRequirementStatus.required;

      if (_canRequestAds) {
        await MobileAds.instance.initialize();
      }
    } catch (error, stackTrace) {
      _canRequestAds = false;
      _allowsPersonalization = false;
      _privacyOptionsRequired = false;
      debugPrint('ConsentGate: $error\n$stackTrace');
    } finally {
      _isResolved = true;
      notifyListeners();
    }
  }

  /// Reopens the UMP privacy options form so the user can change or withdraw
  /// consent. Withdrawing has to be as easy as giving it.
  Future<void> showPrivacyOptionsForm() async {
    if (!PlatformCapabilities.mobileAds) return;
    await _safely<void>(
      () => ConsentForm.showPrivacyOptionsForm((error) {
        if (error != null) {
          debugPrint('Privacy options form dismissed with error: '
              '${error.errorCode} ${error.message}');
        }
      }),
      orElse: null,
    );

    // The user may have just withdrawn consent, so re-read rather than assume
    // the previous answer still holds.
    _privacyOptionsRequired = await _safely(
          () =>
              ConsentInformation.instance.getPrivacyOptionsRequirementStatus(),
          orElse: PrivacyOptionsRequirementStatus.unknown,
        ) ==
        PrivacyOptionsRequirementStatus.required;
    _canRequestAds = await _safely(
      () => ConsentInformation.instance.canRequestAds(),
      orElse: _canRequestAds,
    );
    notifyListeners();
  }

  Future<TrackingStatus> _trackingStatus() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return TrackingStatus.notSupported;
    }
    return _safely(
      () => AppTrackingTransparency.trackingAuthorizationStatus,
      orElse: TrackingStatus.denied,
    );
  }

  Future<TrackingStatus> _requestTracking() async {
    if (defaultTargetPlatform != TargetPlatform.iOS) {
      return TrackingStatus.notSupported;
    }
    // iOS refuses to show the prompt until the app is actually foregrounded;
    // asking a beat later avoids a silent no-op on a cold launch.
    await Future<void>.delayed(const Duration(milliseconds: 500));
    return _safely(
      () => AppTrackingTransparency.requestTrackingAuthorization(),
      orElse: TrackingStatus.denied,
    );
  }

  /// Forces the UMP geography in debug builds so the EEA path can be exercised
  /// without a VPN. Compiled out of release: [kDebugMode] is a const false
  /// there, so neither this field nor the debug settings survive the tree
  /// shake.
  static DebugGeography? debugGeographyOverride;

  /// Clears the stored consent so the form can be re-tested from scratch.
  /// Debug only — a release build must never discard a recorded choice.
  Future<void> resetForTesting() async {
    if (!kDebugMode) return;
    if (PlatformCapabilities.mobileAds) {
      await ConsentInformation.instance.reset();
    }
    _resolution = null;
    _isResolved = false;
    _canRequestAds = false;
    _allowsPersonalization = false;
    _privacyOptionsRequired = false;
    notifyListeners();
  }

  Future<void> _requestConsentInfoUpdate() {
    final completer = Completer<void>();
    // The app is a general-purpose notes app, not directed to children, and
    // collects no age signal — so this is a statement of fact, not a guess.
    final params = ConsentRequestParameters(
      tagForUnderAgeOfConsent: false,
      consentDebugSettings: kDebugMode && debugGeographyOverride != null
          ? ConsentDebugSettings(debugGeography: debugGeographyOverride)
          : null,
    );
    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      completer.complete,
      (error) {
        debugPrint('Consent info update failed: '
            '${error.errorCode} ${error.message}');
        completer.complete();
      },
    );
    return completer.future;
  }

  Future<void> _showConsentFormIfRequired() async {
    await _safely<void>(
      () => ConsentForm.loadAndShowConsentFormIfRequired((error) {
        if (error != null) {
          debugPrint('Consent form dismissed with error: '
              '${error.errorCode} ${error.message}');
        }
      }),
      orElse: null,
    );
  }

  /// Consent plumbing must never take the app down with it — a failure here
  /// degrades to the restrictive default instead of throwing on the launch
  /// path.
  Future<T> _safely<T>(Future<T> Function() action, {required T orElse}) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      debugPrint('ConsentGate: $error\n$stackTrace');
      return orElse;
    }
  }
}
