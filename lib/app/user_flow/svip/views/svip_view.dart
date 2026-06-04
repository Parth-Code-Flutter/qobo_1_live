import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/svip_controller.dart';

class SvipView extends GetView<SvipController> {
  const SvipView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CommonAppBarWidget(
        title: 'SVIP Center',
        useMaterialAppBar: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),
            _buildPrivilegesSection(),
            Spacing.v24,
            _buildPlansSection(),
            Spacing.v32,
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF0F0F0F), Color(0xFF2C2C2C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Glimmering Star
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFD700).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.stars_rounded,
              color: Color(0xFFFFD700),
              size: 56,
            ),
          ),
          Spacing.v12,
          const BoldText(
            text: 'SUPREME VIP',
            fontSize: TextStyles.k22FontSize,
            color: Color(0xFFFFD700),
            style: TextStyle(letterSpacing: 2),
          ),
          Spacing.v8,
          Obx(() => AppText(
                text: controller.isSvipActive.value
                    ? '★ Active Member (Expires in 30 days) ★'
                    : 'Unlock elite customizations and absolute immunity.',
                fontSize: TextStyles.k14FontSize,
                color: controller.isSvipActive.value ? const Color(0xFFFFD700) : kColorWhite.withValues(alpha: 0.8),
                align: TextAlign.center,
                style: controller.isSvipActive.value
                    ? const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFFFD700), fontSize: TextStyles.k14FontSize)
                    : null,
              )),
          Spacing.v16,
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                Spacing.h6,
                Obx(() => AppText(
                      text: 'Balance: ${controller.coinsBalance.value} Coins',
                      fontSize: TextStyles.k12FontSize,
                      color: kColorWhite,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivilegesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: SemiBoldText(
              text: 'Exclusive Privileges',
              fontSize: TextStyles.k18FontSize,
              color: kColorText,
            ),
          ),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.privileges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.25,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final privilege = controller.privileges[index];
              final Color color = privilege['color'] as Color;
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kColorWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kColorBlack.withValues(alpha: 0.02),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(privilege['icon'] as IconData, color: color, size: 20),
                    ),
                    Spacing.v8,
                    SemiBoldText(
                      text: privilege['title'] as String,
                      fontSize: TextStyles.k14FontSize,
                      color: kColorText,
                    ),
                    Spacing.v2,
                    AppText(
                      text: privilege['desc'] as String,
                      fontSize: 10,
                      color: kColorHint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlansSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 12),
            child: SemiBoldText(
              text: 'Choose Your Membership',
              fontSize: TextStyles.k18FontSize,
              color: kColorText,
            ),
          ),
          Obx(() => Row(
                children: controller.plans.map((plan) {
                  final isSelected = controller.selectedPlan.value == plan['id'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => controller.selectPlan(plan['id'] as int),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD700).withValues(alpha: 0.05) : kColorWhite,
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFD700) : Colors.transparent,
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: kColorBlack.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFFD700).withValues(alpha: 0.15) : const Color(0xFFF3F3F3),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                plan['saving'] as String,
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isSelected ? const Color(0xFFD4AF37) : kColorHint,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Spacing.v8,
                            SemiBoldText(
                              text: plan['duration'] as String,
                              fontSize: TextStyles.k14FontSize,
                              color: kColorText,
                            ),
                            Spacing.v4,
                            BoldText(
                              text: '${plan['price']}',
                              fontSize: TextStyles.k16FontSize,
                              color: const Color(0xFFD4AF37),
                            ),
                            const AppText(
                              text: 'Coins',
                              fontSize: 9,
                              color: kColorHint,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              )),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: kColorWhite,
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Obx(() {
          final isAlreadyActive = controller.isSvipActive.value;
          return appButton(
            onPressed: isAlreadyActive ? () {} : controller.subscribe,
            buttonText: isAlreadyActive ? 'Membership Active' : 'Open SVIP Now',
            buttonColor: isAlreadyActive ? const Color(0xFFF3F3F3) : const Color(0xFF1E1E1E),
            textColor: isAlreadyActive ? kColorHint : const Color(0xFFFFD700),
            borderRadius: 24,
          );
        }),
      ),
    );
  }
}
