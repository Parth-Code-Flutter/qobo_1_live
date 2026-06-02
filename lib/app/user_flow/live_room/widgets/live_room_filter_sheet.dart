import 'package:flutter/material.dart';
import 'package:qobo_one_live/app/user_flow/live_room/models/live_room_filter_state.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/constants/live_room_ui_colors.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Opens the Live Rooms filter sheet; returns applied [LiveRoomFilterState] or null.
Future<LiveRoomFilterState?> showLiveRoomFilterSheet({
  required BuildContext context,
  required LiveRoomFilterState initial,
}) {
  return showModalBottomSheet<LiveRoomFilterState>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black54,
    builder: (sheetContext) => _LiveRoomFilterSheet(
      initial: initial,
      onClose: () => Navigator.of(sheetContext).pop(),
      onApply: (state) => Navigator.of(sheetContext).pop(state),
    ),
  );
}

class _LiveRoomFilterSheet extends StatefulWidget {
  const _LiveRoomFilterSheet({
    required this.initial,
    required this.onClose,
    required this.onApply,
  });

  final LiveRoomFilterState initial;
  final VoidCallback onClose;
  final ValueChanged<LiveRoomFilterState> onApply;

  @override
  State<_LiveRoomFilterSheet> createState() => _LiveRoomFilterSheetState();
}

class _LiveRoomFilterSheetState extends State<_LiveRoomFilterSheet> {
  late LiveRoomFilterState _draft;

  @override
  void initState() {
    super.initState();
    _draft = widget.initial;
  }

  void _update(LiveRoomFilterState next) => setState(() => _draft = next);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2A1A4E),
              Color(0xFF140C28),
            ],
          ),
          border: Border.all(
            color: LiveRoomUiColors.joinLiveBorder.withValues(alpha: 0.35),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Spacing.v10,
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            kColorPrimary.withValues(alpha: 0.5),
                            LiveRoomUiColors.joinLiveBorder.withValues(
                              alpha: 0.4,
                            ),
                          ],
                        ),
                        border: Border.all(
                          color: LiveRoomUiColors.joinLiveBorder.withValues(
                            alpha: 0.5,
                          ),
                        ),
                      ),
                      child: const Icon(
                        Icons.tune_rounded,
                        color: kColorWhite,
                        size: 22,
                      ),
                    ),
                    Spacing.h12,
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SemiBoldText(
                            text: 'Filter Rooms',
                            fontSize: TextStyles.k18FontSize,
                            color: kColorWhite,
                          ),
                          Spacing.v4,
                          AppText(
                            text: 'Refine what you see in the list',
                            fontSize: TextStyles.k12FontSize,
                            color: const Color(0xFFB8B8D0),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: widget.onClose,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: kColorWhite,
                        size: 24,
                      ),
                    ),
                  ],
                ),
              ),
              Spacing.v20,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _FilterSectionCard(
                      title: 'Room Type',
                      icon: Icons.mic_none_rounded,
                      child: _SegmentedFilterRow(
                        options: const [
                          _FilterOption(
                            id: LiveRoomFilterState.allTypes,
                            label: 'All',
                          ),
                          _FilterOption(id: 'AUDIO', label: 'Audio'),
                          _FilterOption(id: 'VIDEO', label: 'Video'),
                        ],
                        selectedId: _draft.roomType,
                        onSelected: (id) =>
                            _update(_draft.copyWith(roomType: id)),
                      ),
                    ),
                    Spacing.v12,
                    _FilterSectionCard(
                      title: 'Region',
                      icon: Icons.public_rounded,
                      child: _RegionChipGrid(
                        options: const [
                          _FilterOption(
                            id: LiveRoomFilterState.allRegions,
                            label: 'All',
                          ),
                          _FilterOption(id: 'IN', label: 'India'),
                          _FilterOption(id: 'BD', label: 'Bangladesh'),
                          _FilterOption(id: 'GLOBAL', label: 'Global'),
                        ],
                        selectedId: _draft.region,
                        onSelected: (id) =>
                            _update(_draft.copyWith(region: id)),
                      ),
                    ),
                  ],
                ),
              ),
              Spacing.v20,
              Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: _FooterButton(
                        label: 'Reset',
                        outlined: true,
                        onTap: () => widget.onApply(const LiveRoomFilterState()),
                      ),
                    ),
                    Spacing.h12,
                    Expanded(
                      flex: 2,
                      child: _FooterButton(
                        label: 'Apply Filters',
                        outlined: false,
                        onTap: () => widget.onApply(_draft),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOption {
  const _FilterOption({required this.id, required this.label});

  final String id;
  final String label;
}

class _FilterSectionCard extends StatelessWidget {
  const _FilterSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: LiveRoomUiColors.cardSurface.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: LiveRoomUiColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: LiveRoomUiColors.joinLiveBorder),
              Spacing.h8,
              SemiBoldText(
                text: title,
                fontSize: TextStyles.k14FontSize,
                color: kColorWhite,
              ),
            ],
          ),
          Spacing.v12,
          child,
        ],
      ),
    );
  }
}

/// Three-way segmented control for room type.
class _SegmentedFilterRow extends StatelessWidget {
  const _SegmentedFilterRow({
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_FilterOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: LiveRoomUiColors.cardBorder.withValues(alpha: 0.8),
        ),
      ),
      child: Row(
        children: options.map((option) {
          final isSelected = selectedId == option.id;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(option.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [
                            kColorLiveFilterChipGradientStart,
                            kColorLiveFilterChipGradientEnd,
                          ],
                        )
                      : null,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: kColorPrimary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: SemiBoldText(
                    text: option.label,
                    fontSize: TextStyles.k12FontSize,
                    color: isSelected ? kColorWhite : const Color(0xFF9E9EB8),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _RegionChipGrid extends StatelessWidget {
  const _RegionChipGrid({
    required this.options,
    required this.selectedId,
    required this.onSelected,
  });

  final List<_FilterOption> options;
  final String selectedId;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((option) {
        final isSelected = selectedId == option.id;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => onSelected(option.id),
            borderRadius: BorderRadius.circular(22),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: isSelected
                    ? null
                    : Colors.black.withValues(alpha: 0.18),
                gradient: isSelected
                    ? const LinearGradient(
                        colors: [
                          kColorLiveFilterChipGradientStart,
                          kColorLiveFilterChipGradientMid,
                          kColorLiveFilterChipGradientEnd,
                        ],
                      )
                    : null,
                border: Border.all(
                  color: isSelected
                      ? kColorLiveFilterChipBorder
                      : LiveRoomUiColors.cardBorder,
                ),
              ),
              child: SemiBoldText(
                text: option.label,
                fontSize: TextStyles.k12FontSize,
                color: isSelected ? kColorWhite : const Color(0xFF9E9EB8),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _FooterButton extends StatelessWidget {
  const _FooterButton({
    required this.label,
    required this.onTap,
    required this.outlined,
  });

  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Ink(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: outlined ? Colors.transparent : null,
            gradient: outlined
                ? null
                : const LinearGradient(
                    colors: [
                      LiveRoomUiColors.goLiveGradientStart,
                      LiveRoomUiColors.goLiveGradientEnd,
                    ],
                  ),
            border: outlined
                ? Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                    width: 1.2,
                  )
                : null,
            boxShadow: outlined
                ? null
                : [
                    BoxShadow(
                      color: LiveRoomUiColors.goLiveGradientStart
                          .withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Center(
            child: SemiBoldText(
              text: label,
              fontSize: TextStyles.k14FontSize,
              color: outlined ? kColorWhite : kColorWhite,
            ),
          ),
        ),
      ),
    );
  }
}
