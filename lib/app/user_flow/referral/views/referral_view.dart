import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/referral/controllers/referral_controller.dart';
import 'package:qobo_one_live/app/user_flow/referral/models/referral_models.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/admin_agency_chrome.dart';
import 'package:qobo_one_live/utils/app_widgets/app_coin_icon.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Invite Friends — light AppLightUi cards with readable contrast.
abstract final class _ReferralUi {
  static const pink = AppLightUi.pink;
  static const mint = Color(0xFF25D366);

  static const whatsAppGradient = [Color(0xFF25D366), Color(0xFF128C7E)];
}

class ReferralView extends GetView<ReferralController> {
  const ReferralView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorLavenderBg,
      appBar: const CommonAppBarWidget(
        title: 'Invite Friends',
        subtitle: 'Share code · earn bonus coins',
        trailingIcon: Icons.card_giftcard_rounded,
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value &&
                  controller.activeCode.value.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(color: AppLightUi.pink),
                );
              }
              return _scrollBody(context);
            }),
          ),
          _bottomActions(context),
        ],
      ),
    );
  }

  Widget _scrollBody(BuildContext context) {
    return RefreshIndicator(
      color: _ReferralUi.pink,
      backgroundColor: AppLightUi.card,
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
                AppLightUi.card.withValues(alpha: 0.92),
                AppLightUi.cardSoft,
              ],
            ),
            border: const Border(
              top: BorderSide(color: AppLightUi.border),
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
      () => Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: AppLightUi.familyCtaGradient,
          boxShadow: [
            BoxShadow(
              color: AppLightUi.pink.withValues(alpha: 0.3),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: kColorWhite.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: kColorWhite.withValues(alpha: 0.4)),
              ),
              child: const Icon(
                Icons.people_alt_rounded,
                color: kColorWhite,
                size: 28,
              ),
            ),
            Spacing.v12,
            const SemiBoldText(
              text: 'Earn bonus coins together',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
            Spacing.v6,
            AppText(
              text:
                  'Your friend gets signup bonus coins. You earn when they join.',
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite.withValues(alpha: 0.92),
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
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: _statTile(
                    label: 'Coins earned',
                    value: '${controller.totalCoinsEarned.value}',
                    iconWidget: const AppCoinIcon(
                      size: 16,
                      color: AppLightUi.gold,
                    ),
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
    IconData? icon,
    Widget? iconWidget,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: kColorWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: kColorBlack.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              iconWidget ??
                  Icon(icon, color: AppLightUi.violet, size: 16),
              Spacing.h6,
              Expanded(
                child: AppText(
                  text: label,
                  fontSize: TextStyles.k10FontSize,
                  color: AppLightUi.body,
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
            color: AppLightUi.title,
          ),
        ],
      ),
    );
  }

  Widget _codeCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: AppLightUi.cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: AppLightUi.iconTileDecoration(AppLightUi.violet),
                child: const Icon(
                  Icons.tag_rounded,
                  color: AppLightUi.violet,
                  size: 22,
                ),
              ),
              Spacing.h12,
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: 'Your referral code',
                      fontSize: TextStyles.k14FontSize,
                      color: AppLightUi.title,
                    ),
                    AppText(
                      text: 'Share this code with friends',
                      fontSize: TextStyles.k10FontSize,
                      color: AppLightUi.subtitle,
                    ),
                  ],
                ),
              ),
              Obx(
                () => _copyChip(
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
                  color: AppLightUi.cardSoft,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppLightUi.border),
                ),
                child: const AppText(
                  text: 'Generate a code below to start inviting friends',
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.body,
                  align: TextAlign.center,
                ),
              );
            }
            return Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppLightUi.violet.withValues(alpha: 0.12),
                    AppLightUi.pink.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppLightUi.violet.withValues(alpha: 0.35),
                ),
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  code,
                  style: TextStyles.kSemiBoldPoppins(
                    fontSize: TextStyles.k28FontSize,
                    colors: AppLightUi.title,
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
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
      decoration: AppLightUi.cardDecoration(radius: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: AppLightUi.iconTileDecoration(AppLightUi.cyan),
                child: const Icon(
                  Icons.chat_bubble_outline_rounded,
                  color: AppLightUi.cyan,
                  size: 22,
                ),
              ),
              Spacing.h12,
              const Expanded(
                child: SemiBoldText(
                  text: 'Share message',
                  fontSize: TextStyles.k14FontSize,
                  color: AppLightUi.title,
                ),
              ),
              Obx(
                () => _copyChip(
                  enabled: controller.shareMessage.value.trim().isNotEmpty ||
                      controller.activeCode.value.isNotEmpty,
                  onTap: () => controller.copyShareMessage(context),
                ),
              ),
            ],
          ),
          Spacing.v12,
          Obx(
            () => Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppLightUi.cardSoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppLightUi.border),
              ),
              child: AppText(
                text: controller.shareMessage.value.trim().isNotEmpty
                    ? controller.shareMessage.value.trim()
                    : 'Your personal invite text appears here after you generate a code.',
                fontSize: TextStyles.k12FontSize,
                color: AppLightUi.body,
              ),
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
          color: AppLightUi.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppLightUi.border),
          boxShadow: AppLightUi.cardShadow,
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
            gradient: selected ? AppLightUi.familyCtaGradient : null,
          ),
          child: SemiBoldText(
            text: label,
            fontSize: TextStyles.k12FontSize,
            color: selected ? kColorWhite : AppLightUi.subtitle,
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
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppLightUi.cardDecoration(radius: 18),
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
                    color: AppLightUi.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Spacing.v2,
                  AppText(
                    text: 'Code ${entry.code}',
                    fontSize: TextStyles.k10FontSize,
                    color: AppLightUi.subtitle,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppLightUi.gold.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppLightUi.gold.withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                children: [
                  SemiBoldText(
                    text: '+${entry.coinsEarned}',
                    fontSize: TextStyles.k14FontSize,
                    color: const Color(0xFFB7791F),
                  ),
                  const AppText(
                    text: 'coins',
                    fontSize: TextStyles.k10FontSize,
                    color: AppLightUi.body,
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
          useCoinIcon: true,
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
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: AppLightUi.cardDecoration(radius: 18),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: AppLightUi.iconTileDecoration(AppLightUi.gold),
              child: const Center(
                child: AppCoinIcon(size: 20, color: AppLightUi.gold),
              ),
            ),
            Spacing.h12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SemiBoldText(
                    text: label,
                    fontSize: TextStyles.k12FontSize,
                    color: AppLightUi.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (entry.referralCode?.isNotEmpty == true) ...[
                    Spacing.v2,
                    AppText(
                      text: entry.referralCode!,
                      fontSize: TextStyles.k10FontSize,
                      color: AppLightUi.subtitle,
                    ),
                  ],
                ],
              ),
            ),
            SemiBoldText(
              text: '+${entry.amount}',
              fontSize: TextStyles.k14FontSize,
              color: const Color(0xFFB7791F),
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
    IconData? icon,
    bool useCoinIcon = false,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
      decoration: AppLightUi.cardDecoration(radius: 22),
      child: Column(
        children: [
          if (useCoinIcon)
            Container(
              width: 52,
              height: 52,
              decoration: AppLightUi.iconTileDecoration(AppLightUi.pink),
              child: const Center(
                child: AppCoinIcon(size: 26, color: AppLightUi.pink),
              ),
            )
          else
            Container(
              width: 52,
              height: 52,
              decoration: AppLightUi.iconTileDecoration(AppLightUi.pink),
              child: Icon(
                icon ?? Icons.inbox_outlined,
                color: AppLightUi.pink,
                size: 26,
              ),
            ),
          Spacing.v12,
          SemiBoldText(
            text: title,
            fontSize: TextStyles.k14FontSize,
            color: AppLightUi.title,
            align: TextAlign.center,
          ),
          Spacing.v6,
          AppText(
            text: subtitle,
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.subtitle,
            align: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _copyChip({
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
              gradient: AppLightUi.familyCtaGradient,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppLightUi.pink.withValues(alpha: 0.22),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
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
