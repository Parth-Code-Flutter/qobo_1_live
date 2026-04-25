import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';

/// Common widget for displaying overlapping member avatars
/// 
/// This widget displays a list of members with overlapping circular avatars.
/// Shows up to 3 avatars, and displays "+X members" if there are more.
/// 
/// Usage:
/// ```dart
/// OverlappingMembersWidget(
///   members: [
///     {'name': 'John Doe', 'image': 'https://...'},
///     {'name': 'Jane Smith', 'image': null},
///   ],
///   maxVisible: 3,
///   avatarRadius: 18,
///   onTap: () => showMembersList(),
/// )
/// ```
class OverlappingMembersWidget extends StatelessWidget {
  /// List of member data maps with 'name' and optional 'image' keys
  final List<Map<String, dynamic>> members;
  
  /// Maximum number of avatars to show before showing "+X members"
  final int maxVisible;
  
  /// Radius of each avatar circle
  final double avatarRadius;
  
  /// Callback when the widget is tapped (optional)
  final VoidCallback? onTap;
  
  /// Text to show when there are no members (optional)
  final String? emptyStateText;
  
  /// Show empty state icon when there are no members
  final bool showEmptyState;
  
  /// Background color for avatars (defaults to primary color)
  final Color? avatarBackgroundColor;

  const OverlappingMembersWidget({
    super.key,
    required this.members,
    this.maxVisible = 3,
    this.avatarRadius = 18,
    this.onTap,
    this.emptyStateText,
    this.showEmptyState = true,
    this.avatarBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final totalMembers = members.length;
    
    // Show empty state if no members
    if (totalMembers == 0 && showEmptyState) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          width: avatarRadius * 2,
          height: avatarRadius * 2,
          decoration: BoxDecoration(
            color: kColorHint,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.person_outline,
              size: avatarRadius,
              color: kColorHint,
            ),
          ),
        ),
      );
    }

    // Build overlapping avatars
    Widget widget = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: avatarRadius * 2,
          child: ListView.builder(
            itemCount: totalMembers > maxVisible ? maxVisible : totalMembers,
            shrinkWrap: true,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final member = members[index];
              final name = member['name']?.toString() ?? '';
              final image = member['image']?.toString();
              
              return Align(
                widthFactor: 0.6, // Creates overlap effect
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: kColorWhite,
                      width: 2.0, // White border width
                    ),
                  ),
                  child: CircleAvatar(
                    radius: avatarRadius,
                    // Always use primary color when there's no profile image
                    backgroundColor: (image == null || image.isEmpty)
                        ? kColorPrimary
                        : (avatarBackgroundColor ?? kColorPrimary),
                    backgroundImage: (image != null && image.isNotEmpty)
                        ? NetworkImage(image)
                        : null,
                    child: (image == null || image.isEmpty)
                        ? AppText(
                            text: name.isNotEmpty
                                ? name.substring(0, 1).toUpperCase()
                                : '?',
                            fontSize: avatarRadius * 0.67, // ~12 for radius 18
                            color: kColorWhite,
                            style: TextStyles.kBoldPoppins(
                              fontSize: avatarRadius * 0.67,
                              colors: kColorWhite,
                            ),
                          )
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
        // Show count circle if there are more than maxVisible
        if (totalMembers > maxVisible) ...[
          Align(
            widthFactor: 0.6, // Creates overlap effect
            child: Container(
              width: avatarRadius * 2,
              height: avatarRadius * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: kColorWhite,
                border: Border.all(
                  color: kColorHint,
                  width: 1.0,
                ),
              ),
              child: Center(
                child: AppText(
                  text: '+${totalMembers - maxVisible}',
                  fontSize: avatarRadius * 0.5, // ~9 for radius 18
                  color: kColorHint,
                  style: TextStyles.kBoldPoppins(
                    fontSize: avatarRadius * 0.5,
                    colors: kColorHint,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    // Wrap with GestureDetector if onTap is provided
    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: widget,
      );
    }

    return widget;
  }
}

