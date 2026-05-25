import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_host_status_controller.dart';

class AgencyHostStatusView extends GetView<AgencyHostStatusController> {
  const AgencyHostStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kColorWhite,
      appBar: AppBar(
        title: const SemiBoldText(
          text: 'Application Status',
          fontSize: TextStyles.k18FontSize,
          color: kColorText,
        ),
        backgroundColor: kColorWhite,
        centerTitle: true,
        elevation: 0,
        leading: const BackButton(color: kColorText),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.access_time_rounded,
                size: 80,
                color: kColorPrimary,
              ),
              Spacing.v24,
              const SemiBoldText(
                text: 'Application Submitted',
                fontSize: TextStyles.k22FontSize,
                color: kColorText,
                align: TextAlign.center,
              ),
              Spacing.v10,
              Obx(() => AppText(
                text: 'Application ID: ${controller.applicationId.value}',
                fontSize: TextStyles.k14FontSize,
                color: kColorHint,
                align: TextAlign.center,
              )),
              Spacing.v24,
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    const AppText(
                      text: 'Current Status',
                      fontSize: TextStyles.k14FontSize,
                      color: kColorHint,
                    ),
                    Spacing.v6,
                    Obx(() => SemiBoldText(
                      text: controller.status.value,
                      fontSize: TextStyles.k18FontSize,
                      color: kColorPrimary,
                    )),
                  ],
                ),
              ),
              const Spacer(),
              Obx(() => controller.isLoading.value
                  ? const Center(child: CircularProgressIndicator(color: kColorPrimary))
                  : appButton(
                      onPressed: controller.refreshStatus,
                      buttonText: 'Refresh Status',
                    )),
              Spacing.v20,
              TextButton(
                onPressed: () {
                  Get.offAllNamed('/bottom-nav'); // Go back to home
                },
                child: const AppText(
                  text: 'Back to Home',
                  fontSize: TextStyles.k14FontSize,
                  color: kColorHint,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
