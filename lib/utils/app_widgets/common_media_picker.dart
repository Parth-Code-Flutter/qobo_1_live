import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared media-picker bottom sheet for choosing camera/gallery source.
class CommonMediaPicker {
  const CommonMediaPicker._();

  static Future<ImageSource?> show(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: kColorWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: AppText(
                    text: 'Select From Gallery',
                    style: TextStyles.kMediumPoppins(
                      fontSize: TextStyles.k14FontSize,
                      colors: kColorText,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt_outlined),
                  title: AppText(
                    text: 'Open Camera',
                    style: TextStyles.kMediumPoppins(
                      fontSize: TextStyles.k14FontSize,
                      colors: kColorText,
                    ),
                  ),
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
