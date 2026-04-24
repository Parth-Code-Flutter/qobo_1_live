import 'package:aligned_rewards/constants/image_constants.dart';
import 'package:aligned_rewards/utils/app_widgets/app_spaces.dart';
import 'package:aligned_rewards/utils/app_widgets/app_text_field.dart';
import 'package:flutter/material.dart';
import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/utils/text_utils/app_text.dart';
import 'package:aligned_rewards/utils/text_utils/text_styles.dart';
import 'package:aligned_rewards/utils/ui_utils/app_ui_utils.dart';
import 'package:flutter_svg/svg.dart';

// Simple ValueItem class to avoid import issues
class ValueItem {
  final String label;
  final dynamic value;

  const ValueItem({
    required this.label,
    required this.value,
  });

  @override
  String toString() => label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ValueItem &&
          runtimeType == other.runtimeType &&
          label == other.label &&
          value == other.value;

  @override
  int get hashCode => label.hashCode ^ value.hashCode;
}

class AppMultiDropdown extends StatefulWidget {
  final List<ValueItem> items;
  final String? labelText;
  final String? hintText;
  final bool isRequired;
  final Function(List<ValueItem>)? onSelectionChanged;
  final List<ValueItem>? selectedItems;
  final bool isEnabled;
  final String? errorText;
  final bool showError;
  final EdgeInsetsGeometry padding;
  final String? fieldTitle;
  final TextStyle? labelStyle;
  final bool error;

  const AppMultiDropdown({
    super.key,
    required this.items,
    this.labelText,
    this.hintText,
    this.isRequired = false,
    this.onSelectionChanged,
    this.selectedItems,
    this.isEnabled = true,
    this.errorText,
    this.showError = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    this.fieldTitle,
    this.labelStyle,
    this.error = false,
  });

  @override
  State<AppMultiDropdown> createState() => _AppMultiDropdownState();
}

class _AppMultiDropdownState extends State<AppMultiDropdown> {
  List<ValueItem> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    if (widget.selectedItems != null) {
      _selectedItems = List.from(widget.selectedItems!);
    }
  }

  @override
  void didUpdateWidget(AppMultiDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedItems != null) {
      _selectedItems = List.from(widget.selectedItems!);
    }
  }

  void _showBottomSheet() {
    if (!widget.isEnabled) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return _MultiDropdownBottomSheet(
          items: widget.items,
          selectedItems: _selectedItems,
          onSelectionChanged: (selectedItems) {
            setState(() {
              _selectedItems = selectedItems;
            });
            if (widget.onSelectionChanged != null) {
              widget.onSelectionChanged!(selectedItems);
            }
          },
          fieldTitle: widget.fieldTitle ?? widget.labelText ?? 'Select Options',
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Field Title (above field, if provided)
        if (widget.fieldTitle != null) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AppText(
                    text: widget.fieldTitle!,
                    style: widget.labelStyle ?? AppUIUtils.labelTextFieldTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isRequired)
                  AppText(
                    text: ' *',
                    style: widget.labelStyle ??
                        AppUIUtils.labelTextFieldTextStyle
                            .copyWith(color: kColorRed),
                  ),
              ],
            ),
          ),
          Spacing.v8,
        ] else if (widget.labelText != null) ...[
          // Label Text (above field, matching text field pattern)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: AppText(
                    text: widget.labelText ?? '',
                    style: widget.labelStyle ?? AppUIUtils.labelTextFieldTextStyle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (widget.isRequired)
                  AppText(
                    text: ' *',
                    style: widget.labelStyle ??
                        AppUIUtils.labelTextFieldTextStyle
                            .copyWith(color: kColorRed),
                  ),
              ],
            ),
          ),
          Spacing.v8,
        ],

        // Multi Dropdown Field
        GestureDetector(
          onTap: _showBottomSheet,
          child: Container(
            decoration: BoxDecoration(
              color: widget.isEnabled ? kColorBackground : kColorFAFAFA,
              borderRadius: AppUIUtils.primaryBorderRadius,
              border: Border.all(
                color: widget.error ? kColorRed : kColorTextFieldBorder,
                width: 0.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected Items Display
                if (_selectedItems.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Selected items as compact chips/tags
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            ..._selectedItems.take(4).map((item) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kColorPrimary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: kColorPrimary.withValues(alpha: 0.2),
                                    width: 0.5,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 8,
                                      backgroundColor: kColorPrimary,
                                      child: AppText(
                                        text: item.label.isNotEmpty
                                            ? item.label[0].toUpperCase()
                                            : '?',
                                        style: TextStyles.kBoldLato(
                                          fontSize: 8,
                                          colors: kColorWhite,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: AppText(
                                        text: item.label,
                                        style: TextStyles.kMediumLato(
                                          fontSize: 11,
                                          colors: kColorBlack,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                            if (_selectedItems.length > 4)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: kColorGreyDA,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: AppText(
                                  text: '+${_selectedItems.length - 4}',
                                  style: TextStyles.kMediumLato(
                                    fontSize: 11,
                                    colors: kColorGrey76,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Selection count and dropdown arrow
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              AppText(
                                text: '${_selectedItems.length} selected',
                                style: TextStyles.kRegularLato(
                                  fontSize: 10,
                                  colors: kColorGrey76,
                                ),
                              ),
                              Icon(
                                Icons.keyboard_arrow_down,
                                color: kColorGrey76,
                                size: 16,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  // Empty state
                  Padding(
                    padding: widget.padding,
                    child: Row(
                      children: [
                        Expanded(
                          child: AppText(
                            text: widget.hintText ?? 'Select options',
                            style: AppUIUtils.hintTextFieldTextStyle,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          color: kColorGrey76,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        // Error Text
        if (widget.showError && widget.errorText != null) ...[
          const SizedBox(height: 8),
          AppText(
            text: widget.errorText!,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

class _MultiDropdownBottomSheet extends StatefulWidget {
  final List<ValueItem> items;
  final List<ValueItem> selectedItems;
  final Function(List<ValueItem>) onSelectionChanged;
  final String fieldTitle;

  const _MultiDropdownBottomSheet({
    required this.items,
    required this.selectedItems,
    required this.onSelectionChanged,
    required this.fieldTitle,
  });

  @override
  State<_MultiDropdownBottomSheet> createState() =>
      _MultiDropdownBottomSheetState();
}

class _MultiDropdownBottomSheetState extends State<_MultiDropdownBottomSheet> {
  late List<ValueItem> _selectedItems;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _selectedItems = List.from(widget.selectedItems);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ValueItem> get _filteredItems {
    if (_searchQuery.isEmpty) {
      return widget.items;
    }
    return widget.items
        .where((item) =>
            item.label.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _toggleItem(ValueItem item) {
    setState(() {
      if (_selectedItems.contains(item)) {
        _selectedItems.remove(item);
      } else {
        _selectedItems.add(item);
      }
    });
    widget.onSelectionChanged(_selectedItems);
  }

  void _selectAll() {
    setState(() {
      if (_filteredItems.isNotEmpty &&
          _selectedItems.length == _filteredItems.length) {
        _selectedItems.clear();
      } else {
        _selectedItems = List.from(_filteredItems);
      }
    });
    widget.onSelectionChanged(_selectedItems);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: kColorBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: kColorGreyD9, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: AppText(
                    text: widget.fieldTitle,
                    align: TextAlign.center,
                    style: TextStyles.kBoldLato(
                      fontSize: 18,
                      colors: kColorBlack,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.close,
                    color: kColorGrey76,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),

          // Search Section
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AppText(
                //   text: 'Search',
                //   style: TextStyles.kBoldLato(
                //     fontSize: 14,
                //     colors: kColorBlack,
                //   ),
                // ),
                Spacing.v8,
                AppTextField(
                  controller: _searchController,
                  hintText: 'Search for members',
                  labelText: 'Search',
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  prefix: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SvgPicture.asset(
                      kIconSearch2,
                      height: 20,
                      width: 20,
                    ),
                  ),
                  suffix: _searchQuery.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            setState(() {
                              _searchController.clear();
                              _searchQuery = '';
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Icon(
                              Icons.close,
                              size: 20,
                              color: kColorGrey76,
                            ),
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),

          // Avatar Row - show only selected items
          if (_filteredItems.isNotEmpty && _selectedItems.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedItems.length,
                  itemBuilder: (context, index) {
                    final item = _selectedItems[index];
                    return Container(
                      margin: const EdgeInsets.only(right: 8),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: kColorPrimary,
                        child: AppText(
                          text: item.label.isNotEmpty
                              ? item.label[0].toUpperCase()
                              : '?',
                          style: TextStyles.kBoldLato(
                            fontSize: 12,
                            colors: kColorWhite,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Spacing.v16,
          ],

          // Select All Checkbox
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GestureDetector(
              onTap: () => _selectAll(),
              child: Row(
                children: [
                  Checkbox(
                    value: _filteredItems.isNotEmpty &&
                        _selectedItems.length == _filteredItems.length,
                    onChanged: (value) => _selectAll(),
                    activeColor: kColorPrimary,
                    checkColor: kColorWhite,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  AppText(
                    text: 'Select All',
                    style: TextStyles.kMediumLato(
                      fontSize: 14,
                      colors: kColorBlack,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Spacing.v8,
          // Items List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredItems.length,
              itemBuilder: (context, index) {
                final item = _filteredItems[index];
                final isSelected = _selectedItems.contains(item);

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: kColorBackground,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: kColorGreyD9,
                      width: 0.5,
                    ),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    onTap: () => _toggleItem(item),
                    leading: Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Checkbox(
                        value: isSelected,
                        onChanged: (value) => _toggleItem(item),
                        activeColor: kColorPrimary,
                        checkColor: kColorWhite,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity:
                            VisualDensity(horizontal: -4, vertical: -4),
                      ),
                    ),
                    title: Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: kColorPrimary,
                          child: AppText(
                            text: item.label.isNotEmpty
                                ? item.label[0].toUpperCase()
                                : '?',
                            style: TextStyles.kBoldLato(
                              fontSize: 12,
                              colors: kColorWhite,
                            ),
                          ),
                        ),
                        Spacing.h10,
                        // Wrap text column in Expanded so long labels wrap
                        // within the tile instead of overflowing the card.
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AppText(
                                text: item.label,
                                style: TextStyles.kMediumLato(
                                  fontSize: 14,
                                  colors: kColorBlack,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              AppText(
                                text:
                                    '${item.label.toLowerCase().replaceAll(' ', '')}@roundtechsquare.com',
                                style: TextStyles.kRegularLato(
                                  fontSize: 12,
                                  colors: kColorGrey76,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Helper class to create ValueItem from strings
class MultiDropdownHelper {
  static List<ValueItem> createItemsFromStrings(List<String> strings) {
    return strings
        .map((string) => ValueItem(label: string, value: string))
        .toList();
  }

  static List<ValueItem> createItemsFromMap(Map<String, String> map) {
    return map.entries
        .map((entry) => ValueItem(label: entry.value, value: entry.key))
        .toList();
  }

  static List<String> getSelectedValues(List<ValueItem> selectedItems) {
    return selectedItems.map((item) => item.value.toString()).toList();
  }

  static List<String> getSelectedLabels(List<ValueItem> selectedItems) {
    return selectedItems.map((item) => item.label).toList();
  }
}
