import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/errors/app_failure.dart';
import '../../core/models/models.dart';
import '../../core/network/api_client.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import 'presentation.dart';
import 'rank.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.api,
    required this.playerId,
    this.own = false,
  });
  final ApiClient api;
  final String playerId;
  final bool own;
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  PlayerProfile? _profile;
  List<PlayerStats>? _stats;
  CountryLabels? _countries;
  String? _error;
  GameType _game = GameType.bhabhi;
  bool _loading = true;
  int _loadGeneration = 0;
  bool get _isBot => widget.playerId.startsWith('bot-');
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerId != widget.playerId) {
      _profile = null;
      _stats = null;
      _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_loadGeneration;
    if (_isBot) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait<Object>([
        widget.api.getPlayer(widget.playerId),
        widget.api.getStats(widget.playerId),
        CountryLabels.load(),
      ]);
      if (!mounted || generation != _loadGeneration) return;
      setState(() {
        _profile = results[0] as PlayerProfile;
        _stats = results[1] as List<PlayerStats>;
        _countries = results[2] as CountryLabels;
      });
    } catch (e) {
      if (mounted && generation == _loadGeneration) {
        setState(
          () => _error = e is AppFailure
              ? e.message
              : Copy.weCouldNotLoadThisProfilePlease,
        );
      }
    } finally {
      if (mounted && generation == _loadGeneration) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.own ? Copy.yourProfile : Copy.playerProfile),
        actions: [
          IconButton(
            tooltip: Copy.refreshProfile,
            onPressed: _loading || _isBot ? null : _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: _isBot
            ? const TaashEmpty(
                title: Copy.meetYourRoomBot,
                message: Copy.botsKeepTheGameMovingTheyDo,
                icon: Icons.smart_toy_outlined,
              )
            : profile == null
            ? _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        semanticsLabel: Copy.loadingPlayerProfile,
                      ),
                    )
                  : TaashEmpty(
                      title: Copy.profileUnavailable,
                      message: _error ?? Copy.thisPlayerCouldNotBeFound,
                      onRetry: _load,
                    )
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  children: [
                    if (_loading)
                      const LinearProgressIndicator(
                        semanticsLabel: Copy.refreshingProfile,
                      ),
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: T.danger)),
                      const SizedBox(height: 12),
                    ],
                    TaashPanel(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: T.ochre, width: 2),
                            ),
                            child: TaashAvatar(
                              id: profile.selectedPfp,
                              size: 88,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            profile.displayName,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TaashFlag(code: profile.country, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                _countries?.name(profile.country) ?? 'Global',
                                style: const TextStyle(color: T.muted),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Wrap(
                            spacing: 12,
                            runSpacing: 10,
                            alignment: WrapAlignment.center,
                            children: [
                              TaashCurrencyChip(value: profile.coins),
                              TaashCurrencyChip(value: profile.xp, xp: true),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            profile.createdAt.year > 1970
                                ? Copy.atTheRoomSince(
                                    DateFormat.yMMMMd(
                                      'en',
                                    ).format(profile.createdAt.toLocal()),
                                  )
                                : Copy.joinedDateUnavailable,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: T.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    const TaashSectionHeader(
                      eyebrow: Copy.yourGameYourStory,
                      title: Copy.atTheRoom,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded),
                          onPressed: () {
                            final i = GameType.values.indexOf(_game);
                            setState(
                              () => _game =
                                  GameType.values[i > 0
                                      ? i - 1
                                      : GameType.values.length - 1],
                            );
                          },
                        ),
                        Expanded(
                          child: Text(
                            _game == GameType.tc ? Copy.tc : _game.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: T.ochre,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded),
                          onPressed: () {
                            final i = GameType.values.indexOf(_game);
                            setState(
                              () => _game = GameType
                                  .values[(i + 1) % GameType.values.length],
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _statsView(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _statsView(BuildContext context) {
    final stats =
        _stats!.where((row) => row.game == _game).firstOrNull ??
        PlayerStats(game: _game);
    final rank = rankFor(_game, stats.points);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RankProgressPanel(game: _game, rank: rank),
        const SizedBox(height: 16),
        TaashPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_game.label, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _stat(Copy.totalPoints, displayNumber(stats.points)),
              _stat(Copy.gamesPlayed, displayNumber(stats.gamesPlayed)),
              _stat(
                Copy.gamesWon,
                '${displayNumber(stats.gamesWon)} / ${displayNumber(stats.gamesPlayed)}',
              ),
              _stat(
                Copy.winRate,
                '${(stats.winRate * 100).toStringAsFixed(2)}%',
              ),
              _stat(Copy.currentWinStreak, displayNumber(stats.winStreakCount)),
              const SizedBox(height: 8),
              Text(
                stats.gamesPlayed == 0
                    ? Copy.noCompletedGamesRecordedYetYourStory
                    : _game == GameType.tc
                    ? 'A TC win means finishing first.'
                    : 'A win means finishing anywhere except last. It is not a first-place count.',
                style: const TextStyle(color: T.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: const TextStyle(color: T.muted)),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
      ],
    ),
  );
}

class RankProgressPanel extends StatelessWidget {
  const RankProgressPanel({super.key, required this.game, required this.rank});
  final GameType game;
  final RankProgress rank;
  @override
  Widget build(BuildContext context) => TaashPanel(
    color: T.pine,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(
              Icons.workspace_premium_outlined,
              color: T.ochre,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rank.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                    ),
                  ),
                  Text(
                    rank.ambiguous
                        ? '${displayNumber(rank.points)} points'
                        : rank.number == 0
                        ? Copy.firstRankAtPoints(displayNumber(rank.next!))
                        : Copy.rank(rank.number, game.label),
                    style: const TextStyle(color: T.mint),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        if (rank.ambiguous)
          const Text(
            Copy.pointsAreSavedRankProgressIsUnavailable,
            style: TextStyle(color: T.mint),
          )
        else ...[
          Semantics(
            label: '${rank.name} rank progress',
            value: '${(rank.fraction * 100).round()} percent',
            child: LinearProgressIndicator(
              value: rank.fraction,
              minHeight: 7,
              borderRadius: BorderRadius.circular(20),
              backgroundColor: Colors.white24,
              color: T.ochre,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            rank.isMaximum
                ? Copy.mythicAchievedKeepMakingYourMark
                : '${displayNumber(rank.remaining!)} points to ${rankNames[rank.number + 1]}',
            style: const TextStyle(color: T.mint),
          ),
        ],
      ],
    ),
  );
}
