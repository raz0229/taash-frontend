import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import 'learn_model.dart';
import 'learn_progress.dart';
import 'learn_widgets.dart';

/// Steps through one lesson, then offers the next one in the course.
class LessonPlayerScreen extends StatefulWidget {
  const LessonPlayerScreen({
    super.key,
    required this.lessons,
    required this.index,
    required this.color,
  });

  /// The whole course, so the finish screen can continue to the next lesson.
  final List<Lesson> lessons;
  final int index;
  final Color color;

  @override
  State<LessonPlayerScreen> createState() => _LessonPlayerScreenState();
}

class _LessonPlayerScreenState extends State<LessonPlayerScreen> {
  late final List<LessonStep> steps = lesson.build(Random());
  final resolved = <int>{};
  int at = 0, firstTry = 0, questions = 0;
  bool finished = false;

  Lesson get lesson => widget.lessons[widget.index];
  Lesson? get next => widget.index + 1 < widget.lessons.length
      ? widget.lessons[widget.index + 1]
      : null;

  bool get ready => steps[at] is ExplainStep || resolved.contains(at);

  void advance() {
    if (at + 1 < steps.length) {
      setState(() => at++);
    } else {
      LearnProgress.instance.complete(lesson.id);
      setState(() => finished = true);
    }
  }

  void openNext() => Navigator.pushReplacement(
    context,
    MaterialPageRoute(
      builder: (_) => LessonPlayerScreen(
        lessons: widget.lessons,
        index: widget.index + 1,
        color: widget.color,
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(lesson.title),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: LinearProgressIndicator(
          value: finished ? 1 : (at + (ready ? 1 : 0)) / steps.length,
          minHeight: 4,
          color: T.ochre,
          backgroundColor: T.surface,
        ),
      ),
    ),
    body: SafeArea(child: finished ? _finish(context) : _stepBody(context)),
  );

  Widget _stepBody(BuildContext context) => Column(
    children: [
      Expanded(
        child: ListView(
          key: ValueKey(at),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          children: [
            Text(
              'STEP ${at + 1} OF ${steps.length}',
              style: const TextStyle(
                color: T.muted,
                fontSize: 10,
                letterSpacing: 1.6,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            StepView(
              step: steps[at],
              color: widget.color,
              onResolved: (first) => setState(() {
                if (resolved.add(at)) {
                  questions++;
                  if (first) firstTry++;
                }
              }),
            ),
          ],
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
        child: Row(
          children: [
            if (at > 0) ...[
              Expanded(
                child: TaashButton(
                  label: 'Back',
                  secondary: true,
                  onPressed: () => setState(() => at--),
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              flex: 2,
              child: TaashButton(
                label: at + 1 == steps.length ? 'Finish lesson' : 'Continue',
                icon: Icons.arrow_forward,
                onPressed: ready ? advance : null,
              ),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _finish(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 24),
      Center(
        child: Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: widget.color,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.emoji_events, color: T.white, size: 48),
        ),
      ),
      const SizedBox(height: 22),
      Text(
        'Lesson complete!',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      const SizedBox(height: 10),
      Text(
        questions == 0
            ? lesson.title
            : '$firstTry of $questions answered right on the first try.',
        textAlign: TextAlign.center,
        style: const TextStyle(color: T.muted),
      ),
      const SizedBox(height: 28),
      if (next != null) ...[
        TaashPanel(
          child: Row(
            children: [
              Icon(next!.icon, color: T.ochre),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'UP NEXT',
                      style: TextStyle(
                        color: T.coral,
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      next!.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(next!.summary, style: const TextStyle(color: T.muted)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TaashButton(
          label: 'Next lesson',
          icon: Icons.arrow_forward,
          onPressed: openNext,
        ),
        const SizedBox(height: 10),
      ],
      TaashButton(
        label: 'Back to lessons',
        secondary: next != null,
        onPressed: () => Navigator.pop(context),
      ),
    ],
  );
}

/// Endless practice: every round is a freshly generated scenario.
class PracticeScreen extends StatefulWidget {
  const PracticeScreen({
    super.key,
    required this.id,
    required this.title,
    required this.drills,
    required this.color,
  });
  final String id, title;
  final List<Drill> drills;
  final Color color;

  @override
  State<PracticeScreen> createState() => _PracticeScreenState();
}

class _PracticeScreenState extends State<PracticeScreen> {
  final rng = Random();
  late Drill drill;
  late LessonStep step;
  int round = 0, streak = 0, correct = 0, played = 0;
  bool resolved = false;

  @override
  void initState() {
    super.initState();
    _roll();
  }

  void _roll() {
    drill = widget.drills[rng.nextInt(widget.drills.length)];
    step = drill.make(rng);
    resolved = false;
    round++;
  }

  void onResolved(bool firstTry) {
    setState(() {
      resolved = true;
      played++;
      if (firstTry) {
        correct++;
        streak++;
        LearnProgress.instance.recordStreak(widget.id, streak);
      } else {
        streak = 0;
      }
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                _Stat(
                  icon: Icons.local_fire_department,
                  label: 'Streak',
                  value: '$streak',
                ),
                const SizedBox(width: 8),
                _Stat(
                  icon: Icons.military_tech_outlined,
                  label: 'Best',
                  value:
                      '${max(streak, LearnProgress.instance.bestStreak(widget.id))}',
                ),
                const SizedBox(width: 8),
                _Stat(
                  icon: Icons.check,
                  label: 'First try',
                  value: '$correct/$played',
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              key: ValueKey(round),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              children: [
                if (widget.drills.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      drill.title.toUpperCase(),
                      style: const TextStyle(
                        color: T.muted,
                        fontSize: 10,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                StepView(
                  step: step,
                  color: widget.color,
                  onResolved: onResolved,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
            child: TaashButton(
              label: 'Next challenge',
              icon: Icons.shuffle,
              onPressed: resolved ? () => setState(_roll) : null,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label, value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: T.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: T.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: T.ochre),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: T.muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
