import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/constants/image_constants.dart';
import 'package:aligned_rewards/generated/locales.g.dart';
import 'package:aligned_rewards/routes/app_pages.dart';
import 'package:aligned_rewards/utils/app_widgets/app_size_extension.dart';
import 'package:aligned_rewards/utils/app_widgets/app_spaces.dart';
import 'package:aligned_rewards/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:aligned_rewards/utils/text_utils/app_text.dart';
import 'package:aligned_rewards/utils/text_utils/text_styles.dart';
import 'package:aligned_rewards/utils/alert_message_utils/alert_message_utils.dart';
import 'package:aligned_rewards/utils/error_handler_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class CommonDrawerWidget extends StatelessWidget {
  final String userType; // 'admin', 'employee', 'client'
  final String userName;
  final List<Widget>? customMenuItems;
  final Widget? headerWidget;

  const CommonDrawerWidget({
    super.key,
    required this.userType,
    this.userName = 'User',
    this.customMenuItems,
    this.headerWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 0.75.screenWidth,
      backgroundColor: kColorBlack38,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(0),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header section
            _buildHeader(),
            Divider(
              thickness: 0.4,
            ),
            // Main content section
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User type indicator
                    _buildUserTypeIndicator(),
                    Spacing.v24,
                    // Custom menu items or default menu
                    if (customMenuItems != null) ...customMenuItems!,
                    if (customMenuItems == null) _buildDefaultMenu(),
                  ],
                ),
              ),
            ),
            // Logout button at bottom
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  /// Build header section
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                kDummyProfileImg,
                width: 38,
                height: 38,
              ),
              Spacing.h10,
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    text: LocaleKeys.welcome.tr,
                    style: TextStyles.kRegularLato(
                      fontSize: TextStyles.k12FontSize,
                    ),
                  ),
                  AppText(
                    text: userName,
                    style: TextStyles.kBoldLato(
                      fontSize: TextStyles.k14FontSize,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SvgPicture.asset(kIconSettings),
        ],
      ),
    );
  }

  /// Build user type indicator
  Widget _buildUserTypeIndicator() {
    String userTypeText = '';
    String userTypeIcon = '';

    switch (userType.toLowerCase()) {
      case 'admin':
        userTypeText = LocaleKeys.workforceAdmin.tr;
        userTypeIcon = kIconWorkForceAdmin;
        break;
      case 'employee':
        userTypeText = 'Employee';
        userTypeIcon = kIconWorkForceAdmin; // You can change this to employee icon
        break;
      case 'client':
        userTypeText = 'Client';
        userTypeIcon = kIconWorkForceAdmin; // You can change this to client icon
        break;
      default:
        userTypeText = 'User';
        userTypeIcon = kIconWorkForceAdmin;
    }

    return Row(
      children: [
        SvgPicture.asset(userTypeIcon),
        Spacing.h16,
        MediumText(
          text: userTypeText,
          fontSize: 16,
          color: kColorWhite,
        ),
      ],
    );
  }

  /// Build default menu items
  Widget _buildDefaultMenu() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SemiBoldText(
          text: 'Menu'.toUpperCase(),
          fontSize: 16,
          color: kColorWhite,
        ),
        Spacing.v8,
        _buildMenuItem(
          icon: Icons.dashboard,
          title: 'Dashboard',
          onTap: () {
            // Navigate to appropriate dashboard
            switch (userType.toLowerCase()) {
              case 'admin':
                Get.toNamed(Routes.ADMIN_DASHBOARD);
                break;
              case 'employee':
                // Navigate to employee dashboard
                break;
              case 'client':
                // Navigate to client dashboard
                break;
            }
          },
        ),
        _buildMenuItem(
          icon: Icons.person,
          title: 'Profile',
          onTap: () {
            // Navigate to profile
          },
        ),
        _buildMenuItem(
          icon: Icons.settings,
          title: 'Settings',
          onTap: () {
            // Navigate to settings
          },
        ),
      ],
    );
  }

  /// Build menu item
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(
              icon,
              color: kColorGrey187,
              size: 20,
            ),
            Spacing.h16,
            SemiBoldText(
              text: title,
              fontSize: 16,
              color: kColorGrey187,
            ),
          ],
        ),
      ),
    );
  }

  /// Build logout button at bottom of drawer
  Widget _buildLogoutButton() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Divider(
            thickness: 0.4,
            color: kColorGrey187.withOpacity(0.3),
          ),
          Spacing.v16,
          GestureDetector(
            onTap: () => _handleLogout(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: kColorRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: kColorRed.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.logout,
                    color: kColorRed,
                    size: 20,
                  ),
                  Spacing.h12,
                  SemiBoldText(
                    text: 'Logout',
                    fontSize: 16,
                    color: kColorRed,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Handle logout functionality
  void _handleLogout() async {
    try {
      // Show confirmation dialog
      bool? shouldLogout = await Get.dialog<bool>(
        AlertDialog(
          backgroundColor: kColorWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: SemiBoldText(
            text: 'Logout',
            fontSize: 18,
            color: kColorBlack,
          ),
          content: MediumText(
            text: 'Are you sure you want to logout?',
            fontSize: 14,
            color: kColorBlack,
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: MediumText(
                text: 'Cancel',
                fontSize: 14,
                color: kColorGrey187,
              ),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: MediumText(
                text: 'Logout',
                fontSize: 14,
                color: kColorRed,
              ),
            ),
          ],
        ),
      );

      if (shouldLogout == true) {
        // Use centralized logout handler
        ErrorHandlerUtils.logoutUser();
      }
    } catch (e) {
      Get.find<AlertMessageUtils>().showErrorSnackBar('Error during logout');
    }
  }
}
