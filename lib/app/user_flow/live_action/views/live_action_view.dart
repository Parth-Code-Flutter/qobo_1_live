import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_action_controller.dart';

class LiveActionView extends StatelessWidget {
  const LiveActionView({super.key});

  @override
  Widget build(BuildContext context) {
    // Assuming Get.put for tab views, or handled via bottom_nav_binding
    final controller = Get.put(LiveActionController());

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Spacing.v32,
              const Center(
                child: SemiBoldText(
                  text: 'Go Live',
                  fontSize: 28,
                  color: kColorWhite,
                ),
              ),
              Spacing.v8,
              Center(
                child: AppText(
                  text: 'Start broadcasting and building your community',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              _buildOptionCard(
                context,
                title: 'Start Video Live',
                subtitle: 'Face to face interaction with your audience',
                icon: Icons.videocam_rounded,
                gradientColors: [Colors.purpleAccent, Colors.deepPurple],
                onTap: controller.navToCreateVideoRoom,
              ),
              Spacing.v20,
              _buildOptionCard(
                context,
                title: 'Start Audio Room',
                subtitle: 'Casual drop-in audio conversation',
                icon: Icons.graphic_eq_rounded,
                gradientColors: [Colors.orangeAccent, Colors.deepOrange],
                onTap: controller.navToCreateAudioRoom,
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: gradientColors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: gradientColors.last.withValues(alpha: 0.4),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: kColorWhite, size: 32),
            ),
            Spacing.h20,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SemiBoldText(
                    text: title,
                    fontSize: 20,
                    color: kColorWhite,
                  ),
                  Spacing.v4,
                  AppText(
                    text: subtitle,
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: kColorWhite, size: 20),
          ],
        ),
      ),
    );
  }
}
