import 'dart:collection';

enum GameType {
  bhabhi('Bhabhi', 500, 7),
  bluff('Bluff', 400, 7),
  daketi('Daketi', 250, 7),
  tc('Tissar Chausar', 1000, 4);

  const GameType(this.label, this.entryFee, this.maxPlayers);
  final String label;
  final int entryFee;
  final int maxPlayers;
  int get minPlayers => 2;
  String get wire => name;
  static GameType parse(Object? value) => values.firstWhere(
    (game) => game.name == value,
    orElse: () => throw const FormatException('Unknown game type'),
  );
}

Map<String, dynamic> jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected an object');
  return Map<String, dynamic>.from(value);
}

int jsonInt(Object? value, [int fallback = 0]) =>
    value is num ? value.toInt() : int.tryParse('$value') ?? fallback;
String jsonString(Object? value, [String fallback = '']) =>
    value is String ? value : fallback;
List<T> jsonList<T>(Object? value, T Function(Object?) parse) =>
    UnmodifiableListView((value is List ? value : const []).map(parse));
DateTime jsonDate(Object? value) =>
    DateTime.tryParse(jsonString(value))?.toUtc() ??
    DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
List<String> cardList(Object? value) => jsonList(value, (card) {
  final id = jsonString(card);
  if (!RegExp(r'^[cehp]-(?:[2-9]|10|g|b|k|y)$').hasMatch(id)) {
    throw const FormatException('Invalid card ID');
  }
  return id;
});

class PlayerProfile {
  PlayerProfile({
    required this.id,
    required this.displayName,
    this.email = '',
    this.country = '',
    this.coins = 0,
    this.xp = 0,
    List<int> unlockedPfps = const [],
    this.selectedPfp = 0,
    required this.createdAt,
  }) : unlockedPfps = List.unmodifiable(unlockedPfps);

  factory PlayerProfile.fromJson(Map<String, dynamic> json) => PlayerProfile(
    id: jsonString(json['id']),
    displayName: jsonString(json['display_name']),
    email: jsonString(json['email']),
    country: jsonString(json['country']),
    coins: jsonInt(json['coins']),
    xp: jsonInt(json['xp']),
    unlockedPfps: jsonList(json['unlocked_pfps'], (v) => jsonInt(v)),
    selectedPfp: jsonInt(json['selected_pfp']),
    createdAt: jsonDate(json['created_at']),
  );

  final String id, displayName, email, country;
  final int coins, xp, selectedPfp;
  final List<int> unlockedPfps;
  final DateTime createdAt;
}

class PlayerStats {
  const PlayerStats({
    required this.game,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.points = 0,
    this.winStreakCount = 0,
  });
  factory PlayerStats.fromJson(Map<String, dynamic> json) => PlayerStats(
    game: GameType.parse(json['game_type']),
    gamesPlayed: jsonInt(json['games_played']),
    gamesWon: jsonInt(json['games_won']),
    points: jsonInt(json['points']),
    winStreakCount: jsonInt(json['win_streak_count']),
  );
  final GameType game;
  final int gamesPlayed, gamesWon, points, winStreakCount;
  int get gamesLost => (gamesPlayed - gamesWon).clamp(0, gamesPlayed);
  double get winRate => gamesPlayed == 0 ? 0 : gamesWon / gamesPlayed;
}

class LeaderboardEntry {
  const LeaderboardEntry({
    required this.playerId,
    required this.displayName,
    this.country = '',
    this.selectedPfp = 0,
    this.points = 0,
  });
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        playerId: jsonString(json['player_id']),
        displayName: jsonString(json['display_name']),
        country: jsonString(json['country']),
        selectedPfp: jsonInt(json['selected_pfp']),
        points: jsonInt(json['points']),
      );
  final String playerId, displayName, country;
  final int selectedPfp, points;
}

class RoomSummary {
  const RoomSummary({
    required this.id,
    required this.name,
    required this.game,
    required this.maxPlayers,
    this.playerCount = 0,
    this.private = false,
    this.status = 'waiting',
    this.version = 0,
    required this.createdAt,
  });
  factory RoomSummary.fromJson(Map<String, dynamic> json) {
    final game = GameType.parse(json['game_type']);
    final capacity = jsonInt(json['max_players']);
    final status = jsonString(json['status']);
    if (capacity < 2 ||
        capacity > game.maxPlayers ||
        !const ['waiting', 'active', 'finished'].contains(status)) {
      throw const FormatException('Invalid room metadata');
    }
    return RoomSummary(
      id: jsonString(json['id']),
      name: jsonString(json['name']),
      game: game,
      maxPlayers: capacity,
      playerCount: jsonInt(json['player_count']),
      private: json['private'] == true,
      status: status,
      version: jsonInt(json['version']),
      createdAt: jsonDate(json['created_at']),
    );
  }
  final String id, name, status;
  final GameType game;
  final int maxPlayers, playerCount, version;
  final bool private;
  final DateTime createdAt;
  bool get isWaiting => status == 'waiting';
  bool get isActive => status == 'active';
  bool get isFinished => status == 'finished';
}

class PublicPlayer {
  PublicPlayer({
    required this.id,
    required this.displayName,
    this.country = '',
    this.seat = 0,
    this.connected = false,
    this.handCount = 0,
    this.place = 0,
    this.points = 0,
    this.selectedPfp = 0,
    List<String> collection = const [],
  }) : collection = List.unmodifiable(collection);
  factory PublicPlayer.fromJson(Map<String, dynamic> json) => PublicPlayer(
    id: jsonString(json['id']),
    displayName: jsonString(json['display_name']),
    country: jsonString(json['country']),
    seat: jsonInt(json['seat']),
    connected: json['connected'] == true,
    handCount: jsonInt(json['hand_count']),
    place: jsonInt(json['place']),
    points: jsonInt(json['points']),
    selectedPfp: jsonInt(json['selectedPfp']),
    collection: cardList(json['collection']),
  );
  final String id, displayName, country;
  final int seat, handCount, place, points, selectedPfp;
  final bool connected;
  final List<String> collection;
  bool get isBot => id.startsWith('bot-');
}

class PrivatePlayer {
  PrivatePlayer({required this.id, required List<String> hand})
    : hand = List.unmodifiable(hand);
  factory PrivatePlayer.fromJson(Map<String, dynamic> json) =>
      PrivatePlayer(id: jsonString(json['id']), hand: cardList(json['hand']));
  final String id;
  final List<String> hand;
}

class Winner {
  const Winner({required this.playerId, required this.place, this.points = 0});
  factory Winner.fromJson(Map<String, dynamic> json) => Winner(
    playerId: jsonString(json['player_id']),
    place: jsonInt(json['place']),
    points: jsonInt(json['points']),
  );
  final String playerId;
  final int place, points;
}

class PlayedCard {
  const PlayedCard({required this.playerId, required this.card});
  factory PlayedCard.fromJson(Map<String, dynamic> json) => PlayedCard(
    playerId: jsonString(json['player_id']),
    card: cardList([json['card']]).single,
  );
  final String playerId, card;
}

sealed class PublicGameState {
  const PublicGameState();
  factory PublicGameState.parse(GameType game, Map<String, dynamic> json) =>
      switch (game) {
        GameType.bhabhi => BhabhiState.fromJson(json),
        GameType.bluff => BluffState.fromJson(json),
        GameType.daketi => DaketiState.fromJson(json),
        GameType.tc => TcState.fromJson(json),
      };
}

class BhabhiState extends PublicGameState {
  BhabhiState.fromJson(Map<String, dynamic> json)
    : trick = jsonList(
        json['trick'],
        (v) => PlayedCard.fromJson(jsonObject(v)),
      ),
      firstTrick = json['first_trick'] == true,
      leadSuit = jsonString(json['lead_suit']),
      lastPickupPlayerId = jsonString(json['last_pickup_player_id']),
      lastThullu = json['last_thullu'] == true;
  final List<PlayedCard> trick;
  final bool firstTrick, lastThullu;
  final String leadSuit, lastPickupPlayerId;
}

class BluffState extends PublicGameState {
  BluffState.fromJson(Map<String, dynamic> json)
    : pileCount = jsonInt(json['pile_count']),
      lastPlayCount = jsonInt(json['last_play_count']),
      lastPlayerId = jsonString(json['last_player_id']),
      declaredRank = jsonString(json['declared_rank']),
      passedPlayerIds = jsonList(
        json['passed_player_ids'],
        (v) => jsonString(v),
      ),
      pendingWinnerId = jsonString(json['pending_winner_id']);
  final int pileCount, lastPlayCount;
  final String lastPlayerId, declaredRank, pendingWinnerId;
  final List<String> passedPlayerIds;
}

class DaketiState extends PublicGameState {
  DaketiState.fromJson(Map<String, dynamic> json)
    : stockCount = jsonInt(json['stock_count']),
      playArea = cardList(json['play_area']);
  final int stockCount;
  final List<String> playArea;
}

class TcState extends PublicGameState {
  TcState.fromJson(Map<String, dynamic> json)
    : stockCount = jsonInt(json['stock_count']),
      discardCount = jsonInt(json['discard_count']),
      discardTop = json['discard_top'] == null
          ? null
          : cardList([json['discard_top']]).single,
      indicator = json['indicator'] == null
          ? null
          : cardList([json['indicator']]).single,
      yarakRank = jsonString(json['yarak_rank']);
  final int stockCount, discardCount;
  final String? discardTop, indicator;
  final String yarakRank;
}

class RoomSnapshot {
  RoomSnapshot({
    required this.room,
    required this.you,
    required List<PublicPlayer> players,
    required List<Winner> winners,
    this.currentPlayerId = '',
    this.gameState,
    List<String> winnerHand = const [],
  }) : players = List.unmodifiable(players),
       winners = List.unmodifiable(winners),
       winnerHand = List.unmodifiable(winnerHand);
  factory RoomSnapshot.fromJson(Map<String, dynamic> json) {
    final room = RoomSummary.fromJson(jsonObject(json['room']));
    return RoomSnapshot(
      room: room,
      you: PrivatePlayer.fromJson(jsonObject(json['you'])),
      players: jsonList(
        json['players'],
        (v) => PublicPlayer.fromJson(jsonObject(v)),
      ),
      winners: jsonList(json['winners'], (v) => Winner.fromJson(jsonObject(v))),
      currentPlayerId: jsonString(json['current_player_id']),
      gameState: json['game_state'] == null
          ? null
          : PublicGameState.parse(room.game, jsonObject(json['game_state'])),
      winnerHand: cardList(json['winner_hand']),
    );
  }
  final RoomSummary room;
  final PrivatePlayer you;
  final List<PublicPlayer> players;
  final List<Winner> winners;
  final String currentPlayerId;
  final PublicGameState? gameState;
  final List<String> winnerHand;
  bool get isYourTurn => room.isActive && currentPlayerId == you.id;

  RoomSnapshot withPrivatePlayer(
    PrivatePlayer privatePlayer, {
    List<String>? reveal,
  }) => RoomSnapshot(
    room: room,
    you: privatePlayer,
    players: players,
    winners: winners,
    currentPlayerId: currentPlayerId,
    gameState: gameState,
    winnerHand: reveal ?? winnerHand,
  );
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.playerId,
    required this.displayName,
    required this.text,
    required this.sentAt,
  });
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: jsonString(json['id']),
    playerId: jsonString(json['player_id']),
    displayName: jsonString(json['display_name']),
    text: jsonString(json['text']),
    sentAt: jsonDate(json['sent_at']),
  );
  final String id, playerId, displayName, text;
  final DateTime sentAt;
}

/// A resolved Bluff challenge broadcast to every seat. The server announces
/// these whenever a player challenges the previous play; the challenger also
/// receives the same payload as the ack of its own `bluff.challenge` command.
class BluffChallengeEvent {
  BluffChallengeEvent({
    required this.bluffCaught,
    required this.challenger,
    required this.challenged,
    required this.pileGoesTo,
    required this.declaredRank,
    required List<String> lastPlayCards,
  }) : lastPlayCards = List.unmodifiable(lastPlayCards);

  /// Accepts the full ack envelope (`{"command": ...,
  /// "result": {"type": ..., "data": {...}}}`), the result object on its own,
  /// or the data map directly.
  static BluffChallengeEvent? tryParse(Object? value) {
    if (value is! Map) return null;
    var fields = Map<String, dynamic>.from(value);
    final result = fields['result'];
    if (result is Map) fields = Map<String, dynamic>.from(result);
    final data = fields['data'];
    if (data is Map) fields = Map<String, dynamic>.from(data);
    final bluffCaught = fields['bluff_caught'] == true;
    final challenger = jsonString(fields['challenger']);
    final challenged = jsonString(fields['challenged']);
    final pileGoesTo = jsonString(fields['pile_goes_to']);
    final declaredRank = jsonString(fields['declared_rank']);
    final lastPlayCards = jsonList(fields['last_play_cards'], (v) => v is String ? v : '').toList();
    if (challenger.isEmpty ||
        challenged.isEmpty ||
        pileGoesTo.isEmpty ||
        declaredRank.isEmpty ||
        lastPlayCards.isEmpty) {
      return null;
    }
    return BluffChallengeEvent(
      bluffCaught: bluffCaught,
      challenger: challenger,
      challenged: challenged,
      pileGoesTo: pileGoesTo,
      declaredRank: declaredRank,
      lastPlayCards: lastPlayCards,
    );
  }

  final bool bluffCaught;
  final String challenger, challenged, pileGoesTo, declaredRank;
  final List<String> lastPlayCards;

  String get dedupKey =>
      '$bluffCaught|$challenger|$challenged|$declaredRank|${lastPlayCards.join(',')}';
}

class ChatAnimation {
  const ChatAnimation({
    required this.animId,
    required this.fromPlayer,
    required this.toPlayer,
    required this.sentAt,
  });
  factory ChatAnimation.fromJson(Map<String, dynamic> json) => ChatAnimation(
    animId: jsonInt(json['anim_id']),
    fromPlayer: jsonString(json['from_player']),
    toPlayer: jsonString(json['to_player']),
    sentAt: jsonDate(json['sent_at']),
  );
  final int animId;
  final String fromPlayer, toPlayer;
  final DateTime sentAt;
  String get deduplicationKey =>
      '$animId:$fromPlayer:$toPlayer:${sentAt.toIso8601String()}';
}
