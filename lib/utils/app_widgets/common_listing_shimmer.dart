import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../constants/color_constants.dart';
import 'app_spaces.dart';
import 'container_box_shadow_util.dart';
import '../ui_utils/app_ui_utils.dart';

/// Common shimmer effect widget for listing screens
/// This widget provides a consistent shimmer loading effect for:
/// - Employee listing (with profile avatar)
/// - Department listing (with description)
/// - Teams listing (with description)
/// - Projects listing (simple format)
/// - Roles listing (horizontal chips)
/// - Leaves listing (card format)
/// - Meetings listing (card format)
class CommonListingShimmer extends StatelessWidget {
  /// Number of shimmer items to display
  final int itemCount;
  
  /// Whether to show profile/avatar shimmer (for employee-like listings)
  final bool showProfileAvatar;
  
  /// Whether to show secondary text line (for department-like listings)
  final bool showSecondaryText;
  
  /// Whether to show action buttons shimmer
  final bool showActionButtons;
  
  /// Number of action buttons to show (default: 3 for send/edit/delete)
  final int actionButtonCount;
  
  /// Custom padding for the shimmer items
  final EdgeInsets? padding;
  
  /// Whether to use card format (with shadow and rounded corners)
  final bool useCardFormat;
  
  /// Whether to use horizontal scrollable format (for roles)
  final bool isHorizontal;

  const CommonListingShimmer({
    super.key,
    this.itemCount = 6,
    this.showProfileAvatar = true,
    this.showSecondaryText = false,
    this.showActionButtons = true,
    this.actionButtonCount = 3,
    this.padding,
    this.useCardFormat = false,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    // Horizontal scrollable format (for roles)
    if (isHorizontal) {
      return SizedBox(
        height: 50,
        child: ListView.builder(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.only(left: 16),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
              child: _buildHorizontalShimmerChip(context),
            );
          },
        ),
      );
    }
    
    // Regular list format
    // Use AlwaysScrollableScrollPhysics to ensure RefreshIndicator works properly
    // Remove shrinkWrap to allow ListView to fill available space and prevent loader conflicts
    return Padding(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: ListView.builder(
        itemCount: itemCount,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: EdgeInsets.symmetric(
              vertical: useCardFormat ? 10 : 8,
              horizontal: useCardFormat ? 2 : 0,
            ),
            child: useCardFormat 
                ? _buildCardShimmerItem(context)
                : _buildShimmerItem(context),
          );
        },
      ),
    );
  }

  /// Build regular shimmer item (for employee listing)
  Widget _buildShimmerItem(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kColorGreyDD,
      highlightColor: kColorWhite,
      period: const Duration(milliseconds: 1200),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Profile/Avatar + Text content
          Row(
            children: [
              if (showProfileAvatar) ...[
                // Profile/Avatar shimmer
                Container(
                  height: 50,
                  width: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kColorGreyDD,
                    border: Border.all(color: kColorGreyDD),
                  ),
                ),
                Spacing.h10,
              ],
              // Text content
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary text (name/title)
                  Container(
                    height: 16,
                    width: 120,
                    decoration: BoxDecoration(
                      color: kColorGreyDD,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Secondary text (role/description) - optional
                  if (showSecondaryText) ...[
                    Container(
                      height: 12,
                      width: 180,
                      decoration: BoxDecoration(
                        color: kColorGreyDD,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ] else ...[
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: kColorGreyDD,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          // Right side: Action buttons
          if (showActionButtons)
            Row(
              children: List.generate(
                actionButtonCount,
                (index) => Padding(
                  padding: EdgeInsets.only(left: index > 0 ? 10 : 0),
                  child: Container(
                    height: 28,
                    width: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: kColorGreyDD,
                      border: Border.all(color: kColorGreyDD),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Build card format shimmer item (for departments, teams, projects)
  Widget _buildCardShimmerItem(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kColorGreyDD,
      highlightColor: kColorWhite,
      period: const Duration(milliseconds: 1200),
      child: Container(
        padding: EdgeInsets.symmetric(
          vertical: useCardFormat ? 16 : 8,
          horizontal: 16,
        ),
        decoration: BoxDecoration(
          color: kColorWhite,
          borderRadius: AppUIUtils.primaryBorderRadius,
          boxShadow: useCardFormat ? containerBoxShadowUtils() : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left side: Text content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Primary text (name/title)
                  Container(
                    height: 16,
                    width: 150,
                    decoration: BoxDecoration(
                      color: kColorGreyDD,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  if (showSecondaryText) ...[
                    const SizedBox(height: 8),
                    Container(
                      height: 12,
                      width: 200,
                      decoration: BoxDecoration(
                        color: kColorGreyDD,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 4),
                    Container(
                      height: 12,
                      width: 80,
                      decoration: BoxDecoration(
                        color: kColorGreyDD,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Right side: Action buttons
            if (showActionButtons)
              Row(
                children: List.generate(
                  actionButtonCount,
                  (index) => Padding(
                    padding: EdgeInsets.only(left: index > 0 ? 8 : 0),
                    child: Container(
                      height: 28,
                      width: 28,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: kColorGreyDD,
                        border: Border.all(color: kColorGreyDD),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Build horizontal shimmer chip (for roles listing)
  Widget _buildHorizontalShimmerChip(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: kColorGreyDD,
      highlightColor: kColorWhite,
      period: const Duration(milliseconds: 1200),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: kColorGreyDD,
          borderRadius: AppUIUtils.homeBorderRadius,
          border: Border.all(color: kColorGreyDD),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 12,
              width: 60,
              decoration: BoxDecoration(
                color: kColorGreyDD,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                color: kColorGreyDD,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
