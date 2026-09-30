import 'package:flutter/material.dart';
import '../ads/ad_service.dart';
import '../auth/auth_controller.dart';
import '../errors/app_failure.dart';
import '../theme/taash_theme.dart';

/// Slide-up "Need more coins?" sheet. Reused by the home quick-match gate and
/// the VS-bots room flow so every low-coins moment offers the same path to
/// earn coins.
///
/// Two ways to top up sit side by side: the rewarded ad, and the Coins Shop.
/// They are deliberately separated so the free option is not buried, but the
/// purchase path stays available even when no ad can be served, which is the
/// moment a player is most likely to want it.
class RewardSheet extends StatefulWidget {
  const RewardSheet({
    super.key,
    required this.adService,
    required this.auth,
    this.onPurchaseCoins,
  });

  final AdService adService;
  final AuthController auth;

  /// Navigates to the Coins Shop. Omitted where the caller cannot switch tabs,
  /// in which case the purchase button is not offered at all.
  final VoidCallback? onPurchaseCoins;

  bool get canPurchase => onPurchaseCoins != null;

  @override
  State<RewardSheet> createState() => _RewardSheetState();
}

class _RewardSheetState extends State<RewardSheet> {
  bool _loading = false;
  bool _processing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    widget.adService.addListener(_onAdChanged);
  }

  @override
  void dispose() {
    widget.adService.removeListener(_onAdChanged);
    super.dispose();
  }

  void _onAdChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _watchAd() async {
    if (_loading || _processing) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final sessionId = await widget.auth.api.startRewardSession();
      final playerId = widget.auth.profile?.id ?? '';

      if (!mounted) return;
      setState(() => _loading = false);

      final shown = await widget.adService.showRewardedAd(
        customData: sessionId,
        userId: playerId,
        onUserEarnedReward: (amount) {
          // The reward itself arrives via the AdMob SSV callback. In local
          // development (no AdMob account / SSV callback URL yet) the callback
          // never fires, so a dev-only grant endpoint mimics it. It must be
          // disabled in production: it trusts the client.
          if (widget.auth.api.needsDevRewardGrant) {
            widget.auth.api.devGrantReward(sessionId).catchError((Object e) {});
          }
        },
      );

      if (!shown) {
        if (!mounted) return;
        setState(() => _error = 'Ad could not be shown. Please try again.');
        return;
      }

      if (!mounted) return;
      setState(() => _processing = true);

      // Poll for balance update from SSV callback
      for (var i = 0; i < 10; i++) {
        await Future<void>.delayed(const Duration(seconds: 1));
        if (!mounted) return;
        try {
          await widget.auth.refreshProfile();
        } catch (_) {}
        if (!mounted) return;
        if (!mounted) break;
      }

      if (!mounted) return;
      setState(() => _processing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Your reward is being processed. Please check your balance shortly.',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final coins = widget.auth.profile?.coins ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 4,
            decoration: BoxDecoration(
              color: T.outline,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Icon(
            Icons.toll_rounded,
            size: 48,
            color: T.ochre,
          ),
          const SizedBox(height: 16),
          Text(
            'Need more coins?',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Watch a short ad to earn 100 coins',
            style: TextStyle(color: T.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Current balance: $coins coins',
            style: TextStyle(
              color: T.ochre,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          if (_processing) ...[
            const CircularProgressIndicator(),
            const SizedBox(height: 12),
            Text(
              'Processing your reward...',
              style: TextStyle(color: T.muted),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: T.ochre,
                  foregroundColor: const Color(0xff2B1B35),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: (widget.adService.isReady && !_loading)
                    ? _watchAd
                    : null,
                icon: _loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_circle_outline),
                label: Text(
                  _loading ? 'Preparing...' : 'Watch Ad +100 Coins',
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            if (!widget.adService.isReady && !_loading) ...[
              const SizedBox(height: 12),
              Text(
                'No ad available right now. Try again shortly.',
                style: TextStyle(color: T.muted, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
            if (widget.canPurchase) ...[
              // A separator above the purchase path keeps "earn free" and "spend
              // money" as two clearly different choices rather than two buttons
              // that look like the same decision.
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: T.outline, height: 1),
              ),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: T.coral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: _loading ? null : widget.onPurchaseCoins,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Purchase Coins'),
                ),
              ),
            ],
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}