import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../game/shared/playing_card.dart';
import 'learn_model.dart';

/// Renders the zones of a lesson scene on a game-coloured felt.
class SceneView extends StatelessWidget {
  const SceneView({super.key, required this.zones});
  final List<SceneZone> zones;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final most = zones.map((z) => z.cards.length).fold(0, max);
      // Long zones (a full TC hand) wrap into two even rows of larger cards.
      final widest = most > 6 ? (most / 2).ceil() : most;
      // Fit the widest zone on one line where possible, within sane bounds.
      final width = widest == 0
          ? 56.0
          : ((constraints.maxWidth - 8 * (widest - 1)) / widest).clamp(
              36.0,
              widest <= 4 ? 64.0 : 54.0,
            );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < zones.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            _Zone(zone: zones[i], cardWidth: width),
          ],
        ],
      );
    },
  );
}

class _Zone extends StatelessWidget {
  const _Zone({required this.zone, required this.cardWidth});
  final SceneZone zone;
  final double cardWidth;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        zone.label.toUpperCase(),
        style: TextStyle(
          color: T.white.withValues(alpha: .7),
          fontSize: 10,
          letterSpacing: 1.4,
          fontWeight: FontWeight.w800,
        ),
      ),
      if (zone.cards.isNotEmpty) ...[
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 10,
          children: [
            for (final c in zone.cards)
              _SceneCardView(card: c, width: cardWidth),
          ],
        ),
      ],
      if (zone.note != null) ...[
        const SizedBox(height: 6),
        Text(
          zone.note!,
          style: const TextStyle(
            color: T.ochre,
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ],
  );
}

class _SceneCardView extends StatelessWidget {
  const _SceneCardView({required this.card, required this.width});
  final SceneCard card;
  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width + 10,
    child: Column(
      children: [
        Opacity(
          opacity: card.dim ? .38 : 1,
          child: Container(
            decoration: card.glow
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(width * .12),
                    boxShadow: [
                      BoxShadow(
                        color: T.ochre.withValues(alpha: .75),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  )
                : null,
            child: PlayingCard(
              card: card.card,
              faceDown: card.faceDown,
              width: width,
              selected: card.glow,
            ),
          ),
        ),
        if (card.caption != null) ...[
          const SizedBox(height: 4),
          Text(
            card.caption!,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: T.white.withValues(alpha: .85),
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              height: 1.2,
            ),
          ),
        ],
      ],
    ),
  );
}

/// Coloured panel holding a step's header and scene.
class _Felt extends StatelessWidget {
  const _Felt({required this.color, required this.children});
  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

Widget _eyebrow(String text, IconData icon) => Row(
  children: [
    Icon(icon, size: 14, color: T.white.withValues(alpha: .7)),
    const SizedBox(width: 6),
    Text(
      text,
      style: TextStyle(
        color: T.white.withValues(alpha: .7),
        fontSize: 10,
        letterSpacing: 1.6,
        fontWeight: FontWeight.w800,
      ),
    ),
  ],
);

Widget _title(String text) => Padding(
  padding: const EdgeInsets.only(top: 10),
  child: Text(
    text,
    style: const TextStyle(
      color: T.white,
      fontSize: 23,
      fontWeight: FontWeight.w800,
      height: 1.15,
    ),
  ),
);

/// Result message under a quiz or move.
class FeedbackBox extends StatelessWidget {
  const FeedbackBox({super.key, required this.good, required this.message});
  final bool good;
  final String message;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (good ? T.mint : T.danger).withValues(alpha: .12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (good ? T.mint : T.danger).withValues(alpha: .55),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            good ? Icons.check_circle : Icons.lightbulb_outline,
            color: good ? T.mint : T.ochre,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: const TextStyle(height: 1.45))),
        ],
      ),
    ),
  );
}

/// Shows any lesson step. [onResolved] fires once, when the step is solved;
/// `firstTry` is false if the player needed more than one attempt.
class StepView extends StatelessWidget {
  const StepView({
    super.key,
    required this.step,
    required this.color,
    required this.onResolved,
  });
  final LessonStep step;
  final Color color;
  final void Function(bool firstTry) onResolved;

  @override
  Widget build(BuildContext context) => switch (step) {
    final ExplainStep s => _ExplainView(step: s, color: color),
    final QuizStep s => _QuizView(
      step: s,
      color: color,
      onResolved: onResolved,
    ),
    final TapStep s => _TapView(step: s, color: color, onResolved: onResolved),
  };
}

class _ExplainView extends StatelessWidget {
  const _ExplainView({required this.step, required this.color});
  final ExplainStep step;
  final Color color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Felt(
        color: color,
        children: [
          _eyebrow('LEARN', Icons.menu_book_outlined),
          _title(step.title),
          const SizedBox(height: 12),
          Text(
            step.body,
            style: const TextStyle(color: T.white, height: 1.5, fontSize: 15),
          ),
          if (step.bullets.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final b in step.bullets)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 6, right: 10),
                      child: Icon(Icons.circle, size: 6, color: T.ochre),
                    ),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(color: T.white, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
          ],
          if (step.scene.isNotEmpty) ...[
            const SizedBox(height: 18),
            SceneView(zones: step.scene),
          ],
        ],
      ),
      if (step.tip != null)
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: T.ochre.withValues(alpha: .1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: T.ochre.withValues(alpha: .4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.tips_and_updates_outlined,
                color: T.ochre,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(step.tip!, style: const TextStyle(height: 1.45)),
              ),
            ],
          ),
        ),
    ],
  );
}

class _QuizView extends StatefulWidget {
  const _QuizView({
    required this.step,
    required this.color,
    required this.onResolved,
  });
  final QuizStep step;
  final Color color;
  final void Function(bool firstTry) onResolved;

  @override
  State<_QuizView> createState() => _QuizViewState();
}

class _QuizViewState extends State<_QuizView> {
  late final List<int> order;
  final wrong = <int>{};
  bool solved = false;

  @override
  void initState() {
    super.initState();
    order = List.generate(widget.step.options.length, (i) => i);
    if (widget.step.shuffle) order.shuffle(Random());
  }

  void pick(int option) {
    if (solved || wrong.contains(option)) return;
    setState(() {
      if (option == widget.step.correct) {
        solved = true;
      } else {
        wrong.add(option);
      }
    });
    if (solved) widget.onResolved(wrong.isEmpty);
  }

  @override
  Widget build(BuildContext context) {
    final step = widget.step;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Felt(
          color: widget.color,
          children: [
            _eyebrow('QUIZ', Icons.quiz_outlined),
            if (step.title != null) _title(step.title!),
            if (step.scene.isNotEmpty) ...[
              const SizedBox(height: 16),
              SceneView(zones: step.scene),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Text(step.question, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (final i in order)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                backgroundColor: solved && i == step.correct
                    ? T.mint.withValues(alpha: .18)
                    : wrong.contains(i)
                    ? T.danger.withValues(alpha: .1)
                    : T.surface,
                side: BorderSide(
                  color: solved && i == step.correct
                      ? T.mint
                      : wrong.contains(i)
                      ? T.danger.withValues(alpha: .6)
                      : T.outline,
                ),
              ),
              onPressed: () => pick(i),
              child: Row(
                children: [
                  Icon(
                    solved && i == step.correct
                        ? Icons.check_circle
                        : wrong.contains(i)
                        ? Icons.close
                        : Icons.radio_button_unchecked,
                    size: 20,
                    color: solved && i == step.correct
                        ? T.mint
                        : wrong.contains(i)
                        ? T.danger
                        : T.muted,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step.options[i],
                      style: TextStyle(
                        color: wrong.contains(i) ? T.muted : T.ink,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (solved)
          FeedbackBox(
            good: true,
            message: '${wrong.isEmpty ? 'Correct! ' : ''}${step.explanation}',
          )
        else if (wrong.isNotEmpty)
          FeedbackBox(
            good: false,
            message:
                'Not quite. ${step.hint ?? 'Have another look and try again.'}',
          ),
      ],
    );
  }
}

class _TapView extends StatefulWidget {
  const _TapView({
    required this.step,
    required this.color,
    required this.onResolved,
  });
  final TapStep step;
  final Color color;
  final void Function(bool firstTry) onResolved;

  @override
  State<_TapView> createState() => _TapViewState();
}

class _TapViewState extends State<_TapView> {
  final selected = <String>{};
  int attempts = 0;
  bool solved = false, revealed = false;
  String? message;

  TapStep get step => widget.step;

  void toggle(String card) {
    if (solved) return;
    setState(() {
      message = null;
      if (selected.remove(card)) return;
      if (step.maxPick == 1) selected.clear();
      if (selected.length < step.maxPick) selected.add(card);
    });
  }

  void check() {
    if (step.accepts(selected)) {
      setState(() => solved = true);
      widget.onResolved(attempts == 0);
    } else {
      setState(() {
        attempts++;
        message = step.feedback?.call(selected) ?? 'Not quite. Try again.';
      });
    }
  }

  void reveal() {
    setState(() {
      selected
        ..clear()
        ..addAll(step.solution);
      solved = revealed = true;
    });
    widget.onResolved(false);
  }

  @override
  Widget build(BuildContext context) {
    final canCheck =
        !solved &&
        selected.length >= step.minPick &&
        selected.length <= step.maxPick;
    final width = MediaQuery.sizeOf(context).width;
    final cardWidth = step.hand.length > 6
        ? ((width - 40 - 8 * 5) / 6).clamp(40.0, 58.0)
        : 62.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Felt(
          color: widget.color,
          children: [
            _eyebrow('YOUR MOVE', Icons.touch_app_outlined),
            if (step.title != null) _title(step.title!),
            if (step.scene.isNotEmpty) ...[
              const SizedBox(height: 16),
              SceneView(zones: step.scene),
            ],
          ],
        ),
        const SizedBox(height: 18),
        Text(
          step.prompt,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 14),
        Text(
          step.handLabel.toUpperCase(),
          style: const TextStyle(
            color: T.coral,
            fontSize: 10,
            letterSpacing: 1.6,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 12,
          children: [
            for (final card in step.hand)
              AnimatedSlide(
                offset: selected.contains(card)
                    ? const Offset(0, -.08)
                    : Offset.zero,
                duration: T.micro,
                child: PlayingCard(
                  card: card,
                  width: cardWidth,
                  selected: selected.contains(card),
                  available: !solved || selected.contains(card),
                  onTap: () => toggle(card),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (!solved)
          Row(
            children: [
              Expanded(
                child: TaashButton(
                  label: step.maxPick > 1
                      ? 'Check (${selected.length} selected)'
                      : 'Check my move',
                  icon: Icons.check,
                  onPressed: canCheck ? check : null,
                ),
              ),
              if (attempts >= 2) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: TaashButton(
                    label: 'Show me',
                    icon: Icons.visibility_outlined,
                    secondary: true,
                    onPressed: reveal,
                  ),
                ),
              ],
            ],
          ),
        if (solved)
          FeedbackBox(
            good: true,
            message: revealed
                ? 'Here is one good answer. ${step.explanation}'
                : '${attempts == 0 ? 'Great move! ' : 'Got it! '}${step.explanation}',
          )
        else if (message != null)
          FeedbackBox(good: false, message: message!),
      ],
    );
  }
}
