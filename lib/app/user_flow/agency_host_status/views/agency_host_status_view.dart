import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/theme/app_theme_colors.dart';
import 'package:qobo_one_live/theme/theme_context.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/app_text_field.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

import '../controllers/agency_host_status_controller.dart';

class AgencyHostStatusView extends GetView<AgencyHostStatusController> {
  const AgencyHostStatusView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.scaffold,
      appBar: AppBar(
        title: const Text('Application Status'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(
            24,
            30,
            24,
            28 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Obx(() => _statusHero(colors)),
              Spacing.v24,
              _lookupCard(colors),
              Spacing.v20,
              Obx(() => _statusCard(colors)),
              Spacing.v28,
              Obx(
                () => controller.isLoading.value
                    ? const Center(
                        child: CircularProgressIndicator(color: kColorPrimary),
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
                child: AppText(
                  text: 'Back to Home',
                  fontSize: TextStyles.k14FontSize,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusHero(AppThemeColors colors) {
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
          color: colors.textPrimary,
          align: TextAlign.center,
        ),
        Spacing.v8,
        AppText(
          text: searched
              ? 'Use your application ID or WhatsApp number to refresh status.'
              : 'Check by Application ID or phone number.',
          fontSize: TextStyles.k14FontSize,
          color: colors.textSecondary,
          align: TextAlign.center,
        ),
      ],
    );
  }

  Widget _lookupCard(AppThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceMuted,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SemiBoldText(
            text: 'Search With',
            fontSize: TextStyles.k14FontSize,
            color: colors.textPrimary,
          ),
          Spacing.v12,
          Obx(
            () => Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _lookupChip(
                  colors,
                  'Application ID',
                  AgencyStatusLookupType.applicationId,
                ),
                _lookupChip(colors, 'Phone', AgencyStatusLookupType.phone),
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
              prefix: Padding(
                padding: const EdgeInsets.only(left: 14, right: 10),
                child: Icon(
                  _iconForLookup(controller.lookupType.value),
                  color: colors.iconMuted,
                  size: 22,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _lookupChip(
    AppThemeColors colors,
    String label,
    AgencyStatusLookupType type,
  ) {
    final selected = controller.lookupType.value == type;
    return GestureDetector(
      onTap: () => controller.selectLookupType(type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? kColorPrimary : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? kColorPrimary : colors.border,
          ),
        ),
        child: SemiBoldText(
          text: label,
          fontSize: TextStyles.k12FontSize,
          color: selected ? kColorWhite : colors.textSecondary,
        ),
      ),
    );
  }

  Widget _statusCard(AppThemeColors colors) {
    final searched = controller.hasSearched.value;
    final status = controller.status.value;
    final reason = controller.reason.value;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _statusColor(status).withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          AppText(
            text: 'Current Status',
            fontSize: TextStyles.k14FontSize,
            color: colors.textSecondary,
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
              color: colors.textSecondary,
              align: TextAlign.center,
            ),
          ],
          Spacing.v16,
          _metaRow(colors, 'Application ID', controller.applicationId.value),
          _metaRow(colors, 'Host ID', controller.hostId.value),
          _metaRow(colors, 'Agency ID', controller.agencyId.value),
          _metaRow(colors, 'Phone', controller.phone.value),
        ],
      ),
    );
  }

  Widget _metaRow(AppThemeColors colors, String label, String value) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: colors.textSecondary,
            ),
          ),
          Flexible(
            child: SemiBoldText(
              text: value,
              fontSize: TextStyles.k12FontSize,
              color: colors.textPrimary,
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
      case AgencyStatusLookupType.hostId:
        return Icons.badge_outlined;
      case AgencyStatusLookupType.agencyId:
        return Icons.business_outlined;
      case AgencyStatusLookupType.phone:
        return Icons.phone_android_outlined;
    }
  }

  String _titleForStatus(String status) {
    if (_isApproved(status)) return 'Application Approved';
    if (_isRejected(status)) return 'Application Rejected';
    if (status.toLowerCase().contains('not')) return 'Application Not Found';
    return 'Application Submitted';
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('approved')) return Colors.green;
    if (normalized.contains('rejected') || normalized.contains('not')) {
      return Colors.redAccent;
    }
    return kColorPrimary;
  }

  bool _isApproved(String status) => status.toLowerCase().contains('approved');

  bool _isRejected(String status) {
    final normalized = status.toLowerCase();
    return normalized.contains('rejected') || normalized.contains('not');
  }
}
