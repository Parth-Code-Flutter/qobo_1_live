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
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

class EmployeeDrawerWidget extends StatelessWidget {
  const EmployeeDrawerWidget({super.key});

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
                    // Employee indicator
                    _buildEmployeeIndicator(),
                    Spacing.v24,
                    // Objectives section
                    SemiBoldText(
                      text: LocaleKeys.objectives.tr.toUpperCase(),
                      fontSize: 16,
                      color: kColorWhite,
                    ),
                    Spacing.v8,
                    _buildObjectivesList(),
                    Spacing.v16,
                    // Employee Hub section
                    SemiBoldText(
                      text: LocaleKeys.employeeHub.tr.toUpperCase(),
                      fontSize: 16,
                      color: kColorWhite,
                    ),
                    Spacing.v8,
                    _buildEmployeeHubList(),
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

  /// Build header section with dynamic user data from local storage
  Widget _buildHeader() {
    return FutureBuilder<Map<String, dynamic>?>(
      future: Get.find<LocalStorage>().getEmployeeUserData(),
      builder: (context, snapshot) {
        String userName = 'Employee';
        String userEmail = '';
        
        if (snapshot.hasData && snapshot.data != null) {
          userName = snapshot.data!['name'] ?? 'Employee';
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
                      AppText(
                        text: userName,
                        style: TextStyles.kBoldLato(
                          fontSize: TextStyles.k14FontSize,
                          colors: kColorWhite,
                        ),
                      ),
                      if (userEmail.isNotEmpty) ...[
                        Spacing.v2,
                        AppText(
                          text: userEmail,
                          style: TextStyles.kRegularLato(
                            fontSize: TextStyles.k10FontSize,
                            colors: kColorWhite.withValues(alpha: 0.7),
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

  /// Build employee indicator
  Widget _buildEmployeeIndicator() {
    return Row(
      children: [
        SvgPicture.asset(kIconWorkForceAdmin),
        Spacing.h16,
        MediumText(
          text: 'Employee',
          fontSize: 16,
          color: kColorWhite,
        ),
      ],
    );
  }

  /// Build objectives list (same as admin drawer)
  Widget _buildObjectivesList() {
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
                SvgPicture.asset(
                  data.icon ?? '',
                  alignment: Alignment.center,
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

  /// Build employee hub list (same as admin drawer)
  Widget _buildEmployeeHubList() {
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
                SvgPicture.asset(data.icon ?? ''),
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
                color: kColorRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: kColorRed.withValues(alpha: 0.3),
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

  /// Handle logout
  void _handleLogout() async {
    try {
      // Clear all stored data
      await Get.find<LocalStorage>().clearAllData();
      
      // Navigate to login options
      Get.offAllNamed(Routes.LOGIN_OPTIONS);
    } catch (e) {
      // Handle error
      Get.snackbar(
        'Error',
        'Failed to logout. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
}
