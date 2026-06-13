import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/services/chat/chat_inbox_preview.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/chat_detail_controller.dart';

class ChatDetailView extends GetView<ChatDetailController> {
  const ChatDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Obx(() => _buildChatAppBar(context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(
              () {
                if (controller.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(color: kColorPrimary),
                  );
                }
                if (controller.timelineEntries.isEmpty &&
                    controller.messages.isEmpty) {
                  return const _ChatEmptyState();
                }
                final entries = controller.timelineEntries;
                return ListView.builder(
                  controller: controller.scrollController,
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, index) {
                    final entry = entries[index];
                    if (entry.isDateHeader) {
                      return _buildDateHeader(entry.dateLabel!);
                    }
                    final msg = entry.message!;
                    if (msg.isCallEntry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCallLogEntry(msg),
                      );
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildMessageBubble(msg),
                    );
                  },
                );
              },
            ),
          ),
          Obx(() => _buildTypingBanner()),
          _buildMessageInput(context),
        ],
      ),
    );
  }

  Widget _buildChatAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: kColorWhite,
      elevation: 0,
      centerTitle: true,
      automaticallyImplyLeading: false,
      leadingWidth: 60,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: IconButton(
          onPressed: () => Get.back(),
          icon: SvgPicture.asset(kIconArrowBack),
        ),
      ),
      title: GestureDetector(
        onTap: controller.openContactProfile,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                controller.chatName.value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.kBoldPoppins(
                  fontSize: TextStyles.k18FontSize,
                  colors: kColorText,
                ),
              ),
              const SizedBox(height: 2),
              AppText(
                text: controller.presenceStatusLabel,
                fontSize: TextStyles.k12FontSize,
                color: controller.presenceStatusColor,
              ),
            ],
          ),
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => controller.startVoiceCall(context),
          icon: const Icon(Icons.call_rounded, color: kColorText),
        ),
        IconButton(
          onPressed: () => controller.startVideoCall(context),
          icon: const Icon(Icons.videocam_rounded, color: kColorText),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildTypingBanner() {
    if (!controller.peerIsTyping.value) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: AppText(
          text: '${controller.chatName.value} is typing...',
          fontSize: TextStyles.k12FontSize,
          color: kColorPrimary,
        ),
      ),
    );
  }

  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: kColorAppBackground,
            borderRadius: BorderRadius.circular(8),
          ),
          child: AppText(
            text: label,
            fontSize: TextStyles.k12FontSize,
            color: kColorHint,
          ),
        ),
      ),
    );
  }

  Widget _buildCallLogEntry(ChatMessageModel msg) {
    final accentColor = msg.isMissedCall
        ? const Color(0xFFE53935)
        : msg.isUnansweredCall
        ? const Color(0xFFE65100)
        : (msg.isMe ? kColorPrimary : kColorText);

    final bubbleFill = msg.isMe
        ? kColorPrimary.withValues(alpha: 0.14)
        : const Color(0xFFF3F4F8);

    final iconData = _callLogIcon(msg);

    String? subtitle;
    if (msg.isMissedCall) {
      subtitle = 'Missed call';
    } else if (msg.isUnansweredCall) {
      subtitle = 'No answer';
    } else {
      subtitle = ChatInboxPreviewType.callDurationLabel(msg.callDurationSeconds);
    }

    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: msg.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            constraints: const BoxConstraints(maxWidth: 240, minWidth: 168),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleFill,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg.isMe ? 16 : 4),
                bottomRight: Radius.circular(msg.isMe ? 4 : 16),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.16),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Icon(iconData, size: 18, color: accentColor),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SemiBoldText(
                        text: msg.text,
                        fontSize: TextStyles.k12FontSize,
                        color: accentColor,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null && subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        AppText(
                          text: subtitle,
                          fontSize: TextStyles.k10FontSize,
                          color: kColorHint,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          Spacing.v4,
          AppText(
            text: msg.time,
            fontSize: 10,
            color: kColorHint,
          ),
        ],
      ),
    );
  }

  IconData _callLogIcon(ChatMessageModel msg) {
    if (msg.isVideoCall) return Icons.videocam_rounded;
    if (msg.isMissedCall) return Icons.phone_missed_rounded;
    if (msg.isUnansweredCall) return Icons.phone_callback_rounded;
    return msg.isMe ? Icons.call_made_rounded : Icons.call_received_rounded;
  }

  Widget _buildMessageBubble(ChatMessageModel msg) {
    return Align(
      alignment: msg.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: msg.isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: const BoxConstraints(maxWidth: 280),
            decoration: BoxDecoration(
              color: msg.isMe ? kColorPrimary : kColorBackground,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(msg.isMe ? 16 : 0),
                bottomRight: Radius.circular(msg.isMe ? 0 : 16),
              ),
            ),
            child: AppText(
              text: msg.text,
              fontSize: TextStyles.k14FontSize,
              color: msg.isMe ? kColorWhite : kColorText,
            ),
          ),
          Spacing.v4,
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText(text: msg.time, fontSize: 10, color: kColorHint),
              if (msg.isMe) ...[
                const SizedBox(width: 4),
                _buildDeliveryIcon(msg.deliveryStatus),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryIcon(ChatDeliveryStatus status) {
    final Color color;
    final IconData icon;
    switch (status) {
      case ChatDeliveryStatus.read:
        color = Colors.lightBlueAccent;
        icon = Icons.done_all_rounded;
      case ChatDeliveryStatus.delivered:
        color = kColorHint;
        icon = Icons.done_all_rounded;
      case ChatDeliveryStatus.sent:
        color = kColorHint;
        icon = Icons.done_rounded;
    }
    return Icon(icon, size: 14, color: color);
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.paddingOf(context).bottom + 12,
      ),
      decoration: BoxDecoration(
        color: kColorWhite,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            offset: const Offset(0, -4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: kColorBackground,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.add_rounded, color: kColorHint),
          ),
          Spacing.h12,
          Expanded(
            child: AppTextField(
              controller: controller.messageController,
              hintText: 'Type a message...',
              fillColor: kColorBackground,
              inputBorderRadius: BorderRadius.circular(20),
            ),
          ),
          Spacing.h12,
          GestureDetector(
            onTap: controller.sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: kColorPrimary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.send_rounded,
                color: kColorWhite,
                size: 20,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatEmptyState extends StatelessWidget {
  const _ChatEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, color: kColorHint, size: 56),
          SizedBox(height: 12),
          SemiBoldText(
            text: 'No data found',
            fontSize: TextStyles.k16FontSize,
            color: kColorText,
            align: TextAlign.center,
          ),
          SizedBox(height: 6),
          AppText(
            text: 'Messages will appear here when available.',
            fontSize: TextStyles.k12FontSize,
            color: kColorHint,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
