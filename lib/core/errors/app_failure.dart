class AppFailure implements Exception {
  const AppFailure(
    this.code,
    this.message, {
    this.statusCode,
    this.uncertain = false,
    this.details,
  });

  final String code;
  final String message;
  final int? statusCode;
  final bool uncertain;
  final Map<String, dynamic>? details;

  bool get isOffline => code == 'offline' || code == 'timeout';
  bool get isMaintenance => code == 'server_under_maintenance';
  bool get isUnauthorized =>
      code == 'unauthorized' || code == 'session_expired';

  factory AppFailure.fromServer(
    String code, {
    String? serverMessage,
    int? statusCode,
    Map<String, dynamic>? details,
  }) {
    final lower = (serverMessage ?? '').toLowerCase();
    final String message;
    if (lower.contains('insufficient coins') ||
        code == 'not_enough_coins' ||
        code == 'insufficient_coins') {
      message = 'You need more coins for this action.';
    } else if (lower.contains('trick is resolving')) {
      message = 'The trick is settling. Give it a moment.';
    } else if (lower.contains('cannot discard the card just taken')) {
      message = 'Choose a different card. You just picked this one up.';
    } else if (lower.contains('partition')) {
      message = 'The server could not find a complete 4 + 3 + 3 hand.';
    } else if (lower.contains('parse chat anims') ||
        lower.contains('stat chat anims')) {
      message = 'Reactions are unavailable on the server right now.';
    } else {
      message = switch (code) {
        'unauthorized' ||
        'session_expired' => 'Please sign in again to continue.',
        'invalid_credentials' =>
          'Check your email and password, then try again.',
        'server_under_maintenance' =>
          'TaashOnline is taking a short maintenance break.',
        'room_conflict' =>
          'This room is full or has already started. Try another room.',
        'not_found' => 'This room or player is no longer available.',
        'player_does_not_exist_in_room' ||
        'not_joined' => 'Your seat is no longer available in this room.',
        'not_your_turn' => 'It is another player’s turn.',
        'game_not_active' => 'This game is not active right now.',
        'conflict' =>
          'The room just changed. Check the latest room before trying again.',
        'already_unlocked' => 'You already own this avatar.',
        'pfp_not_unlocked' => 'Unlock this avatar before selecting it.',
        'rate_limited' => 'A little too fast. Wait a moment and try again.',
        'chat_disabled' => 'Room chat is currently turned off by TaashOnline.',
        'anim_id_does_not_exist' => 'This reaction is no longer available.',
        'misconfigured' =>
          'The server is not ready for sign-in. Please try later.',
        'password_reset_failed' =>
          'We could not send a reset email. Please try again later.',
        'database_error' =>
          'Your account needs a server check. Try signing in before registering again.',
        'firebase_delete_failed' =>
          'Sign in again, then retry account deletion.',
        'invalid_request' =>
          'That action is not available right now. Check your choices.',
        _ => 'Something went wrong on the server. Please try again shortly.',
      };
    }
    return AppFailure(code, message, statusCode: statusCode, details: details);
  }

  // Never include an upstream response, private card state or credentials.
  @override
  String toString() => 'AppFailure($code)';
}
