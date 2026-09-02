import 'dart:io';
import 'dart:math';

import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

/// Provides one stable app-install id for backend single-device sessions.
///
/// This is not an auth secret. It only lets the backend distinguish "same app
/// install re-login" from "another device login".
class DeviceIdService {
  DeviceIdService({LocalStorage? storage})
    : _storage = storage ?? LocalStorage.shared;

  final LocalStorage _storage;

  Future<String> getOrCreateDeviceId() async {
    final existing = await _storage.getStringFromStorage(kStorageDeviceId);
    if (existing.trim().isNotEmpty) return existing.trim();

    final created = _newDeviceId();
    await _storage.writeStringStorage(kStorageDeviceId, created);
    return created;
  }

  String _newDeviceId() {
    final platform = Platform.isAndroid
        ? 'android'
        : Platform.isIOS
        ? 'ios'
        : 'flutter';
    final now = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final suffix = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return 'qobo_${platform}_${now}_$suffix';
  }
}
