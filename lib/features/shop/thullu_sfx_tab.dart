import 'package:flutter/material.dart';
import 'package:taash/l10n/copy.dart';

import '../../core/audio/audio_system.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../profile/presentation.dart';
import 'thullu_sfx_catalog.dart';

/// The Thulla SFX half of the Shop: unlock clips with coins, then pick which
/// one the whole room hears when you are the one who hands over the Thullu.
///
/// The same purchase and selection endpoints are reused by the in-room options
/// picker, so a clip bought or selected here is live in the very next hand.
class ThulluSfxTab extends StatefulWidget {
  const ThulluSfxTab({super.key, required this.auth, required this.api});

  final AuthController auth;
  final ApiClient api;

  @override
  State<ThulluSfxTab> createState() => _ThulluSfxTabState();
}

class _ThulluSfxTabState extends State<ThulluSfxTab> {
  List<ThulluSfxItem>? _catalog;
  String? _error;
  String? _notice;
  String _filter = Copy.filterAll;
  int? _busyId;
  int? _previewId;
  bool _loading = true;
  bool _needsReconcile = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // A preview must not keep playing after the tab is gone.
    audio.stopPreviewSfx();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await loadThulluSfxCatalog();
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
              : Copy.weCouldNotLoadTheThulluSfx,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Plays (or stops) the preview for [item]. Previewing never requires
  /// ownership, so a locked clip can be auditioned before spending coins.
  Future<void> _togglePreview(ThulluSfxItem item) async {
    if (_previewId == item.id) {
      await audio.stopPreviewSfx();
      if (mounted) setState(() => _previewId = null);
      return;
    }
    setState(() => _previewId = item.id);
    await audio.previewSfx(
      item.sfxKey,
      onComplete: () {
        if (mounted && _previewId == item.id) setState(() => _previewId = null);
      },
    );
  }

  Future<void> _choose(ThulluSfxItem item) async {
    final profile = widget.auth.profile;
    if (profile == null || _busyId != null || _needsReconcile || _loading) {
      return;
    }
    final state = thulluSfxOwnership(item, profile);
    if (state == ThulluSfxOwnership.selected ||
        state == ThulluSfxOwnership.insufficient) {
      return;
    }
    if (state == ThulluSfxOwnership.affordable) {
      final confirmed = await confirmAction(
        context,
        title: Copy.unlockThulluSound(item.name),
        message: Copy.yourBalanceCoinsThisUnlocksTheSound(
          displayNumber(item.cost),
          displayNumber(profile.coins),
        ),
        confirmLabel: item.cost == 0
            ? Copy.unlockThulluSoundForFree
            : Copy.unlockThulluSoundFor(displayNumber(item.cost)),
      );
      if (!confirmed || !mounted) return;
    }
    if (_busyId != null || !mounted) return;
    setState(() {
      _busyId = item.id;
      _error = null;
      _notice = null;
    });
    var acknowledged = false;
    try {
      if (state == ThulluSfxOwnership.owned) {
        await widget.api.selectThulluSfx(profile.id, item.id);
      } else {
        await widget.api.buyThulluSfx(profile.id, item.id);
      }
      acknowledged = true;
      await widget.auth.refreshProfile();
      if (mounted) {
        setState(
          () => _notice = state == ThulluSfxOwnership.owned
              ? '${item.name} is your Thullu sound. The room will hear it next time you hand over a Thullu.'
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
              ? Copy.yourThulluActionMayHaveCompletedRefresh
              : e is AppFailure
              ? e.message
              : Copy.weCouldNotChangeYourThulluSoundPlease;
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
      if (_catalog == null) {
        return _loading
            ? Center(
                child: CircularProgressIndicator(
                  semanticsLabel: Copy.loadingThulluSfx,
                ),
              )
            : TaashEmpty(
                title: Copy.thulluSfxUnavailable,
                message: _error ?? Copy.pleaseTryAgain,
                onRetry: _load,
              );
      }
      if (profile == null) {
        return const TaashEmpty(
          title: Copy.signInToChooseYourLook,
          message: Copy.yourCollectionIsSavedWithYourAccount,
        );
      }
      return RefreshIndicator(
        onRefresh: _busyId == null ? _load : () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _header(profile),
            const SizedBox(height: 22),
            const Text(Copy.thulluSfxIntro, style: TextStyle(color: T.muted)),
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
                    Text(_error!, style: const TextStyle(color: T.danger)),
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
                for (final filter in [Copy.filterAll, Copy.filterOwned])
                  ChoiceChip(
                    label: Text(filter),
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            ..._visibleItems(profile),
          ],
        ),
      );
    },
  );

  List<Widget> _visibleItems(PlayerProfile profile) {
    final visible = _catalog!
        .where(
          (item) =>
              _filter == Copy.filterAll ||
              profile.unlockedThulluSfx.contains(item.id),
        )
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    if (visible.isEmpty) {
      return [
        const TaashEmpty(
          title: Copy.thulluSfxUnavailable,
          message: Copy.noThulluSfxYet,
        ),
      ];
    }
    return [
      for (final item in visible)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _tile(item, thulluSfxOwnership(item, profile)),
        ),
    ];
  }

  Widget _header(PlayerProfile profile) {
    final selected = _catalog!.firstWhere(
      (item) => item.id == profile.selectedThulluSfx,
      orElse: () => _catalog!.firstWhere(
        (item) => item.id == ThulluSfxItem.defaultId,
        orElse: () => _catalog!.first,
      ),
    );
    return TaashPanel(
      color: T.pine,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final large = MediaQuery.textScalerOf(context).scale(1) > 1.4;
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                Copy.yourThulluSound,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                selected.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: T.mint,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '${profile.unlockedThulluSfx.length} ${Copy.soundsOwned}'
                ' · ${Copy.virtualCoins2(displayNumber(profile.coins))}',
                style: const TextStyle(color: T.ochre, fontWeight: FontWeight.w800),
              ),
            ],
          );
          final badge = _PreviewBadge(
            label: selected.name,
            playing: _previewId == selected.id,
            size: large ? 64 : 56,
            onTap: () => _togglePreview(selected),
          );
          return large
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [badge, const SizedBox(height: 16), copy],
                )
              : Row(
                  children: [
                    badge,
                    const SizedBox(width: 16),
                    Expanded(child: copy),
                  ],
                );
        },
      ),
    );
  }

  Widget _tile(ThulluSfxItem item, ThulluSfxOwnership state) {
    final owned =
        state == ThulluSfxOwnership.owned ||
        state == ThulluSfxOwnership.selected;
    final isDefault = item.id == ThulluSfxItem.defaultId;
    return TaashPanel(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PreviewBadge(
            label: item.name,
            playing: _previewId == item.id,
            onTap: _loading || _busyId != null
                ? null
                : () => _togglePreview(item),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isDefault
                      ? owned
                            ? state == ThulluSfxOwnership.selected
                                  ? Copy.yourCurrentLook
                                  : Copy.inYourCollection
                            : Copy.unlockFree
                      : owned
                      ? state == ThulluSfxOwnership.selected
                            ? Copy.thulluSoundInUse
                            : Copy.alreadyUnlocked
                      : Copy.virtualCoins(displayNumber(item.cost)),
                  style: const TextStyle(color: T.muted, fontSize: 12),
                ),
                const SizedBox(height: 11),
                TaashButton(
                  label: switch (state) {
                    ThulluSfxOwnership.selected => Copy.selected,
                    ThulluSfxOwnership.owned => Copy.select,
                    ThulluSfxOwnership.affordable =>
                      item.cost == 0 ? Copy.unlockFree : Copy.unlock,
                    ThulluSfxOwnership.insufficient => Copy.moreCoinsNeeded,
                  },
                  icon: state == ThulluSfxOwnership.selected
                      ? Icons.check_circle_outline
                      : null,
                  secondary: owned,
                  busy: _busyId == item.id,
                  onPressed:
                      _loading ||
                          _busyId != null ||
                          _needsReconcile ||
                          state == ThulluSfxOwnership.selected ||
                          state == ThulluSfxOwnership.insufficient
                      ? null
                      : () => _choose(item),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable artwork that doubles as the preview control, so every clip can be
/// auditioned before it is bought.
class _PreviewBadge extends StatelessWidget {
  const _PreviewBadge({
    required this.label,
    required this.playing,
    required this.onTap,
    this.size = 56,
  });

  final String label;
  final bool playing;
  final VoidCallback? onTap;
  final double size;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: playing ? Copy.stopPreview : '${Copy.preview} $label',
    child: Material(
      color: playing ? T.pine : T.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: playing ? T.ochre : T.outline.withValues(alpha: .65),
              width: playing ? 1.5 : 1,
            ),
          ),
          child: Icon(
            playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
            size: size * .5,
            color: playing ? T.ochre : T.muted,
          ),
        ),
      ),
    ),
  );
}
