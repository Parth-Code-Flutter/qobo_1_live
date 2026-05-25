import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_owner_controller.dart';

class AgencyOwnerView extends StatelessWidget {
  const AgencyOwnerView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(AgencyOwnerController());

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _header(),
              Expanded(
                child: Obx(() {
                  if (!controller.hasAgency.value) {
                    return _buildCreateAgencyScreen(controller);
                  }
                  return _buildDashboardScreen(controller);
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: Get.back,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: kColorWhite, size: 16),
            ),
          ),
          const Expanded(
            child: Center(
              child: SemiBoldText(
                text: 'Agency Owner Center',
                fontSize: 18,
                color: kColorWhite,
              ),
            ),
          ),
          const SizedBox(width: 36), // spacing balance
        ],
      ),
    );
  }

  Widget _buildCreateAgencyScreen(AgencyOwnerController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BoldText(text: 'Register Your Agency', fontSize: 22, color: kColorWhite),
          Spacing.v6,
          const AppText(
            text: 'Create a new agency to onboard hosts, track performance, and earn host commissions.',
            fontSize: 12,
            color: Colors.white70,
          ),
          Spacing.v24,
          const AppText(text: 'Agency Name', fontSize: 13, color: kColorWhite),
          Spacing.v6,
          AppTextField(
            controller: controller.nameController,
            hintText: 'e.g. Star Agency Pakistan',
            fillColor: Colors.white10,
            borderColor: Colors.white12,
            textStyle: TextStyles.kRegularPoppins(colors: kColorWhite, fontSize: 13),
          ),
          Spacing.v16,
          const AppText(text: 'Description', fontSize: 13, color: kColorWhite),
          Spacing.v6,
          AppTextField(
            controller: controller.descController,
            hintText: 'Describe your agency goals/requirements...',
            maxLines: 4,
            fillColor: Colors.white10,
            borderColor: Colors.white12,
            textStyle: TextStyles.kRegularPoppins(colors: kColorWhite, fontSize: 13),
          ),
          Spacing.v32,
          SizedBox(
            width: double.infinity,
            height: 48,
            child: appButton(
              onPressed: controller.createAgency,
              buttonText: 'Register Agency',
              isGradient: true,
              borderRadius: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardScreen(AgencyOwnerController controller) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Agency Info Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE91E63), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Obx(() => BoldText(text: controller.agencyName.value, fontSize: 20, color: kColorWhite)),
                Spacing.v4,
                const AppText(text: 'Creator Commission: 15%', fontSize: 11, color: Colors.white70),
                Spacing.v16,
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _dashboardTile('Monthly Rev', 'PKR ${controller.monthlyEarningsPkr.value}', Colors.white),
                    _dashboardTile('Payout due', 'PKR ${controller.pendingCommissionPkr.value}', Colors.amberAccent),
                    _dashboardTile('Total Hosts', '${controller.totalHosts.value}', Colors.white),
                  ],
                ),
              ],
            ),
          ),
          Spacing.v20,

          // Share and invite code section (AGENCY-04)
          const SemiBoldText(text: 'Recruitment & Invite Links', fontSize: 14, color: kColorWhite),
          Spacing.v10,
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.black38,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(text: 'Agency Code', fontSize: 10, color: Colors.white38),
                          Spacing.v4,
                          Obx(() => SemiBoldText(text: controller.agencyCode.value, fontSize: 13, color: Colors.amber)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy_rounded, color: Colors.amber, size: 18),
                      onPressed: controller.copyInviteCode,
                    ),
                  ],
                ),
                const Divider(color: Colors.white12, height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppText(text: 'Agency Recruitment Link', fontSize: 10, color: Colors.white38),
                          Spacing.v4,
                          const AppText(text: 'https://qobo.live/agency/join...', fontSize: 12, color: Colors.white70),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.share_rounded, color: kColorWhite, size: 18),
                      onPressed: controller.copyInviteLink,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Spacing.v20,

          // Active Hosts list
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SemiBoldText(text: 'My Hosts', fontSize: 14, color: kColorWhite),
              AppText(text: 'Total: ${controller.hosts.length}', fontSize: 11, color: Colors.white38),
            ],
          ),
          Spacing.v10,
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.hosts.length,
            separatorBuilder: (_, __) => Spacing.v10,
            itemBuilder: (_, index) {
              final host = controller.hosts[index];
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundImage: AssetImage(host['avatar']),
                    ),
                    Spacing.h12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SemiBoldText(text: host['name'], fontSize: 13, color: kColorWhite),
                          Spacing.v2,
                          AppText(text: 'Host ID: ${host['id']}', fontSize: 10, color: Colors.white54),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        SemiBoldText(text: 'PKR ${host['earningsPkr']}', fontSize: 13, color: Colors.green),
                        Spacing.v2,
                        AppText(text: 'Commission: PKR ${host['commissionPkr']}', fontSize: 9, color: Colors.amber),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _dashboardTile(String label, String value, Color valueColor) {
    return Column(
      children: [
        AppText(text: label, fontSize: 10, color: Colors.white70),
        Spacing.v4,
        SemiBoldText(text: value, fontSize: 14, color: valueColor),
      ],
    );
  }
}
