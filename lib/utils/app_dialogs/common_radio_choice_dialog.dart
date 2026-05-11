import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Centered dialog: title, vertical [Radio] list, **Cancel** + **Confirm** (matches [CommonAppDialog] chrome).
class CommonRadioChoiceDialog extends StatefulWidget {
  const CommonRadioChoiceDialog({
    super.key,
    required this.title,
    required this.options,
    this.initialSelected,
  });

  final String title;
  final List<String> options;
  final String? initialSelected;

  /// Returns the chosen option on **Confirm**, or `null` on **Cancel** / dismiss.
  static Future<String?> show(
    BuildContext context, {
    required String title,
    required List<String> options,
    String? initialSelected,
    bool barrierDismissible = true,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (dialogContext) => CommonRadioChoiceDialog(
        title: title,
        options: options,
        initialSelected: initialSelected,
      ),
    );
  }

  @override
  State<CommonRadioChoiceDialog> createState() =>
      _CommonRadioChoiceDialogState();
}

class _CommonRadioChoiceDialogState extends State<CommonRadioChoiceDialog> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    final first = widget.options.isNotEmpty ? widget.options.first : '';
    final initial = widget.initialSelected;
    if (initial != null && widget.options.contains(initial)) {
      _selected = initial;
    } else {
      _selected = first;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: kColorWhite,
      shadowColor: Colors.transparent,
      surfaceTintColor: kColorWhite,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SemiBoldText(
              text: widget.title,
              fontSize: TextStyles.k16FontSize,
              color: kColorText,
              align: TextAlign.center,
            ),
            Spacing.v12,
            ...widget.options.map(
              (option) => RadioListTile<String>(
                value: option,
                groupValue: _selected,
                onChanged: (value) {
                  if (value != null) setState(() => _selected = value);
                },
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                activeColor: kColorPrimary,
                title: AppText(
                  text: option,
                  fontSize: TextStyles.k14FontSize,
                  color: kColorText,
                ),
              ),
            ),
            Spacing.v16,
            LayoutBuilder(
              builder: (context, constraints) {
                final half = (constraints.maxWidth - 12) / 2;
                return Row(
                  children: [
                    SizedBox(
                      width: half,
                      child: appButton(
                        onPressed: () => Navigator.of(context).pop<String>(),
                        buttonText: 'Cancel',
                        buttonHeight: 44,
                        buttonWidth: half,
                        isGradient: false,
                        buttonBorderColor: kColorHint,
                        buttonColor: kColorWhite,
                        textStyle: TextStyles.kSemiBoldPoppins(
                          fontSize: TextStyles.k14FontSize,
                          colors: kColorText,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: half,
                      child: appButton(
                        onPressed: () =>
                            Navigator.of(context).pop<String>(_selected),
                        buttonText: 'Confirm',
                        buttonHeight: 44,
                        buttonWidth: half,
                        isGradient: true,
                        textStyle: TextStyles.kSemiBoldPoppins(
                          fontSize: TextStyles.k14FontSize,
                          colors: kColorWhite,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
