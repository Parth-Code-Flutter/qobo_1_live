import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/app_widgets/app_spaces.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:flutter/material.dart';

/// Reusable footer widget to display the current app version.
///
/// The label is sourced from [ApiConstants.appVersionLabel] so updating
/// the version in a single place keeps admin and employee settings in sync.
class AppVersionFooter extends StatelessWidget {
  const AppVersionFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(thickness: 0.5),
          Spacing.v8,
          AppText(
            text: 'App version: ${ApiConstants.appVersionLabel}',
            fontSize: 12,
            color: kColorHint,
          ),
        ],
      ),
    );
  }
}


