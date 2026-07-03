import 'dart:io';

import 'package:flutter/foundation.dart';

import 'ad_ids_release.dart';

class AdsManager {
  static bool disableAllAdsForScreenshot = true;

  static String get bannerAdUnitId {
    if (Platform.isAndroid) {
      if (kDebugMode) {
        if (disableAllAdsForScreenshot) {
          return "";
        } else {
          return "ca-app-pub-3940256099942544/6300978111";
        }
      } else {
        // android banner ID
        return AdIdsRelease.bannerAdUnitIdAndroid;
      }
    } else if (Platform.isIOS) {
      if (kDebugMode) {
        if (disableAllAdsForScreenshot) {
          return "";
        } else {
          return "ca-app-pub-3940256099942544/2934735716";
        }
      } else {
        // ios banner ID
        return AdIdsRelease.bannerAdUnitIdIOS;
      }
    } else {
      throw new UnsupportedError("Unsupported platform");
    }
  }

  // static String get openAdUnitID {
  //   if (Platform.isAndroid) {
  //     if (kDebugMode) {
  //       if (disableAllAdsForScreenshot) {
  //         return "";
  //       } else {
  //         return 'ca-app-pub-3940256099942544/3419835294';
  //       }
  //     } else {
  //       // android openAd ID
  //       return openAdUnitIDAndroid;
  //     }
  //   } else if (Platform.isIOS) {
  //     if (kDebugMode) {
  //       if (disableAllAdsForScreenshot) {
  //         return "";
  //       } else {
  //         return 'ca-app-pub-3940256099942544/5662855259';
  //       }
  //     } else {
  //       // ios openAd ID
  //       return openAdUnitIDIOS;
  //     }
  //   } else {
  //     throw new UnsupportedError("Unsupported platform");
  //   }
  // }

  static void debugPrintID() {
    print("bannerAdUnitId: ${AdsManager.bannerAdUnitId}");
    // print("openAdUnitID: ${AdsManager.openAdUnitID}");
  }
}

// class AppOpenAdManager {
//   AppOpenAd? _appOpenAd;
//   bool _isShowingAd = false;
//
//   /// Maximum duration allowed between loading and showing the ad.
//   final Duration maxCacheDuration = Duration(hours: 4);
//
//   /// Keep track of load time so we don't show an expired ad.
//   DateTime? _appOpenLoadTime;
//
//   /// Load an AppOpenAd.
//   void loadAd() {
//     AppOpenAd.load(
//       adUnitId: AdsManager.openAdUnitID,
//       orientation: AppOpenAd.orientationPortrait,
//       request: AdRequest(),
//       adLoadCallback: AppOpenAdLoadCallback(
//         onAdLoaded: (ad) {
//           print('$ad loaded');
//           _appOpenLoadTime = DateTime.now();
//           _appOpenAd = ad;
//         },
//         onAdFailedToLoad: (error) {
//           print('AppOpenAd failed to load: $error');
//           // Handle the error.
//         },
//       ),
//     );
//   }
//
//   /// Whether an ad is available to be shown.
//   bool get isAdAvailable {
//     return _appOpenAd != null;
//   }
//
//   void showAdIfAvailable() {
//     if (!isAdAvailable) {
//       print('Tried to show ad before available.');
//       loadAd();
//       return;
//     }
//     if (_isShowingAd) {
//       print('Tried to show ad while already showing an ad.');
//       return;
//     }
//     if (_appOpenLoadTime != null &&
//         DateTime.now().subtract(maxCacheDuration).isAfter(_appOpenLoadTime!)) {
//       print('Maximum cache duration exceeded. Loading another ad.');
//       _appOpenAd?.dispose();
//       _appOpenAd = null;
//       loadAd();
//       return;
//     }
//
//     // Set the fullScreenContentCallback and show the ad.
//     _appOpenAd?.fullScreenContentCallback = FullScreenContentCallback(
//       onAdShowedFullScreenContent: (ad) {
//         _isShowingAd = true;
//         print('$ad onAdShowedFullScreenContent');
//       },
//       onAdFailedToShowFullScreenContent: (ad, error) {
//         print('$ad onAdFailedToShowFullScreenContent: $error');
//         _isShowingAd = false;
//         ad.dispose();
//         _appOpenAd = null;
//       },
//       onAdDismissedFullScreenContent: (ad) {
//         print('$ad onAdDismissedFullScreenContent');
//         _isShowingAd = false;
//         ad.dispose();
//         _appOpenAd = null;
//         loadAd();
//       },
//     );
//     _appOpenAd?.show();
//   }
// }
//
// /// Listens for app foreground events and shows app open ads.
// class AppLifecycleReactor extends WidgetsBindingObserver {
//   final AppOpenAdManager appOpenAdManager;
//
//   AppLifecycleReactor({required this.appOpenAdManager});
//
//   @override
//   Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
//     // Try to show an app open ad if the app is being resumed and
//     // we're not already showing an app open ad.
//     print("didChangeAppLifecycleState: $state");
//     if (state == AppLifecycleState.resumed) {
//       appOpenAdManager.showAdIfAvailable();
//     }
//   }
// }
