import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_recruit_link_controller.dart';

/// Local palette — matches agency dashboard glass UI.
abstract final class _RecruitUi {
  static const radiusMd = 18.0;
  static const radiusSm = 14.0;

  static const glassFill = Color(0x14FFFFFF);
  static const glassBorder = Color(0x28FFFFFF);

  static const accentPink = Color(0xFFFF5CAB);
  static const accentViolet = Color(0xFF9B5CFF);
  static const accentCyan = Color(0xFF4FD1C5);

  static const textMuted = Color(0xB3FFFFFF);
  static const textSoft = Color(0x8FFFFFFF);
}

class AgencyRecruitLinkView extends GetView<AgencyRecruitLinkController> {
  const AgencyRecruitLinkView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0618),
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(kImgBG),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: -70,
            right: -30,
            child: _glowOrb(_RecruitUi.accentViolet.withValues(alpha: 0.32), 170),
          ),
          Positioned(
            top: 160,
            left: -50,
            child: _glowOrb(_RecruitUi.accentPink.withValues(alpha: 0.22), 130),
          ),
          Positioned(
            bottom: 40,
            right: -10,
            child: _glowOrb(_RecruitUi.accentCyan.withValues(alpha: 0.14), 110),
          ),
          SafeArea(
            child: Column(
              children: [
                _header(),
                Expanded(
                  child: Obx(() {
                    if (controller.isLoading.value &&
                        controller.agencyCode.value.isEmpty) {
                      return const Center(
                        child: CircularProgressIndicator(color: kColorWhite),
                      );
                    }
                    return _scrollBody(context);
                  }),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _glowOrb(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: color, blurRadius: 80, spreadRadius: 18)],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      child: _glass(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        radius: _RecruitUi.radiusSm,
        child: Row(
          children: [
            _iconButton(Icons.arrow_back_ios_new_rounded, Get.back),
            const Expanded(
              child: Column(
                children: [
                  SemiBoldText(
                    text: 'Recruit Hosts',
                    fontSize: TextStyles.k16FontSize,
                    color: kColorWhite,
                  ),
                  AppText(
                    text: 'Invite talent to your agency',
                    fontSize: TextStyles.k10FontSize,
                    color: _RecruitUi.textSoft,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 40, height: 40),
          ],
        ),
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: kColorWhite, size: 18),
        ),
      ),
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
                  _primaryAction(
                    icon: Icons.chat_rounded,
                    label: 'Share on WhatsApp',
                    onTap: () => controller.shareOnWhatsApp(context),
                  ),
                  Spacing.v10,
                  _secondaryAction(
                    icon: Icons.hub_rounded,
                    label: 'View My Hosts',
                    onTap: () => Get.toNamed(Routes.AGENCY_HOST_LIST),
                  ),
                  Spacing.v10,
                  _secondaryAction(
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
    return _glass(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [_RecruitUi.accentPink, _RecruitUi.accentViolet],
              ),
              boxShadow: [
                BoxShadow(
                  color: _RecruitUi.accentPink.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              color: kColorWhite,
              size: 30,
            ),
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
    return _glass(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _RecruitUi.accentViolet.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.tag_rounded,
              color: _RecruitUi.accentViolet,
              size: 22,
            ),
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
          _copyChip(onTap: () => controller.copyCode(context)),
        ],
      ),
    );
  }

  Widget _linkCard(BuildContext context) {
    return _glass(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _RecruitUi.accentCyan.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.link_rounded,
              color: _RecruitUi.accentCyan,
              size: 22,
            ),
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
          _copyChip(onTap: () => controller.copyLink(context)),
        ],
      ),
    );
  }

  Widget _copyChip({required VoidCallback onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: kColorWhite.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _RecruitUi.glassBorder),
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

  Widget _primaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_RecruitUi.radiusMd),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_RecruitUi.radiusMd),
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [_RecruitUi.accentPink, _RecruitUi.accentViolet],
            ),
            boxShadow: [
              BoxShadow(
                color: _RecruitUi.accentPink.withValues(alpha: 0.28),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kColorWhite, size: 20),
              Spacing.h8,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _secondaryAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(_RecruitUi.radiusMd),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(_RecruitUi.radiusMd),
            color: kColorWhite.withValues(alpha: 0.06),
            border: Border.all(color: _RecruitUi.glassBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: kColorWhite.withValues(alpha: 0.9), size: 18),
              Spacing.h8,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glass({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
    double radius = _RecruitUi.radiusMd,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: _RecruitUi.glassFill,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: _RecruitUi.glassBorder),
          ),
          child: child,
        ),
      ),
    );
  }
}
