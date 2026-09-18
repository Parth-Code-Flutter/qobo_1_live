import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/common_app_bar_widget.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  static const _rose = Color(0xFFE11D48);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppLightUi.bg,
      appBar: const CommonAppBarWidget(
        title: 'Settings',
        subtitle: 'Manage your account',
        useMaterialAppBar: true,
      ),
      body: Stack(
        children: [
          _ambientBackdrop(),
          SafeArea(
            top: false,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                    child: Column(
                      children: [
                        _buildSection(
                          title: 'Account',
                          items: [
                            _buildListTile(
                              icon: Icons.language_rounded,
                              accent: AppLightUi.cyan,
                              title: 'Language',
                              trailingText: 'English',
                              onTap: controller.onLanguageTap,
                            ),
                            _divider(),
                            _buildListTile(
                              icon: Icons.card_giftcard_rounded,
                              accent: AppLightUi.pink,
                              title: 'Invite',
                              onTap: controller.onInviteTap,
                            ),
                            _divider(),
                            _buildListTile(
                              icon: Icons.support_agent_rounded,
                              accent: AppLightUi.violet,
                              title: 'Support',
                              onTap: controller.onSupportTap,
                            ),
                            _divider(),
                            _buildListTile(
                              icon: Icons.block_rounded,
                              accent: AppLightUi.rose,
                              title: 'Blocked users',
                              onTap: controller.onBlockListTap,
                            ),
                          ],
                        ),
                        Spacing.v20,
                        _buildSection(
                          title: 'About',
                          items: [
                            _buildListTile(
                              icon: Icons.privacy_tip_rounded,
                              accent: AppLightUi.pink,
                              title: 'Privacy & Terms',
                              onTap: controller.onPrivacyTermsTap,
                            ),
                            _divider(),
                            _buildListTile(
                              icon: Icons.info_outline_rounded,
                              accent: AppLightUi.violet,
                              title: 'Version',
                              trailingText: 'v1.0.0',
                              showChevron: false,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                _bottomActions(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ambientBackdrop() {
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            top: 40,
            right: -60,
            child: _glow(140, AppLightUi.pink.withValues(alpha: 0.08)),
          ),
          Positioned(
            bottom: 120,
            left: -50,
            child: _glow(160, AppLightUi.violet.withValues(alpha: 0.07)),
          ),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
  }

  Widget _bottomActions(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: AppLightUi.bg.withValues(alpha: 0.96),
        border: Border(
          top: BorderSide(color: AppLightUi.border.withValues(alpha: 0.9)),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Primary action — clear white label on brand gradient.
          appButton(
            onPressed: controller.onLogoutTap,
            buttonText: 'Logout',
            isGradient: true,
            gradientColors: AppLightUi.familyCtaColors,
            borderRadius: 16,
            buttonHeight: 52,
          ),
          Spacing.v12,
          // Destructive — outlined, high-contrast rose (never on gradient).
          appButton(
            onPressed: () => controller.onDeleteAccountTap(context),
            buttonText: 'Delete Account',
            isGradient: false,
            buttonColor: Colors.white,
            textColor: _rose,
            buttonBorderColor: _rose.withValues(alpha: 0.55),
            borderRadius: 16,
            buttonHeight: 52,
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(height: 1, thickness: 1, color: AppLightUi.border),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 10),
          child: SemiBoldText(
            text: title.toUpperCase(),
            fontSize: TextStyles.k12FontSize,
            color: AppLightUi.subtitle,
          ),
        ),
        Container(
          decoration: AppLightUi.cardDecoration(radius: 18),
          clipBehavior: Clip.antiAlias,
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required Color accent,
    required String title,
    String? trailingText,
    VoidCallback? onTap,
    bool showChevron = true,
  }) {
    final tappable = onTap != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      accent.withValues(alpha: 0.18),
                      accent.withValues(alpha: 0.08),
                    ],
                  ),
                  border: Border.all(color: accent.withValues(alpha: 0.22)),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              Spacing.h12,
              Expanded(
                child: AppText(
                  text: title,
                  fontSize: TextStyles.k14FontSize,
                  color: AppLightUi.title,
                ),
              ),
              if (trailingText != null) ...[
                AppText(
                  text: trailingText,
                  fontSize: TextStyles.k12FontSize,
                  color: AppLightUi.muted,
                ),
                if (showChevron && tappable) Spacing.h6,
              ],
              if (showChevron && tappable)
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppLightUi.muted.withValues(alpha: 0.85),
                  size: 22,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
