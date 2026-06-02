import 'package:flutter/material.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_button.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Visual theme for [showAppBottomSheet].
class AppBottomSheetTheme {
  const AppBottomSheetTheme({
    required this.backgroundColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.handleColor,
    required this.dividerColor,
  });

  final Color backgroundColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color handleColor;
  final Color dividerColor;

  static const light = AppBottomSheetTheme(
    backgroundColor: kColorWhite,
    titleColor: kColorText,
    subtitleColor: kColorHint,
    handleColor: Color(0xFFE2E8F0),
    dividerColor: Color(0xFFE2E8F0),
  );

  static const dark = AppBottomSheetTheme(
    backgroundColor: Color(0xFF1A1230),
    titleColor: kColorWhite,
    subtitleColor: kColorHint,
    handleColor: Color(0x55FFFFFF),
    dividerColor: Color(0x33FFFFFF),
  );
}

/// Primary / secondary action for the sheet footer.
class AppBottomSheetAction {
  const AppBottomSheetAction({
    required this.label,
    required this.onPressed,
    this.isPrimary = true,
  });

  final String label;
  final void Function(BuildContext sheetContext) onPressed;
  final bool isPrimary;
}

/// Shared modal bottom sheet shell — use across filters, pickers, etc.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required String title,
  required Widget child,
  String? subtitle,
  AppBottomSheetTheme theme = AppBottomSheetTheme.light,
  List<AppBottomSheetAction>? actions,
  bool isScrollControlled = true,
  bool useSafeArea = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return AppBottomSheetShell(
        title: title,
        subtitle: subtitle,
        theme: theme,
        actions: actions,
        useSafeArea: useSafeArea,
        child: child,
      );
    },
  );
}

class AppBottomSheetShell extends StatelessWidget {
  const AppBottomSheetShell({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.theme = AppBottomSheetTheme.light,
    this.actions,
    this.useSafeArea = true,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final AppBottomSheetTheme theme;
  final List<AppBottomSheetAction>? actions;
  final bool useSafeArea;

  @override
  Widget build(BuildContext context) {
    final sheetContext = context;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.backgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: SafeArea(
          top: false,
          bottom: useSafeArea,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Spacing.v10,
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.handleColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Spacing.v16,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    SemiBoldText(
                      text: title,
                      fontSize: TextStyles.k18FontSize,
                      color: theme.titleColor,
                    ),
                    if (subtitle != null) ...[
                      Spacing.v6,
                      AppText(
                        text: subtitle!,
                        fontSize: TextStyles.k12FontSize,
                        color: theme.subtitleColor,
                        align: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
              Spacing.v16,
              Divider(height: 1, color: theme.dividerColor),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: child,
                ),
              ),
              if (actions != null && actions!.isNotEmpty) ...[
                Divider(height: 1, color: theme.dividerColor),
                Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + bottomInset),
                  child: Row(
                    children: _buildActions(sheetContext),
                  ),
                ),
              ] else
                SizedBox(height: bottomInset > 0 ? 8 : 0),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildActions(BuildContext sheetContext) {
    final widgets = <Widget>[];
    for (var i = 0; i < actions!.length; i++) {
      final action = actions![i];
      if (i > 0) widgets.add(Spacing.h12);
      widgets.add(
        Expanded(
          child: action.isPrimary
              ? appButton(
                  onPressed: () => action.onPressed(sheetContext),
                  buttonText: action.label,
                  buttonColor: kColorPrimary,
                )
              : appButton(
                  onPressed: () => action.onPressed(sheetContext),
                  buttonText: action.label,
                  buttonColor: kColorWhite,
                  buttonBorderColor: kColorHint,
                  textColor: kColorText,
                  isGradient: false,
                ),
        ),
      );
    }
    return widgets;
  }
}
