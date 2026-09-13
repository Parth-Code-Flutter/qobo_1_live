import 'package:qobo_one_live/app/user_flow/role_application/role_application_view.dart';
import 'package:qobo_one_live/repo/agency/role_application_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/agency_host_onboarding_controller.dart';

class AgencyHostOnboardingView extends GetView<AgencyHostOnboardingController> {
  const AgencyHostOnboardingView({super.key});
  @override
  Widget build(BuildContext context) => Obx(() {
    if (controller.isAgencyCodePrefilling.value) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return RoleApplicationView(
      role: ApplicationRole.host,
      initialCode: controller.agencyCodeController.text,
      lockCode: controller.isAgencyCodeLocked.value,
      forAnotherUser:
          controller.isFromAgencyOwner.value ||
          controller.isFromSuperAdmin.value,
    );
  });
}
