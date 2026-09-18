import '../../core/audio/audio_system.dart';

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/theme/taash_theme.dart';

/// The Sidelocks Wheel, a casino-style five-segment prize wheel shown when a
/// player taps the Gift icon on the home screen.
///
/// The reward amount is chosen and granted by the server (`claimThreeHourly
/// Reward` picks from 100/200/250/400/500); this widget only plays the
/// animation that lands the pointer on the segment the server already
/// credited, then celebrates with the same coin sound as before.
Future<void> showSidelocksWheel(
  BuildContext context, {
  required AuthController auth,
}) async {
  final startCoins = auth.profile?.coins ?? 0;
  await showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close Sidelocks Wheel',
    barrierColor: Colors.black.withValues(alpha: .6),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (_, animation, _, child) => FadeTransition(
      opacity: animation,
      child: ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: child,
      ),
    ),
    pageBuilder: (_, _, _) =>
        SidelocksWheelDialog(auth: auth, startCoins: startCoins),
  );
}

/// The five prizes, in wheel order (clockwise from the top).
const wheelValues = [400, 100, 500, 200, 250];

class SidelocksWheelDialog extends StatefulWidget {
  const SidelocksWheelDialog({
    super.key,
    required this.auth,
    required this.startCoins,
  });
  final AuthController auth;
  final int startCoins;
  @override
  State<SidelocksWheelDialog> createState() => _SidelocksWheelDialogState();
}

enum _WheelPhase { idle, awaiting, spinning, won, failed }

class _SidelocksWheelDialogState extends State<SidelocksWheelDialog>
    with TickerProviderStateMixin {
  static final _segmentAngle = 2 * math.pi / wheelValues.length;

  late final AnimationController _spinController;
  late final AnimationController _winController;
  late final Animation<double> _spinProgress;
  late Animation<double> _balance;

  _WheelPhase _phase = _WheelPhase.idle;
  String? _error;
  int _reward = 0;
  double _fromRotation = 0;
  double _toRotation = 0;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 5900),
    )..addStatusListener(_onSpinFinished);
    _spinProgress = _spinController.drive(CurveTween(curve: _SpinCurve()));
    _winController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _balance = Tween<double>(
      begin: widget.startCoins.toDouble(),
      end: widget.startCoins.toDouble(),
    ).animate(_winController);
  }

  void _onSpinFinished(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    audio.stopLoopingSfx();
    audio.playSfx('coins_added_in_hourly_reward');
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    setState(() => _phase = _WheelPhase.won);
    _winController.forward(from: 0);
  }

  Future<void> _spin() async {
    if (_phase == _WheelPhase.awaiting ||
        _phase == _WheelPhase.spinning ||
        _phase == _WheelPhase.won) {
      return;
    }
    audio.playSfx('generic_button_press');
    setState(() {
      _phase = _WheelPhase.awaiting;
      _error = null;
    });
    try {
      final result = await widget.auth.api.claimThreeHourlyReward(
        widget.auth.profile?.id ?? '',
      );
      final targetIndex = wheelValues.indexOf(result.rewardAmount);
      if (targetIndex < 0) {
        throw const AppFailure(
          'invalid_server_response',
          'The server returned an unknown wheel prize. Please try again.',
        );
      }
      if (!mounted) return;

      // Small jitter so the result doesn't always land dead-centre.
      final jitter =
          (math.Random().nextDouble() * 2 - 1) * (_segmentAngle * 0.34);
      var target = -(targetIndex + 0.5) * _segmentAngle + jitter;
      target %= 2 * math.pi;

      // The wheel keeps its rest bearing between spins, so the total travel
      // must end with `target` as the final bearing. Otherwise each spin would
      // add on top of the previous one and land on a random segment.
      final baseRotation = _fromRotation % (2 * math.pi);
      final delta = (target - baseRotation + 2 * math.pi) % (2 * math.pi);
      // Whole turns only; any fractional turn would shift the final bearing.
      final spins = 6 + math.Random().nextInt(2).toDouble();
      final total = spins * 2 * math.pi + delta;

      setState(() {
        _reward = result.rewardAmount;
        _fromRotation = _toRotation;
        _toRotation = _fromRotation + total;
        _phase = _WheelPhase.spinning;
      });
      _balance = Tween<double>(
        begin: widget.startCoins.toDouble(),
        end: result.coins.toDouble(),
      ).animate(_winController);
      _spinController.forward(from: 0);
      audio.playLoopingSfx('wheel-spin');
    } on AppFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _phase = _WheelPhase.failed;
        _error = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _phase = _WheelPhase.failed;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  void dispose() {
    audio.stopLoopingSfx();
    _spinController.dispose();
    _winController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spinning =
        _phase == _WheelPhase.spinning || _phase == _WheelPhase.awaiting;
    final media = MediaQuery.of(context);
    final wheelSize = (media.size.width - 96).clamp(210.0, 268.0);

    return PopScope(
      canPop: !spinning,
      child: Center(
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xff241F3B), Color(0xff151223)],
              ),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: const Color(0xffFFCC54).withValues(alpha: .55),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffFFCC54).withValues(alpha: .18),
                  blurRadius: 34,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _header(),
                  const SizedBox(height: 18),
                  SizedBox(
                    width: wheelSize,
                    height: wheelSize + 58,
                    child: _buildWheel(wheelSize),
                  ),
                  const SizedBox(height: 14),
                  _buildControls(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _header() {
    final title = Text(
      'Sidelocks Wheel',
      style: const TextStyle(
        fontSize: 26,
        fontWeight: FontWeight.w900,
        letterSpacing: 1.1,
      ),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.auto_awesome, size: 17, color: Color(0xffA581FF)),
        const SizedBox(width: 8),
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xffFFE8A1), Color(0xffFFB647), Color(0xffFFE8A1)],
          ).createShader(bounds),
          child: title,
        ),
        const SizedBox(width: 8),
        const Icon(Icons.auto_awesome, size: 17, color: Color(0xff69DFFF)),
      ],
    );
  }

  Widget _buildWheel(double wheelSize) {
    final spinning = _phase == _WheelPhase.spinning;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Soft glow behind the wheel while it spins.
        AnimatedOpacity(
          opacity: spinning ? 1 : 0,
          duration: const Duration(milliseconds: 400),
          child: Container(
            width: wheelSize + 44,
            height: wheelSize + 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xffFFCC54).withValues(alpha: .28),
                  blurRadius: 46,
                  spreadRadius: 6,
                ),
              ],
            ),
          ),
        ),
        SizedBox(
          width: wheelSize,
          height: wheelSize,
          child: AnimatedBuilder(
            animation: _spinProgress,
            builder: (context, _) => CustomPaint(
              painter: _WheelPainter(
                rotation: _fromRotation +
                    (_toRotation - _fromRotation) * _spinProgress.value,
              ),
            ),
          ),
        ),
        // Fixed pointer. Sits just below the header (top edge of the stack)
        // with its tip overlapping the wheel rim.
        Positioned(
          top: 0,
          child: CustomPaint(
            size: const Size(44, 60),
            painter: _PointerPainter(),
          ),
        ),
        // Win burst overlay.
        if (_phase == _WheelPhase.won || _winController.isAnimating)
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _winController,
              builder: (context, _) => _WinOverlay(
                progress: _winController.value,
                amount: _reward,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildControls() {
    switch (_phase) {
      case _WheelPhase.won:
        return Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: const LinearGradient(
                  colors: [Color(0xff3A2A14), Color(0xff2A1D0E)],
                ),
                border: Border.all(
                  color: const Color(0xffFFCC54).withValues(alpha: .7),
                ),
              ),
              child: Column(
                children: [
                  const Text(
                    'YOU WIN',
                    style: TextStyle(
                      color: Color(0xffFFCC54),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '+$_reward coins',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: Color(0xffFFE8A1),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Balance: ${_balance.value.round()} coins',
                    style: const TextStyle(color: T.muted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: T.ochre,
                  foregroundColor: const Color(0xff2B1B35),
                ),
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.savings_outlined, size: 20),
                label: const Text('Collect coins & close'),
              ),
            ),
          ],
        );
      case _WheelPhase.failed:
        return Column(
          children: [
            Text(
              _error ?? 'Could not claim the reward.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: T.danger, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ),
          ],
        );
      case _WheelPhase.awaiting:
      case _WheelPhase.spinning:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xff2A2340),
              foregroundColor: const Color(0xffA79AC7),
            ),
            onPressed: null,
            icon: const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2.2),
            ),
            label: const Text('Spinning…'),
          ),
        );
      case _WheelPhase.idle:
        return Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: T.ochre,
                  foregroundColor: const Color(0xff2B1B35),
                  side: const BorderSide(color: Color(0xffFFE7A0)),
                  elevation: 5,
                  shadowColor: const Color(0xff090812),
                ),
                onPressed: _spin,
                icon: const Icon(Icons.change_circle_outlined, size: 22),
                label: const Text('SPIN'),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Balance: ${_balance.value.round()} coins',
              style: const TextStyle(color: T.muted, fontSize: 13),
            ),
          ],
        );
    }
  }
}

/// Spin timing curve: launches fast and decelerates smoothly and
/// continuously so the wheel never appears to stall and re-spin mid-way, and
/// comes to a full stop exactly at 1.0 so the pointer and the awarded prize
/// always agree.
class _SpinCurve extends Curve {
  const _SpinCurve();

  @override
  double transformInternal(double t) {
    if (t <= 0) return 0;
    if (t >= 1) return 1;
    return 1 - math.pow(1 - t, 3.6).toDouble();
  }
}

class _WheelPainter extends CustomPainter {
  _WheelPainter({required this.rotation});
  final double rotation;

  static const _gold = Color(0xffF2B84B);
  static const _goldDeep = Color(0xffA96E1E);
  static const _plum = Color(0xff6A2FA0);
  static const _plumDeep = Color(0xff34144F);

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = math.min(size.width, size.height) / 2;
    final wedgeOuter = outer - 3;
    final hubRadius = outer * 0.21;
    final segmentAngle = 2 * math.pi / wheelValues.length;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);
    canvas.translate(-center.dx, -center.dy);

    // Outer bezel.
    final bezelPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.2),
        radius: 1.1,
        colors: [Color(0xff4A3B63), Color(0xff221C33)],
      ).createShader(Rect.fromCircle(center: center, radius: outer));
    canvas.drawCircle(center, outer, bezelPaint);

    // Gold rim ring.
    final rimPaint = Paint()
      ..shader = const SweepGradient(
        colors: [
          Color(0xffFFE8A1),
          Color(0xffF2B84B),
          Color(0xff8F5E18),
          Color(0xffF2B84B),
          Color(0xffFFE8A1),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: outer));
    canvas.drawCircle(
      center,
      (outer + wedgeOuter) / 2,
      rimPaint
        ..style = PaintingStyle.stroke
        ..strokeWidth = outer - wedgeOuter + 1,
    );

    // Wedges.
    for (var i = 0; i < wheelValues.length; i++) {
      final start = -math.pi / 2 + i * segmentAngle;
      final isGold = i.isEven;
      final isJackpot = wheelValues[i] == 500;
      final path = Path()
        ..moveTo(center.dx, center.dy)
        ..arcTo(
          Rect.fromCircle(center: center, radius: wedgeOuter),
          start,
          segmentAngle,
          false,
        )
        ..close();

      final shader = RadialGradient(
        radius: 1.05,
        colors: isGold
            ? [
                const Color(0xffFFE8A1),
                _gold,
                isJackpot ? const Color(0xffD98F14) : _goldDeep,
              ]
            : [
                const Color(0xffA575E0),
                _plum,
                _plumDeep,
              ],
        stops: isJackpot ? const [0.0, 0.45, 1.0] : const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: wedgeOuter));
      canvas.drawPath(path, Paint()..shader = shader);

      // Fine separator between wedges.
      final sepPaint = Paint()
        ..color = const Color(0xff1A1226).withValues(alpha: .8)
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
        Offset(
          center.dx + math.cos(start) * hubRadius,
          center.dy + math.sin(start) * hubRadius,
        ),
        Offset(
          center.dx + math.cos(start) * wedgeOuter,
          center.dy + math.sin(start) * wedgeOuter,
        ),
        sepPaint,
      );
    }

    // Segment labels.
    final labelRadius = wedgeOuter * 0.64;
    for (var i = 0; i < wheelValues.length; i++) {
      final ca = -math.pi / 2 + (i + 0.5) * segmentAngle;
      final pos = Offset(
        center.dx + math.cos(ca) * labelRadius,
        center.dy + math.sin(ca) * labelRadius,
      );
      final isGold = i.isEven;
      final tp = TextPainter(
        text: TextSpan(
          text: '+${wheelValues[i]}',
          style: TextStyle(
            color: isGold ? const Color(0xff2E1A05) : const Color(0xffFBe7FF),
            fontSize: wheelValues[i] == 500 ? 16 : 13.5,
            fontWeight: wheelValues[i] == 500
                ? FontWeight.w900
                : FontWeight.w800,
            shadows: isGold
                ? const []
                : [
                    Shadow(
                      color: Colors.black.withValues(alpha: .45),
                      blurRadius: 3,
                    ),
                  ],
          ),
        ),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      )..layout();
      tp.paint(canvas, pos - Offset(tp.width / 2, tp.height / 2));
    }

    // Boundary pegs on the rim.
    final pegPaint = Paint()..color = const Color(0xffFFD97A);
    for (var i = 0; i < wheelValues.length * 2; i++) {
      final a = -math.pi / 2 + i * math.pi / wheelValues.length;
      final p = Offset(
        center.dx + math.cos(a) * (outer + wedgeOuter) / 2,
        center.dy + math.sin(a) * (outer + wedgeOuter) / 2,
      );
      canvas.drawCircle(p, 2.2, pegPaint);
    }

    // Hub.
    final hubPaint = Paint()
      ..shader = const RadialGradient(
        center: Alignment(0, -0.3),
        colors: [Color(0xffFFE8A1), Color(0xffF2B84B), Color(0xff9A6516)],
      ).createShader(Rect.fromCircle(center: center, radius: hubRadius));
    canvas.drawCircle(center, hubRadius, hubPaint);
    canvas.drawCircle(
      center,
      hubRadius * 0.72,
      Paint()
        ..color = const Color(0xff3A2410)
        ..style = PaintingStyle.stroke
        ..strokeWidth = hubRadius * 0.14,
    );
    _drawStar(canvas, center, hubRadius * 0.4, const Color(0xff3A2410));
    canvas.restore();
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.42;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

class _PointerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final tip = Offset(centerX, size.height - 8);
    final left = Offset(centerX - 15, size.height - 22);
    final right = Offset(centerX + 15, size.height - 22);

    // Gold triangle.
    final triangle = Path()..addPolygon([left, right, tip], true);
    canvas.drawPath(
      triangle,
      Paint()..color = const Color(0xffFFE8A1),
    );
    canvas.drawPath(
      triangle,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2
        ..color = const Color(0xff8F5E18),
    );

    // Circular head button.
    final head = Offset(centerX, size.height - 48);
    final headRadius = size.width * 0.3;
    canvas.drawCircle(
      head,
      headRadius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xffFFE8A1), Color(0xffF2B84B), Color(0xff9A6516)],
        ).createShader(Rect.fromCircle(center: head, radius: headRadius)),
    );
    canvas.drawCircle(
      head,
      headRadius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xff3A2410),
    );
    _pointerStar(canvas, head, size.width * 0.13);
  }

  void _pointerStar(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final r = i.isEven ? radius : radius * 0.42;
      final a = -math.pi / 2 + i * math.pi / 5;
      final p = Offset(center.dx + math.cos(a) * r, center.dy + math.sin(a) * r);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = const Color(0xff3A2410));
  }

  @override
  bool shouldRepaint(_PointerPainter oldDelegate) => false;
}

/// Transient "you won" glow + coin burst shown over the wheel after it lands.
class _WinOverlay extends StatelessWidget {
  const _WinOverlay({required this.progress, required this.amount});
  final double progress;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);
    final scale = Curves.elasticOut.transform((t / 0.45).clamp(0.0, 1.0));
    return IgnorePointer(
      child: CustomPaint(
        painter: _WinOverlayPainter(progress: t, seed: amount),
        child: Center(
          child: Opacity(
            opacity: t > 0.7 ? (1 - t) / 0.3 : 1,
            child: Transform.scale(
              scale: 0.6 + 0.4 * scale,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xffFFCC54), width: 2),
                  gradient: const LinearGradient(
                    colors: [Color(0xff3A2A14), Color(0xff241A0C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xffFFCC54).withValues(alpha: .4),
                      blurRadius: 26,
                    ),
                  ],
                ),
                child: Text(
                  '+$amount',
                  style: const TextStyle(
                    color: Color(0xffFFE8A1),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WinOverlayPainter extends CustomPainter {
  _WinOverlayPainter({required this.progress, required this.seed});
  final double progress;
  final int seed;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);
    final rng = math.Random(seed + 1);
    for (var i = 0; i < 14; i++) {
      final dir = rng.nextDouble() * 2 * math.pi;
      final dist = 0.35 + rng.nextDouble() * 0.45;
      final radius = size.shortestSide * (0.10 + rng.nextDouble() * 0.13);
      final travel = (progress * progress) * dist * size.shortestSide;
      final pos = Offset(
        center.dx + math.cos(dir) * travel,
        center.dy + math.sin(dir) * travel - progress * size.height * 0.12,
      );
      final opacity = (1 - progress).clamp(0.05, 1.0);
      final coinRadius = radius * (0.4 + 0.6 * progress);
      canvas.drawCircle(
        pos,
        coinRadius,
        Paint()..color = const Color(0xffFFCC54).withValues(alpha: opacity),
      );
      canvas.drawCircle(
        pos,
        coinRadius,
        Paint()
          ..color = const Color(0xff8F5E18).withValues(alpha: opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6,
      );
    }
  }

  @override
  bool shouldRepaint(_WinOverlayPainter oldDelegate) =>
      oldDelegate.progress != progress;
}