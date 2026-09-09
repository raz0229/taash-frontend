import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import '../../core/models/models.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../game/shared/playing_card.dart';
import '../home/game_art.dart';

class Lesson {
  const Lesson(
    this.title,
    this.body,
    this.cards,
    this.question,
    this.answers,
    this.correct,
    this.explanation,
  );
  final String title, body, question, explanation;
  final List<String> cards, answers;
  final int correct;
}

const lessons = {
  GameType.bhabhi: [
    Lesson(
      Copy.leaveTheCardsBehind,
      Copy.finishYourHandBeforeTheLastPlayer,
      ['h-y', 'h-3', 'p-k'],
      Copy.whichCardOpensTheFirstTrick,
      [Copy.hukamYakka, Copy.anyKinga],
      0,
      Copy.hukamYakkaStartsTheFirstTrickThe,
    ),
    Lesson(
      Copy.followTheLead,
      Copy.whenYouHaveTheLeadSuitYou,
      ['e-3', 'e-g', 'p-k'],
      Copy.eitLeadsAndYouHoldEitWhat,
      ['A Pawn card', Copy.anEitCard],
      1,
      Copy.youMustFollowEitWhileYouHave,
    ),
    Lesson(
      Copy.watchTheThullu,
      Copy.theHighestLeadSuitPlayerPicksUp,
      ['e-3', 'e-g', 'p-k'],
      Copy.whoTakesThisOffSuitThullu,
      [Copy.theEitGolaPlayer, Copy.thePawnKingaPlayer],
      0,
      Copy.eitGolaIsHighestInTheLead,
    ),
  ],
  GameType.bluff: [
    Lesson(
      'A good poker face',
      Copy.finishYourCardsTheHYHolder,
      ['h-y', 'c-3'],
      Copy.howManyCardsOpenANewRound,
      ['1 card', '2–4 cards'],
      1,
      'A new round needs 2–4 cards. Only the claim and card count are public.',
    ),
    Lesson(
      Copy.keepTheStoryGoing,
      Copy.laterPlaysUse14CardsAnd,
      ['e-5', 'p-k'],
      Copy.canTheNextPlayerChangeAnActive,
      [Copy.noKeepTheDeclaredRank, Copy.yesEveryTurn],
      0,
      Copy.theRoundKeepsItsDeclaredRankUntil,
    ),
    Lesson(
      Copy.callItCarefully,
      Copy.ifTheLastPlayIsABluff,
      ['h-b', 'c-b'],
      Copy.isAnEmptyHandAnImmediateFinal,
      [Copy.always, Copy.itMayStillBeChallenged],
      1,
      Copy.waitForServerConfirmationACaughtProvisional,
    ),
  ],
  GameType.daketi: [
    Lesson(
      Copy.buildYourCollection,
      Copy.startWithFourCardsDrawFromStock,
      ['c-7', 'e-7', 'p-7'],
      Copy.whatMakesACapture,
      [Copy.matchingSuits, Copy.matchingRanks],
      1,
      'A seven can collect other sevens, whichever suit they have.',
    ),
    Lesson(
      Copy.keepAnEyeOnTheTops,
      'A rank matching your own collection top adds to it. A successful capture keeps your turn while stock remains. Once stock is empty, play advances after every card.',
      ['h-g', 'p-g', 'e-g'],
      Copy.stockIsEmptyDoesACaptureKeep,
      [Copy.noPlayAdvances, Copy.yes],
      0,
      Copy.afterStockRunsOutEveryPlayedCard,
    ),
    Lesson(
      Copy.makeEveryCardCount,
      Copy.yourFinalCollectionDecidesYourPointsYakka,
      ['h-y', 'h-k', 'h-7'],
      Copy.howManyPointsIsYakkaWorth,
      ['20 points', '5 points'],
      0,
      Copy.yakkaIsWorth20PointsWatchExposed,
    ),
  ],
  GameType.tc: [
    Lesson(
      Copy.find433,
      Copy.buildOneGroupOfFourAndTwo,
      ['p-3', 'p-4', 'p-5'],
      Copy.isThisAValidTypeOfGroup,
      ['A same-suit run', Copy.anUnrelatedTrio],
      0,
      Copy.pawn345IsASame,
    ),
    Lesson(
      Copy.meetYourYarak,
      Copy.yarakIsTheRankImmediatelyAfterThe,
      ['h-k', 'p-y', 'c-y'],
      Copy.ifTheIndicatorIsKingaWhichRank,
      [Copy.yakka2, Copy.gola],
      0,
      Copy.yakkaFollowsKingaEveryYakkaBecomesA,
    ),
    Lesson(
      Copy.drawArrangeDiscard,
      Copy.drawStockOrTakeTheTopDiscard,
      ['p-6', 'p-7', 'p-8'],
      Copy.canYouImmediatelyReturnThePickedDiscard,
      [Copy.noChooseAnotherCard, Copy.yes],
      0,
      Copy.pickAnotherCardToDiscardTheServer,
    ),
  ],
};

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  GameType game = GameType.bhabhi;
  int step = 0;
  int? answer;
  String? selected;
  @override
  Widget build(BuildContext context) {
    final lesson = lessons[game]![step];
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const TaashSectionHeader(
          eyebrow: Copy.learnATYOURPACE,
          title: Copy.fromFirstCardToOneMoreRound,
          subtitle: 'A little practice. A lot more confidence.',
        ),
        const SizedBox(height: 22),
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
                    onSelected: (_) => setState(() {
                      game = g;
                      step = 0;
                      answer = null;
                      selected = null;
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: gameColor(game),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                Copy.practiceSTEPOF3(step + 1),
                style: TextStyle(
                  color: T.white.withValues(alpha: .65),
                  fontSize: 10,
                  letterSpacing: 1.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                lesson.title,
                style: const TextStyle(
                  color: T.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 13),
              Text(
                lesson.body,
                style: const TextStyle(color: T.white, height: 1.5),
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 14,
                runSpacing: 14,
                alignment: WrapAlignment.center,
                children: lesson.cards
                    .map(
                      (card) => PlayingCard(
                        card: card,
                        width: 70,
                        selected: selected == card,
                        onTap: () => setState(
                          () => selected = selected == card ? null : card,
                        ),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              Text(
                selected == null
                    ? Copy.tapACardToLearnItsName
                    : _cardName(selected!),
                style: const TextStyle(
                  color: T.ochre,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),
        Text(lesson.question, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        for (var i = 0; i < lesson.answers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: answer == i
                    ? (i == lesson.correct
                          ? T.mint
                          : T.ochre.withValues(alpha: .25))
                    : T.surface,
              ),
              onPressed: () => setState(() => answer = i),
              child: Row(
                children: [
                  Icon(
                    answer == i
                        ? (i == lesson.correct
                              ? Icons.check_circle
                              : Icons.refresh)
                        : Icons.radio_button_unchecked,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(lesson.answers[i])),
                ],
              ),
            ),
          ),
        if (answer != null)
          Semantics(
            liveRegion: true,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                answer == lesson.correct
                    ? lesson.explanation
                    : Copy.tryAgain2(lesson.explanation),
                style: const TextStyle(color: T.muted),
              ),
            ),
          ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
              child: TaashButton(
                label: Copy.previous,
                secondary: true,
                onPressed: step > 0
                    ? () => setState(() {
                        step--;
                        answer = null;
                        selected = null;
                      })
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TaashButton(
                label: step == 2 ? Copy.practiceAgain : Copy.nextStep,
                icon: Icons.arrow_forward,
                onPressed: () => setState(() {
                  step = (step + 1) % 3;
                  answer = null;
                  selected = null;
                }),
              ),
            ),
          ],
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
  }

  String _cardName(String id) {
    final parts = id.split('-');
    return '${const {'h': 'Hukam', 'c': 'Chirri', 'e': 'Eit', 'p': 'Pawn'}[parts[0]]} ${const {'y': 'Yakka', 'k': 'Kinga', 'b': 'Begi', 'g': 'Gola'}[parts[1]] ?? parts[1]}';
  }
}
