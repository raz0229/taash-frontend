import 'package:flutter/material.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../game/shared/playing_card.dart';
import 'card_skin_catalog.dart';

class SkinsTab extends StatefulWidget {
  const SkinsTab({super.key, required this.auth, required this.api});
  final AuthController auth;
  final ApiClient api;
  @override
  State<SkinsTab> createState() => _SkinsTabState();
}

class _SkinsTabState extends State<SkinsTab> {
  List<CardSkinItem>? _catalog;
  String? _error, _notice;
  int? _previewId, _busyId;
  bool _loading = true, _needsReconcile = false;

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
      final catalog = await CardSkinItem.load();
      await widget.auth.refreshProfile();
      if (mounted) {
        setState(() {
          _catalog = catalog;
          _needsReconcile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppFailure
              ? e.message
              : 'We could not load the card atelier.',
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _choose(CardSkinItem item) async {
    final profile = widget.auth.profile;
    if (profile == null || _busyId != null || _needsReconcile) return;
    final state = skinOwnership(item, profile);
    if (state == SkinOwnership.selected ||
        state == SkinOwnership.insufficient) {
      return;
    }
    if (state == SkinOwnership.affordable) {
      final ok = await _confirmUnlock(item);
      if (!ok || !mounted) return;
    }
    setState(() {
      _busyId = item.id;
      _error = null;
      _notice = null;
    });
    var acknowledged = false;
    try {
      if (state == SkinOwnership.owned) {
        await widget.api.selectSkin(profile.id, item.id);
      } else {
        await widget.api.buySkin(profile.id, item.id);
        acknowledged = true;
      }
      await widget.auth.refreshProfile();
      if (mounted) {
        setState(
          () => _notice = state == SkinOwnership.owned
              ? '${item.name} is now on your table.'
              : '${item.name} was added to your collection.',
        );
      }
    } catch (e) {
      final uncertain = acknowledged || e is AppFailure && e.uncertain;
      if (mounted) {
        setState(() {
          _needsReconcile = uncertain;
          _error = uncertain
              ? 'This action may have completed. Refresh to check your collection.'
              : e is AppFailure
              ? e.message
              : 'We could not change your card skin.';
        });
      }
      if (!uncertain) {
        try {
          await widget.auth.refreshProfile();
        } catch (_) {}
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<bool> _confirmUnlock(CardSkinItem item) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Unlock ${item.name}?'),
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.monetization_on_rounded, color: T.ochre),
              const SizedBox(width: 8),
              Text(
                '${item.cost}',
                style: const TextStyle(
                  color: T.ochre,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Unlock'),
            ),
          ],
        ),
      ) ??
      false;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: widget.auth,
    builder: (context, _) {
      final profile = widget.auth.profile;
      if (_catalog == null) {
        return _loading
            ? const Center(child: CircularProgressIndicator())
            : TaashEmpty(
                title: 'Card atelier unavailable',
                message: _error ?? 'Please try again.',
                onRetry: _load,
              );
      }
      if (profile == null) {
        return const TaashEmpty(
          title: 'Sign in to style your deck',
          message: 'Your unlocked card skins are saved with your account.',
        );
      }
      return RefreshIndicator(
        onRefresh: _busyId == null ? _load : () async {},
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 34),
          children: [
            _hero(profile),
            const SizedBox(height: 14),
            const Text(
              'Tap a deck to fan it open. Every skin is carried into the room, card by card.',
              style: TextStyle(color: T.muted, fontSize: 13, height: 1.35),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: T.danger)),
              ),
            if (_notice != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _notice!,
                  style: const TextStyle(
                    color: T.pine,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            const SizedBox(height: 18),
            for (final item in _catalog!)
              _tile(item, skinOwnership(item, profile)),
          ],
        ),
      );
    },
  );

  Widget _hero(PlayerProfile profile) => Container(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        colors: [Color(0xff18112f), Color(0xff3a1d50)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(color: T.ochre.withValues(alpha: .6)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55140b2e),
          blurRadius: 18,
          offset: Offset(0, 10),
        ),
      ],
    ),
    child: Row(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Transform.rotate(
              angle: -.14,
              child: PlayingCard(
                card: 'h-y',
                width: 54,
                skinId: profile.selectedSkin,
              ),
            ),
            Positioned(
              left: 28,
              top: 4,
              child: Transform.rotate(
                angle: .14,
                child: PlayingCard(
                  card: 'c-7',
                  width: 54,
                  skinId: profile.selectedSkin,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 46),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'THE CARD ATELIER',
                style: TextStyle(
                  color: T.ochre,
                  fontSize: 11,
                  letterSpacing: 2,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Dress the deck.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _tile(CardSkinItem item, SkinOwnership state) {
    final open = _previewId == item.id;
    final color = switch (item.rarity) {
      'rare' => const Color(0xff73CAFF),
      'epic' => const Color(0xffDCA9FF),
      _ => T.ochre,
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: const Color(0xff171429),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _previewId = open ? null : item.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 260),
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: state == SkinOwnership.selected
                    ? T.ochre
                    : color.withValues(alpha: open ? .75 : .25),
                width: state == SkinOwnership.selected ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, size: 16, color: color),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        item.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      item.rarity.toUpperCase(),
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 350),
                  child: open ? _preview(item) : _closedPreview(item),
                ),
                const SizedBox(height: 13),
                Row(
                  children: [
                    Expanded(
                      child: switch (state) {
                        SkinOwnership.selected => const Text(
                          'Currently equipped',
                          style: TextStyle(color: T.muted, fontSize: 12),
                        ),
                        SkinOwnership.owned => const Text(
                          'In your collection',
                          style: TextStyle(color: T.muted, fontSize: 12),
                        ),
                        _ => Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.monetization_on_rounded,
                              size: 16,
                              color: T.ochre,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${item.cost} needed',
                              style: const TextStyle(
                                color: T.ochre,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      },
                    ),
                    if (state != SkinOwnership.insufficient)
                      state == SkinOwnership.selected
                          ? SizedBox(
                              width: 56,
                              height: 48,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: T.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.greenAccent),
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.check_rounded,
                                    color: Colors.greenAccent,
                                  ),
                                ),
                              ),
                            )
                          : SizedBox(
                              width: 116,
                              child: TaashButton(
                                label: state == SkinOwnership.owned
                                    ? 'Equip'
                                    : 'Unlock',
                                secondary: state == SkinOwnership.owned,
                                busy: _busyId == item.id,
                                onPressed: _needsReconcile
                                    ? null
                                    : () => _choose(item),
                              ),
                            ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _closedPreview(CardSkinItem item) => SizedBox(
    height: 108,
    key: ValueKey('closed-${item.id}'),
    child: Row(
      children: [
        PlayingCard(card: 'h-y', width: 56, skinId: item.id),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            'Tap to preview',
            textAlign: TextAlign.center,
            style: const TextStyle(color: T.muted, fontSize: 13),
          ),
        ),
        const SizedBox(width: 14),
        PlayingCard(faceDown: true, width: 56, skinId: item.id),
      ],
    ),
  );
  Widget _preview(CardSkinItem item) => SizedBox(
    height: 140,
    key: ValueKey('open-${item.id}'),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (final entry in [('h-y', -.16), ('c-7', 0.0), ('p-10', .16)])
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 7),
            child: Transform.rotate(
              angle: entry.$2,
              child: PlayingCard(card: entry.$1, width: 68, skinId: item.id),
            ),
          ),
      ],
    ),
  );
}
