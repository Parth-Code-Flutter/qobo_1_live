import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/entrance_patti_controller.dart';

class EntrancePattiView extends GetView<EntrancePattiController> {
  const EntrancePattiView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBarWidget(
        title: 'Entrance Patti & Frames',
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
            _buildLivePreviewCard(),
            Expanded(
              child: _buildPattiList(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildLivePreviewCard() {
    final activePatti = controller.pattiItems.firstWhere(
      (p) => p['id'] == controller.equippedPattiId.value,
      orElse: () => controller.pattiItems.first,
    );
    final colors = (activePatti['colors'] as List<int>).map((c) => Color(c)).toList();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Live Entrance Preview',
            fontSize: TextStyles.k14FontSize,
            color: kColorText,
          ),
          Spacing.v12,
          // Mock Live Streaming Chat Entrance Ribbon
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF161622),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white10,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const AppText(
                    text: 'Streaming Chat View',
                    fontSize: 8,
                    color: Colors.white54,
                  ),
                ),
                Spacing.v12,
                // The announcement Patti Banner!
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: colors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: colors.first.withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.workspace_premium_rounded,
                        color: kColorWhite,
                        size: 16,
                      ),
                      Spacing.h8,
                      const Flexible(
                        child: SemiBoldText(
                          text: 'Elite User enters the room ✨',
                          fontSize: 12,
                          color: kColorWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPattiList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: controller.pattiItems.length,
      separatorBuilder: (_, __) => Spacing.v12,
      itemBuilder: (context, index) {
        final item = controller.pattiItems[index];
        final bool isUnlocked = item['isUnlocked'] ?? false;
        final bool isEquipped = item['id'] == controller.equippedPattiId.value;
        final colors = (item['colors'] as List<int>).map((c) => Color(c)).toList();

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
          child: Row(
            children: [
              // Patti Ribbon Mini Preview
              Container(
                width: 64,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.text_fields_rounded,
                  color: kColorWhite,
                  size: 20,
                ),
              ),
              Spacing.h16,
              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: SemiBoldText(
                            text: item['title'] ?? '',
                            fontSize: TextStyles.k14FontSize,
                            color: kColorText,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Spacing.h8,
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: colors.first.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: AppText(
                            text: item['type'] ?? '',
                            fontSize: 9,
                            color: colors.first,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Spacing.v4,
                    AppText(
                      text: item['desc'] ?? '',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorHint,
                    ),
                  ],
                ),
              ),
              Spacing.h12,
              // Action Button (Equip / Equipped / Locked)
              SizedBox(
                height: 32,
                width: 84,
                child: appButton(
                  onPressed: isUnlocked && !isEquipped
                      ? () => controller.equipPatti(item['id'])
                      : () {},
                  buttonText: isEquipped
                      ? 'Active'
                      : (isUnlocked ? 'Equip' : 'Locked'),
                  buttonColor: isEquipped
                      ? Colors.green.shade100
                      : (isUnlocked ? kColorPrimary : Colors.grey.shade200),
                  borderRadius: 16,
                  buttonWidth: 84,
                  textStyle: TextStyles.kBoldPoppins(
                    fontSize: 11,
                    colors: isEquipped
                        ? Colors.green.shade700
                        : (isUnlocked ? kColorWhite : Colors.grey.shade500),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
