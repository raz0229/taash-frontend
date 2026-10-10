import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../home/game_art.dart';
import 'courses/basics_course.dart';
import 'courses/bhabhi_course.dart';
import 'courses/bluff_course.dart';
import 'courses/daketi_course.dart';
import 'courses/tc_course.dart';
import 'learn_drills.dart';
import 'learn_model.dart';
import 'learn_progress.dart';
import 'lesson_player.dart';

final courses = {
  GameType.bhabhi: bhabhiCourse,
  GameType.bluff: bluffCourse,
  GameType.daketi: daketiCourse,
  GameType.tc: tcCourse,
};

const _basicsColor = Color(0xff5B4A86);

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, this.initialGame = GameType.bhabhi});
  final GameType initialGame;
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  late GameType game = widget.initialGame;
  final progress = LearnProgress.instance;

  @override
  void initState() {
    super.initState();
    progress.load();
  }

  void openLesson(List<Lesson> lessons, int index, Color color) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              LessonPlayerScreen(lessons: lessons, index: index, color: color),
        ),
      );

  void openPractice(String id, String title, List<Drill> drills, Color color) =>
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PracticeScreen(
            id: id,
            title: title,
            drills: drills,
            color: color,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: progress,
    builder: (context, _) {
      final course = courses[game]!;
      final color = gameColor(game);
      final basicsDone = progress.doneCount(basicsLessons.map((l) => l.id));
      return ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const TaashSectionHeader(
            eyebrow: Copy.learnATYOURPACE,
            title: Copy.fromFirstCardToOneMoreRound,
            subtitle:
                'Step-by-step lessons, guided hands and practice that is never the same twice.',
          ),
          const SizedBox(height: 20),
          _sectionLabel('Start here'),
          for (var i = 0; i < basicsLessons.length; i++)
            _LessonTile(
              lesson: basicsLessons[i],
              number: i + 1,
              done: progress.isDone(basicsLessons[i].id),
              color: _basicsColor,
              onTap: () => openLesson(basicsLessons, i, _basicsColor),
            ),
          if (basicsDone == basicsLessons.length)
            _PracticeTile(
              title: 'Card names practice',
              subtitle: 'Names and ranks, endlessly shuffled.',
              icon: Icons.style_outlined,
              best: progress.bestStreak('basics.mix'),
              onTap: () => openPractice(
                'basics.mix',
                'Card basics',
                basicsDrills,
                _basicsColor,
              ),
            ),
          const SizedBox(height: 18),
          _sectionLabel('Choose a game'),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final g in lobbyGames)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(g == GameType.tc ? Copy.tc : g.label),
                      selected: g == game,
                      onSelected: (_) => setState(() => game = g),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CourseHero(
            course: course,
            color: color,
            done: progress.doneCount(course.lessons.map((l) => l.id)),
            onContinue: () {
              final next = course.lessons.indexWhere(
                (l) => !progress.isDone(l.id),
              );
              openLesson(course.lessons, next < 0 ? 0 : next, color);
            },
          ),
          const SizedBox(height: 22),
          _sectionLabel('Lessons'),
          for (var i = 0; i < course.lessons.length; i++)
            _LessonTile(
              lesson: course.lessons[i],
              number: i + 1,
              done: progress.isDone(course.lessons[i].id),
              color: color,
              onTap: () => openLesson(course.lessons, i, color),
            ),
          const SizedBox(height: 18),
          _sectionLabel('Practice · never the same twice'),
          _PracticeTile(
            title: 'Mixed practice',
            subtitle:
                'Every ${game == GameType.tc ? 'Tissar Chausar' : game.label} drill, shuffled together.',
            icon: Icons.shuffle,
            best: progress.bestStreak('${game.name}.mix'),
            highlight: color,
            onTap: () => openPractice(
              '${game.name}.mix',
              '${game.label} practice',
              course.drills,
              color,
            ),
          ),
          for (final drill in course.drills)
            _PracticeTile(
              title: drill.title,
              subtitle: drill.subtitle,
              icon: drill.icon,
              best: progress.bestStreak(drill.id),
              onTap: () => openPractice(drill.id, drill.title, [drill], color),
            ),
          const SizedBox(height: 18),
          _sectionLabel('Rules at a glance'),
          TaashPanel(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
            child: Column(
              children: [
                for (final (heading, detail) in course.cheatSheet)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 96,
                          child: Text(
                            heading,
                            style: const TextStyle(
                              color: T.ochre,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            detail,
                            style: const TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            Copy.thisIsALearningExerciseItDoes,
            textAlign: TextAlign.center,
            style: TextStyle(color: T.muted, fontSize: 12),
          ),
          const SizedBox(height: 20),
        ],
      );
    },
  );

  Widget _sectionLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: T.coral,
        fontSize: 11,
        letterSpacing: 2,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _CourseHero extends StatelessWidget {
  const _CourseHero({
    required this.course,
    required this.color,
    required this.done,
    required this.onContinue,
  });
  final Course course;
  final Color color;
  final int done;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final total = course.lessons.length;
    final label = done == 0
        ? 'Start learning'
        : done >= total
        ? 'Review from the start'
        : 'Continue';
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  course.game.label,
                  style: const TextStyle(
                    color: T.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: .18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  course.players,
                  style: const TextStyle(
                    color: T.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            course.goal,
            style: const TextStyle(color: T.white, height: 1.45),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: total == 0 ? 0 : done / total,
              minHeight: 8,
              color: T.ochre,
              backgroundColor: Colors.black.withValues(alpha: .2),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$done of $total lessons complete',
            style: TextStyle(
              color: T.white.withValues(alpha: .8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          TaashButton(
            label: label,
            icon: Icons.play_arrow_rounded,
            onDark: true,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _LessonTile extends StatelessWidget {
  const _LessonTile({
    required this.lesson,
    required this.number,
    required this.done,
    required this.color,
    required this.onTap,
  });
  final Lesson lesson;
  final int number;
  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: T.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: lesson.guided ? color.withValues(alpha: .8) : T.outline,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: done ? T.mint : color.withValues(alpha: .9),
                  shape: BoxShape.circle,
                ),
                child: done
                    ? const Icon(Icons.check, color: Color(0xff1B2A3A))
                    : Text(
                        '$number',
                        style: const TextStyle(
                          color: T.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          lesson.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (lesson.guided)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: T.ochre,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Text(
                              'INTERACTIVE',
                              style: TextStyle(
                                color: Color(0xff2A193A),
                                fontSize: 9,
                                letterSpacing: 1,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lesson.summary,
                      style: const TextStyle(color: T.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(lesson.icon, color: T.muted, size: 22),
            ],
          ),
        ),
      ),
    ),
  );
}

class _PracticeTile extends StatelessWidget {
  const _PracticeTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.best,
    required this.onTap,
    this.highlight,
  });
  final String title, subtitle;
  final IconData icon;
  final int best;
  final VoidCallback onTap;
  final Color? highlight;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: highlight?.withValues(alpha: .22) ?? T.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: highlight ?? T.outline),
          ),
          child: Row(
            children: [
              Icon(icon, color: T.ochre),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(color: T.muted, fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (best > 0) ...[
                const SizedBox(width: 8),
                Column(
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: T.ochre,
                      size: 18,
                    ),
                    Text(
                      '$best',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, color: T.muted),
            ],
          ),
        ),
      ),
    ),
  );
}
