part of 'game_screen.dart';

/// Room social and preference sheets are separate from the room composition.
mixin _GameMenus on State<GameScreen> {
  RoomSession get session;
  bool get muted;
  set muted(bool value);
  bool get chatOpen;
  set chatOpen(bool value);
  int get readCount;
  set readCount(int value);
  void announce(String text);
  Future<void> send(String command, {Map<String, dynamic>? payload});
  Future<void> leave({bool expired = false});
  Future<void> openChat() async {
    setState(() {
      chatOpen = true;
      readCount = session.chat.length;
    });
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ChatSheet(
        session: session,
        muted: muted,
        onMuteChanged: (v) => setState(() => muted = v),
      ),
    );
    if (mounted) {
      setState(() {
        chatOpen = false;
        readCount = session.chat.length;
      });
    }
  }

  Future<void> playerMenu(PublicPlayer p) async {
    await showTaashSheet<void>(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              TaashAvatar(id: p.selectedPfp),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  p.id == session.playerId ? Copy.you : p.displayName,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (!p.isBot)
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text(Copy.playerStatistics),
              onTap: () {
                Navigator.pop(context);
                widget.onPlayerProfile?.call(p.id);
              },
            ),
          if (p.isBot)
            const ListTile(
              leading: Icon(Icons.smart_toy_outlined),
              title: Text(Copy.botPlayer),
              subtitle: Text(Copy.botsPlayByTheSameGameRules),
            ),
          if (session.snapshot?.room.game == GameType.daketi)
            ListTile(
              leading: const Icon(Icons.collections_bookmark_outlined),
              title: const Text(Copy.exploreCollection),
              onTap: () {
                Navigator.pop(context);
                inspectCollection(context, p);
              },
            ),
          ListTile(
            leading: const Icon(Icons.emoji_emotions_outlined),
            title: const Text(Copy.sendAReaction),
            subtitle: const Text(Copy.costsVirtualCoinsReviewBeforeSending),
            onTap: () {
              Navigator.pop(context);
              reactionPicker(p);
            },
          ),
        ],
      ),
    );
  }

  Future<void> reactionPicker(PublicPlayer target) async {
    List<ReactionChoice> choices;
    try {
      choices = await ReactionChoice.load();
    } catch (_) {
      announce(Copy.theReactionCatalogCouldNotBeLoaded);
      return;
    }
    if (!mounted) return;
    final own = target.id == session.playerId;
    final selected = await showTaashSheet<ReactionChoice>(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            own ? Copy.expressYourself : 'A little room talk',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 10),
          Text(Copy.balanceCoins(widget.coinBalance?.call() ?? 0)),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 14,
            children: choices
                .where((r) => r.static == own)
                .map(
                  (r) => SizedBox(
                    width: 92,
                    child: InkWell(
                      onTap: () => Navigator.pop(context, r),
                      borderRadius: BorderRadius.circular(14),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            ReactionArt(id: r.id),
                            const SizedBox(height: 8),
                            Text(r.label, textAlign: TextAlign.center),
                            Text(
                              Copy.coins2(r.cost),
                              style: const TextStyle(
                                fontSize: 11,
                                color: T.muted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
    if (selected == null || !mounted) return;
    if ((widget.coinBalance?.call() ?? 0) < selected.cost) {
      announce(Copy.youNeedVirtualCoinsForThisReaction(selected.cost));
      return;
    }
    if (await confirmAction(
          context,
          title: Copy.send(selected.label),
          message: Copy.spendVirtualCoins(
            selected.cost,
            own ? 'on your reaction' : 'to send to ${target.displayName}',
          ),
          confirmLabel: Copy.sendCoins(selected.cost),
        ) &&
        mounted) {
      await send(
        'chat.anim',
        payload: {
          'anim_id': selected.id,
          'from_player': session.playerId,
          'to_player': target.id,
        },
      );
    }
  }

  Future<void> options() async {
    await showTaashSheet<void>(
      context,
      StatefulBuilder(
        builder: (context, setSheet) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.snapshot?.room.name ?? Copy.yourRoom,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            SelectableText(Copy.room(session.roomId ?? '')),
            const SizedBox(height: 12),
            // A3: Show game type and active player count.
            if (session.snapshot != null) ...[
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: T.coral.withValues(alpha: .18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: T.coral.withValues(alpha: .3)),
                    ),
                    child: Text(
                      session.snapshot!.room.game.label,
                      style: const TextStyle(
                        color: T.coral,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.people_outline, size: 18, color: T.muted),
                  const SizedBox(width: 6),
                  Text(
                    '${session.snapshot!.players.where((p) => p.connected).length} / ${session.snapshot!.room.maxPlayers} players',
                    style: const TextStyle(color: T.muted),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 14),
            if (widget.preferences != null) ...[
              SwitchListTile(
                value: widget.preferences!.sfx,
                onChanged: (v) {
                  widget.preferences!.set('sfx', v);
                  audio.sfxEnabled = v;
                  setSheet(() {});
                },
                title: const Text(Copy.soundEffects),
                subtitle: const Text(Copy.audioPackUnavailableInThisBuild),
              ),
              SwitchListTile(
                value: widget.preferences!.music,
                onChanged: (v) {
                  widget.preferences!.set('music', v);
                  if (v) {
                    audio.playBgm();
                  } else {
                    audio.stopBgm();
                  }
                  setSheet(() {});
                },
                title: const Text(Copy.music),
              ),
              SwitchListTile(
                value: widget.preferences!.haptics,
                onChanged: (v) {
                  widget.preferences!.set('haptics', v);
                  setSheet(() {});
                },
                title: const Text(Copy.haptics),
              ),
            ],
            const SizedBox(height: 12),
            TaashButton(
              label: Copy.leaveRoom,
              secondary: true,
              icon: Icons.logout,
              onPressed: () {
                Navigator.pop(context);
                leave();
              },
            ),
          ],
        ),
      ),
    );
  }
}
