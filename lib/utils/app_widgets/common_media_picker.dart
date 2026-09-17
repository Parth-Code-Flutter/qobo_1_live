import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:qobo_one_live/constants/app_light_theme.dart';
import 'package:qobo_one_live/utils/text_utils/app_text.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Shared media-picker bottom sheet for choosing camera/gallery source.
class CommonMediaPicker {
  const CommonMediaPicker._();

  static Future<ImageSource?> show(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: AppLightUi.bottomSheetDecoration(topRadius: 18),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: AppLightUi.borderStrong,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.photo_library_outlined,
                      color: AppLightUi.violet,
                    ),
                    title: AppText(
                      text: 'Select From Gallery',
                      style: TextStyles.kMediumPoppins(
                        fontSize: TextStyles.k14FontSize,
                        colors: AppLightUi.title,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                  ),
                  ListTile(
                    leading: const Icon(
                      Icons.camera_alt_outlined,
                      color: AppLightUi.pink,
                    ),
                    title: AppText(
                      text: 'Open Camera',
                      style: TextStyles.kMediumPoppins(
                        fontSize: TextStyles.k14FontSize,
                        colors: AppLightUi.title,
                      ),
                    ),
                    onTap: () => Navigator.of(context).pop(ImageSource.camera),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
