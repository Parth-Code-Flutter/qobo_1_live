import 'package:qobo_one_live/app/user_flow/role_application/role_application_view.dart';
import 'package:qobo_one_live/repo/agency/role_application_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AgencyOwnerStatusView extends StatelessWidget {
  const AgencyOwnerStatusView({super.key});
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    return RoleApplicationView(
      role: ApplicationRole.agency,
      statusOnly: true,
      initialLookup: args is Map ? (args['phone'] ?? '').toString() : '',
    );
  }
}
