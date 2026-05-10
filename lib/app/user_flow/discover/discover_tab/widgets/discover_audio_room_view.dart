import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Placeholder for Audio Room discover content (replace when design is ready).
class DiscoverAudioRoomView extends StatelessWidget {
  const DiscoverAudioRoomView({super.key});

  static const String roomLabel = 'Audio Room';

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SemiBoldText(
        text: roomLabel,
        fontSize: TextStyles.k22FontSize,
        color: kColorWhite,
      ),
    );
  }
}
