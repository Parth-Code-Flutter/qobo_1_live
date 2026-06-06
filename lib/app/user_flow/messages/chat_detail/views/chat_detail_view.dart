import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
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
        child: Obx(
          () => CommonAppBarWidget(
            title: controller.chatName.value,
            useMaterialAppBar: true,
            actions: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.call_rounded, color: kColorText),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.videocam_rounded, color: kColorText),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
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
                if (controller.messages.isEmpty) {
                  return const _ChatEmptyState();
                }
                return ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: controller.messages.length,
                  separatorBuilder: (_, __) => Spacing.v16,
                  itemBuilder: (context, index) {
                    final msg = controller.messages[index];
                    return _buildMessageBubble(msg);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(context),
        ],
      ),
    );
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
          AppText(text: msg.time, fontSize: 10, color: kColorHint),
        ],
      ),
    );
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
            decoration: BoxDecoration(
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
