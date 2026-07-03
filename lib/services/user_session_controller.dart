import 'package:get/get.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

/// Centralized, app-wide user session store.
///
/// Keeps profile data in memory for fast access and syncs it with local storage
/// so any screen can read user info without repeating storage/API parsing logic.
class UserSessionController extends GetxController {
  Map<String, dynamic>? _profileData;

  Map<String, dynamic>? get profileData => _profileData;
  String get userId => _stringValue('id');
  String get userName => _stringValue('name');
  String get email => _stringValue('email');
  String get phone => _stringValue('phone');
  String get role => _stringValueFromProfile(const ['role', 'userRole']);
  String get agencyCode =>
      _stringValueFromProfile(const ['agencyCode', 'agency_code']);
  String get displayPicturePath => _stringValue('displayPicture');
  bool get isSuperAdmin => role.toLowerCase() == 'super_admin';

  String get displayName {
    if (userName.isNotEmpty) return userName;
    if (email.isNotEmpty) return email;
    if (phone.isNotEmpty) return phone;
    return 'User';
  }

  /// Builds final avatar URL from relative path when needed.
  String? get displayPictureUrl {
    final path = displayPicturePath;
    if (path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${ApiConstants.baseUrl}$path';
  }

  /// Initials fallback used when profile image is missing.
  String get initials {
    final source = displayName.trim();
    if (source.isEmpty) return 'U';
    final parts = source.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return source.substring(0, source.length >= 2 ? 2 : 1).toUpperCase();
  }

  Future<void> loadFromStorage() async {
    final storage = _storage;
    _profileData = await storage.getJsonFromStorage(kStorageUserData);
    update();
  }

  Future<void> saveProfile(Map<String, dynamic> data) async {
    _profileData = Map<String, dynamic>.from(data);
    await _storage.writeJsonStorage(kStorageUserData, _profileData!);
    update();
  }

  Future<void> clearSession() async {
    _profileData = null;
    update();
  }

  String _stringValue(String key) {
    return _stringValueFromProfile([key]);
  }

  String _stringValueFromProfile(List<String> keys) {
    for (final key in keys) {
      final direct = _profileData?[key];
      final directValue = _cleanString(direct);
      if (directValue.isNotEmpty) return directValue;

      // Auth responses can be cached as `{ user: {...}, token: ... }`, while
      // `getProfile` stores a flat user row. Support both shapes here.
      final nested = _profileData?['user'];
      if (nested is Map) {
        final nestedValue = _cleanString(nested[key]);
        if (nestedValue.isNotEmpty) return nestedValue;
      }
    }
    return '';
  }

  String _cleanString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  LocalStorage get _storage => LocalStorage.shared;
}
