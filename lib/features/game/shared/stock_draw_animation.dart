import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/audio/audio_system.dart';
import '../../../core/theme/taash_theme.dart';
import 'player_strip.dart';
import 'playing_card.dart';

/// The hand that reaches over a Daketi or TC stock draw: it pops over the draw
/// pile, snatches a card (with a soft poof) and sweeps it up to the seat whose
/// turn it is. Quick, non-blocking and self-removing.
class StockDrawAnimation extends StatefulWidget {
  const StockDrawAnimation({
    super.key,
    required this.playerStripKey,
    required this.stockKey,
    required this.drawerSeat,
    this.onComplete,
  });
  final GlobalKey playerStripKey;
  final GlobalKey stockKey;
  final int drawerSeat;
  final VoidCallback? onComplete;
  @override
  State<StockDrawAnimation> createState() => _StockDrawAnimationState();
}

class _StockDrawAnimationState extends State<StockDrawAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _stock = Offset.zero;
  Offset _seat = Offset.zero;
  bool _resolved = false;
  bool _controllerReady = false;
  bool _poof = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controllerReady) {
      _controllerReady = true;
      _controller =
          AnimationController(
              vsync: this,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? const Duration(milliseconds: 650)
                  : const Duration(milliseconds: 1100),
            )
            ..addListener(_playPuffs)
            ..addStatusListener((status) {
              if (status == AnimationStatus.completed) {
                widget.onComplete?.call();
              }
            });
    }
    _resolvePositions();
  }

  void _resolvePositions() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final size = MediaQuery.sizeOf(context);
      final stockBox =
          widget.stockKey.currentContext?.findRenderObject() as RenderBox?;
      if (stockBox != null && stockBox.hasSize && stockBox.attached) {
        _stock = stockBox.localToGlobal(stockBox.size.center(Offset.zero));
      } else {
        _stock = Offset(size.width * .42, size.height * .52);
      }
      _seat =
          stripSeatGlobalCenter(widget.playerStripKey, widget.drawerSeat) ??
          Offset(size.width * .5, size.height * .18);
      if (!_controller.isAnimating && _controller.value == 0) {
        _controller.forward();
      }
      _resolved = true;
      setState(() {});
    });
  }

  void _playPuffs() {
    if (!_poof && _controller.value >= .06) {
      _poof = true;
      audio.playSfx('poof');
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_playPuffs);
    _controller.dispose();
    super.dispose();
  }

  static double _s(double t, double a, double b) {
    if (b <= a) {
      return t >= b ? 1 : 0;
    }
    return ((t - a) / (b - a)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return const IgnorePointer(child: SizedBox.expand());
    }
    return Semantics(
      container: true,
      label: 'Stock card drawn',
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final grab = _s(t, .0, .08);
              final fly = _s(t, .1, .62);
              final holdEnd = _s(t, .7, .85);
              final heading = _heading(_stock, _seat);
              final pos = _lerp(_stock, _seat, Curves.easeOut.transform(fly));
              final scale = 1 + .22 * (1 - grab) * (t < .08 ? 1 : 0) + .05;
              final cardsOut = Curves.easeOutBack
                  .transform(_s(t, .06, .14))
                  .clamp(0.0, 1.0);
              final poofA = Curves.easeOut
                  .transform(1 - _s(t, .06, .2))
                  .clamp(0.0, 1.0);
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (poofA > 0)
                    Positioned(
                      left: _stock.dx - 66,
                      top: _stock.dy - 66,
                      child: Opacity(
                        opacity: poofA,
                        child: Container(
                          width: 132,
                          height: 132,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withValues(alpha: .85),
                                T.mint.withValues(alpha: .25),
                                Colors.transparent,
                              ],
                              stops: const [0, .55, 1],
                            ),
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    left: pos.dx - 40,
                    top: pos.dy - 40,
                    child: Transform.rotate(
                      angle: heading,
                      child: Transform.scale(
                        scale: scale,
                        child: Opacity(
                          opacity: 1 - Curves.easeIn.transform(holdEnd),
                          child: _hand(cards: cardsOut, angle: heading),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _hand({required double cards, required double angle}) {
    return SizedBox(
      width: 80,
      height: 80,
      child: Stack(
        alignment: Alignment.center,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: const [
                BoxShadow(color: Color(0x44333333), blurRadius: 14),
              ],
              gradient: RadialGradient(
                colors: [T.ochre.withValues(alpha: .30), Colors.transparent],
              ),
            ),
            child: const SizedBox(width: 74, height: 74),
          ),
          Opacity(
            opacity: cards,
            child: Transform.translate(
              offset: const Offset(0, -11),
              child: Transform.rotate(
                angle: -angle * .6,
                child: PlayingCard(faceDown: true, width: 26),
              ),
            ),
          ),
          Transform.rotate(
            angle: angle * .35,
            child: Icon(
              Icons.back_hand_rounded,
              color: T.white,
              size: 46,
              shadows: const [
                Shadow(color: Color(0xff241338), blurRadius: 8),
                Shadow(color: Color(0xff241338), blurRadius: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Offset _lerp(Offset a, Offset b, double v) =>
      Offset(a.dx + (b.dx - a.dx) * v, a.dy + (b.dy - a.dy) * v);
  static double _heading(Offset from, Offset to) =>
      math.atan2(to.dy - from.dy, to.dx - from.dx);
}
