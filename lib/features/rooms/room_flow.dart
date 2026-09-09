import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../../l10n/strings.dart';

enum RoomFlowMode { create, join, quick }

class RoomFlow extends StatefulWidget {
  const RoomFlow({
    super.key,
    required this.mode,
    required this.api,
    required this.auth,
    required this.onJoin,
    this.game = GameType.bhabhi,
  });
  final RoomFlowMode mode;
  final ApiClient api;
  final AuthController auth;
  final GameType game;
  final ValueChanged<RoomSummary> onJoin;
  @override
  State<RoomFlow> createState() => _RoomFlowState();
}

class _RoomFlowState extends State<RoomFlow> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(), code = TextEditingController();
  late GameType game = widget.game;
  int seats = 4;
  bool private = false, busy = false;
  RoomSummary? room;
  String? error;
  @override
  void initState() {
    super.initState();
    if (widget.mode == RoomFlowMode.quick) {
      WidgetsBinding.instance.addPostFrameCallback((_) => lookup());
    }
  }

  @override
  void dispose() {
    name.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> lookup() async {
    if (widget.mode == RoomFlowMode.join &&
        !(form.currentState?.validate() ?? false)) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = widget.mode == RoomFlowMode.quick
          ? await widget.api.findMatch(game)
          : await widget.api.getRoom(
              code.text.replaceAll(RegExp(r'\s'), '').toUpperCase(),
            );
      await widget.auth.refreshProfile();
      if (mounted) setState(() => room = r);
    } on AppFailure catch (e) {
      if (mounted) setState(() => error = e.message);
    } catch (_) {
      if (mounted) {
        setState(() => error = Copy.weCouldNotReadThisRoomPlease);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> create() async {
    if (!(form.currentState?.validate() ?? false)) return;
    if ((widget.auth.profile?.coins ?? 0) < game.entryFee) {
      setState(
        () => error = Copy.youNeedVirtualCoinsToEnterThis(game.entryFee),
      );
      return;
    }
    final approved = await confirmAction(
      context,
      title: Copy.createAndEnter(game.label),
      message: Copy.entryFeeVirtualCoinsBalanceCoins(
        game.entryFee,
        widget.auth.profile?.coins ?? 0,
        S.coinNote,
      ),
      confirmLabel: Copy.createEnter,
    );
    if (!approved || !mounted) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final r = await widget.api.createRoom(
        game: game,
        maxPlayers: seats,
        name: name.text,
        private: private,
      );
      if (mounted) {
        setState(() => room = r);
        widget.onJoin(r);
      }
    } on AppFailure catch (e) {
      if (mounted) {
        setState(
          () => error = e.uncertain
              ? Copy.theRoomMayHaveBeenCreatedBut
              : e.message,
        );
      }
    } catch (_) {
      if (mounted) {
        setState(() => error = Copy.weCouldNotCreateTheRoomPlease);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void enter() {
    final r = room;
    if (r == null || busy) return;
    widget.onJoin(r);
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.mode == RoomFlowMode.create
        ? S.createRoom
        : widget.mode == RoomFlowMode.quick
        ? Copy.findYourCompany
        : S.joinRoom;
    final balance = widget.auth.profile?.coins ?? 0;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: form,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TaashSectionHeader(
                  eyebrow: Copy.theROOMISYOURS,
                  title: widget.mode == RoomFlowMode.create
                      ? Copy.makeRoomForAGoodNight
                      : widget.mode == RoomFlowMode.quick
                      ? 'A few new faces.\nA familiar game.'
                      : Copy.friendsAreExpectingYou,
                  subtitle: widget.mode == RoomFlowMode.create
                      ? Copy.chooseTheGameWeLlDealThe
                      : widget.mode == RoomFlowMode.join
                      ? Copy.pasteTheSixCharacterCodeYourFriend
                      : Copy.weLlFindAPublicRoomWith,
                ),
                const SizedBox(height: 28),
                if (room == null && widget.mode == RoomFlowMode.create) ...[
                  TextFormField(
                    controller: name,
                    maxLength: 25,
                    decoration: const InputDecoration(
                      labelText: S.roomName,
                      hintText: Copy.fridayCardNight,
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                    validator: (v) =>
                        v == null ||
                            v.trim().isEmpty ||
                            !RegExp(r'^[A-Za-z0-9 ]{1,25}$').hasMatch(v.trim())
                        ? Copy.use125EnglishLettersNumbersOr
                        : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<GameType>(
                    initialValue: game,
                    decoration: const InputDecoration(labelText: Copy.game),
                    items: GameType.values
                        .map(
                          (g) =>
                              DropdownMenuItem(value: g, child: Text(g.label)),
                        )
                        .toList(),
                    onChanged: busy
                        ? null
                        : (v) {
                            if (v != null) {
                              setState(() {
                                game = v;
                                seats = seats.clamp(1, v.maxPlayers);
                              });
                            }
                          },
                  ),
                  const SizedBox(height: 20),
                  TaashPanel(
                    child: Row(
                      children: [
                        const Expanded(
                          child: Text(
                            Copy.seatsAtYourRoom,
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        IconButton(
                          tooltip: Copy.fewerPlayers,
                          onPressed: seats > 1 && !busy
                              ? () => setState(() => seats--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                        ),
                        Text(
                          '$seats',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        IconButton(
                          tooltip: Copy.morePlayers,
                          onPressed: seats < game.maxPlayers && !busy
                              ? () => setState(() => seats++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      S.privateRoom,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(private ? S.privateHint : S.publicHint),
                    value: private,
                    onChanged: busy ? null : (v) => setState(() => private = v),
                  ),
                  const SizedBox(height: 20),
                  _Fee(fee: game.entryFee, balance: balance),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: TaashButton(
                      label: Copy.createEnter,
                      icon: Icons.arrow_forward,
                      onPressed: create,
                      busy: busy,
                    ),
                  ),
                ],
                if (room == null && widget.mode == RoomFlowMode.join) ...[
                  TextFormField(
                    controller: code,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: [LengthLimitingTextInputFormatter(10)],
                    decoration: const InputDecoration(
                      labelText: Copy.roomCode,
                      hintText: 'XXX XXX',
                      prefixIcon: Icon(Icons.key_outlined),
                    ),
                    validator: (v) =>
                        v == null ||
                            !RegExp(
                              r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{6}$',
                            ).hasMatch(
                              v.replaceAll(RegExp(r'\s'), '').toUpperCase(),
                            )
                        ? Copy.enterTheSixCharacterRoomCode
                        : null,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TaashButton(
                      label: S.lookup,
                      onPressed: lookup,
                      busy: busy,
                      icon: Icons.search,
                    ),
                  ),
                ],
                if (room == null && widget.mode == RoomFlowMode.quick && busy)
                  const TaashPanel(
                    child: Row(
                      children: [
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: 16),
                        Expanded(child: Text(Copy.lookingForARoom)),
                      ],
                    ),
                  ),
                if (room != null) ...[
                  TaashPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              room!.private ? Icons.lock_outline : Icons.public,
                              color: T.coral,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                room!.name,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SelectableText(
                          room!.id,
                          style: const TextStyle(
                            fontSize: 31,
                            letterSpacing: 5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          Copy.players(
                            room!.game.label,
                            room!.playerCount,
                            room!.maxPlayers,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          room!.private ? S.privateHint : S.publicHint,
                          style: const TextStyle(color: T.muted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _Fee(fee: room!.game.entryFee, balance: balance),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: TaashButton(
                      label: room!.isWaiting
                          ? Copy.enterCoins(room!.game.entryFee)
                          : Copy.thisRoomHasStarted,
                      icon: Icons.arrow_forward,
                      onPressed:
                          room!.isWaiting && balance >= room!.game.entryFee
                          ? enter
                          : null,
                      busy: busy,
                    ),
                  ),
                  if (!room!.isWaiting)
                    TextButton(
                      onPressed: () => setState(() => room = null),
                      child: const Text(Copy.findAnotherRoom),
                    ),
                ],
                if (error != null) ...[
                  const SizedBox(height: 18),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      error!,
                      style: const TextStyle(color: T.danger),
                    ),
                  ),
                  if (widget.mode == RoomFlowMode.quick)
                    TextButton(
                      onPressed: busy ? null : lookup,
                      child: const Text(Copy.tryAgain),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Fee extends StatelessWidget {
  const _Fee({required this.fee, required this.balance});
  final int fee, balance;
  @override
  Widget build(BuildContext context) => TaashPanel(
    color: T.ochre.withValues(alpha: .16),
    child: Column(
      children: [
        Row(
          children: [
            const Icon(Icons.toll, color: T.coral),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                Copy.entryFee,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            Text(
              Copy.coins4(fee),
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            const Expanded(child: Text(Copy.yourBalance)),
            Text(Copy.coins3(balance)),
          ],
        ),
        if (balance < fee) ...[
          const SizedBox(height: 12),
          Text(
            Copy.youNeedMoreCoins(fee - balance),
            style: const TextStyle(color: T.danger),
          ),
        ],
        const SizedBox(height: 12),
        const Text(S.coinNote, style: TextStyle(color: T.muted, fontSize: 12)),
      ],
    ),
  );
}
