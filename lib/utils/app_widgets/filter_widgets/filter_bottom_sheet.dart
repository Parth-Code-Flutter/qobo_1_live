import 'package:flutter/material.dart';
import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/utils/ui_utils/app_ui_utils.dart';
import 'package:aligned_rewards/utils/app_widgets/app_spaces.dart';
import 'package:aligned_rewards/utils/app_widgets/horizontal_black_line.dart';
import 'package:aligned_rewards/utils/app_widgets/app_button.dart';
import 'package:aligned_rewards/utils/text_utils/app_text.dart'
    show AppText, SemiBoldText;
import 'package:aligned_rewards/utils/text_utils/text_styles.dart';

/// Filter option model for filter bottom sheet
/// 
/// Represents a single filter option with a value and display label
class FilterOption {
  /// The filter value (e.g., 'AZ', 'ZA', 'DL', '2024', etc.)
  final String value;

  /// The display label for this filter option
  final String label;

  const FilterOption({
    required this.value,
    required this.label,
  });
}

/// Filter section model for grouped filters
/// 
/// Represents a section of filters with a title and list of options
class FilterSection {
  /// Section title (e.g., 'Sort By', 'Status')
  final String? title;

  /// List of filter options in this section
  final List<FilterOption> options;

  const FilterSection({
    this.title,
    required this.options,
  });
}

/// Generic reusable filter bottom sheet widget
/// 
/// This widget provides a professional bottom sheet for filtering any list
/// with immediate filter application on selection.
/// 
/// Features:
/// - Dynamic filter options
/// - Configurable title
/// - Immediate filter application on selection
/// - Clear filter functionality
/// - Half screen initial height
/// - Draggable and scrollable
/// 
/// Usage:
/// ```dart
/// FilterBottomSheet.show(
///   context: context,
///   title: 'Filter & Sort',
///   currentFilter: controller.currentOrderBy.value,
///   filterOptions: [
///     FilterOption(value: 'AZ', label: 'Alphabetically (A-Z)'),
///     FilterOption(value: 'ZA', label: 'Alphabetically (Z-A)'),
///     FilterOption(value: 'DL', label: 'Created Date (Newest First)'),
///   ],
///   onFilterSelected: (filter) => controller.applyFilter(filter),
///   onClearFilter: () => controller.applyFilter('AZ'), // Reset to default
/// );
/// ```
class FilterBottomSheet {
  /// Show the filter bottom sheet with sections
  /// 
  /// [context] - Build context for showing the bottom sheet
  /// [title] - Title to display in the bottom sheet header (default: 'Filter & Sort')
  /// [currentFilter] - Currently selected filter value (can be from any section)
  /// [filterSections] - List of filter sections to display (with optional section titles)
  /// [onFilterSelected] - Callback when a filter option is selected (applies immediately)
  /// [onClearFilter] - Optional callback when clear filter is tapped. If not provided, clear button won't be shown.
  /// [initialHeight] - Initial height of the bottom sheet (0.0 to 1.0, default: 0.5 for half screen)
  /// [maxHeight] - Maximum height of the bottom sheet (default: 0.7)
  /// [minHeight] - Minimum height of the bottom sheet (default: 0.3)
  static void showWithSections({
    required BuildContext context,
    String title = 'Filter & Sort',
    String? currentFilter,
    required List<FilterSection> filterSections,
    required Function(String) onFilterSelected,
    VoidCallback? onClearFilter,
    double initialHeight = 0.5,
    double maxHeight = 0.7,
    double minHeight = 0.3,
  }) {
    if (filterSections.isEmpty || filterSections.every((section) => section.options.isEmpty)) {
      throw ArgumentError('filterSections cannot be empty');
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: kColorWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppUIUtils.primaryRadius),
          topRight: Radius.circular(AppUIUtils.primaryRadius),
        ),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialHeight,
          maxChildSize: maxHeight,
          minChildSize: minHeight,
          builder: (context, scrollController) {
            final bottomInset = MediaQuery.of(context).padding.bottom;

            return SafeArea(
              top: false,
              // Ensure content stays above the system gesture bar
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag handle
                  Spacing.v8,
                  const HorizontalBlackLine(),
                  Spacing.v16,
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SemiBoldText(
                          text: title,
                          style: TextStyles.kBoldLato(
                            fontSize: 18,
                            colors: kColorBlack,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            if (onClearFilter != null) {
                              onClearFilter();
                            }
                            Navigator.pop(context);
                          },
                          child: AppText(
                            text: 'Clear Filter',
                            style: TextStyles.kSemiBoldLato(
                              fontSize: 14,
                              colors: kColorPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Spacing.v8,
                  Divider(
                    color: kColorDivider,
                    thickness: 1,
                  ),
                  Spacing.v16,
                  // Filter options with sections
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      padding: EdgeInsets.fromLTRB(
                        20,
                        0,
                        20,
                        bottomInset + 16,
                      ),
                      children: [
                        ...filterSections.asMap().entries.expand((sectionEntry) {
                          final sectionIndex = sectionEntry.key;
                          final section = sectionEntry.value;
                          final List<Widget> widgets = [];
                          
                          // Add spacing before section (except first)
                          if (sectionIndex > 0) {
                            widgets.add(Spacing.v16);
                          }
                          
                          // Add section title if provided
                          if (section.title != null && section.title!.isNotEmpty) {
                            widgets.add(
                              Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: SemiBoldText(
                                  text: section.title!,
                                  style: TextStyles.kBoldLato(
                                    fontSize: 16,
                                    colors: kColorGrey76,
                                  ),
                                ),
                              ),
                            );
                          }
                          
                          // Add filter options in this section
                          widgets.addAll(section.options.asMap().entries.map((entry) {
                            final optionIndex = entry.key;
                            final option = entry.value;
                            return Column(
                              children: [
                                if (optionIndex > 0) Spacing.v12,
                                _FilterOptionItem(
                                  title: option.label,
                                  value: option.value,
                                  selectedValue: currentFilter ?? '',
                                  onTap: () {
                                    onFilterSelected(option.value);
                                    Navigator.pop(context);
                                  },
                                ),
                              ],
                            );
                          }).toList());
                          
                          return widgets;
                        }).toList(),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Show the filter bottom sheet (legacy method for backward compatibility)
  /// 
  /// [context] - Build context for showing the bottom sheet
  /// [title] - Title to display in the bottom sheet header (default: 'Filter & Sort')
  /// [currentFilter] - Currently selected filter value
  /// [filterOptions] - List of filter options to display
  /// [onFilterSelected] - Callback when a filter option is selected (applies immediately)
  /// [onClearFilter] - Optional callback when clear filter is tapped. If not provided, clear button won't be shown.
  /// [initialHeight] - Initial height of the bottom sheet (0.0 to 1.0, default: 0.5 for half screen)
  /// [maxHeight] - Maximum height of the bottom sheet (default: 0.7)
  /// [minHeight] - Minimum height of the bottom sheet (default: 0.3)
  static void show({
    required BuildContext context,
    String title = 'Filter & Sort',
    required String currentFilter,
    required List<FilterOption> filterOptions,
    required Function(String) onFilterSelected,
    VoidCallback? onClearFilter,
    double initialHeight = 0.5,
    double maxHeight = 0.7,
    double minHeight = 0.3,
  }) {
    showWithSections(
      context: context,
      title: title,
      currentFilter: currentFilter,
      filterSections: [FilterSection(options: filterOptions)],
      onFilterSelected: onFilterSelected,
      onClearFilter: onClearFilter,
      initialHeight: initialHeight,
      maxHeight: maxHeight,
      minHeight: minHeight,
    );
  }
}

/// Individual filter option widget with radio button style
class _FilterOptionItem extends StatelessWidget {
  final String title;
  final String value;
  final String selectedValue;
  final VoidCallback onTap;

  const _FilterOptionItem({
    required this.title,
    required this.value,
    required this.selectedValue,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected
              ? kColorPrimary.withValues(alpha: 0.1)
              : kColorBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? kColorPrimary : kColorGreyD9,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Radio button indicator
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? kColorPrimary : kColorGrey76,
                  width: 2,
                ),
                color: isSelected ? kColorPrimary : Colors.transparent,
              ),
              child: isSelected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: kColorWhite,
                        ),
                      ),
                    )
                  : null,
            ),
            Spacing.h12,
            // Filter option text
            Expanded(
              child: AppText(
                text: title,
                style: TextStyles.kRegularLato(
                  fontSize: 14,
                  colors: isSelected ? kColorBlack : kColorGrey76,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
