import '../../core/audio/audio_system.dart';

import 'package:taash/l10n/copy.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/taash_theme.dart';
import '../../core/widgets/taash_widgets.dart';
import '../../core/websocket/room_session.dart';

class ChatSheet extends StatefulWidget {
  const ChatSheet({
    super.key,
    required this.session,
    required this.muted,
    required this.onMuteChanged,
    this.allowed = true,
  });
  final RoomSession session;
  final bool muted, allowed;
  final ValueChanged<bool> onMuteChanged;
  @override
  State<ChatSheet> createState() => _ChatSheetState();
}

class _ChatSheetState extends State<ChatSheet> {
  final _text = TextEditingController();
  bool _muted = false, _accepted = false, _sending = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _muted = widget.muted;
    widget.session.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.session.removeListener(_changed);
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final message = _text.text.trim();
    if (message.isEmpty) return;
    if (message.runes.length > 150) {
      setState(() => _error = Copy.keepYourMessageTo150Characters);
      return;
    }
    if (RegExp(
      r'(https?://|www\.|\b[a-z0-9-]+\.(com|net|org|io|co)\b)',
      caseSensitive: false,
    ).hasMatch(message)) {
      setState(() => _error = Copy.linksAreNotAllowedInRoomChat);
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await widget.session.command('chat.send', payload: {'text': message});
      audio.playSfx('chat_send_message');
      if (mounted) _text.clear();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              widget.session.error?.message ??
              Copy.yourMessageWasNotConfirmedCheckChat,
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = widget.session.chat;
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .72,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 12, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        Copy.aroundTheRoom,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: _muted ? Copy.unmuteRoomChat : Copy.muteRoomChat,
                      onPressed: () {
                        setState(() => _muted = !_muted);
                        widget.onMuteChanged(_muted);
                      },
                      icon: Icon(
                        _muted
                            ? Icons.volume_off_outlined
                            : Icons.volume_up_outlined,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.allowed)
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(Copy.chatIsUnavailableForThisBuild),
                ),
              Expanded(
                child: _muted
                    ? const TaashEmpty(
                        title: 'A quieter room',
                        message: Copy.messagesAndReactionsAreHiddenOnThis,
                        icon: Icons.volume_off_outlined,
                      )
                    : chat.isEmpty
                    ? const TaashEmpty(
                        title: Copy.sayAFriendlyHello,
                        message: Copy.messagesAreSharedWithEveryoneAtThis,
                        icon: Icons.forum_outlined,
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 8,
                        ),
                        itemCount: chat.length,
                        itemBuilder: (context, index) {
                          final message = chat[chat.length - 1 - index];
                          final mine =
                              message.playerId == widget.session.playerId;
                          return Align(
                            alignment: mine
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 310),
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: mine ? T.mint : T.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    mine ? Copy.you : message.displayName,
                                    style: TextStyle(
                                      fontWeight: mine
                                          ? FontWeight.w900
                                          : FontWeight.w800,
                                      fontSize: 11,
                                      color: mine ? T.pine : T.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  SelectableText(message.text),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (!_accepted && widget.allowed)
                CheckboxListTile(
                  value: _accepted,
                  onChanged: (v) => setState(() => _accepted = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  title: const Text(
                    Copy.keepItFriendlyNoAbuseLinksOr,
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: Text(_error!, style: const TextStyle(color: T.danger)),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 8, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        enabled: widget.allowed && !_muted,
                        maxLines: 3,
                        minLines: 1,
                        inputFormatters: [_RuneLimit(150)],
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: Copy.messageTheRoom,
                          counterText: '${_text.text.runes.length}/150',
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: Copy.sendMessage,
                      onPressed:
                          widget.allowed &&
                              _accepted &&
                              !_muted &&
                              !_sending &&
                              widget.session.connected &&
                              _text.text.trim().isNotEmpty
                          ? _send
                          : null,
                      icon: _sending
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded, color: T.coral),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RuneLimit extends TextInputFormatter {
  _RuneLimit(this.limit);
  final int limit;
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) => newValue.text.runes.length <= limit ? newValue : oldValue;
}
