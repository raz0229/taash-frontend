import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../profile/presentation.dart';
import 'avatar_catalog.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key, required this.auth, required this.api});
  final AuthController auth;
  final ApiClient api;
  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  List<AvatarItem>? _catalog;
  String? _error;
  String? _notice;
  String _filter = 'all';
  int? _busyId;
  bool _loading = true;
  bool _needsReconcile = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await AvatarItem.load();
      await widget.auth.refreshProfile();
      if (mounted) {
        setState(() {
          _catalog = data;
          _needsReconcile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppFailure
              ? e.message
              : Copy.weCouldNotLoadTheAvatarCollection,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _choose(AvatarItem item) async {
    final profile = widget.auth.profile;
    if (profile == null || _busyId != null || _needsReconcile || _loading) {
      return;
    }
    final state = avatarOwnership(item, profile);
    if (state == AvatarOwnership.selected ||
        state == AvatarOwnership.insufficient) {
      return;
    }
    if (state == AvatarOwnership.affordable) {
      final confirmed = await confirmAction(
        context,
        title: Copy.unlock2(item.name),
        message: Copy.virtualCoinsYourBalanceCoinsThisUnlocks(
          displayNumber(item.cost),
          displayNumber(profile.coins),
        ),
        confirmLabel: item.cost == 0
            ? Copy.unlockForFree
            : Copy.unlockFor(displayNumber(item.cost)),
      );
      if (!confirmed || !mounted) return;
    }
    // A global busy guard prevents double tap / cross-item mutation overlap.
    if (_busyId != null || !mounted) return;
    setState(() {
      _busyId = item.id;
      _error = null;
      _notice = null;
    });
    var acknowledged = false;
    try {
      if (state == AvatarOwnership.owned) {
        await widget.api.selectPfp(profile.id, item.id);
      } else {
        await widget.api.buyPfp(profile.id, item.id);
      }
      acknowledged = true;
      await widget.auth.refreshProfile();
      if (mounted) {
        setState(
          () => _notice = state == AvatarOwnership.owned
              ? '${item.name} is your new look. It will appear when you next join a room.'
              : '${item.name} is unlocked. Select it whenever you like.',
        );
      }
    } catch (e) {
      // Never replay a purchase whose response was lost. Only a read may reconcile.
      final uncertain = acknowledged || e is AppFailure && e.uncertain;
      if (mounted) {
        setState(() {
          _needsReconcile = uncertain;
          _error = uncertain
              ? Copy.yourAvatarActionMayHaveCompletedRefresh
              : e is AppFailure
              ? e.message
              : Copy.weCouldNotChangeYourAvatarPlease;
        });
      }
      if (!uncertain) {
        try {
          await widget.auth.refreshProfile();
        } catch (_) {
          /* Original error remains visible. */
        }
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.auth,
    builder: (context, _) {
      final profile = widget.auth.profile;
      return Scaffold(
        appBar: AppBar(
          title: const Text(Copy.avatarCollection),
          actions: [
            IconButton(
              tooltip: Copy.refreshCollectionAndBalance,
              onPressed: _loading || _busyId != null ? null : _load,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: _catalog == null
              ? _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          semanticsLabel: Copy.loadingAvatars,
                        ),
                      )
                    : TaashEmpty(
                        title: Copy.collectionUnavailable,
                        message: _error ?? Copy.pleaseTryAgain,
                        onRetry: _load,
                      )
              : profile == null
              ? const TaashEmpty(
                  title: Copy.signInToChooseYourLook,
                  message: Copy.yourCollectionIsSavedWithYourAccount,
                )
              : RefreshIndicator(
                  onRefresh: _busyId == null ? _load : () async {},
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                    children: [
                      TaashPanel(
                        color: T.pine,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final large =
                                MediaQuery.textScalerOf(context).scale(1) > 1.4;
                            final copy = Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  Copy.makeAnEntrance,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 23,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${profile.unlockedPfps.length} in your collection',
                                  style: const TextStyle(color: T.mint),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  Copy.virtualCoins2(
                                    displayNumber(profile.coins),
                                  ),
                                  style: const TextStyle(
                                    color: T.ochre,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            );
                            return large
                                ? Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TaashAvatar(
                                        id: profile.selectedPfp,
                                        size: 72,
                                      ),
                                      const SizedBox(height: 16),
                                      copy,
                                    ],
                                  )
                                : Row(
                                    children: [
                                      TaashAvatar(
                                        id: profile.selectedPfp,
                                        size: 72,
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(child: copy),
                                    ],
                                  );
                          },
                        ),
                      ),
                      const SizedBox(height: 22),
                      const Text(
                        'A familiar face at every room. Unlock a look with virtual coins, then make it yours.',
                        style: TextStyle(color: T.muted),
                      ),
                      if (_loading) ...[
                        const SizedBox(height: 16),
                        const LinearProgressIndicator(
                          semanticsLabel: Copy.refreshingCollection,
                        ),
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        TaashPanel(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _error!,
                                style: const TextStyle(color: T.danger),
                              ),
                              if (_needsReconcile) ...[
                                const SizedBox(height: 12),
                                TaashButton(
                                  label: Copy.checkCollection,
                                  onPressed: _loading ? null : _load,
                                  secondary: true,
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                      if (_notice != null) ...[
                        const SizedBox(height: 16),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _notice!,
                            style: const TextStyle(
                              color: T.pine,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final rarity in [
                            'all',
                            'owned',
                            'common',
                            'rare',
                            'epic',
                            'legendary',
                          ])
                            ChoiceChip(
                              label: Text(
                                rarity[0].toUpperCase() + rarity.substring(1),
                              ),
                              selected: _filter == rarity,
                              onSelected: (_) =>
                                  setState(() => _filter = rarity),
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final visible = _catalog!
                              .where(
                                (item) =>
                                    _filter == 'all' ||
                                    _filter == item.rarity ||
                                    _filter == 'owned' &&
                                        profile.unlockedPfps.contains(item.id),
                              )
                              .toList();
                          final textScale =
                              MediaQuery.textScalerOf(context).scale(16) / 16;
                          final columns =
                              constraints.maxWidth >= 340 && textScale <= 1.4
                              ? 2
                              : 1;
                          if (visible.isEmpty) {
                            return const TaashEmpty(
                              title: 'A new look awaits',
                              message: Copy.noAvatarsInThisCollectionYet,
                            );
                          }
                          final width =
                              (constraints.maxWidth - (columns - 1) * 12) /
                              columns;
                          return Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              for (final item in visible)
                                SizedBox(
                                  width: width,
                                  child: _tile(
                                    item,
                                    avatarOwnership(item, profile),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
        ),
      );
    },
  );
  Widget _tile(AvatarItem item, AvatarOwnership state) {
    final owned =
        state == AvatarOwnership.owned || state == AvatarOwnership.selected;
    final color = switch (item.rarity) {
      'rare' => const Color(0xff73CAFF),
      'epic' => const Color(0xffDCA9FF),
      'legendary' => T.ochre,
      _ => T.mint,
    };
    return TaashPanel(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome, size: 13, color: color),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  item.rarity.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    letterSpacing: 1.3,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TaashAvatar(id: item.id, size: 90),
          const SizedBox(height: 12),
          Text(
            item.name,
            style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            owned
                ? state == AvatarOwnership.selected
                      ? Copy.yourCurrentLook
                      : Copy.inYourCollection
                : Copy.virtualCoins(displayNumber(item.cost)),
            textAlign: TextAlign.center,
            style: const TextStyle(color: T.muted, fontSize: 12),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: TaashButton(
              label: switch (state) {
                AvatarOwnership.selected => Copy.selected,
                AvatarOwnership.owned => Copy.select,
                AvatarOwnership.affordable =>
                  item.cost == 0 ? Copy.unlockFree : Copy.unlock,
                AvatarOwnership.insufficient => Copy.moreCoinsNeeded,
              },
              icon: state == AvatarOwnership.selected
                  ? Icons.check_circle_outline
                  : null,
              secondary: owned,
              busy: _busyId == item.id,
              onPressed:
                  _loading ||
                      _busyId != null ||
                      _needsReconcile ||
                      state == AvatarOwnership.selected ||
                      state == AvatarOwnership.insufficient
                  ? null
                  : () => _choose(item),
            ),
          ),
        ],
      ),
    );
  }
}
