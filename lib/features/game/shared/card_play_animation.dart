import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/audio/audio_system.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/taash_theme.dart';
import 'game_tint.dart';
import 'player_strip.dart';
import 'playing_card.dart';

/// The hand that reaches out when a card is played, in every game. It pops
/// over the source — a remote player's seat in the strip, or the local hand
/// rail — snatches up to four cards with a soft poof, arcs across to the play
/// area / pile and drops them with a burst. Quick, non-blocking and
/// self-removing, so it never pauses the turn clock.
class CardPlayAnimation extends StatefulWidget {
  const CardPlayAnimation({
    super.key,
    required this.game,
    required this.playerStripKey,
    required this.targetKey,
    required this.fromSeat,
    required this.cardCount,
    this.card = '',
    this.handKey,
    this.onComplete,
  });
  final GameType game;
  final GlobalKey playerStripKey;

  /// The pile the cards land on (Bhabhi trick, Bluff pile, Daketi play area,
  /// TC discard). Null falls back to table centre.
  final GlobalKey? targetKey;

  /// Seat index of the player who played; -1 means the local hand rail.
  final int fromSeat;
  final int cardCount;

  /// Face of the played card ('' renders a face-down cover).
  final String card;
  final GlobalKey? handKey;
  final VoidCallback? onComplete;
  @override
  State<CardPlayAnimation> createState() => _CardPlayAnimationState();
}

class _CardPlayAnimationState extends State<CardPlayAnimation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Offset _source = Offset.zero;
  Offset _target = Offset.zero;
  bool _resolved = false;
  bool _controllerReady = false;
  bool _dropPoof = false;

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
                  : const Duration(milliseconds: 1000),
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
      final self = widget.fromSeat < 0;
      if (self) {
        final handBox =
            widget.handKey?.currentContext?.findRenderObject() as RenderBox?;
        if (handBox != null && handBox.hasSize && handBox.attached) {
          _source = handBox.localToGlobal(handBox.size.center(Offset.zero));
        } else {
          _source = Offset(size.width * .5, size.height * .84);
        }
      } else {
        _source =
            stripSeatGlobalCenter(widget.playerStripKey, widget.fromSeat) ??
            Offset(size.width * .5, size.height * .16);
      }
      final targetBox =
          widget.targetKey?.currentContext?.findRenderObject() as RenderBox?;
      if (targetBox != null && targetBox.hasSize && targetBox.attached) {
        _target = targetBox.localToGlobal(targetBox.size.center(Offset.zero));
      } else {
        _target = Offset(size.width * .5, size.height * .5);
      }
      if (!_controller.isAnimating && _controller.value == 0) {
        _controller.forward();
      }
      _resolved = true;
      setState(() {});
    });
  }

  void _playPuffs() {
    if (!_dropPoof && _controller.value >= .58) {
      _dropPoof = true;
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
    if (b <= a) return t >= b ? 1 : 0;
    return ((t - a) / (b - a)).clamp(0.0, 1.0);
  }

  static Offset _lerp(Offset a, Offset b, double v) =>
      Offset(a.dx + (b.dx - a.dx) * v, a.dy + (b.dy - a.dy) * v);
  static double _heading(Offset from, Offset to) =>
      math.atan2(to.dy - from.dy, to.dx - from.dx);

  /// Arcs the hand over the table: control point lifted above the midpoint.
  static Offset _arc(Offset a, Offset b, double v) {
    final mid = _lerp(a, b, .5) - Offset(0, (a.dy < b.dy ? -62.0 : -34.0));
    final u = 1 - v;
    return Offset(
      u * u * a.dx + 2 * u * v * mid.dx + v * v * b.dx,
      u * u * a.dy + 2 * u * v * mid.dy + v * v * b.dy,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_resolved) {
      return const IgnorePointer(child: SizedBox.expand());
    }
    final accent = GameTint(widget.game).accent;
    return Semantics(
      container: true,
      label: 'Cards played',
      child: ExcludeSemantics(
        child: IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final t = _controller.value;
              final grab = _s(t, .0, .1);
              final fly = _s(t, .1, .55);
              final holdEnd = _s(t, .72, .9);
              final pos = _arc(
                _source,
                _target,
                Curves.easeInOut.transform(fly),
              );
              final scale =
                  1 + .24 * (1 - grab) * (t < .1 ? 1 : 0) - .06 * fly;
              final cardsOut = Curves.easeOutBack
                  .transform(_s(t, .04, .14))
                  .clamp(0.0, 1.0);
              final grabPoofA = Curves.easeOut
                  .transform(1 - _s(t, .04, .16))
                  .clamp(0.0, 1.0);
              final dropA = Curves.easeOut
                  .transform(_s(t, .5, .64))
                  .clamp(0.0, 1.0);
              final dropHold = Curves.easeOut
                  .transform(1 - _s(t, .6, .78))
                  .clamp(0.0, 1.0);
              final heading = _heading(_source, _target);
              return Stack(
                fit: StackFit.expand,
                children: [
                  if (grabPoofA > 0)
                    _poof(_source, grabPoofA),
                  if (dropA > 0 && dropHold > 0)
                    Positioned(
                      left: _target.dx - 55,
                      top: _target.dy - 55,
                      child: Opacity(
                        opacity: dropA,
                        child: Transform.scale(
                          scale: 1 + (1 - dropHold) * .6,
                          child: Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  accent.withValues(alpha: .9),
                                  accent.withValues(alpha: .3),
                                  Colors.transparent,
                                ],
                                stops: const [0, .55, 1],
                              ),
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
                          child: _hand(
                            cards: cardsOut,
                            angle: heading,
                            accent: accent,
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

  Widget _poof(Offset at, double alpha) => Positioned(
    left: at.dx - 66,
    top: at.dy - 66,
    child: Opacity(
      opacity: alpha,
      child: Container(
        width: 132,
        height: 132,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [
              Colors.white,
              Color(0x40FFFFFF),
              Colors.transparent,
            ],
            stops: [0, .55, 1],
          ),
        ),
      ),
    ),
  );

  Widget _hand({
    required double cards,
    required double angle,
    required Color accent,
  }) {
    final faces = widget.cardCount.clamp(1, 4);
    final showFace = widget.cardCount == 1 && widget.card.isNotEmpty;
    return SizedBox(
      width: 84,
      height: 84,
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
                colors: [accent.withValues(alpha: .30), Colors.transparent],
              ),
            ),
            child: const SizedBox(width: 76, height: 76),
          ),
          Opacity(
            opacity: cards,
            child: Transform.translate(
              offset: const Offset(0, -11),
              child: Transform.rotate(
                angle: -angle * .6,
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var i = 0; i < faces; i++)
                        Transform.translate(
                          offset: Offset((i - (faces - 1) / 2) * 7, i * -2),
                          child: Transform.rotate(
                            angle: (i - (faces - 1) / 2) * .16,
                            child: PlayingCard(
                              card: showFace ? widget.card : null,
                              faceDown: !showFace,
                              width: 26,
                            ),
                          ),
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
              size: 48,
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