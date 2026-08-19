import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/referral/controllers/referral_controller.dart';
import 'package:qobo_one_live/app/user_flow/referral/models/referral_models.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Invite Friends — matches Family / Agency recruit chrome on [kImgBG].
abstract final class _ReferralUi {
  static const pink = AdminAgencyUi.pink;
  static const violet = AdminAgencyUi.violet;
  static const gold = AdminAgencyUi.gold;
  static const cyan = AdminAgencyUi.cyan;
  static const sky = AdminAgencyUi.sky;
  static const mint = AdminAgencyUi.mint;

  static const textMuted = AdminAgencyUi.textMuted;
  static const textSoft = AdminAgencyUi.textFaint;

  static const heroGradient = [Color(0xFF6A1B9A), Color(0xFFE91E63)];
  static const codeGradient = [Color(0xFF5C6BC0), Color(0xFF3949AB)];
  static const shareGradient = [Color(0xFF00838F), Color(0xFF006064)];
  static const whatsAppGradient = [Color(0xFF25D366), Color(0xFF128C7E)];
}

class ReferralView extends GetView<ReferralController> {
  const ReferralView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage(kImgBG),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: Obx(() {
                  if (controller.isLoading.value &&
                      controller.activeCode.value.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(color: kColorWhite),
                    );
                  }
                  return _scrollBody(context);
                }),
              ),
              _bottomActions(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 4),
      child: Row(
        children: [
          AdminAgencyUi.glassIconButton(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: Get.back,
            accent: _ReferralUi.sky,
            size: 40,
            iconSize: 16,
          ),
          const Expanded(
            child: Column(
              children: [
                SemiBoldText(
                  text: 'Invite Friends',
                  fontSize: TextStyles.k16FontSize,
                  color: kColorWhite,
                ),
                AppText(
                  text: 'Share code · earn bonus coins',
                  fontSize: TextStyles.k10FontSize,
                  color: _ReferralUi.textSoft,
                ),
              ],
            ),
          ),
          AdminAgencyUi.glowIcon(
            icon: Icons.card_giftcard_rounded,
            accent: _ReferralUi.gold,
            size: 40,
            iconSize: 20,
          ),
        ],
      ),
    );
  }

  Widget _scrollBody(BuildContext context) {
    return RefreshIndicator(
      color: _ReferralUi.pink,
      onRefresh: controller.loadDetails,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _heroStats(),
                  Spacing.v16,
                  _codeCard(context),
                  Spacing.v12,
                  _shareCard(context),
                  Spacing.v16,
                  _tabSwitcher(),
                  Spacing.v12,
                  Obx(
                    () => controller.selectedTab.value == 0
                        ? _friendsJoinedList()
                        : _earningsList(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _bottomActions(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF181A5A).withValues(alpha: 0.72),
                const Color(0xFF121644).withValues(alpha: 0.94),
              ],
            ),
            border: Border(
              top: BorderSide(color: kColorWhite.withValues(alpha: 0.12)),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => AdminPrimaryCtaButton(
                    label: controller.activeCode.value.isEmpty
                        ? 'Generate referral code'
                        : 'Generate new code',
                    icon: Icons.auto_awesome_rounded,
                    busy: controller.isGenerating.value,
                    onTap: controller.isGenerating.value
                        ? null
                        : () => controller.generateCode(context),
                  ),
                ),
                Spacing.v10,
                _whatsAppButton(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _whatsAppButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => controller.shareOnWhatsApp(context),
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: _ReferralUi.whatsAppGradient,
            ),
            boxShadow: [
              BoxShadow(
                color: _ReferralUi.mint.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_rounded, color: kColorWhite, size: 20),
              SizedBox(width: 8),
              SemiBoldText(
                text: 'Share on WhatsApp',
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _heroStats() {
    return Obx(
      () => AdminColorPanel(
        colors: _ReferralUi.heroGradient,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          children: [
            AdminAgencyUi.glowIcon(
              icon: Icons.people_alt_rounded,
              accent: _ReferralUi.pink,
              size: 56,
              iconSize: 28,
            ),
            Spacing.v12,
            const SemiBoldText(
              text: 'Earn bonus coins together',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v6,
            const AppText(
              text:
                  'Your friend gets signup bonus coins. You earn when they join.',
              fontSize: TextStyles.k12FontSize,
              color: _ReferralUi.textMuted,
              align: TextAlign.center,
            ),
            Spacing.v16,
            Row(
              children: [
                Expanded(
                  child: _statTile(
                    label: 'Friends joined',
                    value: '${controller.totalReferralsCompleted.value}',
                    icon: Icons.group_rounded,
                    accent: _ReferralUi.violet,
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: _statTile(
                    label: 'Coins earned',
                    value: '${controller.totalCoinsEarned.value}',
                    icon: Icons.monetization_on_rounded,
                    accent: _ReferralUi.gold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statTile({
    required String label,
    required String value,
    required IconData icon,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 16),
              Spacing.h6,
              Expanded(
                child: AppText(
                  text: label,
                  fontSize: TextStyles.k10FontSize,
                  color: _ReferralUi.textMuted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Spacing.v6,
          SemiBoldText(
            text: value,
            fontSize: TextStyles.k20FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _codeCard(BuildContext context) {
    return AdminColorPanel(
      colors: _ReferralUi.codeGradient,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AdminAgencyUi.glowIcon(
                icon: Icons.tag_rounded,
                accent: _ReferralUi.violet,
                size: 42,
                iconSize: 22,
              ),
              Spacing.h12,
              const Expanded(
                child: AppText(
                  text: 'YOUR REFERRAL CODE',
                  fontSize: TextStyles.k10FontSize,
                  color: _ReferralUi.textSoft,
                ),
              ),
              Obx(
                () => _copyChip(
                  accent: _ReferralUi.violet,
                  enabled: controller.activeCode.value.isNotEmpty,
                  onTap: () => controller.copyCode(context),
                ),
              ),
            ],
          ),
          Spacing.v12,
          Obx(() {
            final code = controller.activeCode.value.trim();
            if (code.isEmpty) {
              return Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  color: kColorWhite.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: kColorWhite.withValues(alpha: 0.08),
                  ),
                ),
                child: const AppText(
                  text: 'Generate a code below to start inviting friends',
                  fontSize: TextStyles.k12FontSize,
                  color: _ReferralUi.textMuted,
                  align: TextAlign.center,
                ),
              );
            }
            return Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                code,
                style: TextStyles.kSemiBoldPoppins(
                  fontSize: TextStyles.k28FontSize,
                  colors: kColorWhite,
                ).copyWith(letterSpacing: 2.4),
                textAlign: TextAlign.center,
              ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _shareCard(BuildContext context) {
    return AdminColorPanel(
      colors: _ReferralUi.shareGradient,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              AdminAgencyUi.glowIcon(
                icon: Icons.chat_bubble_outline_rounded,
                accent: _ReferralUi.cyan,
                size: 42,
                iconSize: 22,
              ),
              Spacing.h12,
              const Expanded(
                child: SemiBoldText(
                  text: 'Share message',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorWhite,
                ),
              ),
              Obx(
                () => _copyChip(
                  accent: _ReferralUi.cyan,
                  enabled: controller.shareMessage.value.trim().isNotEmpty ||
                      controller.activeCode.value.isNotEmpty,
                  onTap: () => controller.copyShareMessage(context),
                ),
              ),
            ],
          ),
          Spacing.v10,
          Obx(
            () => AppText(
              text: controller.shareMessage.value.trim().isNotEmpty
                  ? controller.shareMessage.value.trim()
                  : 'Your personal invite text appears here after you generate a code.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.88),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabSwitcher() {
    return Obx(
      () => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: const Color(0xFF2A1748).withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kColorWhite.withValues(alpha: 0.08)),
        ),
        child: Row(
          children: [
            _tabChip('Friends joined', 0),
            _tabChip('Earnings', 1),
          ],
        ),
      ),
    );
  }

  Widget _tabChip(String label, int index) {
    final selected = controller.selectedTab.value == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => controller.selectTab(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: selected
                ? const LinearGradient(
                    colors: _ReferralUi.heroGradient,
                  )
                : null,
          ),
          child: SemiBoldText(
            text: label,
            fontSize: TextStyles.k12FontSize,
            color: selected ? kColorWhite : _ReferralUi.textMuted,
            align: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _friendsJoinedList() {
    return Obx(() {
      final items = controller.completedHistory;
      if (items.isEmpty) {
        return _emptyState(
          icon: Icons.people_outline_rounded,
          title: 'No friends joined yet',
          subtitle: 'Share your code to start earning referral rewards.',
        );
      }
      return Column(
        children: items.map(_friendTile).toList(),
      );
    });
  }

  Widget _friendTile(ReferralCompletedEntry entry) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AdminSolidPanel(
        accent: _ReferralUi.violet,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AppUserAvatar(
              name: entry.friendName ?? 'Friend',
              imageUrl: entry.friendAvatarUrl,
              size: 46,
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SemiBoldText(
                    text: entry.friendName ?? 'New member',
                    fontSize: TextStyles.k14FontSize,
                    color: kColorWhite,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacing.v2,
                  AppText(
                    text: 'Code ${entry.code}',
                    fontSize: TextStyles.k10FontSize,
                    color: _ReferralUi.textMuted,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _ReferralUi.gold.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _ReferralUi.gold.withValues(alpha: 0.35),
                ),
              ),
              child: Column(
                children: [
                  SemiBoldText(
                    text: '+${entry.coinsEarned}',
                    fontSize: TextStyles.k14FontSize,
                    color: _ReferralUi.gold,
                  ),
                  AppText(
                    text: 'coins',
                    fontSize: TextStyles.k10FontSize,
                    color: _ReferralUi.textMuted,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _earningsList() {
    return Obx(() {
      final items = controller.earningHistory;
      if (items.isEmpty) {
        return _emptyState(
          icon: Icons.monetization_on_outlined,
          title: 'No referral earnings yet',
          subtitle: 'Bonuses appear here after friends complete signup.',
        );
      }
      return Column(
        children: items.map(_earningTile).toList(),
      );
    });
  }

  Widget _earningTile(ReferralEarningEntry entry) {
    final label = entry.description?.trim().isNotEmpty == true
        ? entry.description!.trim()
        : _earningTypeLabel(entry.type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AdminSolidPanel(
        accent: _ReferralUi.gold,
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            AdminAgencyUi.glowIcon(
              icon: Icons.monetization_on_rounded,
              accent: _ReferralUi.gold,
              size: 40,
              iconSize: 20,
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SemiBoldText(
                    text: label,
                    fontSize: TextStyles.k12FontSize,
                    color: kColorWhite,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.referralCode?.isNotEmpty == true) ...[
                    Spacing.v2,
                    AppText(
                      text: entry.referralCode!,
                      fontSize: TextStyles.k10FontSize,
                      color: _ReferralUi.textMuted,
                    ),
                  ],
                ],
              ),
            ),
            SemiBoldText(
              text: '+${entry.amount}',
              fontSize: TextStyles.k14FontSize,
              color: _ReferralUi.gold,
            ),
          ],
        ),
      ),
    );
  }

  String _earningTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'REFERRAL_BONUS':
        return 'Signup referral bonus';
      case 'REFERRAL_EARNING':
        return 'Referral reward';
      default:
        return type.isEmpty ? 'Referral reward' : type;
    }
  }

  Widget _emptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return AdminSolidPanel(
      accent: _ReferralUi.pink,
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      child: Column(
        children: [
          AdminAgencyUi.glowIcon(
            icon: icon,
            accent: _ReferralUi.pink,
            size: 52,
            iconSize: 26,
          ),
          Spacing.v12,
          SemiBoldText(
            text: title,
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
          Spacing.v6,
          AppText(
            text: subtitle,
            fontSize: TextStyles.k12FontSize,
            color: _ReferralUi.textMuted,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _copyChip({
    required Color accent,
    required VoidCallback onTap,
    bool enabled = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: enabled ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: kColorWhite.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: accent.withValues(alpha: 0.35)),
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
      ),
    );
  }
}
