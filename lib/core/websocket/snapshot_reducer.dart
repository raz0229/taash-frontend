import '../models/models.dart';

/// Applies only authoritative state for one room and authenticated identity.
/// The existing server's TC reveal repeats the winner's `you` to all clients.
/// That envelope contributes public winner cards, never a replacement self hand.
class SnapshotReducer {
  SnapshotReducer({required this.playerId});
  final String playerId;
  RoomSnapshot? current;
  int get highestVersion => current?.room.version ?? -1;

  bool apply(RoomSnapshot next, {required String roomId}) {
    if (next.room.id != roomId || next.room.version < highestVersion) {
      return false;
    }
    final previous = current;
    final isReveal =
        next.room.game == GameType.tc &&
        next.room.isFinished &&
        next.winnerHand.isNotEmpty &&
        next.winners.any((w) => w.place == 1);
    final legacyWinnerSelf =
        isReveal &&
        next.winners.any((w) => w.place == 1 && w.playerId == next.you.id);
    if (next.you.id != playerId && !legacyWinnerSelf) return false;
    if (!next.players.any((p) => p.id == playerId)) return false;
    if (previous != null && next.room.version == highestVersion) {
      if (!isReveal || previous.winnerHand.isNotEmpty) return false;
      current = previous.withPrivatePlayer(
        previous.you,
        reveal: next.winnerHand,
      );
      return true;
    }
    var accepted = next;
    if (next.you.id != playerId) {
      accepted = next.withPrivatePlayer(
        previous?.you ?? PrivatePlayer(id: playerId, hand: const []),
      );
    }
    if (accepted.room.isFinished &&
        accepted.winnerHand.isEmpty &&
        previous?.winnerHand.isNotEmpty == true) {
      accepted = accepted.withPrivatePlayer(
        accepted.you,
        reveal: previous!.winnerHand,
      );
    }
    current = accepted;
    return true;
  }

  void clear() => current = null;
}
