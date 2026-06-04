import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/theme_controller.dart';
import 'package:qobo_one_live/theme/theme_context.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/themed_scaffold.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ThemedScaffold(
      appBar: CommonAppBarWidget(
        title: 'Settings',
        useMaterialAppBar: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildSection(
              context,
              title: 'Appearance',
              child: _buildThemeSelector(context),
            ),
            Spacing.v24,
            _buildSection(
              context,
              title: 'Account',
              items: [
                _buildListTile(
                  context,
                  icon: Icons.language_rounded,
                  title: 'Language',
                  trailingText: 'English',
                  onTap: controller.onLanguageTap,
                ),
              ],
            ),
            Spacing.v24,
            _buildSection(
              context,
              title: 'About',
              items: [
                _buildListTile(
                  context,
                  icon: Icons.privacy_tip_rounded,
                  title: 'Privacy Policy & Terms',
                  onTap: controller.onPrivacyTermsTap,
                ),
                Divider(height: 1, color: colors.divider),
                _buildListTile(
                  context,
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

  Widget _buildThemeSelector(BuildContext context) {
    final theme = Get.find<ThemeController>();
    final colors = context.appColors;

    return Obx(
      () => Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.listTileLeadingBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.palette_outlined,
                    color: kColorPrimary,
                    size: 20,
                  ),
                ),
                Spacing.h12,
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText(
                        text: 'Theme',
                        fontSize: TextStyles.k14FontSize,
                        color: colors.textPrimary,
                      ),
                      Spacing.v2,
                      AppText(
                        text: theme.labelFor(theme.themeMode.value),
                        fontSize: TextStyles.k12FontSize,
                        color: colors.hint,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _themeChip(
                  context: context,
                  label: 'Light',
                  icon: Icons.light_mode_rounded,
                  mode: ThemeMode.light,
                  selected: theme.themeMode.value == ThemeMode.light,
                ),
                Spacing.h8,
                _themeChip(
                  context: context,
                  label: 'Dark',
                  icon: Icons.dark_mode_rounded,
                  mode: ThemeMode.dark,
                  selected: theme.themeMode.value == ThemeMode.dark,
                ),
                Spacing.h8,
                _themeChip(
                  context: context,
                  label: 'System',
                  icon: Icons.phone_android_rounded,
                  mode: ThemeMode.system,
                  selected: theme.themeMode.value == ThemeMode.system,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _themeChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required ThemeMode mode,
    required bool selected,
  }) {
    final colors = context.appColors;

    return Expanded(
      child: GestureDetector(
        onTap: () => controller.setThemeMode(mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? kColorPrimary : colors.surfaceMuted,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? kColorPrimary : colors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? kColorWhite : colors.hint,
              ),
              const SizedBox(height: 4),
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k10FontSize,
                color: selected ? kColorWhite : colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(
    BuildContext context, {
    required String title,
    List<Widget>? items,
    Widget? child,
  }) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: SemiBoldText(
            text: title,
            fontSize: TextStyles.k14FontSize,
            color: colors.hint,
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border.withValues(alpha: 0.5)),
          ),
          child: child ?? Column(children: items ?? []),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? trailingText,
    required VoidCallback onTap,
  }) {
    final colors = context.appColors;

    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: colors.listTileLeadingBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: kColorPrimary, size: 20),
      ),
      title: AppText(
        text: title,
        fontSize: TextStyles.k14FontSize,
        color: colors.textPrimary,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText != null)
            AppText(
              text: trailingText,
              fontSize: TextStyles.k12FontSize,
              color: colors.hint,
            ),
          if (trailingText != null) Spacing.h8,
          Icon(Icons.chevron_right_rounded, color: colors.hint, size: 20),
        ],
      ),
    );
  }
}
