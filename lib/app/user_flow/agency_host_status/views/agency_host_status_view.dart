import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_shell_background.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_host_status_controller.dart';

class AgencyHostStatusView extends GetView<AgencyHostStatusController> {
  const AgencyHostStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppShellBackground(
        child: SafeArea(
          child: Column(
            children: [
              _appBar(),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    12,
                    24,
                    28 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Obx(() => _statusHero()),
                      Spacing.v24,
                      _lookupCard(context),
                      Spacing.v20,
                      Obx(() => _statusCard()),
                      Spacing.v28,
                      Obx(
                        () => controller.isLoading.value
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: kColorWhite,
                                ),
                              )
                            : appButton(
                                onPressed: controller.fetchStatus,
                                buttonText: controller.hasSearched.value
                                    ? 'Refresh Status'
                                    : 'Check Status',
                              ),
                      ),
                      Spacing.v16,
                      TextButton(
                        onPressed: () => Get.offAllNamed('/bottom-nav'),
                        child: const AppText(
                          text: 'Back to Home',
                          fontSize: TextStyles.k14FontSize,
                          color: Color(0x99FFFFFF),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 16, 4),
      child: Row(
        children: [
          IconButton(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: kColorWhite, size: 18),
          ),
          const Expanded(
            child: SemiBoldText(
              text: 'Application Status',
              fontSize: TextStyles.k18FontSize,
              color: kColorWhite,
              align: TextAlign.center,
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _statusHero() {
    final searched = controller.hasSearched.value;
    final status = controller.status.value;
    final icon = !searched
        ? Icons.manage_search_rounded
        : _isApproved(status)
        ? Icons.verified_rounded
        : _isRejected(status)
        ? Icons.cancel_rounded
        : Icons.access_time_rounded;

    return Column(
      children: [
        Icon(icon, size: 88, color: _statusColor(status)),
        Spacing.v24,
        SemiBoldText(
          text: searched ? _titleForStatus(status) : 'Find Your Application',
          fontSize: TextStyles.k22FontSize,
          color: kColorWhite,
          align: TextAlign.center,
        ),
        Spacing.v8,
        AppText(
          text: searched
              ? 'Use your application ID or WhatsApp number to refresh status.'
              : 'Check by Application ID or phone number.',
          fontSize: TextStyles.k14FontSize,
          color: const Color(0x99FFFFFF),
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget _lookupCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: appShellGlassDecoration(radius: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SemiBoldText(
            text: 'Search With',
            fontSize: TextStyles.k14FontSize,
            color: kColorWhite,
          ),
          Spacing.v12,
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _lookupChip(
                  'Application ID',
                  AgencyStatusLookupType.applicationId,
                ),
                _lookupChip('Phone', AgencyStatusLookupType.phone),
              ],
            ),
          ),
          Spacing.v16,
          Obx(
            () => AppTextField(
              controller: controller.lookupController,
              hintText: controller.lookupHint,
              textInputType: controller.keyboardType,
              textInputAction: TextInputAction.done,
              borderColor: kColorWhite.withValues(alpha: 0.2),
              fillColor: kColorWhite.withValues(alpha: 0.08),
              hintStyle: TextStyles.kRegularPoppins(
                fontSize: TextStyles.k14FontSize,
                colors: const Color(0x99FFFFFF),
              ),
              textStyle: TextStyles.kRegularPoppins(
                fontSize: TextStyles.k14FontSize,
                colors: kColorWhite,
              ),
              prefix: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  _iconForLookup(controller.lookupType.value),
                  color: const Color(0x99FFFFFF),
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lookupChip(String label, AgencyStatusLookupType type) {
    final selected = controller.lookupType.value == type;
    return GestureDetector(
      onTap: () => controller.selectLookupType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? kColorPrimary
              : kColorWhite.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? kColorPrimary
                : kColorWhite.withValues(alpha: 0.22),
          ),
        ),
        child: SemiBoldText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: selected ? kColorWhite : const Color(0xCCFFFFFF),
        ),
      ),
    );
  }

  Widget _statusCard() {
    final searched = controller.hasSearched.value;
    final status = controller.status.value;
    final reason = controller.reason.value;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.32)),
      ),
      child: Column(
        children: [
          const AppText(
            text: 'Current Status',
            fontSize: TextStyles.k14FontSize,
            color: Color(0x99FFFFFF),
          ),
          Spacing.v8,
          SemiBoldText(
            text: searched && status.isNotEmpty ? status : 'Not Checked',
            fontSize: TextStyles.k20FontSize,
            color: _statusColor(status),
            align: TextAlign.center,
          ),
          if (searched && reason.isNotEmpty) ...[
            Spacing.v10,
            AppText(
              text: reason,
              fontSize: 13,
              color: const Color(0x99FFFFFF),
              align: TextAlign.center,
            ),
          ],
          Spacing.v16,
          _metaRow('Host name', controller.hostName.value),
          _metaRow('Agency code', controller.agencyCode.value),
          _metaRow('Type', controller.hostType.value),
          _metaRow('Category', controller.hostInterest.value),
          _metaRow('Application ID', controller.applicationId.value),
          _metaRow('Host ID', controller.hostId.value),
          _metaRow('Phone', controller.phone.value),
          _metaRow('Submitted', controller.createdAt.value),
        ],
      ),
    );
  }

  Widget _metaRow(String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: const Color(0x99FFFFFF),
            ),
          ),
          Flexible(
            child: SemiBoldText(
              text: value,
              fontSize: TextStyles.k12FontSize,
              color: kColorWhite,
              align: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForLookup(AgencyStatusLookupType type) {
    switch (type) {
      case AgencyStatusLookupType.applicationId:
        return Icons.confirmation_number_outlined;
      case AgencyStatusLookupType.phone:
        return Icons.phone_android_outlined;
    }
  }

  String _titleForStatus(String status) {
    if (_isApproved(status)) return 'Application Approved';
    if (_isRejected(status)) return 'Application Rejected';
    if (status.toLowerCase().contains('not')) return 'Application Not Found';
    if (status.toLowerCase() == 'pending') return 'Application Pending';
    return 'Application Submitted';
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (_isApproved(status)) return Colors.greenAccent;
    if (_isRejected(status)) return Colors.redAccent;
    if (normalized == 'pending') return Colors.orangeAccent;
    return const Color(0xFFFF5CAB);
  }

  bool _isApproved(String status) {
    final normalized = status.toLowerCase();
    return normalized.contains('approved') || normalized == 'active';
  }

  bool _isRejected(String status) {
    final normalized = status.toLowerCase();
    return normalized.contains('rejected') || normalized.contains('not');
  }
}
