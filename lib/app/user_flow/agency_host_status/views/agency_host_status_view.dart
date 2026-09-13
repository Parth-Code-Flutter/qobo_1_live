import 'package:qobo_one_live/app/user_flow/role_application/role_application_view.dart';
import 'package:qobo_one_live/repo/agency/role_application_repo.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AgencyHostStatusView extends StatelessWidget {
  const AgencyHostStatusView({super.key});
  @override
  Widget build(BuildContext context) {
    final args = Get.arguments;
    return RoleApplicationView(
      role: ApplicationRole.host,
      statusOnly: true,
      initialLookup: args is Map ? (args['phone'] ?? '').toString() : '',
    );
  }
}
