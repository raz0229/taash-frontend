part of 'game_screen.dart';

/// Action availability is advisory; commands always go to the server.
mixin _GameActions on State<GameScreen> {
  HandOrder get hand;
  bool allowed(String card);
  Future<void> play([String? card]);
  Future<void> send(String command, {Map<String, dynamic>? payload});
  Widget _actions(RoomSnapshot s, bool enabled) {
    final compact =
        MediaQuery.sizeOf(context).height < 720 &&
        MediaQuery.textScalerOf(context).scale(1) <= 1.4;
    final selected = hand.selected;
    final state = s.gameState;
    final buttons = <Widget>[];
    void button(
      String label,
      VoidCallback action, {
      bool allowed = true,
      bool secondary = false,
    }) => buttons.add(
      TaashButton(
        label: label,
        onPressed: enabled && allowed ? action : null,
        secondary: secondary,
        onDark: true,
        compact: compact,
      ),
    );
    if (state is BhabhiState || state is DaketiState) {
      button(
        Copy.playCard,
        () => play(),
        allowed: selected.length == 1 && allowed(selected.single),
      );
    }
    if (state is BluffState) {
      button(
        Copy.playCards(selected.length),
        () => play(),
        allowed: HandGuidance.bluffSelectionAllowed(
          selected.length,
          emptyPile: state.pileCount == 0,
        ),
      );
      button(
        Copy.challenge,
        () => send('bluff.challenge'),
        allowed: state.lastPlayCount > 0 && state.lastPlayerId != s.you.id,
        secondary: true,
      );
      button(Copy.pass, () => send('bluff.pass'), secondary: true);
    }
    if (state is TcState) {
      if (s.you.hand.length == 10) {
        if (state.stockCount == 0) {
          button(
            Copy.recycle,
            () => send('tc.recycle_discard'),
            allowed: state.discardCount > 0,
            secondary: true,
          );
        }
      } else {
        button(
          Copy.discard,
          () => play(),
          allowed: selected.length == 1 && allowed(selected.single),
        );
      }
      button(
        Copy.claimVictory,
        () async {
          if (await confirmAction(
                context,
                title: Copy.claimYour433,
                message: GameCopy.tcClaim,
                confirmLabel: Copy.checkMyHand,
              ) &&
              mounted) {
            await send('tc.claim_victory');
          }
        },
        allowed: HandGuidance.tcMayClaim(s.you.hand.length),
        secondary: true,
      );
    }
    if (compact && buttons.length <= 3) {
      return Row(
        children: [
          for (var i = 0; i < buttons.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: buttons[i]),
          ],
        ],
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: buttons,
    );
  }
}
