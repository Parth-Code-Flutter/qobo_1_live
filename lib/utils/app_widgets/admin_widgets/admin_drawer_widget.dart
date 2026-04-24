import 'package:aligned_rewards/app/roles/admin/admin_dashboard/controllers/admin_dashboard_controller.dart';
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

class AdminDrawerWidget extends StatelessWidget {
  const AdminDrawerWidget({super.key});

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
            // Header section with dynamic user data
            _buildHeader(),
            Divider(
              thickness: 0.4,
            ),
            // Main content section
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () => Get.back(),
                      child: Row(
                        children: [
                          SvgPicture.asset(kIconWorkForceAdmin),
                          Spacing.h16,
                          MediumText(
                            text: LocaleKeys.workforceAdmin.tr,
                            fontSize: 16,
                            color: kColorWhite,
                          ),
                        ],
                      ),
                    ),
                    Spacing.v24,
                    SemiBoldText(
                      text: LocaleKeys.objectives.tr.toUpperCase(),
                      fontSize: 16,
                      color: kColorWhite,
                    ),
                    Spacing.v8,
                    _objList(),
                    Spacing.v16,
                    SemiBoldText(
                      text: LocaleKeys.employeeHub.tr.toUpperCase(),
                      fontSize: 16,
                      color: kColorWhite,
                    ),
                    Spacing.v8,
                    _empHubList(),
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

  _objList() {
    return ListView.builder(
      itemCount: AdminModules.drawerObjList.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        var data = AdminModules.drawerObjList[index];
        return GestureDetector(
          onTap: () {
            if ((data.routeTo ?? '').isNotEmpty) {
              Get.toNamed(data.routeTo ?? '');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: SvgPicture.asset(
                    data.icon ?? '',
                    alignment: Alignment.center,
                  ),
                ),
                Spacing.h16,
                SemiBoldText(
                  text: data.name,
                  fontSize: 16,
                  color: kColorGrey187,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  _empHubList() {
    return ListView.builder(
      itemCount: AdminModules.drawerEmpHubList.length,
      shrinkWrap: true,
      itemBuilder: (context, index) {
        var data = AdminModules.drawerEmpHubList[index];
        return GestureDetector(
          onTap: () {
            if ((data.routeTo ?? '').isNotEmpty) {
              Get.toNamed(data.routeTo ?? '');
            }
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: SvgPicture.asset(data.icon ?? ''),
                ),
                Spacing.h16,
                SemiBoldText(
                  text: data.name,
                  fontSize: 16,
                  color: kColorGrey187,
                ),
              ],
            ),
          ),
        );
      },
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
            color: kColorGrey187.withValues(alpha: 0.3),
          ),
          Spacing.v16,
          GestureDetector(
            onTap: () => _handleLogout(),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: kColorWhite,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: kColorWhite,
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

  /// Build header section with dynamic user data from local storage
  Widget _buildHeader() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Get.find<LocalStorage>().getAdminUserData(),
      builder: (context, snapshot) {
        String userName = 'Admin';
        String userEmail = '';

        if (snapshot.hasData && snapshot.data != null) {
          userName = snapshot.data!['name'] ?? 'Admin';
          userEmail = snapshot.data!['email'] ?? '';
        }

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
                          colors: kColorWhite,
                        ),
                      ),
                      SemiBoldText(
                        text: userName,
                        color: kColorWhite,
                        fontSize: TextStyles.k16FontSize,
                      ),
                      if (userEmail.isNotEmpty) ...[
                        Spacing.v2,
                        SizedBox(
                          width: Get.width * 0.4,
                          child: AppText(
                            text: userEmail,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.kRegularLato(
                              fontSize: TextStyles.k10FontSize,
                              colors: kColorWhite.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              GestureDetector(
                onTap: () {
                  Get.back(); // Close drawer
                  Get.toNamed(Routes.SETTINGS);
                },
                child: SvgPicture.asset(kIconSettings),
              ),
            ],
          ),
        );
      },
    );
  }
}
