import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/emoji_celebration_overlay.dart';

/// Direct emoji picker for audio/video room members.
///
/// Unlike gifts, emojis are intentionally sent to a selected user only.
class EmojiPickerBottomSheet extends GetView<LiveBroadcastController> {
  const EmojiPickerBottomSheet({super.key});

  static const _sheetColor = Color(0xFF10111F);
  static const _pink = Color(0xFFFF3F8B);
  static const _purple = Color(0xFF7C4DFF);
  static const _gold = Color(0xFFFFD84D);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.68;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 16),
      decoration: const BoxDecoration(
        color: _sheetColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ),
          Spacing.v16,
          Obx(() {
            final name = controller.selectedEmojiReceiverName.value?.trim();
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    _pink.withValues(alpha: 0.18),
                    _purple.withValues(alpha: 0.16),
                  ],
                ),
                border: Border.all(color: _pink.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.emoji_emotions_rounded,
                    color: _gold,
                    size: 22,
                  ),
                  Spacing.h10,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SemiBoldText(
                          text: 'Send emoji',
                          fontSize: TextStyles.k16FontSize,
                          color: kColorWhite,
                        ),
                        Spacing.v2,
                        AppText(
                          text: name?.isNotEmpty == true
                              ? 'Shown only to $name'
                              : 'Shown only to selected user',
                          fontSize: TextStyles.k12FontSize,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          Spacing.v16,
          Expanded(
            child: Obx(() {
              if (controller.isLoadingEmojis.value &&
                  controller.emojiCatalog.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: _pink),
                );
              }

              final emojis = controller.emojiCatalog;
              if (emojis.isEmpty) {
                return const Center(
                  child: AppText(
                    text: 'No emojis available right now',
                    fontSize: TextStyles.k14FontSize,
                    color: Colors.white70,
                  ),
                );
              }

              return GridView.builder(
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.86,
                ),
                itemCount: emojis.length,
                itemBuilder: (context, index) {
                  final emoji = emojis[index];
                  return _EmojiTile(
                    emoji: emoji,
                    onTap: () => controller.sendEmoji(emoji),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _EmojiTile extends StatelessWidget {
  const _EmojiTile({required this.emoji, required this.onTap});

  final Map<String, String> emoji;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final image = (emoji['image']?.trim().isNotEmpty == true
        ? emoji['image']!
        : emoji['code'] ?? '😊');
    final name = emoji['name']?.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: Colors.white.withValues(alpha: 0.06),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
            child: Column(
              children: [
                Expanded(
                  child: EmojiMediaView(
                    image: image,
                    emojiFontSize: 34,
                    fit: BoxFit.contain,
                  ),
                ),
                Spacing.v6,
                SemiBoldText(
                  text: name?.isNotEmpty == true ? name! : 'Emoji',
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  align: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
