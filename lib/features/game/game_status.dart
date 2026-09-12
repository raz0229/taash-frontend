part of 'game_screen.dart';

mixin _GameStatus on State<GameScreen> {
  RoomSession get session;
  String get notice;
  bool get leaving;
  void announce(String text);
  void dismissBanner();
  Future<void> leave({bool expired = false});
  Widget _banner(bool terminal) => Container(
    width: double.infinity,
    margin: const EdgeInsets.all(12),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: T.ochre,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Semantics(
      liveRegion: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  notice.isNotEmpty
                      ? notice
                      : session.error?.message ?? _connectionText(),
                  style: const TextStyle(
                    color: T.ink,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              IconButton(
                onPressed: dismissBanner,
                tooltip: 'Dismiss',
                icon: const Icon(Icons.close, size: 18),
                color: T.ink,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            ],
          ),
          if (!session.connected && !terminal)
            TextButton(
              onPressed: () => session.retryConnection(),
              child: const Text(Copy.retryConnection),
            ),
          if (terminal)
            TextButton(
              onPressed: () => leave(),
              child: const Text(Copy.returnToLobby),
            ),
        ],
      ),
    ),
  );
  String _connectionText() => switch (session.state) {
    RoomConnectionState.reconnecting => Copy.connectionLostCheckingYourSeat,
    RoomConnectionState.rejoining => GameCopy.rejoining,
    RoomConnectionState.offline => GameCopy.offline,
    RoomConnectionState.maintenance =>
      Copy.taashonlineIsTakingAMaintenanceBreak,
    RoomConnectionState.recovered => GameCopy.recovered,
    _ => GameCopy.syncing,
  };
  Widget _waiting(RoomSnapshot s) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const SizedBox(height: 15),
      // B7: Enhanced waiting room with animated dots and game badge.
      Center(
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [T.ochre.withValues(alpha: .2), Colors.transparent],
            ),
          ),
          child: const Icon(Icons.chair_alt_outlined, size: 52, color: T.ochre),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        GameCopy.waiting,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: T.white,
          fontSize: 29,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 8),
      // Game type badge.
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: T.coral.withValues(alpha: .15),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: T.coral.withValues(alpha: .3)),
          ),
          child: Text(
            s.room.game.label,
            style: const TextStyle(
              color: T.coral,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        s.room.name,
        textAlign: TextAlign.center,
        style: const TextStyle(color: T.mint),
      ),
      const SizedBox(height: 20),
      // Prominent room code card.
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xff1C3894), Color(0xff2E5BD8)],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xff70B7FF), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xff3163DB).withValues(alpha: .3),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text(
                'ROOM CODE',
                style: TextStyle(
                  color: T.mint,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 6),
              SelectableText(
                s.room.id,
                style: const TextStyle(
                  color: T.white,
                  fontSize: 34,
                  letterSpacing: 5,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Center(
        child: TextButton.icon(
          onPressed: () {
            Clipboard.setData(ClipboardData(text: s.room.id));
            announce(Copy.roomCodeCopied);
          },
          icon: const Icon(Icons.copy, size: 16),
          label: const Text(Copy.copyCode),
          style: TextButton.styleFrom(foregroundColor: T.ochre),
        ),
      ),
      const SizedBox(height: 14),
      // B7: Visual seat progress indicator.
      Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < s.room.maxPlayers; i++) ...[
              if (i > 0) const SizedBox(width: 6),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < s.players.length
                      ? T.ochre.withValues(alpha: .8)
                      : Colors.white12,
                  border: Border.all(
                    color: i < s.players.length ? T.ochre : Colors.white24,
                    width: 2,
                  ),
                ),
                child: i < s.players.length
                    ? const Icon(Icons.person, size: 14, color: T.ink)
                    : const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.white30,
                      ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text(
        '${s.players.length} of ${s.room.maxPlayers} seats filled',
        textAlign: TextAlign.center,
        style: const TextStyle(color: T.white, fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 10),
      Text(
        s.room.private ? GameCopy.privateWaiting : GameCopy.publicBots,
        textAlign: TextAlign.center,
        style: const TextStyle(color: T.mint),
      ),
      const SizedBox(height: 8),
      const Text(
        GameCopy.waitingDetail,
        textAlign: TextAlign.center,
        style: TextStyle(color: T.mint, fontSize: 12),
      ),
      const SizedBox(height: 24),
      if (s.players.length < s.room.maxPlayers)
        TweenAnimationBuilder<double>(
          key: const ValueKey('waiting_timer'),
          tween: Tween(begin: 60.0, end: 0.0),
          duration: const Duration(seconds: 80),
          builder: (context, value, _) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      value: value / 80.0,
                      strokeWidth: 2.5,
                      color: T.ochre,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${value.ceil()}s remaining',
                  style: const TextStyle(color: T.ochre, fontSize: 11),
                ),
              ],
            );
          },
        ),
      const SizedBox(height: 24),
      TaashButton(
        label: Copy.leaveRoom,
        onPressed: () => leave(),
        busy: leaving,
      ),
    ],
  );
  String _instruction(RoomSnapshot s) => switch (s.room.game) {
    GameType.bhabhi => 'choose a card',
    GameType.bluff =>
      (s.gameState as BluffState).pileCount == 0
          ? GameCopy.bluffOpening
          : GameCopy.bluffFollowing,
    GameType.daketi => 'draw or play a matching rank',
    GameType.tc =>
      s.you.hand.length == 10 ? GameCopy.tcDraw : GameCopy.tcDiscard,
  };
}
