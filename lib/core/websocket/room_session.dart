import '../audio/audio_system.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/widgets.dart';
import '../config/app_config.dart';
import '../errors/app_failure.dart';
import '../models/models.dart';
import 'room_socket.dart';
import 'snapshot_reducer.dart';

enum RoomConnectionState {
  idle,
  connecting,
  connected,
  reconnecting,
  offline,
  rejoining,
  recovered,
  roomUnavailable,
  sessionExpired,
  maintenance,
  closed,
}

class _Pending {
  _Pending(this.type, this.completer, this.timer, this.mutation);
  final String type;
  final Completer<Map<String, dynamic>> completer;
  final Timer timer;
  final bool mutation;
}

class RoomSession extends ChangeNotifier with WidgetsBindingObserver {
  RoomSession({
    required this.config,
    required this.tokenProvider,
    required this.playerId,
    this.onEconomyChanged,
    this.appCheckTokenProvider,
    RoomSocketConnector? connector,
    this.commandTimeout = const Duration(seconds: 12),
    this.connectTimeout = const Duration(seconds: 15),
    this.reconnectBase = const Duration(seconds: 3),
    this.reconnectJitter = const Duration(milliseconds: 700),
    this.maxReconnectAttempts = 6,
    bool observeLifecycle = true,
  }) : _connector = connector ?? connectRoomSocket,
       _reducer = SnapshotReducer(playerId: playerId),
       _observeLifecycle = observeLifecycle {
    if (observeLifecycle) WidgetsBinding.instance.addObserver(this);
  }

  final AppConfig config;
  final Future<String?> Function() tokenProvider;
  final String playerId;
  final Future<void> Function()? onEconomyChanged;
  final Future<String?> Function()? appCheckTokenProvider;
  VoidCallback? onStockDecreased;
  final RoomSocketConnector _connector;
  final SnapshotReducer _reducer;
  final Duration commandTimeout, connectTimeout, reconnectBase, reconnectJitter;
  final int maxReconnectAttempts;
  final bool _observeLifecycle;
  final _random = Random.secure();
  final Map<String, _Pending> _pending = {};
  final List<ChatMessage> _chat = [];
  final List<ChatAnimation> _animations = [];
  RoomConnectionState state = RoomConnectionState.idle;
  AppFailure? error;
  RoomSummary? _room;
  RoomSocket? _socket;
  StreamSubscription<Object?>? _subscription;
  Timer? _retryTimer, _recoveredTimer;
  Completer<void>? _joinReady;
  int _generation = 0, _serial = 0, _attempts = 0;
  bool _disposed = false, _closing = false, _uncertain = false;
  bool _settlementRefreshSent = false;

  RoomSnapshot? get snapshot => _reducer.current;
  List<ChatMessage> get chat => List.unmodifiable(_chat);
  List<ChatAnimation> get animations => List.unmodifiable(_animations);
  bool get busy => _uncertain || _pending.values.any((p) => p.mutation);
  bool get connected =>
      state == RoomConnectionState.connected ||
      state == RoomConnectionState.recovered;
  bool get canSend => connected && !busy && snapshot != null;
  int get highestVersion => _reducer.highestVersion;
  String? get roomId => _room?.id;

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  void clearError() {
    error = null;
    _notify();
  }

  Future<void> join(RoomSummary room) async {
    if (_disposed) {
      throw const AppFailure('closed', 'This room connection has closed.');
    }
    if (_socket != null || _room != null) {
      throw const AppFailure(
        'busy',
        'Leave the current room before joining another.',
      );
    }
    _room = room;
    _closing = false;
    _settlementRefreshSent = false;
    _attempts = 0;
    await _connect(recovery: false);
  }

  Future<void> _connect({required bool recovery}) async {
    if (_disposed || _closing || _room == null) return;
    if (!config.isConfigured) {
      throw const AppFailure(
        'configuration',
        'Add a server configuration to join a room.',
      );
    }
    final generation = ++_generation;
    state = recovery
        ? RoomConnectionState.reconnecting
        : RoomConnectionState.connecting;
    error = null;
    _notify();
    try {
      final token = await tokenProvider();
      if (generation != _generation || _disposed || _closing) return;
      if (token == null || token.isEmpty) {
        throw const AppFailure(
          'session_expired',
          'Please sign in again to rejoin.',
        );
      }
      var connectExpired = false;
      final appCheckToken = appCheckTokenProvider == null
          ? null
          : await appCheckTokenProvider!();
      if (generation != _generation || _disposed || _closing) return;
      final connection = _connector(
        config.websocketUrl,
        token,
        appCheckToken,
      ).then((socket) {
        if (connectExpired ||
            generation != _generation ||
            _disposed ||
            _closing) {
          unawaited(socket.close());
          throw const AppFailure('closed', 'Connection attempt was replaced.');
        }
        return socket;
      });
      final socket = await connection.timeout(
        connectTimeout,
        onTimeout: () {
          connectExpired = true;
          throw const AppFailure(
            'timeout',
            'The room connection took too long.',
          );
        },
      );
      _socket = socket;
      _joinReady = Completer<void>();
      _subscription = socket.messages.listen(
        (message) => _receive(message, generation),
        onDone: () => _transportLost(generation),
        onError: (Object _) => _transportLost(generation),
        cancelOnError: true,
      );
      state = recovery
          ? RoomConnectionState.rejoining
          : RoomConnectionState.connecting;
      _notify();
      // Join completes only on a valid personalized snapshot. An ACK alone does
      // not make a stale room actionable, and a lost ACK does not undo a join.
      unawaited(
        _sendCommand('room.join', {
          'player_id': playerId,
        }, internal: true).catchError((Object failure) {
          if (_joinReady?.isCompleted == false) {
            _joinReady!.completeError(failure);
          }
          return <String, dynamic>{};
        }),
      );
      await _joinReady!.future.timeout(commandTimeout);
      if (generation != _generation || _disposed || _closing) return;
      _attempts = 0;
      _uncertain = false;
      state = recovery
          ? RoomConnectionState.recovered
          : RoomConnectionState.connected;
      _notify();
      if (recovery) {
        _recoveredTimer?.cancel();
        _recoveredTimer = Timer(const Duration(seconds: 3), () {
          if (generation == _generation &&
              state == RoomConnectionState.recovered) {
            state = RoomConnectionState.connected;
            _notify();
          }
        });
      }
      _refreshEconomy();
    } catch (failure) {
      if (generation != _generation || _disposed || _closing) {
        if (!recovery && !_disposed) {
          throw error ??
              const AppFailure(
                'closed',
                'The room connection was interrupted.',
              );
        }
        return;
      }
      final normalized = failure is AppFailure
          ? failure
          : const AppFailure(
              'offline',
              'We could not reach the room. Check your connection.',
            );
      error = normalized;
      if (normalized.isUnauthorized) {
        await _terminal(RoomConnectionState.sessionExpired, normalized);
      } else if (normalized.isMaintenance) {
        await _terminal(RoomConnectionState.maintenance, normalized);
      } else if (const [
        'not_found',
        'room_conflict',
        'not_joined',
        'player_does_not_exist_in_room',
      ].contains(normalized.code)) {
        await _terminal(RoomConnectionState.roomUnavailable, normalized);
      } else if (recovery) {
        await _disconnectTransport();
        _scheduleReconnect();
      } else {
        // Initial join is a paid mutation. Never retry it automatically after
        // a timeout, because the server may already have debited the entry fee.
        await _terminal(
          RoomConnectionState.roomUnavailable,
          AppFailure(
            normalized.code,
            normalized.uncertain || _socket != null
                ? 'Your join could not be confirmed. Check your balance before joining again.'
                : normalized.message,
            uncertain: normalized.uncertain,
          ),
        );
      }
      if (!recovery) throw error ?? normalized;
    }
  }

  Future<Map<String, dynamic>> command(
    String type, {
    Map<String, dynamic>? payload,
  }) async {
    if (!connected || _socket == null) {
      throw const AppFailure(
        'offline',
        'Wait for the room to reconnect before taking an action.',
      );
    }
    if (busy && type != 'room.snapshot') {
      throw const AppFailure(
        'busy',
        'Your previous action is still being checked.',
      );
    }
    if (const {
      'bhabhi.play_card',
      'daketi.play_card',
      'tc.discard',
      'bluff.play_cards',
    }.contains(type)) {
      audio.playSfx('play_card');
    }
    if (type == 'game.drawStock') audio.playSfx('draw_stock');
    return _sendCommand(type, payload);
  }

  Future<Map<String, dynamic>> _sendCommand(
    String type,
    Map<String, dynamic>? payload, {
    bool internal = false,
  }) {
    final socket = _socket;
    if (socket == null || _room == null) {
      return Future.error(
        const AppFailure('offline', 'The room connection is unavailable.'),
      );
    }
    final id = '${DateTime.now().microsecondsSinceEpoch}-${++_serial}';
    final completer = Completer<Map<String, dynamic>>();
    final mutation = type != 'room.snapshot';
    final timer = Timer(commandTimeout, () {
      final pending = _pending.remove(id);
      if (pending == null) return;
      final failure = AppFailure(
        'timeout',
        mutation
            ? 'The action may have reached the room. We are checking the latest state.'
            : 'The room did not send an update. Try reconnecting.',
        uncertain: mutation,
      );
      error = failure;
      if (mutation && type != 'room.join') _uncertain = true;
      if (!completer.isCompleted) completer.completeError(failure);
      if (mutation && type != 'room.join' && connected) {
        unawaited(requestSnapshot().catchError((Object _) {}));
      }
      _notify();
    });
    _pending[id] = _Pending(type, completer, timer, mutation);
    try {
      socket.send(
        jsonEncode({
          'v': 1,
          'request_id': id,
          'type': type,
          'room_id': _room!.id,
          'payload': ?payload,
        }),
      );
    } catch (_) {
      _pending.remove(id);
      timer.cancel();
      final failure = AppFailure(
        'offline',
        'The connection closed while sending. We will check the latest state.',
        uncertain: mutation,
      );
      error = failure;
      _uncertain = mutation;
      completer.completeError(failure);
      _transportLost(_generation);
    }
    if (!internal) _notify();
    return completer.future;
  }

  Future<void> requestSnapshot() async {
    if (_socket == null) {
      throw const AppFailure('offline', 'Reconnect to check the latest room.');
    }
    await _sendCommand('room.snapshot', null, internal: true);
  }

  void _receive(Object? data, int generation) {
    if (_disposed || generation != _generation || data is! String) return;
    try {
      final message = jsonObject(jsonDecode(data));
      if (message['v'] != 1) {
        throw const FormatException('Unsupported protocol');
      }
      final type = jsonString(message['type']);
      final id = jsonString(message['request_id']);
      final room = jsonString(message['room_id']);
      if (room.isNotEmpty && room != _room?.id) return;
      final payload = message['payload'] == null
          ? <String, dynamic>{}
          : jsonObject(message['payload']);
      switch (type) {
        case 'ack':
          final pending = _pending[id];
          if (pending == null || payload['command'] != pending.type) return;
          _pending.remove(id);
          pending.timer.cancel();
          pending.completer.complete(payload);
          if (pending.type == 'chat.anim') _refreshEconomy();
        case 'error':
          final failure = AppFailure.fromServer(
            jsonString(payload['code']),
            serverMessage: jsonString(payload['message']),
          );
          error = failure;
          final pending = _pending.remove(id);
          pending?.timer.cancel();
          if (pending != null && !pending.completer.isCompleted) {
            pending.completer.completeError(failure);
          }
          if (failure.isMaintenance) {
            unawaited(_terminal(RoomConnectionState.maintenance, failure));
          } else if (failure.isUnauthorized) {
            unawaited(_terminal(RoomConnectionState.sessionExpired, failure));
          } else if (const [
                'not_found',
                'not_joined',
                'player_does_not_exist_in_room',
              ].contains(failure.code) ||
              pending?.type == 'room.join' && failure.code == 'room_conflict') {
            unawaited(_terminal(RoomConnectionState.roomUnavailable, failure));
          }
        case 'room.snapshot':
          final next = RoomSnapshot.fromJson(payload);
          final previous = snapshot;
          final oldTurn = snapshot?.currentPlayerId;
          final oldPlayers = snapshot?.players.length ?? 0;

          final accepted = _reducer.apply(next, roomId: _room!.id);

          if (accepted && snapshot != null) {
            final newTurn = snapshot!.currentPlayerId;
            if (newTurn != oldTurn && newTurn.isNotEmpty) {
              if (newTurn == playerId) {
                audio.playSfx('my_turn');
              } else {
                audio.playSfx('next_player_turn');
              }
            }
            if (snapshot!.players.length > oldPlayers) {
              audio.playSfx('new_player_joined_room');
            }
          }

          final pending = _pending[id];
          if (pending != null && pending.type == 'room.snapshot') {
            _pending.remove(id);
            pending.timer.cancel();
            if (next.room.version >= highestVersion &&
                next.you.id == playerId) {
              _uncertain = false;
              pending.completer.complete(<String, dynamic>{});
            } else {
              pending.completer.completeError(
                const AppFailure(
                  'stale_snapshot',
                  'The room sent an older state. Please request an update.',
                ),
              );
            }
          }
          if (!accepted) return;
          if (previous != null) _playSnapshotSounds(previous, snapshot!);
          _uncertain = false;
          if (_joinReady?.isCompleted == false) {
            _joinReady!.complete();
            // Snapshot is sufficient proof of admission when its ACK was lost.
            for (final entry
                in _pending.entries
                    .where((e) => e.value.type == 'room.join')
                    .toList()) {
              _pending.remove(entry.key);
              entry.value.timer.cancel();
              entry.value.completer.complete({'command': 'room.join'});
            }
          }
          if (snapshot!.room.isFinished && !_settlementRefreshSent) {
            _settlementRefreshSent = true;
            audio.playSfx('winners_appear_in_room');
            _refreshEconomy();
          }
        case 'chat.message':
          final item = ChatMessage.fromJson(payload);
          if (!_chat.any((existing) => existing.id == item.id)) {
            _chat.add(item);
            if (_chat.length > 150) _chat.removeRange(0, _chat.length - 150);
            if (item.playerId != playerId) audio.playSfx('chat_new_message');
          }
        case 'chat.anim':
          final item = ChatAnimation.fromJson(payload);
          if (!_animations.any(
            (existing) => existing.deduplicationKey == item.deduplicationKey,
          )) {
            _animations.add(item);
            if (_animations.length > 20) _animations.removeAt(0);
          }
          if (item.fromPlayer == playerId) _refreshEconomy();
        default:
          // Forward-compatible unknown event types never change game state.
          return;
      }
      _notify();
    } catch (_) {
      error = const AppFailure(
        'malformed_response',
        'An unreadable room update was ignored. Request a fresh room.',
      );
      _notify();
    }
  }

  void _refreshEconomy() {
    if (onEconomyChanged != null) {
      unawaited(
        onEconomyChanged!().catchError((Object _) {
          if (!_disposed) {
            error = const AppFailure(
              'profile_refresh',
              'Your balance could not be refreshed yet. Check it again from your profile.',
            );
            _notify();
          }
        }),
      );
    }
  }

  void _playSnapshotSounds(RoomSnapshot previous, RoomSnapshot next) {
    final previousState = previous.gameState;
    final nextState = next.gameState;
    final cardAdded = switch ((previousState, nextState)) {
      (BhabhiState previous, BhabhiState next) =>
        next.trick.length > previous.trick.length ||
            (next.trick.isNotEmpty &&
                previous.trick.isNotEmpty &&
                next.trick.length < previous.trick.length),
      (DaketiState previous, DaketiState next) =>
        next.playArea.length > previous.playArea.length,
      (TcState previous, TcState next) =>
        next.discardCount > previous.discardCount,
      (BluffState previous, BluffState next) =>
        next.pileCount > previous.pileCount,
      _ => false,
    };
    if (cardAdded) audio.playSfx('new_card_added_in_play_area');

    final stockDecreased = switch ((previousState, nextState)) {
      (DaketiState prev, DaketiState next) =>
        next.stockCount < prev.stockCount,
      (TcState prev, TcState next) => next.stockCount < prev.stockCount,
      _ => false,
    };
    if (stockDecreased) {
      audio.playSfx('draw_stock');
      onStockDecreased?.call();
    }

    final playAreaDecreased = switch ((previousState, nextState)) {
      (DaketiState prev, DaketiState next) =>
        next.playArea.length < prev.playArea.length,
      _ => false,
    };
    if (playAreaDecreased) audio.playSfx('new_card_added_in_play_area');
  }

  void _transportLost(int generation) {
    if (generation != _generation || _disposed || _closing) return;
    ++_generation;
    final lostSocket = _socket;
    _socket = null;
    _subscription = null;
    if (lostSocket != null) {
      unawaited(lostSocket.close().catchError((Object _) {}));
    }
    _failPending(
      const AppFailure(
        'offline',
        'Connection lost. Your last action may have reached the room.',
        uncertain: true,
      ),
    );
    if (_joinReady?.isCompleted == false) {
      _joinReady!.completeError(
        const AppFailure(
          'offline',
          'The join could not be confirmed.',
          uncertain: true,
        ),
      );
    }
    if (snapshot?.room.isFinished == true) {
      state = RoomConnectionState.closed;
      _notify();
      return;
    }
    if (snapshot == null || snapshot!.room.isWaiting) {
      state = RoomConnectionState.roomUnavailable;
      error = const AppFailure(
        'seat_recovery_unavailable',
        'The connection was lost. This server removes waiting seats, so check your balance before joining again.',
      );
      _notify();
      return;
    }
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_disposed || _closing) return;
    _retryTimer?.cancel();
    if (_attempts >= maxReconnectAttempts) {
      state = RoomConnectionState.offline;
      error = const AppFailure(
        'offline',
        'We could not reconnect. Your last room is saved here; retry when your connection improves.',
      );
      _notify();
      return;
    }
    state = RoomConnectionState.reconnecting;
    final delay =
        min(30000, reconnectBase.inMilliseconds * pow(2, _attempts).toInt()) +
        (reconnectJitter.inMilliseconds > 0
            ? _random.nextInt(reconnectJitter.inMilliseconds)
            : 0);
    _attempts++;
    _retryTimer = Timer(Duration(milliseconds: delay), () {
      unawaited(_connect(recovery: true));
    });
    _notify();
  }

  Future<void> retryConnection() async {
    if (_disposed || _closing || _room == null || connected) return;
    if (snapshot == null || snapshot!.room.isWaiting) {
      throw const AppFailure(
        'seat_recovery_unavailable',
        'Please return to the lobby and confirm your balance before joining again.',
      );
    }
    _retryTimer?.cancel();
    _attempts = 0;
    await _disconnectTransport();
    await _connect(recovery: true);
  }

  void _failPending(AppFailure failure) {
    final pending = _pending.values.toList();
    _pending.clear();
    for (final item in pending) {
      item.timer.cancel();
      if (!item.completer.isCompleted) item.completer.completeError(failure);
    }
  }

  Future<void> _disconnectTransport() async {
    ++_generation;
    final subscription = _subscription;
    _subscription = null;
    final socket = _socket;
    _socket = null;
    await subscription?.cancel();
    try {
      await socket?.close();
    } catch (_) {
      /* transport already closed */
    }
  }

  Future<void> _terminal(RoomConnectionState next, AppFailure failure) async {
    _retryTimer?.cancel();
    _recoveredTimer?.cancel();
    state = next;
    error = failure;
    _failPending(failure);
    if (_joinReady?.isCompleted == false) _joinReady!.completeError(failure);
    await _disconnectTransport();
    _notify();
  }

  Future<void> leave() async {
    if (_disposed) return;
    _closing = true;
    _retryTimer?.cancel();
    _recoveredTimer?.cancel();
    AppFailure? failure;
    if (_socket != null && snapshot?.room.isFinished != true) {
      try {
        await _sendCommand('room.leave', null, internal: true);
      } on AppFailure catch (e) {
        failure = e;
      }
    }
    await _disconnectTransport();
    _failPending(const AppFailure('closed', 'You have left the room.'));
    _room = null;
    _uncertain = false;
    state = RoomConnectionState.closed;
    if (failure != null) error = failure;
    _refreshEconomy();
    _notify();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (connected) {
        unawaited(requestSnapshot().catchError((Object _) {}));
      } else if (this.state == RoomConnectionState.offline) {
        unawaited(retryConnection().catchError((Object _) {}));
      }
    }
    // Do not close a healthy socket merely on pause: the current backend
    // treats transport close as forfeiture. The OS can still interrupt it.
  }

  @override
  void dispose() {
    _disposed = true;
    _closing = true;
    _retryTimer?.cancel();
    _recoveredTimer?.cancel();
    if (_observeLifecycle) WidgetsBinding.instance.removeObserver(this);
    _failPending(const AppFailure('closed', 'The room connection has closed.'));
    if (_joinReady?.isCompleted == false) {
      _joinReady!.completeError(
        const AppFailure('closed', 'The room connection has closed.'),
      );
    }
    unawaited(_disconnectTransport());
    super.dispose();
  }
}
