import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/ui_utils/emoji_celebration_overlay.dart';

/// Shared API emoji catalog used by rooms and direct chat.
class EmojiCatalogBottomSheet extends StatelessWidget {
  const EmojiCatalogBottomSheet({
    super.key,
    required this.items,
    required this.isLoading,
    required this.onTap,
    this.title = 'Send emoji',
    this.subtitle = 'Pick a reaction to share',
  });

  final List<Map<String, String>> items;
  final bool isLoading;
  final ValueChanged<Map<String, String>> onTap;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Container(
      height: MediaQuery.sizeOf(context).height * 0.58,
      padding: EdgeInsets.fromLTRB(16, 10, 16, bottomInset + 16),
      decoration: AppLightUi.bottomSheetDecoration(topRadius: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppLightUi.borderStrong,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Spacing.v16,
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: AppLightUi.familyCtaGradient,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.emoji_emotions_rounded,
                  color: kColorWhite,
                  size: 22,
                ),
              ),
              Spacing.h10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: title,
                      fontSize: TextStyles.k16FontSize,
                      color: AppLightUi.title,
                    ),
                    AppText(
                      text: subtitle,
                      fontSize: TextStyles.k10FontSize,
                      color: AppLightUi.subtitle,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Spacing.v16,
          Expanded(child: _content()),
        ],
      ),
    );
  }

  Widget _content() {
    if (isLoading && items.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppLightUi.pink),
      );
    }
    if (items.isEmpty) {
      return const Center(
        child: AppText(
          text: 'No emojis available right now.',
          fontSize: TextStyles.k12FontSize,
          color: AppLightUi.subtitle,
          align: TextAlign.center,
        ),
      );
    }
    return GridView.builder(
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final emoji = items[index];
        final image = emoji['image']?.trim().isNotEmpty == true
            ? emoji['image']!
            : emoji['code'] ?? '😊';
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onTap(emoji),
            borderRadius: BorderRadius.circular(14),
            child: Ink(
              padding: const EdgeInsets.fromLTRB(7, 9, 7, 7),
              decoration: BoxDecoration(
                color: AppLightUi.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppLightUi.border),
              ),
              child: Column(
                children: [
                  Expanded(
                    child: EmojiMediaView(
                      image: image,
                      emojiFontSize: 34,
                      fit: BoxFit.contain,
                    ),
                  ),
                  Spacing.v4,
                  AppText(
                    text: emoji['name'] ?? 'Emoji',
                    fontSize: 9,
                    color: AppLightUi.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    align: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
