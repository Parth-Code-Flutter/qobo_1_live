import 'dart:io';

import 'package:aligned_rewards/constants/color_constants.dart';
import 'package:aligned_rewards/utils/app_widgets/app_spaces.dart';
import 'package:aligned_rewards/utils/text_utils/app_text.dart';
import 'package:aligned_rewards/utils/ui_utils/app_ui_utils.dart';
import 'package:flutter/material.dart';

/// A compact square tile used to preview a locally selected file.
///
/// - Shows an image thumbnail when [path] points to a common image type.
/// - Falls back to a file icon + extension text for non-image types or
///   when thumbnail loading fails.
/// - Displays a small close button in the top‑right corner which invokes
///   [onRemove] when tapped.
class SelectedFileTile extends StatelessWidget {
  const SelectedFileTile({
    super.key,
    required this.path,
    required this.onRemove,
  });

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final fileName =
        path.split('/').isNotEmpty ? path.split('/').last : path;
    final lower = fileName.toLowerCase();
    final isImage = lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.gif') ||
        lower.endsWith('.webp');
    final ext = lower.contains('.') ? lower.split('.').last : '';

    Widget content;
    if (isImage) {
      content = ClipRRect(
        borderRadius: AppUIUtils.primaryBorderRadius,
        child: Image.file(
          File(path),
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackFileIcon(ext),
        ),
      );
    } else {
      content = _fallbackFileIcon(ext);
    }

    return Container(
      width: 60,
      height: 60,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          Positioned.fill(child: content),
          Positioned(
            top: 0,
            right: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 18,
                height: 18,
                decoration: const BoxDecoration(
                  color: kColorWhite,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  size: 12,
                  color: kColorBlack,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fallbackFileIcon(String ext) {
    return Container(
      decoration: BoxDecoration(
        color: kColorGreyBGF9,
        borderRadius: AppUIUtils.primaryBorderRadius,
        border: Border.all(color: kColorGreyDA),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file,
              color: kColorPrimary,
              size: 20,
            ),
            if (ext.isNotEmpty) ...[
              Spacing.v2,
              AppText(
                text: ext.toUpperCase(),
                fontSize: 8,
                color: kColorBlack,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

