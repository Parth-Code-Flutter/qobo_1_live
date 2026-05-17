import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/family_controller.dart';

class FamilyView extends GetView<FamilyController> {
  const FamilyView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: const CommonAppBarWidget(
        title: 'Family',
        useMaterialAppBar: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeaderBanner(),
            Spacing.v24,
            _buildPopularFamiliesSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeaderBanner() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: kColorPrimary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          const Icon(Icons.groups_rounded, color: kColorWhite, size: 64),
          Spacing.v16,
          const SemiBoldText(
            text: 'Join a Family',
            fontSize: TextStyles.k20FontSize,
            color: kColorWhite,
          ),
          Spacing.v8,
          AppText(
            text: 'Find your tribe, grow together, and unlock family exclusive rewards!',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite.withOpacity(0.8),
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPopularFamiliesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Popular Families',
            fontSize: TextStyles.k18FontSize,
            color: kColorText,
          ),
          Spacing.v16,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.popularFamilies.length,
            separatorBuilder: (_, __) => Spacing.v12,
            itemBuilder: (context, index) {
              final family = controller.popularFamilies[index];
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: kColorWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: kColorBlack.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: kColorPrimary.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: SemiBoldText(
                          text: family['name'][0],
                          fontSize: TextStyles.k20FontSize,
                          color: kColorPrimary,
                        ),
                      ),
                    ),
                    Spacing.h16,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SemiBoldText(
                            text: family['name'],
                            fontSize: TextStyles.k16FontSize,
                            color: kColorText,
                          ),
                          Spacing.v4,
                          AppText(
                            text: 'Lv. ${family['level']} • ${family['members']} Members',
                            fontSize: TextStyles.k12FontSize,
                            color: kColorHint,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(
                      height: 32,
                      width: 70,
                      child: appButton(
                        onPressed: () => controller.joinFamily(family['name']),
                        buttonText: 'Join',
                        buttonColor: kColorPrimary,
                        borderRadius: 16,
                        textStyle: TextStyles.kSemiBoldPoppins(
                          fontSize: TextStyles.k12FontSize,
                          colors: kColorWhite,
                        ),
                      ),
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
          onPressed: controller.createFamily,
          buttonText: 'Create a Family',
          buttonColor: Colors.transparent,
          textColor: kColorPrimary,
          buttonBorderColor: kColorPrimary,
          borderRadius: 24,
        ),
      ),
    );
  }
}
