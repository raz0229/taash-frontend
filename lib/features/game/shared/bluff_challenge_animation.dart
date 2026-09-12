import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/taash_theme.dart';
import '../../../core/widgets/taash_widgets.dart';
import 'hand_order.dart';
import 'playing_card.dart';

/// A full-room cinematic reveal shown in *every* seat of a Bluff room when a
/// challenge resolves. The sequence is staged so a player can follow it in one
/// glance:
///
/// 1. The challenger and the challenged player are named at the top of a
///    central card next to a "VS" badge.
/// 2. The challenged player's declared rank appears, followed by the last play
///    (face up) — the cards that are on trial.
/// 3. A verdict overlay lands on top: **Sacha** (truthful) and **Jhuta**
///    (liar), derived from `bluff_caught`.
/// 4. The face-down pile lifts off the table and flies up to the winner's seat
///    in the player strip, ending with a soft burst and a "+N" card count.
///
/// The entire show runs until [onComplete], which the host uses to release the
/// overlay and resume the paused turn timer.
class BluffChallengeAnimation extends StatefulWidget {
  const BluffChallengeAnimation({
    super.key,
    required this.challengerName,
    required this.challengerPfp,
    required this.challengedName,
    required this.challengedPfp,
    required this.declaredRank,
    required this.lastPlayCards,
    required this.pileCount,
    required this.sachaName,
    required this.jhutaName,
    required this.pileStackKey,
    required this.playerStripKey,
    required this.winnerSeatIndex,
    required this.onComplete,
  });
  final String challengerName, challengedName;
  final int challengerPfp, challengedPfp;
  final String declaredRank;
  final List<String> lastPlayCards;
  final int pileCount;
  final String sachaName, jhutaName;
  final GlobalKey pileStackKey;
  final GlobalKey playerStripKey;
  final int winnerSeatIndex;
  final VoidCallback onComplete;

  @override
  State<BluffChallengeAnimation> createState() =>
      _BluffChallengeAnimationState();
}

class _BluffChallengeAnimationState extends State<BluffChallengeAnimation>
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
      final pileBox =
          widget.pileStackKey.currentContext?.findRenderObject() as RenderBox?;
      if (pileBox != null && pileBox.hasSize && pileBox.attached) {
        start = pileBox.localToGlobal(pileBox.size.center(Offset.zero));
      } else {
        start = Offset(size.width / 2, size.height * .56);
      }
      final stripBox =
          widget.playerStripKey.currentContext?.findRenderObject() as RenderBox?;
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

  static Offset _quadBezier(
    Offset a,
    Offset control,
    Offset b,
    double t,
  ) {
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
          'Bluff caught! ${widget.challengerName} challenged ${widget.challengedName}, who declared ${widget.declaredRank}. ${widget.sachaName} is Sacha, ${widget.jhutaName} is Jhuta. The pile goes to ${widget.winnerSeatIndex + 1}.',
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
                  Positioned.fill(child: _verdict(t)),
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
    final leave = 1 - _smooth(t, .58, .72);
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
              child: const Text(
                'BLUFF CAUGHT!',
                textAlign: TextAlign.center,
                style: TextStyle(
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
    final width = math.min(370.0, MediaQuery.sizeOf(context).width * .92);
    final panel = Curves.easeOutBack.transform(((t - .08) / .2).clamp(0.0, 1.0));
    final verdictDim = _smooth(t, .54, .68);
    final flightDim = _smooth(t, .76, .86) * .45;
    final leave = 1 - _smooth(t, .9, 1);
    final opacity =
        (panel * (1 - verdictDim * .4) * (1 - flightDim) * leave).clamp(
          0.0,
          1.0,
        );
    return Center(
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(
          offset: Offset(0, Curves.easeOut.transform(panel.clamp(0.0, 1.0)) * 28),
          child: Transform.scale(
            scale: panel,
            child: Container(
              width: width,
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 18),
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
                    color: T.coral.withValues(alpha: .18),
                    blurRadius: 34,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _plateRow(t),
                  const SizedBox(height: 14),
                  _rankRow(t),
                  const SizedBox(height: 12),
                  _lastCardsRow(t),
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
    final vs = Curves.elasticOut.transform(((t - .26) / .1).clamp(0.0, 1.0));
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _playerPlate(
          name: widget.challengerName,
          pfp: widget.challengerPfp,
          label: 'CHALLENGER',
          accent: T.coral,
          progress: left,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Opacity(
            opacity: vs.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: vs,
              child: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xff2C1F45),
                  border: Border.all(color: const Color(0xff9B82E0)),
                ),
                child: const Text(
                  'VS',
                  style: TextStyle(
                    color: T.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ),
        ),
        _playerPlate(
          name: widget.challengedName,
          pfp: widget.challengedPfp,
          label: 'CHALLENGED',
          accent: T.ochre,
          progress: right,
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
  }) {
    final shifted = Curves.easeOut.transform(progress);
    final dx = label == 'CHALLENGER' ? -1 : 1;
    return Opacity(
      opacity: progress,
      child: Transform.translate(
        offset: Offset(dx * (1 - shifted) * 56, 0),
        child: Container(
          width: 118,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: accent.withValues(alpha: .55)),
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
    );
  }

  Widget _rankRow(double t) {
    final p = Curves.easeOutBack.transform(((t - .42) / .14).clamp(0.0, 1.0));
    final rank = CardIdentity.rankNameFor(widget.declaredRank);
    return Opacity(
      opacity: p.clamp(0.0, 1.0),
      child: Transform.scale(
        scale: p.clamp(0.0, 1.2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.local_offer_outlined, color: T.mint, size: 16),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                '${widget.challengedName} declared',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: T.mint, fontSize: 13),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: T.ochre.withValues(alpha: .16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: T.ochre.withValues(alpha: .6)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.style, color: T.ochre, size: 15),
                  const SizedBox(width: 5),
                  Text(
                    rank,
                    style: const TextStyle(
                      color: T.ochre,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lastCardsRow(double t) {
    final p = Curves.easeOut.transform(((t - .48) / .16).clamp(0.0, 1.0));
    final count = widget.lastPlayCards.length.clamp(1, 4);
    return Opacity(
      opacity: p.clamp(0.0, 1.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'LAST PLAY',
            style: TextStyle(
              color: Color(0xffB2A4CD),
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Transform.translate(
            offset: Offset(0, (1 - p) * 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < count; i++)
                  Transform.translate(
                    offset: Offset(
                      (i - (count - 1) / 2) * 16,
                      ((i - (count - 1) / 2).abs()) * -2,
                    ),
                    child: Transform.rotate(
                      angle: (i - (count - 1) / 2) * .07,
                      child: PlayingCard(
                        card: widget.lastPlayCards[i],
                        width: 54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _verdict(double t) {
    final enter = Curves.easeOutBack.transform(((t - .56) / .14).clamp(0.0, 1.0));
    final leave = 1 - _smooth(t, .82, .92);
    final width = math.min(350.0, MediaQuery.sizeOf(context).width * .88);
    return Center(
      child: Opacity(
        opacity: (enter * leave).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - Curves.easeOut.transform(enter.clamp(0.0, 1.0))) * 70),
          child: Transform.scale(
            scale: enter,
            child: Container(
              width: width,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xff181028).withValues(alpha: .96),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xff51418A), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff000000).withValues(alpha: .5),
                    blurRadius: 38,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'THE VERDICT',
                    style: TextStyle(
                      color: T.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _verdictRow(
                    label: 'SACHA',
                    name: widget.sachaName,
                    icon: Icons.verified_rounded,
                    color: const Color(0xff4CD97B),
                  ),
                  const SizedBox(height: 9),
                  _verdictRow(
                    label: 'JHUTA',
                    name: widget.jhutaName,
                    icon: Icons.cancel_rounded,
                    color: T.danger,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _verdictRow({
    required String label,
    required String name,
    required IconData icon,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: color.withValues(alpha: .5)),
    ),
    child: Row(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: T.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _pileFlight(double t) {
    final size = MediaQuery.sizeOf(context);
    final start = _positionsReady ? _pileStart : Offset(size.width / 2, size.height * .56);
    final end = _positionsReady ? _winnerEnd : Offset(size.width / 2, size.height * .16);
    final control = Offset(
      (start.dx + end.dx) / 2,
      math.min(start.dy, end.dy) - (size.height * .12).clamp(90, 190),
    );
    final count = widget.lastPlayCards.length.clamp(1, 4);
    final cards = <Widget>[];
    for (var i = 0; i < count; i++) {
      final lead = count == 1 ? 0.0 : i / (count - 1);
      final p = _smooth(t, .74 + lead * .025, .89 + (1 - lead) * .02);
      if (p <= 0) continue;
      final eased = Curves.easeInOutCubic.transform(p);
      final pos = _quadBezier(start, control, end, eased);
      final splay = (i - (count - 1) / 2);
      cards.add(
        Positioned(
          left: pos.dx - 27,
          top: pos.dy - 37,
          child: Transform.translate(
            offset: Offset(splay * (1 - eased) * 8, 0),
            child: Transform.rotate(
              angle: splay * (.2 - .16 * eased),
              child: Transform.scale(
                scale: 1 - .1 * eased,
                child: Opacity(
                  opacity: (p / .12).clamp(0.0, 1.0) * (1 - _smooth(t, .93, 1)),
                  child: const PlayingCard(faceDown: true, width: 54),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: cards);
  }

  Widget _winnerBurst(double t) {
    final size = MediaQuery.sizeOf(context);
    final end = _positionsReady ? _winnerEnd : Offset(size.width / 2, size.height * .16);
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
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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