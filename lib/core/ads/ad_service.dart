import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  AdService({required this.adUnitId, Future<void>? initialization})
      : _initialization = initialization ?? Future<void>.value() {
    _start();
  }

  final String adUnitId;
  final Future<void> _initialization;

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isReady = false;
  bool _started = false;
  bool _disposed = false;

  bool get isReady => _isReady;
  bool get isLoading => _isLoading;

  void _start() {
    if (_started) return;
    _started = true;
    _initialization.then((_) {
      if (_disposed) return;
      loadAd();
    }).catchError((_) {
      if (_disposed) return;
      loadAd();
    });
  }

  void loadAd() {
    if (_disposed || adUnitId.isEmpty || _isLoading) return;
    _isLoading = true;
    notifyListeners();

    RewardedAd.load(
      adUnitId: adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
            return;
          }
          _rewardedAd = ad;
          _isReady = true;
          _isLoading = false;
          notifyListeners();
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _rewardedAd = null;
              _isReady = false;
              notifyListeners();
              loadAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _rewardedAd = null;
              _isReady = false;
              notifyListeners();
              loadAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _isLoading = false;
          _isReady = false;
          _rewardedAd = null;
          notifyListeners();
          Future.delayed(const Duration(seconds: 15), () {
            if (!_disposed) loadAd();
          });
        },
      ),
    );
  }

  Future<bool> showRewardedAd({
    required String customData,
    String? userId,
    required void Function(int amount) onUserEarnedReward,
  }) async {
    final ad = _rewardedAd;
    if (ad == null || !_isReady) return false;

    _isReady = false;
    notifyListeners();

    try {
      await ad.setServerSideOptions(
        ServerSideVerificationOptions(
          userId: userId,
          customData: customData,
        ),
      );
      await ad.show(
        onUserEarnedReward: (ad, reward) {
          onUserEarnedReward(reward.amount.toInt());
        },
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    super.dispose();
  }
}