import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/audio/audio_system.dart';
import '../../../core/theme/taash_theme.dart';
import 'player_strip.dart';
import 'playing_card.dart';

/// A quick, low-prominence hand-grab shown when a Daketi play rakes cards off
/// the play area and/or off the top of a rival's collection. The hand sweeps
/// from the stealer's seat to the source and returns clutching the cards, with
/// a soft "poof" burst at each grab. Nothing blocks input and the reveal lasts
/// only ~1.6s.
class DaketiStealAnimation extends StatefulWidget {
  const DaketiStealAnimation({
    super.key,
    required this.playerStripKey,
    required this.playAreaKey,
    required this.stealerSeat,
    required this.victimSeat,
    required this.areaCapture,
    required this.areaCardCount,
    required this.victimCardCount,
    this.onComplete,
  });

  /// Anchors the seat row so the hand can reach the exact seats.
  final GlobalKey playerStripKey;

  /// Anchors the Daketi play area on the table.
  final GlobalKey playAreaKey;

  /// Index of the stealer within the player strip (0-based).
  final int stealerSeat;

  /// Index of the robbed player, or -1 when only the play area was raided.
  final int victimSeat;

  /// Whether cards were also captured from the play area.
  final bool areaCapture;
  final int areaCardCount;
  final int victimCardCount;
  final VoidCallback? onComplete;

  @override
  State<DaketiStealAnimation> createState() => _DaketiStealAnimationState();
}

class _DaketiStealAnimationState extends State<DaketiStealAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _stealer = Offset.zero;
  Offset _victim = Offset.zero;
  Offset _area = Offset.zero;
  bool _resolved = false;
  bool _controllerReady = false;
  bool _poofArea = false;
  bool _poofVictim = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // MediaQuery (via disableAnimationsOf) can only be read here, not in
    // initState; the controller is created once on the first dependency pass.
    if (!_controllerReady) {
      _controllerReady = true;
      _controller =
          AnimationController(
              vsync: this,
              duration: MediaQuery.disableAnimationsOf(context)
                  ? const Duration(milliseconds: 900)
                  : const Duration(milliseconds: 1650),
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
      // Seats come straight from the strip's own layout (scroll included),
      // so the hand truly flies avatar → avatar instead of "in the general
      // direction".
      _stealer =
          stripSeatGlobalCenter(widget.playerStripKey, widget.stealerSeat) ??
          Offset(size.width * .5, size.height * .18);
      _victim = widget.victimSeat >= 0
          ? (stripSeatGlobalCenter(widget.playerStripKey, widget.victimSeat) ??
                Offset(size.width * .5, size.height * .25))
          : Offset(size.width * .5, size.height * .25);
      final areaBox =
          widget.playAreaKey.currentContext?.findRenderObject() as RenderBox?;
      if (areaBox != null && areaBox.hasSize && areaBox.attached) {
        _area = areaBox.localToGlobal(areaBox.size.center(Offset.zero));
      } else {
        _area = Offset(size.width * .4, size.height * .52);
      }
      if (!_controller.isAnimating && _controller.value == 0) {
        _controller.forward();
      }
      _resolved = true;
      setState(() {});
    });
  }

  void _playPuffs() {
    final t = _controller.value;
    final victimGrab = widget.areaCapture ? .56 : .34;
    if (widget.victimSeat >= 0 && !_poofVictim && t >= victimGrab) {
      _poofVictim = true;
      audio.playSfx('poof');
    }
    if (widget.areaCapture && !_poofArea && t >= .06) {
      _poofArea = true;
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

  static double _easeInOut(double v) => Curves.easeInOut.transform(v);
  static double _easeOut(double v) => Curves.easeOut.transform(v);
  static Offset _lerp(Offset a, Offset b, double v) =>
      Offset(a.dx + (b.dx - a.dx) * v, a.dy + (b.dy - a.dy) * v);
  static double _heading(Offset from, Offset to) =>
      math.atan2(to.dy - from.dy, to.dx - from.dx);

  // ---- per-frame state ----------------------------------------------------

  double _opacityFor(double t, double holdEnd, double fadeEnd) {
    return 1 - Curves.easeIn.transform(_s(t, holdEnd, fadeEnd));
  }

  /// Position, heading, carried cards and poof burst for time [t].
  ({
    Offset pos,
    double angle,
    int cards,
    double cardT,
    double scale,
    double opacity,
    Offset? poofPos,
    double poofA,
    double poofRadius,
  })
  _frame(double t) {
    final victimOnly = widget.victimSeat >= 0 && !widget.areaCapture;
    final areaOnly = widget.areaCapture && widget.victimSeat < 0;

    Offset pos = _stealer;
    double angle = 0;
    int cards = 0;
    double cardT = 0;
    double scale = 1;
    double opacity = 1;
    Offset? poofPos;
    double poofA = 0;
    double poofRadius = 1;

    if (victimOnly) {
      final out = _easeInOut(_s(t, .06, .34));
      final back = _easeInOut(_s(t, .42, .74));
      angle = _heading(_stealer, _victim);
      if (t < .34) {
        pos = _lerp(_stealer, _victim, out);
      } else if (t < .42) {
        pos = _victim;
      } else {
        pos = _lerp(_victim, _stealer, back);
      }
      final grabbed = _s(t, .34, .42);
      if (t >= .34) {
        cards = widget.victimCardCount.clamp(1, 4);
        cardT = Curves.easeOutBack.transform(grabbed).clamp(0.0, 1.0);
        scale = 1.18 - .18 * grabbed;
      }
      poofPos = _victim;
      poofA = Curves.easeOut.transform(1 - _s(t, .34, .46)).clamp(0.0, 1.0);
      poofRadius = 1 + .35;
      opacity = _opacityFor(t, .78, .92);
    } else if (areaOnly) {
      angle = _heading(_area, _stealer);
      pos = _lerp(_area, _stealer, _easeOut(_s(t, .08, .58)));
      cards = widget.areaCardCount.clamp(1, 4);
      cardT = Curves.easeOutBack.transform(_s(t, .06, .14)).clamp(0.0, 1.0);
      scale = 1.08;
      poofPos = _area;
      poofA = Curves.easeOut.transform(1 - _s(t, .06, .2)).clamp(0.0, 1.0);
      poofRadius = 1;
      opacity = _opacityFor(t, .68, .84);
    } else {
      // Both: rake the play area first, then reach over to the robbed player.
      if (t < .3) {
        angle = _heading(_area, _stealer);
        pos = _lerp(_area, _stealer, _easeOut(_s(t, .06, .3)));
        cards = widget.areaCardCount.clamp(1, 4);
        cardT = Curves.easeOutBack.transform(_s(t, .06, .12)).clamp(0.0, 1.0);
        poofPos = _area;
        poofA = Curves.easeOut.transform(1 - _s(t, .06, .2)).clamp(0.0, 1.0);
      } else if (t < .56) {
        angle = _heading(_stealer, _victim);
        pos = _lerp(_stealer, _victim, _easeInOut(_s(t, .34, .56)));
        cards = 0;
        cardT = 0;
        scale = 1;
      } else if (t < .62) {
        pos = _victim;
        cards = widget.victimCardCount.clamp(1, 4);
        cardT = Curves.easeOutBack.transform(_s(t, .56, .62)).clamp(0.0, 1.0);
        scale = 1.18 - .18 * _s(t, .56, .62);
        poofPos = _victim;
        poofA = Curves.easeOut.transform(1 - _s(t, .56, .68)).clamp(0.0, 1.0);
      } else {
        angle = _heading(_stealer, _victim);
        pos = _lerp(_victim, _stealer, _easeInOut(_s(t, .62, .84)));
        cards = widget.victimCardCount.clamp(1, 4);
        cardT = 1;
      }
      opacity = _opacityFor(t, .86, .96);
    }

    return (
      pos: pos,
      angle: angle,
      cards: cards,
      cardT: cardT,
      scale: scale,
      opacity: opacity,
      poofPos: poofPos,
      poofA: poofA,
      poofRadius: poofRadius,
    );
  }

  // ---- rendering ----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return const IgnorePointer(child: SizedBox.expand());
    }
    return Semantics(
      container: true,
      label: 'Cards stolen',
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final f = _frame(_controller.value);
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (f.poofPos != null && f.poofA > 0)
                    _poof(f.poofPos!, f.poofA, f.poofRadius),
                  Positioned(
                    left: f.pos.dx - 40,
                    top: f.pos.dy - 40,
                    child: Transform.rotate(
                      angle: f.angle,
                      child: Transform.scale(
                        scale: f.scale,
                        child: Opacity(
                          opacity: f.opacity,
                          child: _hand(
                            cards: f.cards,
                            cardT: f.cardT,
                            angle: f.angle,
                          ),
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

  Widget _poof(Offset at, double alpha, double growth) {
    final radius = 58 * growth + 10;
    return Positioned(
      left: at.dx - radius,
      top: at.dy - radius,
      child: Opacity(
        opacity: alpha,
        child: Container(
          width: radius * 2,
          height: radius * 2,
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
    );
  }

  Widget _hand({
    required int cards,
    required double cardT,
    required double angle,
  }) {
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
          if (cards > 0)
            Opacity(
              opacity: cardT,
              child: Transform.translate(
                offset: Offset(0, -10),
                child: Transform.rotate(
                  angle: -angle * .6,
                  child: SizedBox(
                    width: 40,
                    height: 46,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        for (var i = cards; i > 0; i--)
                          Transform.translate(
                            offset: Offset((i - 2) * 5.0, (i - 2) * -4),
                            child: PlayingCard(faceDown: true, width: 26),
                          ),
                      ],
                    ),
                  ),
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
}
