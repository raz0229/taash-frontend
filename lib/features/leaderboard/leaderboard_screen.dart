import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import '../../core/errors/app_failure.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../profile/presentation.dart';
import '../profile/profile_screen.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key, required this.api});
  final ApiClient api;
  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  GameType _game = GameType.bhabhi;
  List<LeaderboardEntry>? _players;
  CountryLabels? _countries;
  String? _error;
  bool _loading = true;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final game = _game;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.api.leaderboard(game),
        CountryLabels.load(),
      ]);
      if (!mounted || generation != _generation) return;
      setState(() {
        _players = results[0] as List<LeaderboardEntry>;
        _countries = results[1] as CountryLabels;
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(
          () => _error = e is AppFailure
              ? e.message
              : Copy.weCouldNotLoadTheLeaderboardPlease,
        );
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  void _selectGame(GameType game) {
    if (game == _game) return;
    setState(() {
      _game = game;
      _players = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text(Copy.leaderboard),
      actions: [
        IconButton(
          tooltip: Copy.refreshLeaderboard,
          onPressed: _loading ? null : _load,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: SafeArea(
      top: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const TaashSectionHeader(
                  eyebrow: Copy.leaveYourMark,
                  title: Copy.theRoomHonours,
                  subtitle: Copy.tenPlayersOneGamePointsEarnedAt,
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final game in GameType.values)
                      ChoiceChip(
                        label: Text(game == GameType.tc ? Copy.tc : game.label),
                        selected: game == _game,
                        onSelected: (_) => _selectGame(game),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _players == null
                ? _loading
                      ? const Center(
                          child: CircularProgressIndicator(
                            semanticsLabel: Copy.loadingLeaderboard,
                          ),
                        )
                      : TaashEmpty(
                          title: Copy.leaderboardUnavailable,
                          message: _error ?? Copy.pleaseTryAgain,
                          onRetry: _load,
                        )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      children: [
                        if (_loading)
                          const LinearProgressIndicator(
                            semanticsLabel: Copy.refreshingLeaderboard,
                          ),
                        if (_error != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Text(
                              _error!,
                              style: const TextStyle(color: T.danger),
                            ),
                          ),
                        if (_players!.isEmpty)
                          const TaashEmpty(
                            title: Copy.theHonoursAreWaiting,
                            message: Copy.noPositiveScoresHaveBeenRecordedFor,
                            icon: Icons.emoji_events_outlined,
                          ),
                        for (var i = 0; i < _players!.length; i++)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _entry(context, _players![i], i + 1),
                          ),
                        if (_players!.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 12),
                            child: Text(
                              Copy.rankedByTheServerSAllTime,
                              style: TextStyle(fontSize: 12, color: T.muted),
                            ),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    ),
  );
  Widget _entry(BuildContext context, LeaderboardEntry player, int position) {
    final podium = position <= 3;
    final medal = switch (position) {
      1 => T.ochre,
      2 => const Color(0xFFBFCBD0),
      3 => const Color(0xFFD9A07C),
      _ => T.mint,
    };
    final medalName = switch (position) {
      1 => Copy.gold,
      2 => Copy.silver,
      3 => Copy.bronze,
      _ => '',
    };
    return Semantics(
      label: Copy.position(position, podium ? ', $medalName' : ''),
      child: Material(
        color: podium ? T.surface : T.paper,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: player.playerId.startsWith('bot-')
              ? null
              : () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileScreen(
                      api: widget.api,
                      playerId: player.playerId,
                    ),
                  ),
                ),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: podium ? medal : T.outline),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  width: 31,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: medal,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    '$position',
                    style: const TextStyle(
                      color: T.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 11),
                TaashAvatar(id: player.selectedPfp, size: podium ? 52 : 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        player.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TaashFlag(code: player.country, size: 14),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              _countries?.name(player.country) ?? 'Global',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: T.muted,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${displayNumber(player.points)} points',
                        style: const TextStyle(
                          color: T.mint,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (podium)
                  Icon(
                    Icons.emoji_events_outlined,
                    color: position == 1 ? T.ochre : T.muted,
                    size: 22,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
