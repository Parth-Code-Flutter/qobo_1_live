import 'package:flutter/material.dart';
import 'package:qobo_one_live/app/user_flow/live_room/models/live_room_filter_state.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_bottom_sheet.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Opens the Live Rooms filter sheet; returns applied [LiveRoomFilterState] or null.
Future<LiveRoomFilterState?> showLiveRoomFilterSheet({
  required BuildContext context,
  required LiveRoomFilterState initial,
}) {
  var draft = initial;

  return showAppBottomSheet<LiveRoomFilterState>(
    context: context,
    title: 'Filter Rooms',
    subtitle: 'Refine what you see in the list',
    theme: AppBottomSheetTheme.dark,
    actions: [
      AppBottomSheetAction(
        label: 'Reset',
        isPrimary: false,
        onPressed: (sheetContext) {
          Navigator.of(sheetContext).pop(const LiveRoomFilterState());
        },
      ),
      AppBottomSheetAction(
        label: 'Apply',
        onPressed: (sheetContext) {
          Navigator.of(sheetContext).pop(draft);
        },
      ),
    ],
    child: StatefulBuilder(
      builder: (context, setState) {
        void updateDraft(LiveRoomFilterState next) {
          setState(() => draft = next);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _FilterSection(
              title: 'Room Type',
              options: const [
                _FilterOption(id: LiveRoomFilterState.allTypes, label: 'All'),
                _FilterOption(id: 'AUDIO', label: 'Audio'),
                _FilterOption(id: 'VIDEO', label: 'Video'),
              ],
              selectedId: draft.roomType,
              onSelected: (id) => updateDraft(draft.copyWith(roomType: id)),
            ),
            Spacing.v20,
            _FilterSection(
              title: 'Region',
              options: const [
                _FilterOption(
                  id: LiveRoomFilterState.allRegions,
                  label: 'All',
                ),
                _FilterOption(id: 'IN', label: 'India'),
                _FilterOption(id: 'BD', label: 'Bangladesh'),
                _FilterOption(id: 'GLOBAL', label: 'Global'),
              ],
              selectedId: draft.region,
              onSelected: (id) => updateDraft(draft.copyWith(region: id)),
            ),
          ],
        );
      },
    ),
  );
}

class _FilterOption {
  const _FilterOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _FilterSection extends StatelessWidget {
  const _FilterSection({
    required this.title,
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final String title;
  final List<_FilterOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SemiBoldText(
          text: title,
          fontSize: TextStyles.k14FontSize,
          color: kColorWhite,
        ),
        Spacing.v12,
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected = selectedId == option.id;
            return GestureDetector(
              onTap: () => onSelected(option.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            LiveRoomUiColors.goLiveGradientStart,
                            LiveRoomUiColors.goLiveGradientEnd,
                          ],
                        )
                      : null,
                  color: isSelected ? null : LiveRoomUiColors.cardSurface,
                  border: Border.all(
                    color: isSelected
                        ? Colors.transparent
                        : LiveRoomUiColors.cardBorder,
                  ),
                ),
                child: SemiBoldText(
                  text: option.label,
                  fontSize: TextStyles.k12FontSize,
                  color: isSelected ? kColorWhite : kColorHint,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
