import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_recruit_link_controller.dart';

/// Local palette — matches [AdminAgencyUi] / Super Admin chrome.
abstract final class _RecruitUi {
  static const accentPink = AdminAgencyUi.pink;
  static const accentViolet = AdminAgencyUi.violet;
  static const accentCyan = AdminAgencyUi.cyan;
  static const textMuted = AppLightUi.subtitle;
  static const textSoft = AppLightUi.muted;

  static const heroGradient = [Color(0xFF9C27B0), Color(0xFFE91E63)];
  static const codeGradient = [Color(0xFF5C6BC0), Color(0xFF3949AB)];
  static const linkGradient = [Color(0xFF00838F), Color(0xFF006064)];
}

class AgencyRecruitLinkView extends GetView<AgencyRecruitLinkController> {
  const AgencyRecruitLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold is required so Text has a Material ancestor (avoids yellow underlines).
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      appBar: const CommonAppBarWidget(
        title: 'Recruit Hosts',
        subtitle: 'Invite talent to your agency',
        trailingIcon: Icons.campaign_rounded,
      ),
      body: Obx(() {
        if (controller.isLoading.value && controller.agencyCode.value.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: AppLightUi.pink),
          );
        }
        return _scrollBody(context);
      }),
    );
  }

  Widget _scrollBody(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 10),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _heroCard(),
                  Spacing.v16,
                  _codeCard(context),
                  Spacing.v12,
                  _linkCard(context),
                  const Spacer(),
                  Spacing.v20,
                  AdminGoldCtaButton(
                    label: 'Share on WhatsApp',
                    icon: Icons.chat_rounded,
                    expanded: true,
                    height: 52,
                    onTap: () => controller.shareOnWhatsApp(context),
                  ),
                  Spacing.v10,
                  AdminPrimaryCtaButton(
                    icon: Icons.hub_rounded,
                    label: 'View My Hosts',
                    onTap: () => Get.toNamed(Routes.AGENCY_HOST_LIST),
                  ),
                  Spacing.v10,
                  AdminPrimaryCtaButton(
                    icon: Icons.insights_rounded,
                    label: 'Agency Revenue',
                    onTap: () => Get.toNamed(Routes.AGENCY_REVENUE),
                  ),
                  Spacing.v6,
                  TextButton(
                    onPressed: () => Get.offNamed(Routes.AGENCY_OWNER),
                    child: const SemiBoldText(
                      text: 'Back to Dashboard',
                      fontSize: TextStyles.k12FontSize,
                      color: _RecruitUi.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _heroCard() {
    return AdminColorPanel(
      colors: _RecruitUi.heroGradient,
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        children: [
          AdminAgencyUi.glowIcon(
            icon: Icons.people_alt_rounded,
            accent: _RecruitUi.accentPink,
            size: 64,
            iconSize: 30,
          ),
          Spacing.v16,
          const SemiBoldText(
            text: 'Grow your host network',
            fontSize: TextStyles.k20FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
          Spacing.v8,
          const AppText(
            text:
                'Share your agency code or invite link. Hosts apply under your agency and show up for review.',
            fontSize: TextStyles.k12FontSize,
            color: _RecruitUi.textMuted,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _codeCard(BuildContext context) {
    return AdminColorPanel(
      colors: _RecruitUi.codeGradient,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          AdminAgencyUi.glowIcon(
            icon: Icons.tag_rounded,
            accent: _RecruitUi.accentViolet,
            size: 42,
            iconSize: 22,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  text: 'AGENCY CODE',
                  fontSize: TextStyles.k10FontSize,
                  color: _RecruitUi.textSoft,
                ),
                Spacing.v4,
                Obx(
                  () => SemiBoldText(
                    text: controller.agencyCode.value.isEmpty
                        ? '—'
                        : controller.agencyCode.value,
                    fontSize: TextStyles.k22FontSize,
                    color: kColorWhite,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _copyChip(
            accent: _RecruitUi.accentViolet,
            onTap: () => controller.copyCode(context),
          ),
        ],
      ),
    );
  }

  Widget _linkCard(BuildContext context) {
    return AdminColorPanel(
      colors: _RecruitUi.linkGradient,
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          AdminAgencyUi.glowIcon(
            icon: Icons.link_rounded,
            accent: _RecruitUi.accentCyan,
            size: 42,
            iconSize: 22,
          ),
          Spacing.h12,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppText(
                  text: 'DIRECT INVITE LINK',
                  fontSize: TextStyles.k10FontSize,
                  color: _RecruitUi.textSoft,
                ),
                Spacing.v4,
                Obx(
                  () => AppText(
                    text: controller.recruitLink.value.isEmpty
                        ? 'Generating invite link…'
                        : controller.recruitLink.value,
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite.withValues(alpha: 0.92),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          _copyChip(
            accent: _RecruitUi.accentCyan,
            onTap: () => controller.copyLink(context),
          ),
        ],
      ),
    );
  }

  Widget _copyChip({
    required Color accent,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: kColorWhite.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.copy_rounded, color: kColorWhite, size: 16),
              SizedBox(width: 6),
              SemiBoldText(
                text: 'Copy',
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
