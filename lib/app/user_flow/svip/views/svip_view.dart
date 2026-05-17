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
      backgroundColor: kColorBackground,
      appBar: const CommonAppBarWidget(
        title: 'SVIP Center',
        useMaterialAppBar: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderCard(),
            Spacing.v24,
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
          colors: [Color(0xFF2C3E50), Color(0xFF000000)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(
            Icons.diamond_rounded,
            color: Color(0xFFFFD700),
            size: 64,
          ),
          Spacing.v12,
          const BoldText(
            text: 'Supreme VIP',
            fontSize: TextStyles.k24FontSize,
            color: Color(0xFFFFD700),
          ),
          Spacing.v8,
          Obx(() => AppText(
                text: controller.isSvipActive.value 
                    ? 'Your SVIP is currently active' 
                    : 'Unlock exclusive features and stand out!',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite.withOpacity(0.8),
                align: TextAlign.center,
              )),
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
          const SemiBoldText(
            text: 'SVIP Privileges',
            fontSize: TextStyles.k18FontSize,
            color: kColorText,
          ),
          Spacing.v16,
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.privileges.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final privilege = controller.privileges[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: kColorWhite,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFFFD700), size: 24),
                    Spacing.v8,
                    SemiBoldText(
                      text: privilege['title'],
                      fontSize: TextStyles.k14FontSize,
                      color: kColorText,
                    ),
                    Spacing.v4,
                    AppText(
                      text: privilege['desc'],
                      fontSize: TextStyles.k12FontSize,
                      color: kColorHint,
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
          const SemiBoldText(
            text: 'Choose Plan',
            fontSize: TextStyles.k18FontSize,
            color: kColorText,
          ),
          Spacing.v16,
          Obx(() => Row(
                children: controller.plans.map((plan) {
                  final isSelected = controller.selectedPlan.value == plan['id'];
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => controller.selectPlan(plan['id']),
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFFD700).withOpacity(0.1) : kColorWhite,
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFFD700) : kColorHint.withOpacity(0.2),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            SemiBoldText(
                              text: plan['duration'],
                              fontSize: TextStyles.k14FontSize,
                              color: isSelected ? const Color(0xFFD4AF37) : kColorText,
                            ),
                            Spacing.v8,
                            BoldText(
                              text: '${plan['price']}',
                              fontSize: TextStyles.k18FontSize,
                              color: isSelected ? const Color(0xFFD4AF37) : kColorText,
                            ),
                            AppText(
                              text: plan['coins'],
                              fontSize: TextStyles.k12FontSize,
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kColorWhite,
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: appButton(
          onPressed: controller.subscribe,
          buttonText: 'Open SVIP Now',
          buttonColor: const Color(0xFF2C3E50),
          textColor: const Color(0xFFFFD700),
          borderRadius: 24,
        ),
      ),
    );
  }
}
