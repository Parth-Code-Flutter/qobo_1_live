import 'package:flutter/material.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Small gold SVIP mark for the profile name and live chat.
class SvipBadgeChip extends StatelessWidget {
  const SvipBadgeChip({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: compact ? 16 : 18,
      padding: EdgeInsets.symmetric(horizontal: compact ? 5 : 6),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFE27A), Color(0xFFD4AF37)],
        ),
        borderRadius: BorderRadius.circular(9),
      ),
      child: SemiBoldText(
        text: 'SVIP',
        fontSize: compact ? 8 : TextStyles.k10FontSize,
        color: const Color(0xFF4A3200),
      ),
    );
  }
}
