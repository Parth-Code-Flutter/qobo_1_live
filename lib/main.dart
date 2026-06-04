import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/qobo_app.dart';
import 'package:qobo_one_live/services/theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final themeController = Get.put(ThemeController(), permanent: true);
  await themeController.loadSavedTheme();
  runApp(const QoboApp());
}
