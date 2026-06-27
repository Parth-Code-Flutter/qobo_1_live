import 'package:permission_handler/permission_handler.dart';

/// Microphone + camera access required before using the app.
abstract final class AppMediaPermissions {
  AppMediaPermissions._();

  static Future<bool> areGranted() async {
    final mic = await Permission.microphone.status;
    final camera = await Permission.camera.status;
    return mic.isGranted && camera.isGranted;
  }

  /// Requests microphone then camera. Returns `true` only when both are granted.
  static Future<bool> requestRequired() async {
    final mic = await Permission.microphone.request();
    final camera = await Permission.camera.request();
    return mic.isGranted && camera.isGranted;
  }

  static Future<bool> isPermanentlyDenied() async {
    final mic = await Permission.microphone.status;
    final camera = await Permission.camera.status;
    return mic.isPermanentlyDenied || camera.isPermanentlyDenied;
  }

  static Future<void> openSettings() => openAppSettings();
}
