import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/taash_theme.dart';
import '../../../core/widgets/taash_widgets.dart';
import '../../../l10n/copy.dart';
import 'playing_card.dart';

/// A full-room cinematic reveal shown in *every* seat of a Bhabhi room when
/// someone is handed a Thullu. It replaced the plain "THULLU!" toast so the
/// table can see who did what at a glance:
///
/// 1. The player who caused the Thullu (played off-suit) is named as the
///    giver, next to the player who is stuck with the pile (the taker).
/// 2. The whole trick lifts off the table and flies up to the taker's seat in
///    the player strip, ending with a burst and a "+N" card count.
///
/// The entire show runs until [onComplete], which the host uses to release the
/// overlay and resume the paused turn timer.
class BhabhiThulluAnimation extends StatefulWidget {
  const BhabhiThulluAnimation({
    super.key,
    required this.giverName,
    required this.giverPfp,
    required this.receiverName,
    required this.receiverPfp,
    required this.trickCards,
    required this.pileCount,
    required this.trickKey,
    required this.playerStripKey,
    required this.winnerSeatIndex,
    required this.onComplete,
  });
  final String giverName, receiverName;
  final int giverPfp, receiverPfp;
  final List<String> trickCards;
  final int pileCount;
  final GlobalKey trickKey;
  final GlobalKey playerStripKey;
  final int winnerSeatIndex;
  final VoidCallback onComplete;

  @override
  State<BhabhiThulluAnimation> createState() => _BhabhiThulluAnimationState();
}

class _BhabhiThulluAnimationState extends State<BhabhiThulluAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _pileStart = Offset.zero;
  Offset _winnerEnd = Offset.zero;
  bool _positionsReady = false;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) widget.onComplete();
      });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _controller.duration = MediaQuery.disableAnimationsOf(context)
          ? const Duration(milliseconds: 3000)
          : const Duration(milliseconds: 9200);
      _controller.forward();
    }
    _resolvePositions();
  }

  void _resolvePositions() {
    final size = MediaQuery.sizeOf(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Offset start, end;
      final trickBox =
          widget.trickKey.currentContext?.findRenderObject() as RenderBox?;
      if (trickBox != null && trickBox.hasSize && trickBox.attached) {
        start = trickBox.localToGlobal(trickBox.size.center(Offset.zero));
      } else {
        start = Offset(size.width / 2, size.height * .56);
      }
      final stripBox =
          widget.playerStripKey.currentContext?.findRenderObject()
              as RenderBox?;
      if (stripBox != null && stripBox.hasSize && stripBox.attached) {
        final origin = stripBox.localToGlobal(Offset.zero);
        final slotWidth = (size.width - 24) / 3;
        final compact = size.height < 720;
        end = Offset(
          origin.dx +
              12 +
              widget.winnerSeatIndex.clamp(0, 5) * slotWidth +
              slotWidth / 2,
          origin.dy + (compact ? 27 : 37),
        );
      } else {
        end = Offset(size.width / 2, size.height * .16);
      }
      if (start != _pileStart || end != _winnerEnd) {
        setState(() {
          _pileStart = start;
          _winnerEnd = end;
          _positionsReady = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static double _smooth(double t, double start, double end) {
    if (end <= start) return t >= end ? 1 : 0;
    return ((t - start) / (end - start)).clamp(0.0, 1.0);
  }

  static Offset _quadBezier(Offset a, Offset control, Offset b, double t) {
    final u = 1 - t;
    return Offset(
      u * u * a.dx + 2 * u * t * control.dx + t * t * b.dx,
      u * u * a.dy + 2 * u * t * control.dy + t * t * b.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label:
          '${Copy.thullu} ${widget.giverName} gave the thullu; ${widget.receiverName} gets the pile of ${widget.pileCount} cards.',
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              return Stack(
                fit: StackFit.expand,
                children: [
                  Positioned.fill(child: _scrim(t)),
                  Positioned.fill(child: _title(t)),
                  Positioned.fill(child: _revealCard(t)),
                  Positioned.fill(child: _pileFlight(t)),
                  Positioned.fill(child: _winnerBurst(t)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _scrim(double t) {
    final fadeIn = _smooth(t, 0, .07);
    final fadeOut = 1 - _smooth(t, .9, 1);
    final opacity = (fadeIn * fadeOut).clamp(0.0, 1.0) * .84;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -.25),
          radius: 1.05,
          colors: [
            const Color(0xff2A1745).withValues(alpha: opacity * .55),
            const Color(0xff070314).withValues(alpha: opacity),
          ],
        ),
      ),
    );
  }

  Widget _title(double t) {
    final enter = Curves.elasticOut.transform(
      ((t - .03) / .16).clamp(0.0, 1.0),
    );
    final leave = 1 - _smooth(t, .55, .68);
    final opacity = (enter * leave).clamp(0.0, 1.0);
    final rack = math.sin(t * 46) * 4 * enter.clamp(0.0, 1.0);
    return Align(
      alignment: const Alignment(0, -.72),
      child: Opacity(
        opacity: opacity,
        child: Transform.rotate(
          angle: rack * .008,
          child: Transform.scale(
            scale: enter.clamp(0.0, 1.4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xff241338),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: T.danger, width: 3),
                boxShadow: [
                  BoxShadow(
                    color: T.danger.withValues(alpha: .55),
                    blurRadius: 28,
                  ),
                ],
              ),
              child: Text(
                Copy.thullu,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: T.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _revealCard(double t) {
    final width = math.min(380.0, MediaQuery.sizeOf(context).width * .92);
    final panel = Curves.easeOutBack.transform(
      ((t - .08) / .2).clamp(0.0, 1.0),
    );
    final flightDim = _smooth(t, .72, .82) * .5;
    final leave = 1 - _smooth(t, .9, 1);
    final opacity = (panel * (1 - flightDim) * leave).clamp(0.0, 1.0);
    return Center(
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(
            0,
            Curves.easeOut.transform(panel.clamp(0.0, 1.0)) * 28,
          ),
          child: Transform.scale(
            scale: panel,
            child: Container(
              width: width,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
              decoration: BoxDecoration(
                color: const Color(0xff1C1230).withValues(alpha: .95),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xff6D4DDD), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff000000).withValues(alpha: .5),
                    blurRadius: 40,
                    offset: const Offset(0, 14),
                  ),
                  BoxShadow(
                    color: T.danger.withValues(alpha: .18),
                    blurRadius: 34,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _plateRow(t),
                  const SizedBox(height: 12),
                  _takerLine(t),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _plateRow(double t) {
    final left = _smooth(t, .12, .3);
    final right = _smooth(t, .14, .32);
    final arrowT = _smooth(t, .26, .38);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _playerPlate(
          name: widget.giverName,
          pfp: widget.giverPfp,
          label: 'GAVE IT',
          accent: T.coral,
          progress: left,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Opacity(
            opacity: arrowT,
            child: Transform.scale(
              scale: Curves.easeOutBack.transform(arrowT),
              child: Container(
                width: 38,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff2C1F45),
                  border: Border.all(color: const Color(0xff9B82E0)),
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: T.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
        _playerPlate(
          name: widget.receiverName,
          pfp: widget.receiverPfp,
          label: 'GOT IT',
          accent: T.ochre,
          progress: right,
          emphasize: true,
        ),
      ],
    );
  }

  Widget _playerPlate({
    required String name,
    required int pfp,
    required String label,
    required Color accent,
    required double progress,
    bool emphasize = false,
  }) {
    final shifted = Curves.easeOut.transform(progress);
    final dx = emphasize ? 1 : -1;
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(dx * (1 - shifted) * 56, 0),
        child: Transform.scale(
          scale: emphasize ? 1.06 : 1,
          child: Container(
            width: 118,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: accent.withValues(alpha: emphasize ? .9 : .55),
                width: emphasize ? 2.5 : 1,
              ),
              boxShadow: emphasize
                  ? [
                      BoxShadow(
                        color: accent.withValues(alpha: .4),
                        blurRadius: 22,
                      ),
                    ]
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                TaashAvatar(id: pfp, size: 44),
                const SizedBox(height: 8),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: T.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _takerLine(double t) {
    final p = Curves.easeOut.transform(((t - .3) / .16).clamp(0.0, 1.0));
    return Opacity(
      opacity: p.clamp(0.0, 1.0),
      child: Transform.translate(
        offset: Offset(0, (1 - p) * 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: T.ochre.withValues(alpha: .14),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: T.ochre.withValues(alpha: .5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.assignment_turned_in_outlined,
                color: T.ochre,
                size: 16,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  '${widget.receiverName} picks up the pile',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: T.ochre,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pileFlight(double t) {
    final size = MediaQuery.sizeOf(context);
    final start = _positionsReady
        ? _pileStart
        : Offset(size.width / 2, size.height * .56);
    final end = _positionsReady
        ? _winnerEnd
        : Offset(size.width / 2, size.height * .16);
    final control = Offset(
      (start.dx + end.dx) / 2,
      math.min(start.dy, end.dy) - (size.height * .12).clamp(90, 190),
    );
    final cards = widget.trickCards.isEmpty ? const ['h-y'] : widget.trickCards;
    final count = cards.length.clamp(1, 4);
    final flying = <Widget>[];
    for (var i = 0; i < count; i++) {
      final lead = count == 1 ? 0.0 : i / (count - 1);
      final p = _smooth(t, .7 + lead * .025, .88 + (1 - lead) * .02);
      if (p <= 0) continue;
      final eased = Curves.easeInOutCubic.transform(p);
      final pos = _quadBezier(start, control, end, eased);
      final splay = (i - (count - 1) / 2);
      flying.add(
        Positioned(
          left: pos.dx - 24,
          top: pos.dy - 34,
          child: Transform.translate(
            offset: Offset(splay * (1 - eased) * 8, 0),
            child: Transform.rotate(
              angle: splay * (.2 - .16 * eased),
              child: Transform.scale(
                scale: 1 - .1 * eased,
                child: Opacity(
                  opacity: (p / .12).clamp(0.0, 1.0) * (1 - _smooth(t, .94, 1)),
                  child: PlayingCard(card: cards[i], width: 48),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: flying);
  }

  Widget _winnerBurst(double t) {
    final size = MediaQuery.sizeOf(context);
    final end = _positionsReady
        ? _winnerEnd
        : Offset(size.width / 2, size.height * .16);
    final burst = _smooth(t, .82, .92);
    final chip = Curves.elasticOut.transform(((t - .87) / .1).clamp(0.0, 1.0));
    final opacity = (1 - _smooth(t, .93, 1)) * chip.clamp(0.0, 1.0);
    if (burst <= 0) return const SizedBox.shrink();
    return Stack(
      children: [
        Positioned(
          left: end.dx - 46,
          top: end.dy - 46,
          child: Opacity(
            opacity: burst * .55,
            child: Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    T.ochre.withValues(alpha: .75),
                    T.ochre.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: end.dx - 32,
          top: end.dy - 32,
          child: Opacity(
            opacity: burst * .9,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: T.ochre.withValues(alpha: .9),
                  width: 3,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: end.dx + 26,
          top: end.dy - 14,
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: chip.clamp(0.0, 1.2),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: T.ochre,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: T.ochre.withValues(alpha: .6),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Text(
                  '+${widget.pileCount}',
                  style: const TextStyle(
                    color: Color(0xff2A193A),
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
