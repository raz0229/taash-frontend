import 'package:flutter/material.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/core/update/app_update_service.dart';
import 'package:taash/l10n/strings.dart';

/// Mounts above the navigator (in [MaterialApp.builder]) and drives the
/// global Google Play flexible-update banner. The download runs in the
/// background while the user keeps playing; installing waits for consent.
class AppUpdateCoordinator extends StatefulWidget {
  const AppUpdateCoordinator({
    super.key,
    required this.service,
    required this.child,
  });
  final InAppUpdateService service;
  final Widget child;
  @override
  State<AppUpdateCoordinator> createState() => _AppUpdateCoordinatorState();
}

class _AppUpdateCoordinatorState extends State<AppUpdateCoordinator> {
  @override
  void initState() {
    super.initState();
    widget.service.addListener(_syncBanner);
    WidgetsBinding.instance.addPostFrameCallback((_) => _renderBanner());
  }

  @override
  void didUpdateWidget(AppUpdateCoordinator old) {
    super.didUpdateWidget(old);
    if (old.service != widget.service) {
      old.service.removeListener(_syncBanner);
      widget.service.addListener(_syncBanner);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _renderBanner());
  }

  @override
  Widget build(BuildContext context) => widget.child;

  @override
  void dispose() {
    widget.service.removeListener(_syncBanner);
    super.dispose();
  }

  void _syncBanner() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _renderBanner();
    });
  }

  void _renderBanner() {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentMaterialBanner();
    switch (widget.service.status) {
      case AppUpdateStatus.available:
        messenger.showMaterialBanner(_availableBanner());
      case AppUpdateStatus.downloading:
        messenger.showMaterialBanner(_downloadingBanner());
      case AppUpdateStatus.readyToInstall:
        messenger.showMaterialBanner(_readyBanner());
      case AppUpdateStatus.none:
      case AppUpdateStatus.dismissed:
        break;
    }
  }

  static final ButtonStyle _action = FilledButton.styleFrom(
    minimumSize: const Size(0, 42),
    padding: const EdgeInsets.symmetric(horizontal: 18),
    visualDensity: VisualDensity.compact,
    backgroundColor: T.ochre,
    foregroundColor: const Color(0xff2A193A),
  );
  static final ButtonStyle _quiet = TextButton.styleFrom(
    minimumSize: const Size(0, 42),
    padding: const EdgeInsets.symmetric(horizontal: 14),
    visualDensity: VisualDensity.compact,
    foregroundColor: T.muted,
  );

  MaterialBanner _availableBanner() => MaterialBanner(
    backgroundColor: T.surface,
    leading: const Icon(Icons.system_update_alt_rounded, color: T.ochre),
    content: _BannerBody(
      title: S.updateAvailable,
      body: S.updateAvailableBody,
    ),
    actions: [
      TextButton(
        style: _quiet,
        onPressed: widget.service.dismiss,
        child: const Text(S.notNow),
      ),
      const SizedBox(width: 4),
      FilledButton(
        style: _action,
        onPressed: widget.service.startFlexibleUpdate,
        child: const Text(S.update),
      ),
    ],
  );

  MaterialBanner _downloadingBanner() => MaterialBanner(
    backgroundColor: T.surface,
    leading: const SizedBox(
      width: 26,
      height: 26,
      child: CircularProgressIndicator(strokeWidth: 2.5, color: T.ochre),
    ),
    content: _BannerBody(title: S.downloadingUpdate),
    actions: const [],
  );

  MaterialBanner _readyBanner() => MaterialBanner(
    backgroundColor: T.surface,
    leading: const Icon(Icons.download_done_rounded, color: T.mint),
    content: _BannerBody(title: S.updateReady, body: S.updateReadyBody),
    actions: [
      TextButton(
        style: _quiet,
        onPressed: () {
          ScaffoldMessenger.of(context).hideCurrentMaterialBanner();
        },
        child: const Text(S.later),
      ),
      const SizedBox(width: 4),
      FilledButton(
        style: _action,
        onPressed: widget.service.completeFlexibleUpdate,
        child: const Text(S.restart),
      ),
    ],
  );
}

class _BannerBody extends StatelessWidget {
  const _BannerBody({required this.title, this.body});
  final String title;
  final String? body;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w800, color: T.ink),
      ),
      if (body != null) ...[
        const SizedBox(height: 3),
        Text(body!, style: const TextStyle(color: T.muted, fontSize: 13)),
      ],
    ],
  );
}