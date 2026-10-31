import 'dart:async';

import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:zego_uikit/zego_uikit.dart';

/// Live-style chat over a video call. Messages stay in the call room only.
/// Positioning is owned by the call screen so this only draws the bubbles
/// and the composer.
class VideoCallChatOverlay extends StatefulWidget {
  const VideoCallChatOverlay({super.key});

  @override
  State<VideoCallChatOverlay> createState() => _VideoCallChatOverlayState();
}

class _VideoCallChatOverlayState extends State<VideoCallChatOverlay> {
  final _text = TextEditingController();
  StreamSubscription<List<ZegoInRoomMessage>>? _list;
  var _messages = <ZegoInRoomMessage>[];
  var _sending = false;

  @override
  void initState() {
    super.initState();
    _messages = List<ZegoInRoomMessage>.of(ZegoUIKit().getInRoomMessages());
    _list = ZegoUIKit().getInRoomMessageListStream().listen((messages) {
      if (!mounted) return;
      setState(() => _messages = List<ZegoInRoomMessage>.of(messages));
    });
  }

  @override
  void dispose() {
    unawaited(_list?.cancel());
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _text.clear();
    final sent = await ZegoUIKit().sendInRoomMessage(text);
    if (!mounted) return;
    setState(() => _sending = false);
    if (!sent) {
      AppToast.showError(context, 'Message did not send. Try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final localId = ZegoUIKit().getLocalUser().id;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_messages.isEmpty)
          const _CallChatBubble(sender: '', text: 'Say hi…', hint: true)
        else
          SizedBox(
            height: 112,
            width: MediaQuery.sizeOf(context).width * 0.72,
            child: ListView.separated(
              reverse: true,
              padding: EdgeInsets.zero,
              itemCount: _messages.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final message = _messages[_messages.length - 1 - index];
                final mine = message.user.id == localId;
                final name = message.user.name.trim();
                return _CallChatBubble(
                  sender: mine ? 'You' : (name.isEmpty ? 'Guest' : name),
                  text: message.message,
                );
              },
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                minLines: 1,
                maxLines: 1,
                maxLength: 200,
                textInputAction: TextInputAction.send,
                style: const TextStyle(color: kColorWhite, fontSize: 14),
                cursorColor: const Color(0xFFFF8AC0),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Say something...',
                  hintStyle: TextStyle(
                    color: kColorWhite.withValues(alpha: 0.55),
                    fontSize: 14,
                  ),
                  filled: true,
                  fillColor: const Color(0xCC1A1030),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
            IconButton(
              onPressed: _sending ? null : _send,
              icon: const Icon(
                Icons.send_rounded,
                color: kColorWhite,
                size: 22,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
        ),
      ],
    );
  }
}

class _CallChatBubble extends StatelessWidget {
  const _CallChatBubble({
    required this.sender,
    required this.text,
    this.hint = false,
  });

  final String sender;
  final String text;
  final bool hint;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xB31A1030),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
        ),
        child: hint
            ? AppText(
                text: text,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.72),
              )
            : RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$sender: ',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: sender == 'You'
                            ? const Color(0xFFFF8AC0)
                            : const Color(0xFFFF79B4),
                        fontSize: 13,
                      ),
                    ),
                    TextSpan(
                      text: text,
                      style: const TextStyle(color: kColorWhite, fontSize: 13),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
