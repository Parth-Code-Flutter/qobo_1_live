import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/chat_detail_controller.dart';
import '../widgets/chat_timeline_message_widget.dart';

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
                    return ChatTimelineMessageWidget(entry: entries[index]);
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
