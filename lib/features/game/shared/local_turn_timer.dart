import 'package:taash/l10n/copy.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/taash_theme.dart';
import '../game_copy.dart';

/// Explicitly a local guide: never suggests the server enforces a deadline.
class LocalTurnTimer extends StatefulWidget {
  const LocalTurnTimer({
    super.key,
    required this.turnKey,
    required this.active,
    required this.mine,
    required this.seconds,
    required this.onExpired,
    required this.accent,
    this.paused = false,
  });
  final String turnKey;
  final bool active, mine;
  final int seconds;
  final bool paused;
  final Color accent;
  final VoidCallback onExpired;
  @override
  State<LocalTurnTimer> createState() => _LocalTurnTimerState();
}

class _LocalTurnTimerState extends State<LocalTurnTimer>
    with WidgetsBindingObserver {
  Timer? _timer;
  final Stopwatch _watch = Stopwatch();
  int _remaining = 0;
  bool _fired = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _start();
  }

  @override
  void didUpdateWidget(LocalTurnTimer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.turnKey != widget.turnKey ||
        oldWidget.active != widget.active) {
      _start();
    } else if (oldWidget.paused != widget.paused) {
      if (widget.paused) {
        _pause();
      } else {
        _resume();
      }
    }
  }

  void _start() {
    _timer?.cancel();
    _watch
      ..reset()
      ..stop();
    _remaining = widget.seconds;
    _fired = false;
    if (!widget.active || widget.paused) return;
    _run();
  }

  void _run() {
    if (_watch.isRunning) return;
    _watch.start();
    _tick();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) _tick();
    });
  }

  void _pause() {
    _timer?.cancel();
    _watch.stop();
  }

  void _resume() {
    if (!widget.active) return;
    _timer?.cancel();
    _remaining = (widget.seconds - _watch.elapsed.inSeconds).clamp(
      0,
      widget.seconds,
    );
    if (_remaining == 0) {
      _fired = true;
      if (widget.mine && widget.active) widget.onExpired();
      return;
    }
    _run();
  }

  void _tick() {
    setState(
      () => _remaining = (widget.seconds - _watch.elapsed.inSeconds).clamp(
        0,
        widget.seconds,
      ),
    );
    if (_remaining == 0) {
      _timer?.cancel();
      if (!_fired && widget.mine && widget.active) {
        _fired = true;
        widget.onExpired();
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(_start);
    } else {
      _pause();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: GameCopy.localTimerDetail,
    child: Semantics(
      label:
          '${GameCopy.localTimer}, ${widget.active ? _remaining : widget.seconds} seconds',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              value: widget.active ? _remaining / widget.seconds : 1,
              strokeWidth: 2,
              color: _remaining <= 10
                  ? Color.lerp(widget.accent, Colors.white, .45)!
                  : widget.accent,
              backgroundColor: Colors.white12,
            ),
          ),
          const SizedBox(width: 7),
          Text(
            widget.active
                ? '${_remaining ~/ 60}:${(_remaining % 60).toString().padLeft(2, '0')}'
                : Copy.paused,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 4),
          const Text('local', style: TextStyle(color: T.mint, fontSize: 10)),
        ],
      ),
    ),
  );
}
