import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/super_admin/home/controllers/super_admin_home_controller.dart';
import 'package:qobo_one_live/app/super_admin/models/super_admin_models.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_glass_card.dart';
import 'package:qobo_one_live/app/super_admin/widgets/super_admin_ui_kit.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/app_widgets/safe_network_avatar.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Agency tab — `GET /api/super-admin/agencies` + process approve/reject.
class SuperAdminAgencyTabView extends GetView<SuperAdminHomeController> {
  const SuperAdminAgencyTabView({super.key});

  static const _filters = ['pending', 'approved', 'rejected', 'all'];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(image: AssetImage(kImgBG), fit: BoxFit.cover),
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SuperAdminTabHeader(
              icon: Icons.business_rounded,
              title: 'Agency',
              subtitle: 'Review and process agency applications',
            ),
            _filterChips(),
            Expanded(
              child: Obx(() {
                if (controller.isLoadingAgencies.value &&
                    controller.agencies.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: kColorPrimary),
                  );
                }
                final agencies = controller.agencies;
                if (agencies.isEmpty) {
                  return RefreshIndicator(
                    color: kColorPrimary,
                    onRefresh: () => controller.loadAgencies(showLoader: false),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 120),
                        SuperAdminEmptyState(
                          icon: Icons.storefront_outlined,
                          title: 'No agencies found',
                          subtitle:
                              'Pull down to refresh or try another filter',
                        ),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  color: kColorPrimary,
                  onRefresh: () => controller.loadAgencies(showLoader: false),
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 110),
                    itemCount: agencies.length,
                    separatorBuilder: (_, __) => Spacing.v12,
                    itemBuilder: (_, index) {
                      final agency = agencies[index];
                      final processing =
                          controller.processingAgencyId.value == agency.id;
                      return _agencyCard(context, agency, processing);
                    },
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  /// Icon shown inside each status filter pill.
  static const _filterIcons = <String, IconData>{
    'pending': Icons.hourglass_top_rounded,
    'approved': Icons.verified_rounded,
    'rejected': Icons.cancel_rounded,
    'all': Icons.grid_view_rounded,
  };

  Widget _filterChips() {
    return SizedBox(
      height: 44,
      child: Obx(() {
        final selected = controller.agencyStatusFilter.value;
        return ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _filters.length,
          separatorBuilder: (_, __) => Spacing.h8,
          itemBuilder: (_, index) {
            final filter = _filters[index];
            return _filterPill(filter, isSelected: selected == filter);
          },
        );
      }),
    );
  }

  /// Gradient pill for the selected status; frosted glass for the rest
  /// (same visual language as the discover live filters).
  Widget _filterPill(String filter, {required bool isSelected}) {
    final label = filter[0].toUpperCase() + filter.substring(1);
    return GestureDetector(
      onTap: () => controller.changeAgencyFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: isSelected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    kColorLiveFilterChipGradientStart,
                    kColorLiveFilterChipGradientMid,
                    kColorLiveFilterChipGradientEnd,
                  ],
                )
              : null,
          color: isSelected ? null : kColorWhite.withValues(alpha: 0.10),
          border: Border.all(
            color: isSelected
                ? kColorLiveFilterChipBorder
                : kColorWhite.withValues(alpha: 0.14),
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: kColorPrimary.withValues(alpha: 0.45),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _filterIcons[filter],
              size: 15,
              color: isSelected ? kColorWhite : Colors.white60,
            ),
            Spacing.h6,
            SemiBoldText(
              text: label,
              fontSize: TextStyles.k12FontSize,
              color: isSelected ? kColorWhite : Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  Widget _agencyCard(
    BuildContext context,
    SuperAdminAgencyItem agency,
    bool processing,
  ) {
    return SuperAdminGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SafeNetworkAvatar(
                url: agency.ownerAvatar,
                size: 46,
                fallback: CircleAvatar(
                  radius: 23,
                  backgroundColor: kColorPrimary,
                  child: Text(
                    agency.ownerName.isNotEmpty
                        ? agency.ownerName.characters.first
                        : 'A',
                  ),
                ),
              ),
              Spacing.h10,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SemiBoldText(
                      text: agency.name,
                      fontSize: TextStyles.k14FontSize,
                      color: kColorWhite,
                    ),
                    AppText(
                      text: '${agency.ownerName} • ${agency.code}',
                      fontSize: TextStyles.k10FontSize,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
              _statusPill(agency.status),
            ],
          ),
          Spacing.v12,
          AppText(
            text:
                '${agency.hostCount} hosts • ${agency.pendingHostsCount} pending hosts',
            fontSize: TextStyles.k12FontSize,
            color: Colors.white70,
          ),
          if (agency.isPending) ...[
            Spacing.v12,
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    label: 'Reject',
                    icon: Icons.close_rounded,
                    color: const Color(0xFFFF8A80).withValues(alpha: 0.16),
                    borderColor: const Color(0xFFFF8A80).withValues(alpha: 0.4),
                    foreground: const Color(0xFFFF8A80),
                    onTap: processing
                        ? null
                        : () => _confirmReject(context, agency),
                  ),
                ),
                Spacing.h10,
                Expanded(
                  child: _actionButton(
                    label: processing ? 'Wait...' : 'Approve',
                    icon: Icons.check_rounded,
                    color: const Color(0xFF2E9E5B),
                    foreground: kColorWhite,
                    onTap: processing
                        ? null
                        : () => controller.approveAgency(agency),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _statusPill(String status) {
    final color = status.toLowerCase() == 'pending'
        ? const Color(0xFFFFD166)
        : status.toLowerCase() == 'approved'
        ? const Color(0xFF4ADE80)
        : const Color(0xFFFF8A80);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: SemiBoldText(
        text: status,
        fontSize: TextStyles.k10FontSize,
        color: color,
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required Color foreground,
    required VoidCallback? onTap,
    Color? borderColor,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: borderColor != null ? Border.all(color: borderColor) : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: foreground),
              Spacing.h6,
              SemiBoldText(
                text: label,
                fontSize: TextStyles.k12FontSize,
                color: foreground,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReject(
    BuildContext context,
    SuperAdminAgencyItem agency,
  ) async {
    final feedbackController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: kColorWhite,
        title: const Text('Reject agency?'),
        content: TextField(
          controller: feedbackController,
          decoration: const InputDecoration(hintText: 'Optional feedback'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await controller.rejectAgency(agency, feedbackController.text.trim());
    }
    feedbackController.dispose();
  }
}
