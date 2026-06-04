import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

/// Persists and applies app light / dark / system theme.
class ThemeController extends GetxController {
  final themeMode = ThemeMode.system.obs;

  LocalStorage? _storage;

  @override
  void onInit() {
    super.onInit();
    _ensureStorage();
  }

  void _ensureStorage() {
    if (Get.isRegistered<LocalStorage>()) {
      _storage = Get.find<LocalStorage>();
    } else {
      _storage = Get.put(LocalStorage(), permanent: true);
    }
  }

  Future<void> loadSavedTheme() async {
    _ensureStorage();
    final saved = await _storage!.getStringFromStorage(kStorageThemeMode);
    themeMode.value = _parseMode(saved);
    Get.changeThemeMode(themeMode.value);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    themeMode.value = mode;
    Get.changeThemeMode(mode);
    await _storage?.writeStringStorage(kStorageThemeMode, _modeToString(mode));
  }

  String labelFor(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  ThemeMode _parseMode(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _modeToString(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
