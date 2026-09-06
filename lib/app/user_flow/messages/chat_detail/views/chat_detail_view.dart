import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/chat_detail_controller.dart';
import '../widgets/chat_timeline_message_widget.dart';

class ChatDetailView extends GetView<ChatDetailController> {
  const ChatDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(76),
          child: Obx(() => _buildChatAppBar(context)),
        ),
        body: Column(
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
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
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

  Widget _buildChatAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF24113D).withValues(alpha: 0.96),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      toolbarHeight: 76,
      titleSpacing: 0,
      leadingWidth: 54,
      leading: Padding(
        padding: const EdgeInsets.only(left: 10),
        child: _HeaderIconButton(
          icon: Icons.arrow_back_ios_new_rounded,
          onTap: Get.back,
        ),
      ),
      title: InkWell(
        onTap: controller.openContactProfile,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
          child: Row(
            children: [
              AppUserAvatar(
                name: controller.chatName.value,
                imageUrl: controller.chatImageUrl.value,
                size: 43,
                border: Border.all(
                  color: kColorProfileChipPinkStart.withValues(alpha: 0.8),
                  width: 1.5,
                ),
              ),
              Spacing.h10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SemiBoldText(
                      text: controller.chatName.value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      fontSize: TextStyles.k16FontSize,
                      color: kColorWhite,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: controller.presenceStatusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: AppText(
                            text: controller.presenceStatusLabel,
                            fontSize: TextStyles.k10FontSize,
                            color: kColorWhite.withValues(alpha: 0.65),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        _HeaderIconButton(
          icon: Icons.call_rounded,
          onTap: () => controller.startVoiceCall(context),
        ),
        const SizedBox(width: 6),
        _HeaderIconButton(
          icon: Icons.videocam_rounded,
          onTap: () => controller.startVideoCall(context),
        ),
        const SizedBox(width: 12),
      ],
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
            color: kColorWhite.withValues(alpha: 0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: AppText(
            text: '${controller.chatName.value} is typing...',
            fontSize: TextStyles.k10FontSize,
            color: kColorProfileChipPinkStart,
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
        color: const Color(0xFF13091F).withValues(alpha: 0.98),
        border: Border(
          top: BorderSide(color: kColorWhite.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _ComposerButton(icon: Icons.add_rounded, onTap: () {}),
          Spacing.h8,
          Expanded(
            child: Container(
              constraints: const BoxConstraints(minHeight: 46),
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.09),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: kColorWhite.withValues(alpha: 0.11)),
              ),
              child: TextField(
                controller: controller.messageController,
                minLines: 1,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                style: TextStyles.kRegularPoppins(
                  fontSize: TextStyles.k12FontSize,
                  colors: kColorWhite,
                ),
                decoration: InputDecoration(
                  hintText: 'Write a message...',
                  hintStyle: TextStyles.kRegularPoppins(
                    fontSize: TextStyles.k12FontSize,
                    colors: kColorWhite.withValues(alpha: 0.42),
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
            onTap: controller.sendMessage,
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: kColorWhite.withValues(alpha: 0.09),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: kColorWhite, size: 19),
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
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: emphasized ? null : kColorWhite.withValues(alpha: 0.08),
            gradient: emphasized
                ? const LinearGradient(
                    colors: [
                      kColorProfileChipPinkStart,
                      kColorProfileChipPurpleStart,
                    ],
                  )
                : null,
          ),
          child: Icon(icon, color: kColorWhite, size: 21),
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
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1748),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
        ),
        child: const SizedBox(
          width: 25,
          height: 25,
          child: CircularProgressIndicator(
            color: kColorProfileChipPinkStart,
            strokeWidth: 2.5,
          ),
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
                  colors: [
                    kColorProfileChipPinkStart,
                    kColorProfileChipPurpleStart,
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.favorite_rounded,
                color: kColorWhite,
                size: 30,
              ),
            ),
            Spacing.v16,
            SemiBoldText(
              text: 'Start something meaningful',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v6,
            AppText(
              text: 'Say hello to $name and begin your conversation.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.58),
              align: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
