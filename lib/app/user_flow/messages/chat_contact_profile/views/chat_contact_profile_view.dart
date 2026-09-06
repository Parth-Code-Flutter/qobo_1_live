import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/chat_contact_profile_controller.dart';

class ChatContactProfileView extends GetView<ChatContactProfileController> {
  const ChatContactProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShellBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: const Color(0xFF24113D).withValues(alpha: 0.96),
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: Get.back,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: kColorWhite,
              size: 20,
            ),
          ),
          title: const SemiBoldText(
            text: 'Profile',
            fontSize: TextStyles.k18FontSize,
            color: kColorWhite,
          ),
        ),
        body: Obx(() {
          if (controller.isLoadingProfile.value &&
              controller.bio.value.isEmpty &&
              controller.level.value == 0) {
            return const _ProfileLoadingState();
          }
          return Stack(
            children: [
              ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 32),
                children: [
                  _buildProfileHero(),
                  const SizedBox(height: 14),
                  _buildStats(),
                  if (controller.bio.value.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildAboutSection(),
                  ],
                  const SizedBox(height: 14),
                  _buildDetailsSection(),
                  const SizedBox(height: 14),
                  _buildSafetySection(context),
                ],
              ),
              if (controller.isActionInFlight.value)
                const LinearProgressIndicator(
                  minHeight: 2,
                  color: kColorProfileChipPinkStart,
                  backgroundColor: Colors.transparent,
                ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildProfileHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF52206E), Color(0xFF281442)],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.14)),
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              FramedUserAvatar(
                name: controller.name.value,
                imageUrl: controller.imageUrl.value,
                frameUrl: controller.avatarFrameUrl.value,
                frameSeed: controller.targetId.value,
                size: 86,
                fontSize: TextStyles.k18FontSize,
              ),
              if (controller.isVip.value)
                Positioned(
                  right: -4,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 7,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFC83D),
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: kColorWhite),
                    ),
                    child: const SemiBoldText(
                      text: 'VIP',
                      fontSize: TextStyles.k8FontSize,
                      color: Color(0xFF3B234B),
                    ),
                  ),
                ),
            ],
          ),
          Spacing.v12,
          SemiBoldText(
            text: controller.name.value,
            fontSize: TextStyles.k20FontSize,
            color: kColorWhite,
            align: TextAlign.center,
          ),
          Spacing.v6,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: controller.presenceColor.value,
                  shape: BoxShape.circle,
                ),
              ),
              Spacing.h6,
              AppText(
                text: controller.presenceLabel.value,
                fontSize: TextStyles.k12FontSize,
                color: kColorWhite.withValues(alpha: 0.68),
              ),
            ],
          ),
          Spacing.v12,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              if (controller.level.value > 0)
                _statusChip(
                  Icons.military_tech_rounded,
                  'LV.${controller.level.value}',
                ),
              if (controller.isMutual.value)
                _statusChip(Icons.favorite_rounded, 'Mutual match')
              else if (controller.isFollowing.value)
                _statusChip(Icons.person_add_alt_1_rounded, 'Following')
              else if (controller.isFollower.value)
                _statusChip(Icons.person_rounded, 'Follows you'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: kColorWhite.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: kColorWhite.withValues(alpha: 0.12)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: kColorProfileChipPinkStart),
          Spacing.h6,
          SemiBoldText(
            text: text,
            fontSize: TextStyles.k10FontSize,
            color: kColorWhite,
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: _panelDecoration(),
      child: Row(
        children: [
          Expanded(
            child: _statItem(
              _compactNumber(controller.followersCount.value.toDouble()),
              'Followers',
            ),
          ),
          _divider(height: 34),
          Expanded(
            child: _statItem(
              _compactNumber(controller.followingCount.value.toDouble()),
              'Following',
            ),
          ),
          _divider(height: 34),
          Expanded(
            child: _statItem(_compactNumber(controller.coins.value), 'Coins'),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Column(
      children: [
        SemiBoldText(
          text: value,
          fontSize: TextStyles.k16FontSize,
          color: kColorWhite,
        ),
        Spacing.v2,
        AppText(
          text: label,
          fontSize: TextStyles.k10FontSize,
          color: kColorWhite.withValues(alpha: 0.52),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return _section(
      icon: Icons.favorite_border_rounded,
      title: 'About',
      child: AppText(
        text: controller.bio.value,
        fontSize: TextStyles.k12FontSize,
        color: kColorWhite.withValues(alpha: 0.78),
      ),
    );
  }

  Widget _buildDetailsSection() {
    final details = <(IconData, String, String)>[
      (Icons.badge_outlined, 'User ID', controller.targetId.value),
      if (controller.country.value.isNotEmpty)
        (Icons.public_rounded, 'Country', controller.country.value),
      if (controller.gender.value.isNotEmpty)
        (Icons.person_outline_rounded, 'Gender', controller.gender.value),
      if (controller.level.value > 0)
        (
          Icons.workspace_premium_outlined,
          'Level',
          'Level ${controller.level.value}',
        ),
    ];
    return _section(
      icon: Icons.person_outline_rounded,
      title: 'Profile details',
      child: Column(
        children: [
          for (var index = 0; index < details.length; index++) ...[
            _detailRow(details[index].$1, details[index].$2, details[index].$3),
            if (index < details.length - 1) _divider(),
          ],
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: kColorProfileChipPurpleStart.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: kColorProfileChipPinkStart, size: 17),
          ),
          Spacing.h10,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: label,
                  fontSize: TextStyles.k10FontSize,
                  color: kColorWhite.withValues(alpha: 0.45),
                ),
                const SizedBox(height: 2),
                SemiBoldText(
                  text: value,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorWhite,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetySection(BuildContext context) {
    return _section(
      icon: Icons.shield_outlined,
      title: 'Chat controls',
      child: Column(
        children: [
          _actionTile(
            icon: Icons.block_rounded,
            label: 'Block ${controller.name.value}',
            onTap: controller.isActionInFlight.value
                ? null
                : () => controller.blockUser(context),
          ),
          _divider(),
          _actionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Delete conversation',
            onTap: controller.isActionInFlight.value
                ? null
                : () => controller.deleteChat(context),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFF6B8F), size: 20),
              Spacing.h12,
              Expanded(
                child: AppText(
                  text: label,
                  fontSize: TextStyles.k12FontSize,
                  color: const Color(0xFFFF8DA8),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: kColorWhite.withValues(alpha: 0.35),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 10),
      decoration: _panelDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: kColorProfileChipPinkStart),
              Spacing.h8,
              SemiBoldText(
                text: title,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
          Spacing.v8,
          child,
        ],
      ),
    );
  }

  BoxDecoration _panelDecoration() {
    return BoxDecoration(
      color: const Color(0xFF2A1748),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: kColorWhite.withValues(alpha: 0.11)),
    );
  }

  Widget _divider({double height = 1}) {
    return Container(
      width: height == 1 ? double.infinity : 1,
      height: height,
      color: kColorWhite.withValues(alpha: 0.09),
    );
  }

  static String _compactNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1);
  }
}

class _ProfileLoadingState extends StatelessWidget {
  const _ProfileLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: SizedBox(
        width: 28,
        height: 28,
        child: CircularProgressIndicator(
          color: kColorProfileChipPinkStart,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
