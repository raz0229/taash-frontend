import 'package:taash/l10n/copy.dart';
import 'dart:collection';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/models/models.dart';
import '../../core/theme/taash_theme.dart';

class ReactionChoice {
  const ReactionChoice(this.id, this.cost, this.static);
  final int id, cost;
  final bool static;
  String get label => reactionLabel(id);
  static Future<List<ReactionChoice>> load() async {
    final data =
        jsonDecode(
              await rootBundle.loadString('assets/catalogs/reactions.json'),
            )
            as List;
    return data
        .map(
          (row) => ReactionChoice(
            row['anim_id'] as int,
            row['anim_cost_in_coins'] as int,
            row['static'] == true,
          ),
        )
        .toList(growable: false);
  }
}

String reactionLabel(int id) => const [
  Copy.laugh,
  Copy.phew,
  Copy.shukriya,
  Copy.ohNo,
  Copy.grr,
  Copy.applause,
  Copy.rose,
  Copy.heart,
  Copy.tomato,
  Copy.donkey,
][id.clamp(0, 9)];

/// Supplied reaction artwork; reduced motion keeps a static vector equivalent.
class ReactionArt extends StatelessWidget {
  const ReactionArt({super.key, required this.id, this.size = 48});
  final int id;
  final double size;
  @override
  Widget build(BuildContext context) => Semantics(
    label: reactionLabel(id),
    image: true,
    child: MediaQuery.disableAnimationsOf(context)
        ? CustomPaint(size: Size.square(size), painter: _ReactionPainter(id))
        : Image.asset(
            'assets/reactions/${id.clamp(0, 9)}.gif',
            width: size,
            height: size,
            fit: BoxFit.contain,
            cacheWidth: 160,
            gaplessPlayback: true,
          ),
  );
}

class _ReactionPainter extends CustomPainter {
  _ReactionPainter(this.id);
  final int id;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 100);
    final p = Paint()..isAntiAlias = true;
    if (id <= 4) {
      canvas.drawCircle(const Offset(50, 50), 43, p..color = T.ochre);
      canvas.drawCircle(const Offset(34, 44), 4, p..color = T.ink);
      canvas.drawCircle(const Offset(66, 44), 4, p);
      p
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      if (id == 0) {
        canvas.drawArc(
          const Rect.fromLTWH(29, 42, 42, 34),
          .1,
          math.pi - .2,
          false,
          p,
        );
      }
      if (id == 1) {
        canvas.drawLine(const Offset(34, 65), const Offset(63, 65), p);
      }
      if (id == 2) {
        canvas.drawArc(
          const Rect.fromLTWH(30, 47, 40, 25),
          .1,
          math.pi - .2,
          false,
          p,
        );
      }
      if (id == 3) {
        canvas.drawArc(
          const Rect.fromLTWH(31, 64, 38, 23),
          math.pi + .1,
          math.pi - .2,
          false,
          p,
        );
      }
      if (id == 4) {
        canvas.drawLine(const Offset(27, 31), const Offset(39, 36), p);
        canvas.drawLine(const Offset(61, 36), const Offset(73, 31), p);
        canvas.drawArc(
          const Rect.fromLTWH(33, 65, 34, 17),
          math.pi,
          math.pi,
          false,
          p,
        );
      }
      p.style = PaintingStyle.fill;
      if (id == 1) {
        final drop = Path()
          ..moveTo(80, 22)
          ..quadraticBezierTo(63, 46, 80, 50)
          ..quadraticBezierTo(97, 46, 80, 22);
        canvas.drawPath(drop, p..color = const Color(0xff81bdd4));
      }
      return;
    }
    if (id == 5) {
      canvas.save();
      canvas.translate(50, 54);
      canvas.rotate(-.3);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-29, -29, 24, 59),
          const Radius.circular(12),
        ),
        p..color = T.ochre,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-1, -34, 24, 59),
          const Radius.circular(12),
        ),
        p..color = const Color(0xffd19441),
      );
      canvas.restore();
      p
        ..color = T.ochre
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawLine(const Offset(26, 13), const Offset(20, 4), p);
      canvas.drawLine(const Offset(53, 11), const Offset(55, 1), p);
      canvas.drawLine(const Offset(78, 23), const Offset(89, 16), p);
      return;
    }
    if (id == 6) {
      canvas.drawLine(
        const Offset(48, 46),
        const Offset(42, 91),
        p
          ..color = T.pine
          ..strokeWidth = 6,
      );
      canvas.drawOval(const Rect.fromLTWH(45, 60, 25, 12), p);
      canvas.drawCircle(const Offset(43, 30), 20, p..color = T.coral);
      canvas.drawCircle(
        const Offset(59, 28),
        18,
        p..color = const Color(0xffe07058),
      );
      canvas.drawCircle(
        const Offset(51, 42),
        18,
        p..color = const Color(0xffa52e35),
      );
      return;
    }
    if (id == 7) {
      final heart = Path()
        ..moveTo(50, 85)
        ..cubicTo(-18, 42, 18, 1, 50, 30)
        ..cubicTo(82, 1, 118, 42, 50, 85);
      canvas.drawPath(heart, p..color = T.coral);
      canvas.drawCircle(const Offset(82, 18), 5, p..color = T.ochre);
      canvas.drawCircle(const Offset(90, 70), 3, p);
      return;
    }
    if (id == 8) {
      canvas.drawOval(const Rect.fromLTWH(13, 25, 74, 60), p..color = T.coral);
      final leaves = Path()
        ..moveTo(50, 35)
        ..lineTo(21, 18)
        ..lineTo(43, 22)
        ..lineTo(48, 7)
        ..lineTo(57, 22)
        ..lineTo(80, 17)
        ..close();
      canvas.drawPath(leaves, p..color = T.pine);
      canvas.drawOval(
        const Rect.fromLTWH(23, 39, 9, 20),
        p..color = const Color(0xffffbaa1),
      );
      return;
    }
    canvas.save();
    canvas.translate(29, 26);
    canvas.rotate(-.25);
    canvas.drawOval(
      const Rect.fromLTWH(-7, -24, 14, 46),
      p..color = const Color(0xff8c8172),
    );
    canvas.restore();
    canvas.save();
    canvas.translate(69, 26);
    canvas.rotate(.25);
    canvas.drawOval(const Rect.fromLTWH(-7, -24, 14, 46), p);
    canvas.restore();
    canvas.drawOval(
      const Rect.fromLTWH(23, 21, 54, 65),
      p..color = const Color(0xffa19c89),
    );
    canvas.drawOval(
      const Rect.fromLTWH(25, 58, 50, 32),
      p..color = const Color(0xffd8cab0),
    );
    canvas.drawCircle(const Offset(38, 44), 3, p..color = T.ink);
    canvas.drawCircle(const Offset(63, 44), 3, p);
    canvas.drawLine(
      const Offset(43, 75),
      const Offset(58, 75),
      p..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _ReactionPainter oldDelegate) =>
      oldDelegate.id != id;
}

class ReactionOverlay extends StatefulWidget {
  const ReactionOverlay({
    super.key,
    required this.events,
    required this.players,
    required this.selfId,
    this.muted = false,
  });
  final List<ChatAnimation> events;
  final List<PublicPlayer> players;
  final String selfId;
  final bool muted;
  @override
  State<ReactionOverlay> createState() => _ReactionOverlayState();
}

class _ReactionOverlayState extends State<ReactionOverlay>
    with WidgetsBindingObserver {
  final LinkedHashSet<String> _seen = LinkedHashSet();
  final Queue<ChatAnimation> _queue = Queue();
  final List<ChatAnimation> _active = [];
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ingest();
  }

  @override
  void didUpdateWidget(ReactionOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    _ingest();
  }

  void _ingest() {
    for (final event in widget.events) {
      if (!_seen.add(event.deduplicationKey)) continue;
      if (_seen.length > 256) _seen.remove(_seen.first);
      if (widget.muted ||
          !_foreground ||
          DateTime.now().difference(event.sentAt).inSeconds > 8) {
        continue;
      }
      if (_queue.length == 4) _queue.removeFirst();
      _queue.add(event);
    }
    if (widget.muted) {
      _queue.clear();
      _active.clear();
    }
    _drain();
  }

  void _drain() {
    while (_foreground && _active.length < 2 && _queue.isNotEmpty) {
      _active.add(_queue.removeFirst());
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    if (!_foreground) {
      setState(() {
        _active.clear();
        _queue.clear();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Alignment _anchor(String playerId) {
    if (playerId == widget.selfId) return const Alignment(0, .7);
    final players = widget.players.where((p) => p.id != widget.selfId).toList()
      ..sort((a, b) => a.seat.compareTo(b.seat));
    final index = players.indexWhere((p) => p.id == playerId);
    return Alignment(
      players.length < 2 ? 0 : -.8 + index * 1.6 / (players.length - 1),
      -.72,
    );
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Stack(
      children: [
        for (final event in _active)
          _ReactionFlight(
            key: ValueKey(event.deduplicationKey),
            event: event,
            from: _anchor(event.fromPlayer),
            to: _anchor(event.toPlayer),
            isStatic: event.animId <= 5,
            recipient:
                widget.players
                    .where((p) => p.id == event.toPlayer)
                    .firstOrNull
                    ?.displayName ??
                Copy.player,
            onDone: () {
              if (mounted) {
                setState(() {
                  _active.remove(event);
                  _drain();
                });
              }
            },
          ),
      ],
    ),
  );
}

class _ReactionFlight extends StatefulWidget {
  const _ReactionFlight({
    super.key,
    required this.event,
    required this.from,
    required this.to,
    required this.isStatic,
    required this.recipient,
    required this.onDone,
  });
  final ChatAnimation event;
  final Alignment from, to;
  final bool isStatic;
  final String recipient;
  final VoidCallback onDone;
  @override
  State<_ReactionFlight> createState() => _ReactionFlightState();
}

class _ReactionFlightState extends State<_ReactionFlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 3500))
        ..addStatusListener((status) {
          if (status == AnimationStatus.completed) widget.onDone();
        })
        ..forward();
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final v = _controller.value;
        final travel = Curves.easeInOutCubic.transform((v / .65).clamp(0, 1));
        return Align(
          alignment: reduce || widget.isStatic
              ? widget.from
              : Alignment.lerp(widget.from, widget.to, travel)!,
          child: Opacity(
            opacity: v > .85 ? (1 - v) / .15 : 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: T.surface,
                borderRadius: BorderRadius.circular(22),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 12),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ReactionArt(id: widget.event.animId, size: 64),
                  if (!widget.isStatic)
                    Text(
                      widget.recipient,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
