import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/auth/auth_controller.dart';
import '../../core/errors/app_failure.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../home/game_art.dart';

const _friendNameMaxLength = 17;

String _friendNameLabel(String value) {
  final name = value.trim();
  return name.length > _friendNameMaxLength
      ? '${name.substring(0, _friendNameMaxLength - 1)}…'
      : name;
}

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({
    super.key,
    required this.auth,
    required this.api,
    required this.onFriendProfile,
    required this.onRoom,
    this.onRequestCountChanged,
  });
  final AuthController auth;
  final ApiClient api;
  final ValueChanged<String> onFriendProfile;
  final ValueChanged<RoomSummary> onRoom;
  final ValueChanged<int>? onRequestCountChanged;
  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen> {
  SocialView? _social;
  final Set<String> _emailRequests = {};
  String? _error;
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final value = await widget.api.getSocial();
      if (mounted) {
        setState(() => _social = value);
        widget.onRequestCountChanged?.call(
          value.requests.length +
              value.challenges.where(_isPendingChallenge).length,
        );
      }
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not load your friends.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _respond(FriendRequestModel request, bool accept) async {
    try {
      await widget.api.respondFriend(request.id, accept: accept);
      await _load();
    } on AppFailure catch (e) {
      if (mounted) showNotice(context, e.message);
    }
  }

  Future<void> _challenge() async {
    final social = _social;
    if (social == null || social.friends.isEmpty) {
      showNotice(context, 'Add friends before challenging them.');
      return;
    }
    final game = await showDialog<GameType>(
      context: context,
      builder: (context) => Dialog(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose a game',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...GameType.values.map(
                (game) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context, game),
                    child: SizedBox(
                      height: 82,
                      width: 360,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Transform.translate(
                              key: ValueKey('choose-game-art-${game.name}'),
                              offset: const Offset(0, -32),
                              child: GameArt(game: game),
                            ),
                            ColoredBox(
                              color: gameColor(game).withValues(alpha: .22),
                            ),
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  12,
                                ),
                                child: Text(
                                  game.label,
                                  style: const TextStyle(
                                    color: T.ink,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 17,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xCC000000),
                                        blurRadius: 5,
                                        offset: Offset(0, 1),
                                      ),
                                      Shadow(
                                        color: Color(0x66000000),
                                        blurRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (game == null || !mounted) return;
    final selected = await showDialog<List<FriendProfile>>(
      context: context,
      builder: (_) =>
          _FriendPicker(friends: social.friends, max: game.maxPlayers - 1),
    );
    if (selected == null || selected.isEmpty || !mounted) return;
    try {
      final challenge = await widget.api.createChallenge(
        game: game,
        friendIds: selected.map((f) => f.id).toList(),
      );
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChallengeWaitScreen(
            api: widget.api,
            challengeId: challenge.id,
            ownId: widget.auth.profile!.id,
            onRoom: widget.onRoom,
          ),
        ),
      );
      await _load();
    } on AppFailure catch (e) {
      if (mounted) showNotice(context, e.message);
    }
  }

  Future<void> _accept(Challenge challenge) async {
    try {
      final updated = await widget.api.acceptChallenge(challenge.id);
      if (!mounted) return;
      if (updated.room != null) {
        widget.onRoom(updated.room!);
        return;
      }
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChallengeWaitScreen(
            api: widget.api,
            challengeId: challenge.id,
            ownId: widget.auth.profile!.id,
            onRoom: widget.onRoom,
          ),
        ),
      );
      await _load();
    } on AppFailure catch (e) {
      if (mounted) showNotice(context, e.message);
    }
  }

  bool _isPendingChallenge(Challenge challenge) {
    final accepted =
        challenge.invites
            .where((invite) => invite.status == 'accepted')
            .length +
        1;
    return challenge.status == 'waiting' && accepted < challenge.maxPlayers;
  }

  Future<void> _addFriendByEmail() async {
    final email = await showDialog<String>(
      context: context,
      builder: (_) => const _AddFriendDialog(),
    );
    final normalized = email?.trim().toLowerCase() ?? '';
    if (normalized.isEmpty || !mounted) return;
    if (_emailRequests.contains(normalized)) {
      showNotice(context, 'A request has already been sent for that email.');
      return;
    }
    try {
      await widget.api.addFriendByEmail(normalized);
      if (!mounted) return;
      setState(() => _emailRequests.add(normalized));
      showNotice(
        context,
        'If that email belongs to a player, a request was sent.',
      );
    } on AppFailure catch (e) {
      if (mounted) showNotice(context, e.message);
    }
  }

  Future<void> _openChallenge(Challenge challenge) async {
    try {
      final current = await widget.api.getChallenge(challenge.id);
      if (mounted && current.room != null) widget.onRoom(current.room!);
    } on AppFailure catch (e) {
      if (mounted) showNotice(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final social = _social;
    final visibleChallenges = social?.challenges
        .where(_isPendingChallenge)
        .toList();
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Friends',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: 'Add friend by email',
                      onPressed: _addFriendByEmail,
                      icon: const Icon(Icons.person_add_alt_1_outlined),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Play together, keep the table close.',
                  style: TextStyle(color: T.muted),
                ),
                if (_loading && social == null)
                  const Padding(
                    padding: EdgeInsets.all(40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_error != null && social == null)
                  TaashEmpty(
                    title: 'Friends unavailable',
                    message: _error!,
                    onRetry: _load,
                    icon: Icons.people_outline,
                  )
                else ...[
                  if (visibleChallenges!.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    const _Heading('Challenges'),
                    ...visibleChallenges.map(_challengeCard),
                  ],
                  if (social!.requests.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    _Heading('Requests (${social.requests.length})'),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 148,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: social.requests.length,
                        separatorBuilder: (_, _) => const SizedBox(width: 10),
                        itemBuilder: (_, i) => _requestCard(social.requests[i]),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  const _Heading('Your friends'),
                  if (social.friends.isEmpty)
                    const TaashEmpty(
                      title: 'No friends yet',
                      message:
                          'Tap Add Friend on a player in a room to start your table.',
                      icon: Icons.people_outline,
                    )
                  else
                    ...social.friends.map(_friendTile),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 12),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _challenge,
                icon: const Icon(Icons.sports_esports_outlined),
                label: const Text('Challenge Friends'),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _friendTile(FriendProfile friend) => ListTile(
    contentPadding: EdgeInsets.zero,
    leading: GestureDetector(
      onTap: () => widget.onFriendProfile(friend.id),
      child: TaashAvatar(id: friend.selectedPfp, size: 48),
    ),
    title: Row(
      children: [
        Expanded(
          child: Text(
            _friendNameLabel(friend.displayName),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (friend.online) ...[
          const SizedBox(width: 8),
          const Text(
            'Online',
            style: TextStyle(
              color: T.mint,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ],
    ),
    subtitle: Text(
      friend.online ? 'In a game' : 'Offline',
      style: const TextStyle(color: T.muted),
    ),
    onTap: () => widget.onFriendProfile(friend.id),
    trailing: TextButton(
      onPressed: () => _unfriend(friend),
      child: const Text('Unfriend'),
    ),
  );

  Future<void> _unfriend(FriendProfile friend) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Unfriend?'),
        content: Text('Remove ${friend.displayName} from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await widget.api.unfriend(friend.id);
      await _load();
    } on AppFailure catch (e) {
      if (mounted) showNotice(context, e.message);
    }
  }

  Widget _requestCard(FriendRequestModel request) => SizedBox(
    width: 150,
    child: TaashPanel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      child: Column(
        children: [
          TaashAvatar(id: request.selectedPfp, size: 40),
          const SizedBox(height: 5),
          Text(
            request.displayName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                onPressed: () => _respond(request, false),
                icon: const Icon(Icons.close, size: 19),
              ),
              IconButton(
                onPressed: () => _respond(request, true),
                icon: const Icon(Icons.check, color: T.mint, size: 19),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _challengeCard(Challenge challenge) {
    final ownId = widget.auth.profile!.id;
    final incoming = challenge.creatorId != ownId;
    final ownInvite = challenge.invites
        .where((i) => i.playerId == ownId)
        .firstOrNull;
    final accepted =
        challenge.invites.where((i) => i.status == 'accepted').length + 1;
    final card = TaashPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            incoming
                ? '${challenge.creatorName} invited you to play ${challenge.game.label}'
                : '${challenge.game.label} challenge',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            '$accepted / ${challenge.maxPlayers} players accepted',
            style: const TextStyle(color: T.muted),
          ),
          const SizedBox(height: 8),
          Text(
            '${challenge.invites.map((i) => i.displayName).join(', ')} invited',
          ),
          if (incoming && ownInvite?.status == 'pending')
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 5),
                child: FilledButton(
                  onPressed: () => _accept(challenge),
                  child: const Text('Accept challenge'),
                ),
              ),
            )
          else if (challenge.room != null || challenge.roomId.isNotEmpty)
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton(
                onPressed: () => _openChallenge(challenge),
                child: const Text('Join challenge'),
              ),
            ),
        ],
      ),
    );
    final content = incoming && ownInvite?.status == 'pending'
        ? Dismissible(
            key: ValueKey('challenge-${challenge.id}'),
            direction: DismissDirection.startToEnd,
            background: Container(
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.only(left: 18),
              color: T.surface,
              child: const Icon(Icons.delete_outline),
            ),
            onDismissed: (_) async {
              try {
                await widget.api.declineChallenge(challenge.id);
                await _load();
              } on AppFailure catch (e) {
                if (mounted) showNotice(context, e.message);
              }
            },
            child: card,
          )
        : card;
    return Padding(padding: const EdgeInsets.only(bottom: 10), child: content);
  }
}

class _AddFriendDialog extends StatefulWidget {
  const _AddFriendDialog();

  @override
  State<_AddFriendDialog> createState() => _AddFriendDialogState();
}

class _AddFriendDialogState extends State<_AddFriendDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _controller.text);

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add a friend'),
    content: TextField(
      controller: _controller,
      autofocus: true,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.done,
      decoration: const InputDecoration(
        labelText: 'Email address',
        hintText: 'friend@example.com',
      ),
      onSubmitted: (_) => _submit(),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(onPressed: _submit, child: const Text('Send')),
    ],
  );
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: Theme.of(context).textTheme.titleLarge);
}

class _FriendPicker extends StatefulWidget {
  const _FriendPicker({required this.friends, required this.max});
  final List<FriendProfile> friends;
  final int max;
  @override
  State<_FriendPicker> createState() => _FriendPickerState();
}

class _FriendPickerState extends State<_FriendPicker> {
  final Set<String> _selected = {};
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Choose friends'),
    content: SizedBox(
      width: double.maxFinite,
      child: ListView(
        shrinkWrap: true,
        children: widget.friends
            .map(
              (friend) => CheckboxListTile(
                value: _selected.contains(friend.id),
                onChanged: (value) {
                  if (value == true && _selected.length >= widget.max) return;
                  setState(
                    () => value == true
                        ? _selected.add(friend.id)
                        : _selected.remove(friend.id),
                  );
                },
                secondary: TaashAvatar(id: friend.selectedPfp, size: 38),
                title: Text(
                  _friendNameLabel(friend.displayName),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Cancel'),
      ),
      FilledButton(
        onPressed: _selected.isEmpty
            ? null
            : () => Navigator.pop(
                context,
                widget.friends.where((f) => _selected.contains(f.id)).toList(),
              ),
        child: const Text('Challenge'),
      ),
    ],
  );
}

class ChallengeWaitScreen extends StatefulWidget {
  const ChallengeWaitScreen({
    super.key,
    required this.api,
    required this.challengeId,
    required this.ownId,
    required this.onRoom,
  });
  final ApiClient api;
  final String challengeId, ownId;
  final ValueChanged<RoomSummary> onRoom;
  @override
  State<ChallengeWaitScreen> createState() => _ChallengeWaitScreenState();
}

class _ChallengeWaitScreenState extends State<ChallengeWaitScreen> {
  Challenge? _challenge;
  Timer? _timer;
  String? _error;
  bool _opening = false;
  bool _leaving = false;
  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    if (_opening) return;
    try {
      final c = await widget.api.getChallenge(widget.challengeId);
      if (!mounted) return;
      setState(() {
        _challenge = c;
        _error = null;
      });
      if (c.room != null) {
        _opening = true;
        _timer?.cancel();
        widget.onRoom(c.room!);
        if (mounted) Navigator.pop(context);
      } else if (c.status != 'waiting') {
        _timer?.cancel();
        if (mounted) {
          setState(() => _error = 'This challenge is no longer open.');
        }
      }
    } on AppFailure catch (e) {
      if (e.code == 'challenge_not_found') {
        _timer?.cancel();
        if (mounted) Navigator.pop(context);
      } else if (mounted) {
        setState(() => _error = e.message);
      }
    }
  }

  Future<void> _accept() async {
    try {
      final c = await widget.api.acceptChallenge(widget.challengeId);
      if (c.room != null && mounted) {
        widget.onRoom(c.room!);
        Navigator.pop(context);
      } else if (mounted) {
        setState(() => _challenge = c);
      }
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _startEarly() async {
    try {
      final c = await widget.api.startChallenge(widget.challengeId);
      if (!mounted || c.room == null) return;
      _opening = true;
      _timer?.cancel();
      widget.onRoom(c.room!);
      Navigator.pop(context);
    } on AppFailure catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _leave() async {
    if (_leaving) return;
    final creator = _challenge?.creatorId == widget.ownId;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Are you sure?'),
        content: Text(
          creator
              ? 'This will end the challenge for everyone.'
              : 'If you leave, you cannot join this challenge again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _leaving = true);
    try {
      await widget.api.leaveChallenge(widget.challengeId);
      if (mounted) Navigator.pop(context);
    } on AppFailure catch (e) {
      if (mounted) {
        setState(() => _leaving = false);
        showNotice(context, e.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _challenge;
    final creator = c?.creatorId == widget.ownId;
    final accepted = c == null
        ? 0
        : c.invites.where((invite) => invite.status == 'accepted').length + 1;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: const Text('Challenge friends'),
          actions: [
            TextButton(
              onPressed: _leaving ? null : _leave,
              child: const Text('Leave'),
            ),
          ],
        ),
        body: c == null
            ? Center(
                child: _error == null
                    ? const CircularProgressIndicator()
                    : Text(_error!),
              )
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Icon(
                    Icons.hourglass_top_rounded,
                    size: 58,
                    color: T.ochre,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    c.creatorId == widget.ownId
                        ? '${c.game.label} challenge'
                        : '${c.creatorName} invited you to ${c.game.label}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Waiting for everyone to accept…',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: T.muted),
                  ),
                  const SizedBox(height: 28),
                  ...c.invites.map(
                    (invite) => ListTile(
                      leading: TaashAvatar(id: invite.selectedPfp, size: 42),
                      title: Text(invite.displayName),
                      trailing: Text(
                        invite.status == 'accepted' ? 'Ready' : 'Waiting',
                        style: TextStyle(
                          color: invite.status == 'accepted' ? T.mint : T.muted,
                        ),
                      ),
                    ),
                  ),
                  if (c.creatorId != widget.ownId &&
                      c.invites
                          .where(
                            (i) =>
                                i.playerId == widget.ownId &&
                                i.status == 'pending',
                          )
                          .isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: FilledButton(
                        onPressed: _accept,
                        child: const Text('Accept challenge'),
                      ),
                    ),
                  if (creator && accepted >= 2 && c.status == 'waiting')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: OutlinedButton(
                        onPressed: _startEarly,
                        child: const Text('Start Challenge Anyway'),
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
