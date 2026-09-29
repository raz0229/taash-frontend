import 'package:flutter/material.dart';
import 'package:taash/l10n/copy.dart';

import '../../core/audio/audio_system.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import 'thullu_sfx_catalog.dart';

/// Opens the in-room Thullu sound picker.
///
/// Only sounds the player already owns are listed: this is a switch between
/// sounds you have, not a store. Unlocking happens in the Shop, so nothing
/// here can spend coins mid-hand. Selection is applied on the server straight
/// away, so the next Thullu this player gives plays the new clip.
Future<void> showThulluSfxSheet(
  BuildContext context, {
  required AuthController auth,
  required ApiClient api,
}) => showTaashSheet<void>(
  context,
  ThulluSfxSheet(auth: auth, api: api),
);

class ThulluSfxSheet extends StatefulWidget {
  const ThulluSfxSheet({super.key, required this.auth, required this.api});

  final AuthController auth;
  final ApiClient api;

  @override
  State<ThulluSfxSheet> createState() => _ThulluSfxSheetState();
}

class _ThulluSfxSheetState extends State<ThulluSfxSheet> {
  List<ThulluSfxItem>? _catalog;
  String? _error;
  int? _busyId;
  int? _previewId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
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
      if (mounted) setState(() => _catalog = data);
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
    if (profile == null || _busyId != null || _loading) return;
    // Only owned sounds are listed, so this is always a plain re-select.
    if (profile.selectedThulluSfx == item.id) return;
    if (_busyId != null || !mounted) return;
    setState(() {
      _busyId = item.id;
      _error = null;
    });
    try {
      await widget.api.selectThulluSfx(profile.id, item.id);
      await widget.auth.refreshProfile();
      if (mounted) {
        showFlash(context, '${item.name} ${Copy.thulluSoundInUse}');
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _error = e is AppFailure
              ? e.message
              : Copy.weCouldNotChangeYourThulluSoundPlease,
        );
      }
      try {
        await widget.auth.refreshProfile();
      } catch (_) {
        /* Original error remains visible. */
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
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 28),
                child: Center(
                  child: CircularProgressIndicator(
                    semanticsLabel: Copy.loadingThulluSfx,
                  ),
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
      final items = _catalog!
          .where((item) => profile.unlockedThulluSfx.contains(item.id))
          .toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      if (items.isEmpty) {
        return const TaashEmpty(
          title: Copy.thulluSfxUnavailable,
          message: Copy.noThulluSfxYet,
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Copy.yourThulluSound,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 6),
          const Text(
            Copy.thulluSfxIntro,
            style: TextStyle(color: T.muted),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: T.danger)),
          ],
          const SizedBox(height: 14),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _row(item, profile),
            ),
          const SizedBox(height: 6),
          TaashButton(
            label: Copy.done,
            secondary: true,
            onPressed: _busyId == null ? () => Navigator.pop(context) : null,
          ),
        ],
      );
    },
  );

  Widget _row(ThulluSfxItem item, PlayerProfile profile) {
    final selected = profile.selectedThulluSfx == item.id;
    final playing = _previewId == item.id;
    return TaashPanel(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Semantics(
            button: true,
            label: playing ? Copy.stopPreview : '${Copy.preview} ${item.name}',
            child: Material(
              color: playing ? T.pine : T.surface,
              borderRadius: BorderRadius.circular(14),
              child: InkWell(
                onTap: _loading || _busyId != null
                    ? null
                    : () => _togglePreview(item),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: playing
                          ? T.ochre
                          : T.outline.withValues(alpha: .65),
                    ),
                  ),
                  child: Icon(
                    playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                    size: 22,
                    color: playing ? T.ochre : T.muted,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selected ? Copy.thulluSoundInUse : Copy.alreadyUnlocked,
                  style: const TextStyle(color: T.muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          TaashButton(
            label: selected ? Copy.selected : Copy.select,
            icon: selected ? Icons.check_circle_outline : null,
            secondary: true,
            busy: _busyId == item.id,
            onPressed: _loading || _busyId != null || selected
                ? null
                : () => _choose(item),
          ),
        ],
      ),
    );
  }
}
