import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/theme/app_theme_colors.dart';
import 'package:qobo_one_live/theme/theme_context.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_recruit_link_controller.dart';

class AgencyRecruitLinkView extends GetView<AgencyRecruitLinkController> {
  const AgencyRecruitLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recruit Hosts'),
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: colors.scaffold,
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
                  border: Border.all(color: kColorPrimary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.people_alt_rounded, size: 48, color: kColorPrimary),
                    Spacing.v16,
                    SemiBoldText(
                      text: 'Recruit New Hosts',
                      fontSize: TextStyles.k20FontSize,
                      color: colors.textPrimary,
                    ),
                    Spacing.v8,
                    AppText(
                      text: 'Share your exclusive code or link with hosts so they can apply directly under your agency.',
                      fontSize: TextStyles.k14FontSize,
                      color: colors.textSecondary,
                      align: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Spacing.v32,
              _buildCodeSection(context, colors),
              Spacing.v20,
              _buildLinkSection(context, colors),
              const Spacer(),
              appButton(
                onPressed: () => Get.toNamed(Routes.AGENCY_HOST_LIST),
                buttonText: 'View My Hosts',
                buttonColor: kColorPrimary,
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

  Widget _buildCodeSection(BuildContext context, AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: 'Your Agency Code',
          fontSize: TextStyles.k14FontSize,
          color: colors.textPrimary,
        ),
        Spacing.v8,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.searchFieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.searchFieldBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Obx(() => SemiBoldText(
                text: controller.agencyCode.value,
                fontSize: TextStyles.k18FontSize,
                color: kColorPrimary,
              )),
              GestureDetector(
                onTap: () => controller.copyCode(context),
                child: const Icon(Icons.copy_rounded, color: kColorPrimary, size: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLinkSection(BuildContext context, AppThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: 'Your Direct Link',
          fontSize: TextStyles.k14FontSize,
          color: colors.textPrimary,
        ),
        Spacing.v8,
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: colors.searchFieldFill,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.searchFieldBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Obx(() => AppText(
                  text: controller.recruitLink.value,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorPrimary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
              ),
              Spacing.h12,
              GestureDetector(
                onTap: () => controller.copyLink(context),
                child: const Icon(Icons.copy_rounded, color: kColorPrimary, size: 24),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
