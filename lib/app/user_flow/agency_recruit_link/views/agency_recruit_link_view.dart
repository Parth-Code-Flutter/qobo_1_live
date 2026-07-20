import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_recruit_link_controller.dart';

class AgencyRecruitLinkView extends GetView<AgencyRecruitLinkController> {
  const AgencyRecruitLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      appBar: AppBar(
        title: const SemiBoldText(
          text: 'Recruit Hosts',
          fontSize: TextStyles.k18FontSize,
          color: kColorText,
        ),
        backgroundColor: kColorWhite,
        centerTitle: true,
        elevation: 0,
        leading: const BackButton(color: kColorText),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kColorPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: kColorPrimary.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.people_alt_rounded,
                      size: 48,
                      color: kColorPrimary,
                    ),
                    Spacing.v16,
                    const SemiBoldText(
                      text: 'Recruit New Hosts',
                      fontSize: TextStyles.k20FontSize,
                      color: kColorText,
                    ),
                    Spacing.v8,
                    const AppText(
                      text:
                          'Share your exclusive code or link with hosts so they can apply directly under your agency.',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorHint,
                      align: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Spacing.v32,
              _buildCodeSection(context),
              Spacing.v20,
              _buildLinkSection(context),
              const Spacer(),
              appButton(
                onPressed: () => controller.shareOnWhatsApp(context),
                buttonText: 'Share Host Link on WhatsApp',
                buttonColor: kColorPrimary,
                buttonIcon: const Icon(
                  Icons.ios_share_rounded,
                  color: kColorWhite,
                  size: 18,
                ),
              ),
              Spacing.v12,
              appButton(
                onPressed: () => Get.toNamed(Routes.AGENCY_HOST_LIST),
                buttonText: 'View My Hosts',
                isGradient: false,
                buttonColor: kColorWhite,
                textColor: kColorPrimary,
              ),
              Spacing.v12,
              appButton(
                onPressed: () => Get.toNamed(Routes.AGENCY_REVENUE),
                buttonText: 'Agency Revenue',
                isGradient: false,
                buttonColor: kColorWhite,
                textColor: kColorPrimary,
              ),
              Spacing.v12,
              TextButton(
                onPressed: () => Get.toNamed(Routes.AGENCY_OWNER),
                child: const SemiBoldText(
                  text: 'Back to Dashboard',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: 'Your Agency Code',
          fontSize: TextStyles.k14FontSize,
          color: kColorText,
        ),
        Spacing.v8,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kColorBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(
                () => SemiBoldText(
                  text: controller.agencyCode.value,
                  fontSize: TextStyles.k18FontSize,
                  color: kColorPrimary,
                ),
              ),
              GestureDetector(
                onTap: () => controller.copyCode(context),
                child: const Icon(
                  Icons.copy_rounded,
                  color: kColorPrimary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText(
          text: 'Your Direct Link',
          fontSize: TextStyles.k14FontSize,
          color: kColorText,
        ),
        Spacing.v8,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kColorBackground,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Obx(
                  () => AppText(
                    text: controller.recruitLink.value,
                    fontSize: TextStyles.k14FontSize,
                    color: kColorPrimary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              Spacing.h12,
              GestureDetector(
                onTap: () => controller.copyLink(context),
                child: const Icon(
                  Icons.copy_rounded,
                  color: kColorPrimary,
                  size: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
