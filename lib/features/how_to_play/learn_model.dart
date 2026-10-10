import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/models/models.dart';

/// One card drawn inside a lesson scene.
class SceneCard {
  const SceneCard(
    this.card, {
    this.caption,
    this.glow = false,
    this.dim = false,
    this.faceDown = false,
  });

  /// A face-down card with an optional caption (stock, hidden pile...).
  const SceneCard.back({this.caption})
    : card = null,
      glow = false,
      dim = false,
      faceDown = true;

  final String? card;
  final String? caption;
  final bool glow, dim, faceDown;
}

/// A labelled row of cards: a trick, the table, a collection, the stock.
class SceneZone {
  const SceneZone(this.label, this.cards, {this.note});

  SceneZone.of(
    this.label,
    List<String> ids, {
    this.note,
    Set<String> glow = const {},
    Set<String> dim = const {},
  }) : cards = [
         for (final id in ids)
           SceneCard(id, glow: glow.contains(id), dim: dim.contains(id)),
       ];

  final String label;
  final List<SceneCard> cards;
  final String? note;
}

/// A single screen inside a lesson.
sealed class LessonStep {
  const LessonStep();
}

/// Reading step: an idea, optionally illustrated with a scene.
class ExplainStep extends LessonStep {
  const ExplainStep({
    required this.title,
    required this.body,
    this.bullets = const [],
    this.scene = const [],
    this.tip,
  });
  final String title, body;
  final List<String> bullets;
  final List<SceneZone> scene;
  final String? tip;
}

/// Multiple choice question about a scene.
class QuizStep extends LessonStep {
  const QuizStep({
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
    this.title,
    this.scene = const [],
    this.hint,
    this.shuffle = true,
  });
  final String? title, hint;
  final String question, explanation;
  final List<SceneZone> scene;
  final List<String> options;
  final int correct;

  /// Yes/no style options read better in a fixed order.
  final bool shuffle;
}

/// Interactive step: pick card(s) from a hand to make a move.
class TapStep extends LessonStep {
  const TapStep({
    required this.prompt,
    required this.hand,
    required this.accepts,
    required this.solution,
    required this.explanation,
    this.title,
    this.scene = const [],
    this.minPick = 1,
    this.maxPick = 1,
    this.feedback,
    this.handLabel = 'Your hand',
  });

  /// Exactly [answer] must be selected.
  factory TapStep.exact({
    required String prompt,
    required List<String> hand,
    required Set<String> answer,
    required String explanation,
    String? title,
    List<SceneZone> scene = const [],
    String? Function(Set<String>)? feedback,
    String handLabel = 'Your hand',
  }) => TapStep(
    title: title,
    prompt: prompt,
    hand: hand,
    scene: scene,
    minPick: 1,
    maxPick: answer.length == 1 ? 1 : hand.length,
    accepts: (picked) =>
        picked.length == answer.length && picked.containsAll(answer),
    solution: answer,
    explanation: explanation,
    feedback: feedback,
    handLabel: handLabel,
  );

  final String? title;
  final String prompt, explanation, handLabel;
  final List<SceneZone> scene;
  final List<String> hand;
  final int minPick, maxPick;
  final bool Function(Set<String> picked) accepts;

  /// One correct answer, revealed when the player asks for help.
  final Set<String> solution;

  /// Optional targeted message for a wrong selection.
  final String? Function(Set<String> picked)? feedback;
}

typedef DrillMaker = LessonStep Function(Random rng);

/// An endlessly repeatable exercise that generates a fresh scenario each time.
class Drill {
  const Drill({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.make,
  });
  final String id, title, subtitle;
  final IconData icon;
  final DrillMaker make;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.icon,
    required this.build,
    this.guided = false,
  });
  final String id, title, summary;
  final IconData icon;

  /// Built fresh each time the lesson opens so practice rounds vary.
  final List<LessonStep> Function(Random rng) build;

  /// Guided tutorials walk through a scripted hand move by move.
  final bool guided;
}

class Course {
  const Course({
    required this.game,
    required this.goal,
    required this.players,
    required this.lessons,
    required this.drills,
    required this.cheatSheet,
  });
  final GameType game;
  final String goal, players;
  final List<Lesson> lessons;
  final List<Drill> drills;

  /// Short rule reminders: (heading, detail).
  final List<(String, String)> cheatSheet;
}
