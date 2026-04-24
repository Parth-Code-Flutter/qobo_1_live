import 'package:aligned_rewards/utils/app_widgets/app_horizontal_divider.dart';
import 'package:aligned_rewards/utils/app_widgets/container_box_shadow_util.dart';
import 'package:aligned_rewards/utils/ui_utils/app_ui_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/constants/image_constants.dart';
import 'package:aligned_rewards/utils/text_utils/app_text.dart';
import 'package:aligned_rewards/utils/text_utils/text_styles.dart';
import 'package:aligned_rewards/utils/app_widgets/app_spaces.dart';
import 'package:aligned_rewards/utils/app_widgets/overlapping_members_widget.dart';
import 'package:aligned_rewards/utils/app_widgets/common_action_icons_widget.dart';
import 'package:intl/intl.dart';

/// Modern Project Card Widget
///
/// Displays project information in a card format matching app store design:
/// - Project title (large, bold)
/// - Team member avatars (overlapping, with +X for more)
/// - Due date or status (with color coding for overdue)
/// - Circular progress indicator (showing completion percentage)
/// - Task count with checkbox icon
/// - Options menu (three dots) in top right
///
/// This widget is reusable across different project listing screens.
class ProjectCardWidget extends StatelessWidget {
  /// Project name/title
  final String projectName;

  /// List of member data maps with 'name' and optional 'image' keys
  /// Example: [{'name': 'John Doe', 'image': 'https://...'}, {'name': 'Jane Smith'}]
  final List<Map<String, dynamic>> members;

  /// Due date string (ISO format or date string)
  final String? dueDate;

  /// Created date string (ISO format or date string)
  /// This is shown in small text below the edit/delete icons.
  final String? createdDate;

  /// Project status (onTrack, notStarted, completed, maintenance)
  final String projectStatus;

  /// Total number of tasks
  final int totalTasks;

  /// Number of completed tasks
  final int completedTasks;

  /// Callback when card is tapped
  final VoidCallback? onTap;

  /// Callback when edit button is tapped
  final VoidCallback? onEdit;

  /// Callback when delete button is tapped
  final VoidCallback? onDelete;

  /// Callback when options menu is tapped
  final VoidCallback? onOptions;

  const ProjectCardWidget({
    super.key,
    required this.projectName,
    required this.members,
    this.dueDate,
    this.createdDate,
    required this.projectStatus,
    required this.totalTasks,
    required this.completedTasks,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onOptions,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate progress percentage
    final progressPercentage =
        totalTasks > 0 ? (completedTasks / totalTasks * 100).round() : 0;

    // Check if project is overdue
    final isOverdue = _isOverdue(dueDate);

    // Get status color
    final statusColor = _getStatusColor(projectStatus, isOverdue);

    // Get status text
    final statusText = _getStatusText(projectStatus, isOverdue, dueDate);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6,horizontal: 18),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kColorWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: containerBoxShadowUtils(),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main row with two columns
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // First Column (Left): Project title, status and task count in same row
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Project title with overflow handling for long names
                      SemiBoldText(
                        text: projectName,
                        fontSize: 14,
                        color: kColorBlack,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),

                      Spacing.v6,

                      // Status and task count in same row (below project title)
                      Row(
                        children: [
                          if (statusText.isNotEmpty) ...[
                            _buildDueDateOrStatus(
                                statusText, statusColor, isOverdue),
                            Spacing.h8,
                          ],
                          _buildTaskCount(),
                        ],
                      ),

                      // // Overlapping members widget
                      // OverlappingMembersWidget(
                      //   members: members,
                      //   maxVisible: 3,
                      //   avatarRadius: 18,
                      //   showEmptyState: false,
                      // ),
                    ],
                  ),
                ),

                Spacing.h12,

                // Second Column (Right): Edit and Delete icons, Task count
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Edit and Delete icons with square backgrounds
                    if (onEdit != null || onDelete != null) _buildActionIcons(),
                    if (createdDate != null && createdDate!.isNotEmpty) ...[
                      Spacing.v6,
                      _buildCreatedDateLabel(),
                    ],
                  ],
                ),
              ],
            ),

            // Horizontal divider after the row
            // Spacing.v12,
            // AppHorizontalDivider(
            //   color: kColorGreyDA,
            //   height: 0,
            //   thickness: 0.5,
            // ),

            // Linear progress bar below divider
            // Spacing.v10,
            // _buildLinearProgress(progressPercentage, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildActionIcons() {
    return CommonEditDeleteActionsRow(
      onEditTap: onEdit,
      onDeleteTap: onDelete,
      spacing: 8,
    );
  }

  /// Build created date label shown below the edit/delete icons.
  /// Parses the raw date string and formats it as `MMM dd, yyyy`.
  Widget _buildCreatedDateLabel() {
    String formatted = '';
    try {
      if (createdDate != null && createdDate!.isNotEmpty) {
        DateTime? parsed;
        // Try ISO first
        if (createdDate!.contains('T')) {
          parsed = DateTime.parse(createdDate!);
        } else {
          final formats = ['yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy'];
          for (final format in formats) {
            try {
              parsed = DateFormat(format).parse(createdDate!);
              break;
            } catch (_) {
              // try next format
            }
          }
        }
        if (parsed != null) {
          formatted = DateFormat('MMM dd, yyyy').format(parsed);
        }
      }
    } catch (_) {
      // If parsing fails, leave formatted empty to avoid showing invalid date.
    }

    if (formatted.isEmpty) {
      return const SizedBox.shrink();
    }

    return AppText(
      text: formatted,
      fontSize: 10,
      color: kColorGrey76,
    );
  }

  /// Build due date or status row
  Widget _buildDueDateOrStatus(
      String statusText, Color statusColor, bool isOverdue) {
    return Row(
      children: [
        if (isOverdue) ...[
          // Red clock icon for overdue
          Icon(
            Icons.access_time,
            size: 14,
            color: kColorRed,
          ),
          Spacing.h6,
        ],
        // Status text with rounded edges
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1), // Light background with status color
            borderRadius: BorderRadius.circular(12), // Rounded edges
          ),
          child: AppText(
            text: statusText.toUpperCase(),
            style: TextStyles.kBoldLato(
              fontSize: 8,
              colors: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  /// Build linear progress bar
  /// Displays progress as a horizontal bar with beautiful gradient colors
  /// Color scheme based on progress percentage:
  /// - Red: 0-33% (low progress or overdue)
  /// - Orange/Yellow: 34-66% (medium progress)
  /// - Green: 67-100% (high progress)
  Widget _buildLinearProgress(int percentage, Color statusColor) {
    // Determine progress color based on percentage
    Color progressColor;
    if (percentage <= 33) {
      progressColor = kColorTextGrey; // Red for low progress
    } else if (percentage <= 66) {
      progressColor = kColorOrangeFFA; // Orange/Yellow for medium progress
    } else {
      progressColor = kColorGreen4C; // Green for high progress
    }

    // Override with red if overdue
    if (_isOverdue(dueDate) && projectStatus != 'completed') {
      progressColor = kColorRed;
    }

    return Row(
      children: [
        // Progress bar with rounded corners
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                value: percentage / 100,
                backgroundColor: kColorGreyDA,
                valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                minHeight: 4,
              ),
            ),
          ),
        ),
        // Percentage text beside progress bar
        Spacing.h16,
        AppText(
          text: '$percentage%',
          fontSize: 12,
          color: progressColor,
          style: TextStyles.kBoldLato(
            fontSize: 12,
            colors: progressColor,
          ),
        ),
      ],
    );
  }

  /// Build task count with task icon
  /// Matches design: positioned in first column below members, light grey color
  Widget _buildTaskCount() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.assignment_outlined,
          size: 12,
          color: kColorGrey76,
        ),
        Spacing.h4,
        AppText(
          text: '$totalTasks ${totalTasks == 1 ? 'Task' : 'Tasks'}',
          fontSize: 10,
          color: kColorBlue08,
        ),
      ],
    );
  }

  /// Check if project is overdue
  bool _isOverdue(String? dueDate) {
    if (dueDate == null || dueDate.isEmpty) return false;

    try {
      // Try parsing ISO format first
      DateTime? parsedDate;
      if (dueDate.contains('T')) {
        parsedDate = DateTime.parse(dueDate);
      } else {
        // Try other date formats
        final formats = [
          'yyyy-MM-dd',
          'dd/MM/yyyy',
          'MM/dd/yyyy',
        ];
        for (final format in formats) {
          try {
            parsedDate = DateFormat(format).parse(dueDate);
            break;
          } catch (e) {
            continue;
          }
        }
      }

      if (parsedDate == null) return false;

      // Check if due date is in the past and project is not completed
      final now = DateTime.now();
      final due = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
      final today = DateTime(now.year, now.month, now.day);

      return due.isBefore(today) && projectStatus != 'completed';
    } catch (e) {
      return false;
    }
  }

  /// Get status text based on project status and due date
  String _getStatusText(String status, bool isOverdue, String? dueDate) {
    if (isOverdue) {
      // Calculate days late
      try {
        DateTime? parsedDate;
        if (dueDate != null && dueDate.isNotEmpty) {
          if (dueDate.contains('T')) {
            parsedDate = DateTime.parse(dueDate);
          } else {
            final formats = ['yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy'];
            for (final format in formats) {
              try {
                parsedDate = DateFormat(format).parse(dueDate);
                break;
              } catch (e) {
                continue;
              }
            }
          }

          if (parsedDate != null) {
            final now = DateTime.now();
            final due =
                DateTime(parsedDate.year, parsedDate.month, parsedDate.day);
            final today = DateTime(now.year, now.month, now.day);
            final daysLate = today.difference(due).inDays;

            if (daysLate > 0) {
              return '$daysLate ${daysLate == 1 ? 'Day' : 'Days'} Late';
            }
          }
        }
      } catch (e) {
        // Fall through to default
      }
      return 'Overdue';
    }

    if (dueDate != null && dueDate.isNotEmpty) {
      try {
        DateTime? parsedDate;
        if (dueDate.contains('T')) {
          parsedDate = DateTime.parse(dueDate);
        } else {
          final formats = ['yyyy-MM-dd', 'dd/MM/yyyy', 'MM/dd/yyyy'];
          for (final format in formats) {
            try {
              parsedDate = DateFormat(format).parse(dueDate);
              break;
            } catch (e) {
              continue;
            }
          }
        }

        if (parsedDate != null) {
          final formattedDate = DateFormat('MMM dd, yyyy').format(parsedDate);
          return 'Due Date: $formattedDate';
        }
      } catch (e) {
        // Fall through to status text
      }
    }

    // Return status text
    switch (status) {
      case 'onTrack':
        return 'On Track';
      case 'notStarted':
        return 'Not Started';
      case 'completed':
        return 'Completed';
      case 'maintenance':
        return 'Maintenance';
      default:
        return status;
    }
  }

  /// Get status color based on project status and overdue state
  Color _getStatusColor(String status, bool isOverdue) {
    if (isOverdue) {
      return kColorRed;
    }

    switch (status) {
      case 'onTrack':
        return kColorGreen4C;
      case 'notStarted':
        return kColorGrey76;
      case 'completed':
        return kColorOrangeFFA;
      case 'maintenance':
        return kColorYellow;
      default:
        return kColorGrey76;
    }
  }
}
