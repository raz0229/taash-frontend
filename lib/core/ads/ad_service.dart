import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService extends ChangeNotifier {
  AdService({
    required this.adUnitId,
    this.interstitialAdUnitId = '',
    Future<void>? initialization,
  }) : _initialization = initialization ?? Future<void>.value() {
    _start();
  }

  final String adUnitId;
  final String interstitialAdUnitId;
  final Future<void> _initialization;

  RewardedAd? _rewardedAd;
  bool _isLoading = false;
  bool _isReady = false;
  bool _started = false;
  bool _disposed = false;

  InterstitialAd? _interstitialAd;
  bool _isInterstitialLoading = false;
  bool _isInterstitialReady = false;
  DateTime? _lastInterstitialShown;
  static const _interstitialCooldown = Duration(seconds: 30);

  bool get isReady => _isReady;
  bool get isLoading => _isLoading;
  bool get isInterstitialReady => _isInterstitialReady;

  void _start() {
    if (_started) return;
    _started = true;
    debugPrint('[AdService] _start: waiting for MobileAds init…');
    _initialization.then((_) {
      if (_disposed) return;
      debugPrint('[AdService] MobileAds init done, loading ads');
      loadAd();
      loadInterstitialAd();
    }).catchError((e) {
      debugPrint('[AdService] MobileAds init FAILED: $e');
      if (_disposed) return;
      loadAd();
      loadInterstitialAd();
    });
  }

  // ── Rewarded Ad ──────────────────────────────────────────────────────

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

  // ── Interstitial Ad ──────────────────────────────────────────────────

  void loadInterstitialAd() {
    if (_disposed || interstitialAdUnitId.isEmpty || _isInterstitialLoading) {
      debugPrint(
        '[AdService] loadInterstitialAd skipped: '
        'disposed=$_disposed, unitIdEmpty=${interstitialAdUnitId.isEmpty}, '
        'loading=$_isInterstitialLoading',
      );
      return;
    }
    _isInterstitialLoading = true;
    debugPrint('[AdService] loading interstitial ad…');

    InterstitialAd.load(
      adUnitId: interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          if (_disposed) {
            ad.dispose();
            return;
          }
          _interstitialAd = ad;
          _isInterstitialReady = true;
          _isInterstitialLoading = false;
          debugPrint('[AdService] interstitial ad LOADED');
          notifyListeners();
          _interstitialAd!.fullScreenContentCallback =
              FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[AdService] interstitial ad dismissed');
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              notifyListeners();
              loadInterstitialAd();
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint(
                '[AdService] interstitial ad FAILED TO SHOW: $error',
              );
              ad.dispose();
              _interstitialAd = null;
              _isInterstitialReady = false;
              notifyListeners();
              loadInterstitialAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          debugPrint('[AdService] interstitial ad FAILED TO LOAD: $error');
          _isInterstitialLoading = false;
          _isInterstitialReady = false;
          _interstitialAd = null;
          notifyListeners();
          Future.delayed(const Duration(seconds: 15), () {
            if (!_disposed) loadInterstitialAd();
          });
        },
      ),
    );
  }

  /// Shows a full-screen interstitial ad.
  ///
  /// Respects a 30-second cooldown to avoid ad fatigue. Returns `true` if the
  /// ad was actually shown, `false` otherwise (not ready, cooldown active, etc.).
  Future<bool> showInterstitialAd() async {
    debugPrint(
      '[AdService] showInterstitialAd called: ready=$_isInterstitialReady',
    );
    if (!_isInterstitialReady) {
      debugPrint('[AdService] interstitial not ready, skipping');
      return false;
    }

    if (_lastInterstitialShown != null &&
        DateTime.now().difference(_lastInterstitialShown!) <
            _interstitialCooldown) {
      debugPrint('[AdService] interstitial cooldown active, skipping');
      return false;
    }

    final ad = _interstitialAd;
    if (ad == null) {
      debugPrint('[AdService] interstitial ad object is null, skipping');
      return false;
    }

    _isInterstitialReady = false;
    _lastInterstitialShown = DateTime.now();
    notifyListeners();

    try {
      debugPrint('[AdService] showing interstitial ad…');
      await ad.show();
      debugPrint('[AdService] interstitial ad shown successfully');
      return true;
    } catch (e) {
      debugPrint('[AdService] interstitial ad show FAILED: $e');
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _rewardedAd?.dispose();
    _rewardedAd = null;
    _interstitialAd?.dispose();
    _interstitialAd = null;
    super.dispose();
  }
}
