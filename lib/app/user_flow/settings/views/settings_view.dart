import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorBackground,
      appBar: const CommonAppBarWidget(
        title: 'Settings',
        useMaterialAppBar: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSection(
              title: 'Account',
              items: [
                _buildListTile(
                  icon: Icons.language_rounded,
                  title: 'Language',
                  trailingText: 'English',
                  onTap: controller.onLanguageTap,
                ),
                const Divider(height: 1, color: Colors.white12),
                _buildListTile(
                  icon: Icons.block_rounded,
                  title: 'Block List',
                  onTap: controller.onBlockListTap,
                ),
              ],
            ),
            Spacing.v24,
            _buildSection(
              title: 'About',
              items: [
                _buildListTile(
                  icon: Icons.privacy_tip_rounded,
                  title: 'Privacy Policy & Terms',
                  onTap: controller.onPrivacyTermsTap,
                ),
                const Divider(height: 1, color: Colors.white12),
                _buildListTile(
                  icon: Icons.info_outline_rounded,
                  title: 'Version',
                  trailingText: 'v1.0.0',
                  onTap: () {},
                ),
              ],
            ),
            Spacing.v40,
            appButton(
              onPressed: () => controller.onDeleteAccountTap(context),
              buttonText: 'Delete Account',
              buttonColor: Colors.transparent,
              textColor: Colors.redAccent,
              buttonBorderColor: Colors.redAccent,
              borderRadius: 14,
            ),
            Spacing.v16,
            appButton(
              onPressed: controller.onLogoutTap,
              buttonText: 'Logout',
              buttonColor: kColorPrimary,
              borderRadius: 14,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: SemiBoldText(
            text: title,
            fontSize: TextStyles.k14FontSize,
            color: kColorHint,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: items,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: kColorBackground,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: kColorPrimary, size: 20),
      ),
      title: AppText(
        text: title,
        fontSize: TextStyles.k14FontSize,
        color: kColorText,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            AppText(
              text: trailingText,
              fontSize: TextStyles.k12FontSize,
              color: kColorHint,
            ),
          if (trailingText != null) Spacing.h8,
          const Icon(Icons.chevron_right_rounded, color: kColorHint, size: 20),
        ],
      ),
    );
  }
}
