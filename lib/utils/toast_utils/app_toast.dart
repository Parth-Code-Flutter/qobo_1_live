import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// Centralized toast helpers for success/failure messaging.
///
/// Uses `toastification` so toasts automatically follow the app wrapper config.
class AppToast {
  const AppToast._();

  static void showSuccess(
    BuildContext context,
    String message, {
    String title = 'Success',
  }) {
    toastification.show(
      context: context,
      alignment: Alignment.bottomCenter,
      type: ToastificationType.success,
      style: ToastificationStyle.flat,
      title: Text(title),
      description: Text(message),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      borderRadius: BorderRadius.circular(16),
      animationDuration: const Duration(milliseconds: 200),
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    String title = 'Error',
  }) {
    toastification.show(
      context: context,
      alignment: Alignment.bottomCenter,
      type: ToastificationType.error,
      style: ToastificationStyle.flat,
      title: Text(title),
      description: Text(message),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      borderRadius: BorderRadius.circular(16),
      animationDuration: const Duration(milliseconds: 200),
    );
  }
}

