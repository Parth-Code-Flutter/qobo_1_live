import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Centered date separator in the chat message list.
class ChatDateHeaderWidget extends StatelessWidget {
  const ChatDateHeaderWidget({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
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
}
