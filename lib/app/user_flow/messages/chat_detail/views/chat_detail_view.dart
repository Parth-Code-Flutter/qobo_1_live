import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/app_widgets/direct_gift_bottom_sheet.dart';
import 'package:qobo_one_live/utils/app_widgets/emoji_catalog_bottom_sheet.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/chat_detail_controller.dart';
import '../widgets/chat_detail_theme.dart';
import '../widgets/chat_timeline_message_widget.dart';

class ChatDetailView extends GetView<ChatDetailController> {
  const ChatDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ChatDetailTheme.scaffold,
      appBar: PreferredSize(
        preferredSize: const CommonAppBarWidget(title: '').preferredSize,
        child: Obx(
          () => CommonAppBarWidget(
            title: controller.chatName.value,
            subtitle: controller.presenceStatusLabel,
            onTitleTap: controller.openContactProfile,
            actions: [
              _ChatAppBarAction(
                icon: Icons.call_rounded,
                onTap: () => controller.startVoiceCall(context),
              ),
              const SizedBox(width: 4),
              _ChatAppBarAction(
                icon: Icons.videocam_rounded,
                onTap: () => controller.startVideoCall(context),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: ChatDetailTheme.bodyGradient),
        child: Column(
          children: [
            Expanded(
              child: Obx(() {
                if (controller.isLoading.value) {
                  return const _ChatLoadingState();
                }
                if (controller.timelineEntries.isEmpty &&
                    controller.messages.isEmpty) {
                  return _ChatEmptyState(name: controller.chatName.value);
                }
                final entries = controller.timelineEntries;
                return ListView.builder(
                  controller: controller.scrollController,
                  reverse: true,
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[entries.length - 1 - index];
                    return ChatTimelineMessageWidget(entry: entry);
                  },
                );
              }),
            ),
            Obx(_buildTypingBanner),
            _buildMessageInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingBanner() {
    if (!controller.peerIsTyping.value) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          decoration: BoxDecoration(
            color: kColorWhite.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: ChatDetailTheme.paleBorder),
          ),
          child: AppText(
            text: '${controller.chatName.value} is typing...',
            fontSize: TextStyles.k10FontSize,
            color: ChatDetailTheme.plum,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        10,
        12,
        MediaQuery.paddingOf(context).bottom + 10,
      ),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.94),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        border: const Border(top: BorderSide(color: Color(0xFFFFE0EF))),
        boxShadow: [
          BoxShadow(
            color: ChatDetailTheme.rose.withValues(alpha: 0.1),
            offset: const Offset(0, -8),
            blurRadius: 24,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _ComposerButton(
            icon: Icons.emoji_emotions_outlined,
            tooltip: 'Send emoji',
            onTap: _showEmojiSheet,
            compact: true,
          ),
          const SizedBox(width: 6),
          _ComposerButton(
            icon: Icons.card_giftcard_rounded,
            tooltip: 'Send gift',
            onTap: _showGiftSheet,
            compact: true,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              decoration: BoxDecoration(
                color: ChatDetailTheme.composerField,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFFD8EA)),
              ),
              child: TextField(
                controller: controller.messageController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                style: TextStyles.kRegularPoppins(
                  fontSize: TextStyles.k12FontSize,
                  colors: kColorText,
                ),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyles.kRegularPoppins(
                    fontSize: TextStyles.k12FontSize,
                    colors: const Color(0xFF8A7895),
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 13,
                  ),
                ),
              ),
            ),
          ),
          Spacing.h8,
          _ComposerButton(
            icon: Icons.send_rounded,
            tooltip: 'Send message',
            onTap: controller.sendMessage,
            emphasized: true,
          ),
        ],
      ),
    );
  }

  Future<void> _showEmojiSheet() async {
    if (!await controller.prepareRichMessage()) {
      Get.snackbar(
        'Emoji not available',
        'The chat is still being prepared. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    if (controller.emojiCatalog.isEmpty) {
      unawaited(controller.loadEmojiCatalog());
    }
    await Get.bottomSheet<void>(
      Obx(
        () => EmojiCatalogBottomSheet(
          items: controller.emojiCatalog.toList(),
          isLoading: controller.isLoadingEmojis.value,
          subtitle: 'Pick a reaction to share in this chat',
          onTap: controller.sendEmoji,
        ),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.58),
    );
  }

  Future<void> _showGiftSheet() async {
    if (!await controller.prepareRichMessage()) {
      Get.snackbar(
        'Gift not available',
        'The chat is still being prepared. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    await DirectGiftBottomSheet.show(
      receiverId: controller.targetId.value,
      receiverName: controller.chatName.value,
      roomId: controller.activeRoomId,
      sessionType: 'chat',
      onSent: controller.recordSentGift,
    );
  }
}

class _ChatAppBarAction extends StatelessWidget {
  const _ChatAppBarAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: kColorWhite.withValues(alpha: 0.18),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(icon, color: kColorWhite, size: 19),
          ),
        ),
      ),
    );
  }
}

class _ComposerButton extends StatelessWidget {
  const _ComposerButton({
    required this.icon,
    required this.onTap,
    this.emphasized = false,
    this.compact = false,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool emphasized;
  final bool compact;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 40.0 : 46.0;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: emphasized ? null : ChatDetailTheme.composerField,
              gradient: emphasized ? ChatDetailTheme.outgoingGradient : null,
              border: emphasized
                  ? null
                  : Border.all(color: const Color(0xFFFFD8EA)),
              boxShadow: emphasized
                  ? [
                      BoxShadow(
                        color: ChatDetailTheme.rose.withValues(alpha: 0.24),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: emphasized ? kColorWhite : ChatDetailTheme.plum,
              size: compact ? 19 : 21,
            ),
          ),
        ),
      ),
    );
  }
}

class _ChatLoadingState extends StatelessWidget {
  const _ChatLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: const SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          color: ChatDetailTheme.rose,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 42),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [ChatDetailTheme.lilac, ChatDetailTheme.rose],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: ChatDetailTheme.rose.withValues(alpha: 0.24),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.chat_bubble_rounded,
                color: kColorWhite,
                size: 32,
              ),
            ),
            Spacing.v16,
            SemiBoldText(
              text: 'Start the conversation',
              fontSize: TextStyles.k18FontSize,
              color: kColorText,
              align: TextAlign.center,
            ),
            Spacing.v6,
            AppText(
              text: 'Say hello to $name. Messages will appear here.',
              fontSize: TextStyles.k12FontSize,
              color: kColorHint,
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
