import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_user_avatar.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/chat_contact_profile_controller.dart';

class ChatContactProfileView extends GetView<ChatContactProfileController> {
  const ChatContactProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorAppBackground,
      appBar: const CommonAppBarWidget(
        title: 'Contact info',
        useMaterialAppBar: true,
      ),
      body: Obx(() {
        if (controller.isLoadingProfile.value &&
            controller.bio.value.isEmpty &&
            controller.level.value == 0) {
          return const Center(
            child: CircularProgressIndicator(color: kColorPrimary),
          );
        }

        return ListView(
          children: [
            _buildProfileHeader(),
            Spacing.v8,
            if (controller.bio.value.isNotEmpty) _buildAboutSection(),
            if (controller.country.value.isNotEmpty || controller.level.value > 0)
              _buildDetailsSection(),
            Spacing.v8,
            _buildDangerSection(context),
            Spacing.v24,
          ],
        );
      }),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      color: kColorWhite,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        children: [
          AppUserAvatar(
            name: controller.name.value,
            imageUrl: controller.imageUrl.value,
            size: 112,
          ),
          Spacing.v16,
          SemiBoldText(
            text: controller.name.value,
            fontSize: TextStyles.k20FontSize,
            color: kColorText,
            align: TextAlign.center,
          ),
          Spacing.v6,
          Obx(
            () => AppText(
              text: controller.presenceLabel.value,
              fontSize: TextStyles.k14FontSize,
              color: controller.presenceColor.value,
              align: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      width: double.infinity,
      color: kColorWhite,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            text: 'About',
            fontSize: TextStyles.k12FontSize,
            color: kColorPrimary,
          ),
          Spacing.v6,
          AppText(
            text: controller.bio.value,
            fontSize: TextStyles.k14FontSize,
            color: kColorText,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsSection() {
    return Container(
      width: double.infinity,
      color: kColorWhite,
      margin: const EdgeInsets.only(top: 8),
      child: Column(
        children: [
          if (controller.country.value.isNotEmpty)
            _infoRow(
              icon: Icons.public_rounded,
              label: 'Country',
              value: controller.country.value,
            ),
          if (controller.level.value > 0)
            _infoRow(
              icon: Icons.military_tech_rounded,
              label: 'Level',
              value: 'Lv ${controller.level.value}',
            ),
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, color: kColorPrimary, size: 22),
          Spacing.h16,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  text: label,
                  fontSize: TextStyles.k12FontSize,
                  color: kColorHint,
                ),
                Spacing.v2,
                AppText(
                  text: value,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorText,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDangerSection(BuildContext context) {
    return Container(
      color: kColorWhite,
      child: Column(
        children: [
          _actionTile(
            context: context,
            icon: Icons.block_rounded,
            label: 'Block ${controller.name.value}',
            color: Colors.red.shade700,
            onTap: controller.isActionInFlight.value
                ? null
                : () => controller.blockUser(context),
          ),
          Divider(height: 1, color: kColorBackground, indent: 56),
          _actionTile(
            context: context,
            icon: Icons.delete_outline_rounded,
            label: 'Delete chat',
            color: Colors.red.shade700,
            onTap: controller.isActionInFlight.value
                ? null
                : () => controller.deleteChat(context),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: AppText(
        text: label,
        fontSize: TextStyles.k14FontSize,
        color: color,
      ),
      onTap: onTap,
    );
  }
}
