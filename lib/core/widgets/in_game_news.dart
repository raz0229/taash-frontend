import 'dart:async';

import 'package:flutter/material.dart';
import 'package:taash/core/news/in_game_news_service.dart';
import 'package:taash/core/theme/taash_theme.dart';
import 'package:taash/l10n/copy.dart';

class InGameNewsCoordinator extends StatefulWidget {
  const InGameNewsCoordinator({
    super.key,
    required this.service,
    required this.child,
    this.imageProvider,
  });

  final InGameNewsService service;
  final Widget child;
  final ImageProvider<Object>? imageProvider;

  @override
  State<InGameNewsCoordinator> createState() => _InGameNewsCoordinatorState();
}

class _InGameNewsCoordinatorState extends State<InGameNewsCoordinator> {
  bool _scheduled = false;
  bool _showing = false;

  @override
  void initState() {
    super.initState();
    widget.service.addListener(_schedulePresentation);
    _schedulePresentation();
  }

  @override
  void didUpdateWidget(InGameNewsCoordinator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.service != widget.service) {
      oldWidget.service.removeListener(_schedulePresentation);
      widget.service.addListener(_schedulePresentation);
      _schedulePresentation();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _schedulePresentation();
  }

  @override
  void dispose() {
    widget.service.removeListener(_schedulePresentation);
    super.dispose();
  }

  void _schedulePresentation() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (mounted) unawaited(_presentIfReady());
    });
  }

  Future<void> _presentIfReady() async {
    final news = widget.service.news;
    if (news == null || widget.service.consumed || _showing || !mounted) {
      return;
    }
    if (ModalRoute.of(context)?.isCurrent != true ||
        Navigator.of(context).canPop()) {
      return;
    }
    _showing = true;
    widget.service.consume();
    try {
      await showDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: true,
        barrierLabel: Copy.dismissNews,
        builder: (context) =>
            InGameNewsDialog(news: news, imageProvider: widget.imageProvider),
      );
    } finally {
      if (mounted) _showing = false;
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class InGameNewsDialog extends StatelessWidget {
  const InGameNewsDialog({super.key, required this.news, this.imageProvider});

  final InGameNews news;
  final ImageProvider<Object>? imageProvider;

  @override
  Widget build(BuildContext context) => Dialog(
    key: const ValueKey('inGameNewsDialog'),
    insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
    clipBehavior: Clip.antiAlias,
    backgroundColor: T.surface,
    elevation: 18,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: BorderSide(color: T.coral.withValues(alpha: .3)),
    ),
    child: ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: 380,
        maxHeight: MediaQuery.sizeOf(context).height * .82,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _NewsImage(news: news, imageProvider: imageProvider),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.campaign_rounded,
                        color: T.ochre,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          Copy.latestFromTaash.toUpperCase(),
                          style: const TextStyle(
                            color: T.ochre,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    news.headline,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    news.subtitle,
                    style: const TextStyle(
                      color: T.muted,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _NewsImage extends StatelessWidget {
  const _NewsImage({required this.news, required this.imageProvider});

  final InGameNews news;
  final ImageProvider<Object>? imageProvider;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 164,
    width: double.infinity,
    child: Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [T.aubergine, T.pine],
            ),
          ),
        ),
        Image(
          image: imageProvider ?? NetworkImage(news.image.toString()),
          fit: BoxFit.cover,
          semanticLabel: news.headline,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0 : 1,
              duration: T.standard,
              child: child,
            );
          },
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.campaign_rounded, color: T.white, size: 40),
          ),
        ),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x22000000), Color(0xAA000000)],
              stops: [0, 1],
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            key: const ValueKey('closeInGameNews'),
            tooltip: Copy.closeNews,
            onPressed: () => Navigator.of(context).pop(),
            style: IconButton.styleFrom(
              fixedSize: const Size(42, 42),
              minimumSize: const Size(42, 42),
              backgroundColor: T.paper.withValues(alpha: .78),
              foregroundColor: T.ink,
            ),
            icon: const Icon(Icons.close_rounded, size: 21),
          ),
        ),
      ],
    ),
  );
}
