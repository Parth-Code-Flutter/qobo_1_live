import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/live_moderation_controller.dart';

class LiveModerationView extends GetView<LiveModerationController> {
  const LiveModerationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBarWidget(
        title: 'Security Moderation',
        useMaterialAppBar: true,
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(kColorPrimary),
            ),
          );
        }

        return Column(
          children: [
            _buildRoleHeader(),
            Expanded(
              child: _buildModerationList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildRoleHeader() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shield_rounded, color: Colors.red, size: 20),
              ),
              Spacing.h12,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SemiBoldText(
                    text: 'Moderator Center',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorText,
                  ),
                  Spacing.v2,
                  AppText(
                    text: 'Role: ${controller.adminRole.value}',
                    fontSize: TextStyles.k12FontSize,
                    color: kColorHint,
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: AppText(
              text: 'Active Room',
              fontSize: 10,
              color: Colors.orange,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModerationList() {
    if (controller.liveViewers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_alt_rounded, color: Colors.grey.shade300, size: 64),
            Spacing.v12,
            const SemiBoldText(text: 'No Active Viewers', fontSize: 16, color: kColorText),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: controller.liveViewers.length,
      separatorBuilder: (_, __) => Spacing.v12,
      itemBuilder: (context, index) {
        final viewer = controller.liveViewers[index];
        final bool isMuted = viewer['isMuted'] ?? false;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: kColorBlack.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: kColorPrimary.withOpacity(0.1),
                    child: SemiBoldText(
                      text: viewer['username'][0],
                      fontSize: 14,
                      color: kColorPrimary,
                    ),
                  ),
                  Spacing.h12,
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SemiBoldText(
                          text: viewer['username'] ?? '',
                          fontSize: TextStyles.k14FontSize,
                          color: kColorText,
                        ),
                        Spacing.v2,
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: kColorPrimary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: AppText(
                                text: viewer['level'] ?? '',
                                fontSize: 9,
                                color: kColorPrimary,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            Spacing.h8,
                            AppText(
                              text: 'Status: ${viewer['status']}',
                              fontSize: 10,
                              color: viewer['status'] == 'Active' ? Colors.green : Colors.red,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (isMuted)
                    const Icon(Icons.volume_off_rounded, color: Colors.red, size: 18),
                ],
              ),
              Spacing.v12,
              const Divider(height: 1, color: kColorBackground),
              Spacing.v12,
              // Action Buttons Horizontal list
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _actionBtn(
                    onPressed: () => controller.toggleMuteUser(index),
                    text: isMuted ? 'Unmute' : 'Mute',
                    color: isMuted ? Colors.green : Colors.orange,
                  ),
                  Spacing.h8,
                  _actionBtn(
                    onPressed: () => controller.issueWarning(index),
                    text: 'Warn',
                    color: Colors.blue,
                  ),
                  Spacing.h8,
                  _actionBtn(
                    onPressed: () => controller.kickUser(index),
                    text: 'Kick',
                    color: Colors.red.shade400,
                  ),
                  Spacing.h8,
                  _actionBtn(
                    onPressed: () => controller.banUser(index),
                    text: 'Ban',
                    color: Colors.red.shade700,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _actionBtn({
    required VoidCallback onPressed,
    required String text,
    required Color color,
  }) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.1),
          foregroundColor: color,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: color.withOpacity(0.2), width: 1),
          ),
        ),
        onPressed: onPressed,
        child: BoldText(
          text: text,
          fontSize: 10,
          color: color,
        ),
      ),
    );
  }
}
