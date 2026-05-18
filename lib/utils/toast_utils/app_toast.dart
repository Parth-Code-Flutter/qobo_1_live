import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';

/// Centralized toast helpers for success/failure messaging.
///
/// Uses custom builder for a modern, sleek UI.
class AppToast {
  const AppToast._();

  static void showSuccess(
    BuildContext context,
    String message, {
    String title = 'Success',
  }) {
    _showCustomToast(
      context: context,
      title: title,
      message: message,
      primaryColor: const Color(0xFF22C55E), // Modern Green
      icon: Icons.check_circle_rounded,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String title = 'Error',
  }) {
    _showCustomToast(
      context: context,
      title: title,
      message: message,
      primaryColor: const Color(0xFFEF4444), // Modern Red
      icon: Icons.error_rounded,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    String title = 'Warning',
  }) {
    _showCustomToast(
      context: context,
      title: title,
      message: message,
      primaryColor: const Color(0xFFF59E0B), // Modern Amber/Yellow
      icon: Icons.warning_rounded,
    );
  }

  static void _showCustomToast({
    required BuildContext context,
    required String title,
    required String message,
    required Color primaryColor,
    required IconData icon,
  }) {
    toastification.showCustom(
      context: context,
      alignment: Alignment.topCenter,
      autoCloseDuration: const Duration(seconds: 4),
      animationDuration: const Duration(milliseconds: 300),
      builder: (BuildContext context, ToastificationItem holder) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: kColorWhite,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.12),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: primaryColor.withOpacity(0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primaryColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyles.kSemiBoldPoppins(
                        fontSize: TextStyles.k14FontSize,
                        colors: kColorText,
                      ),
                    ),
                    if (message.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        message,
                        style: TextStyles.kRegularPoppins(
                          fontSize: TextStyles.k12FontSize,
                          colors: kColorHint,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () {
                  toastification.dismiss(holder);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: kColorHint.withOpacity(0.05),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: kColorHint,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

