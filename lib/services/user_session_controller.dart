import 'package:get/get.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/constants/status_code_constants.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/background/background_repo.dart';
import 'package:qobo_one_live/services/api_constants.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/app_widgets/profile_background_media.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

/// Centralized, app-wide user session store.
///
/// Keeps profile data in memory for fast access and syncs it with local storage
/// so any screen can read user info without repeating storage/API parsing logic.
class UserSessionController extends GetxController {
  UserSessionController({
    AuthRepo? authRepo,
    BackgroundRepo? backgroundRepo,
  }) : _authRepo = authRepo ?? AuthRepo(),
       _backgroundRepo = backgroundRepo ?? BackgroundRepo();

  final AuthRepo _authRepo;
  final BackgroundRepo _backgroundRepo;
  Map<String, dynamic>? _profileData;
  bool _syncingEquippedBackground = false;

  Map<String, dynamic>? get profileData => _profileData;
  String get userId => _stringValue('id');
  String get userName => _stringValue('name');
  String get email => _stringValue('email');
  String get phone => _stringValue('phone');
  String get role => _stringValueFromProfile(const ['role', 'userRole']);
  String get agencyCode =>
      _stringValueFromProfile(const ['agencyCode', 'agency_code']);
  String get displayPicturePath => _stringValue('displayPicture');
  String get profileFrameUrl => _stringValueFromProfile(const [
    'profileFrameUrl',
    'profile_frame_url',
    'profileFrame',
    'profile_frame',
    'avatarFrameUrl',
    'avatar_frame_url',
    'frameUrl',
    'frame_url',
    'frame',
    'avatarFrame.image',
  ]);
  String get profileBackgroundUrl => _stringValueFromProfile(const [
    'profileBackgroundUrl',
    'profile_background_url',
    'profileBackground.image',
    'profile_background.image',
    'profileBackground.animationUrl',
    'profileBackground.svgaUrl',
    'profile_background.animationUrl',
    'backgroundUrl',
    'background_url',
    // Map objects last so we extract nested `image` via `_readProfileValue`.
    'profileBackground',
    'profile_background',
  ]);

  /// Static thumbnail for the equipped cover when the animated `.svga` 404s.
  String get profileBackgroundPreviewUrl => _stringValueFromProfile(const [
    'profileBackgroundPreviewUrl',
    'profile_background_preview_url',
  ]);

  /// Entrance nameplate style from `GET /api/user/profile` (defaults to classic).
  String get pattiStyle {
    final value = _stringValueFromProfile(const ['pattiStyle', 'patti_style']);
    return value.isNotEmpty ? value : 'classic';
  }

  bool get isSuperAdmin => role.toLowerCase() == 'super_admin';
  bool get isAgency {
    final normalized = role.toLowerCase().replaceAll(' ', '_');
    return normalized == 'agency' ||
        normalized == 'agency_owner' ||
        normalized == 'agencyowner';
  }
  bool get isHost => role.toLowerCase() == 'host';

  /// Approved P2P coins seller (role and/or profile flags from getProfile).
  bool get isCoinSeller {
    final normalized = role.toLowerCase().replaceAll(' ', '_');
    if (normalized == 'coin_seller' ||
        normalized == 'coins_seller' ||
        normalized == 'seller' ||
        normalized == 'seller_admin') {
      return true;
    }
    if (_boolValueFromProfile(const [
      'isCoinsSeller',
      'isCoinSeller',
      'is_coins_seller',
      'is_coin_seller',
      'coinsSeller',
      'coins_seller',
    ])) {
      return true;
    }
    final status = _stringValueFromProfile(const [
      'coinsSellerStatus',
      'coinSellerStatus',
      'coins_seller_status',
      'sellerStatus',
      'seller_status',
    ]).toLowerCase();
    return status == 'approved' || status == 'active';
  }

  /// Profile header counters — prefer backend `formatted*` strings (e.g. "2K").
  String get formattedVisitors => _formattedSocialStat(
    formattedKeys: const ['formattedVisitors', 'stats.formattedVisitors'],
    countKeys: const ['visitorsCount', 'stats.visitors'],
  );

  String get formattedFriends => _formattedSocialStat(
    formattedKeys: const ['formattedFriends', 'stats.formattedFriends'],
    countKeys: const ['friendsCount', 'stats.friends'],
  );

  String get formattedFollowing => _formattedSocialStat(
    formattedKeys: const ['formattedFollowing', 'stats.formattedFollowing'],
    countKeys: const ['followingCount', 'stats.following'],
  );

  String get formattedFollowers => _formattedSocialStat(
    formattedKeys: const ['formattedFollowers', 'stats.formattedFollowers'],
    countKeys: const ['followersCount', 'stats.followers'],
  );

  String get levelBadge {
    final badge = _stringValueFromProfile(const ['levelBadge', 'level_badge']);
    if (badge.isNotEmpty) return badge;
    final level = _intFromProfile(const ['level']);
    return 'LV.$level';
  }

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
    final parts = source
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
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
    try {
      await _storage.writeJsonStorage(kStorageUserData, _profileData!);
    } catch (_) {
      // Keep the in-memory profile even if secure storage is unavailable.
    }
    update();
  }

  Future<bool> refreshProfileFromApi({bool isShowLoader = false}) async {
    final response = await _authRepo.getProfile(isShowLoader: isShowLoader);
    if (response == null) return false;

    final rawCode = response['statusCode'];
    final statusCode = rawCode is int
        ? rawCode
        : int.tryParse(rawCode?.toString() ?? '') ?? 0;
    if (statusCode != 1 && statusCode != StatusCodeConstants.success) {
      return false;
    }

    final rawData = response['data'];
    final data = rawData is Map<String, dynamic>
        ? rawData
        : rawData is Map
        ? Map<String, dynamic>.from(rawData)
        : null;
    if (data == null) return false;

    await saveProfile(data);
    // getProfile often omits cover media — merge equipped backpack URL + preview.
    await syncEquippedProfileBackgroundFromBackpack();
    return true;
  }

  /// Reads `GET /api/background/my-backpack` and stores the equipped cover URL
  /// (plus a static preview when available) so Profile tab / Basic Profile can
  /// still show distinct art when Render 404s the `.svga` upload.
  Future<void> syncEquippedProfileBackgroundFromBackpack() async {
    if (_syncingEquippedBackground) return;
    _syncingEquippedBackground = true;
    try {
      final response = await _backgroundRepo.getMyBackpack(isShowLoader: false);
      final rawData = response?['data'];
      final items = rawData is List
          ? rawData
          : (rawData is Map && rawData['items'] is List)
          ? rawData['items'] as List
          : const [];

      for (final raw in items.whereType<Map>()) {
        if (raw['isEquipped'] != true) continue;
        final details = raw['backgroundDetails'] ?? raw['background_details'];
        final background = details is Map
            ? Map<String, dynamic>.from(details)
            : const <String, dynamic>{};
        final url = ApiImageUtils.normalize(
          _firstNonEmpty([
            background['animationUrl'],
            background['svgaUrl'],
            background['svga'],
            background['image'],
            background['imageUrl'],
            background['previewUrl'],
            raw['image'],
            raw['imageUrl'],
          ]),
        );
        if (url == null || url.isEmpty) break;

        final preview = ApiImageUtils.normalize(
          _firstNonSvga([
            background['previewUrl'],
            background['thumbnail'],
            background['thumbnailUrl'],
            background['coverImage'],
            background['image'],
            background['imageUrl'],
            raw['previewUrl'],
            raw['thumbnail'],
            raw['thumbnailUrl'],
            raw['image'],
            raw['imageUrl'],
          ]),
        );

        final updated = Map<String, dynamic>.from(_profileData ?? {});
        updated['profileBackgroundUrl'] = url;
        updated['poster'] = url;
        if (preview != null && preview.isNotEmpty) {
          updated['profileBackgroundPreviewUrl'] = preview;
        } else {
          updated.remove('profileBackgroundPreviewUrl');
        }
        await saveProfile(updated);
        break;
      }
    } catch (_) {
      // Cover sync is best-effort; keep existing session values.
    } finally {
      _syncingEquippedBackground = false;
    }
  }

  String? _firstNonEmpty(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }

  String? _firstNonSvga(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString().trim() ?? '';
      if (text.isEmpty || text == 'null') continue;
      if (ProfileBackgroundMedia.isSvgaUrl(text)) continue;
      return text;
    }
    return null;
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
      final direct = _readProfileValue(_profileData, key);
      final directValue = _cleanString(direct);
      if (directValue.isNotEmpty) return directValue;

      // Auth responses can be cached as `{ user: {...}, token: ... }`, while
      // `getProfile` stores a flat user row. Support both shapes here.
      final nested = _profileData?['user'];
      if (nested is Map) {
        final nestedValue = _cleanString(_readProfileValue(nested, key));
        if (nestedValue.isNotEmpty) return nestedValue;
      }
    }
    return '';
  }

  dynamic _readProfileValue(Map<dynamic, dynamic>? source, String key) {
    if (source == null) return null;
    if (key.contains('.')) {
      dynamic cursor = source;
      for (final part in key.split('.')) {
        if (cursor is! Map) return null;
        cursor = cursor[part];
      }
      return cursor;
    }
    final value = source[key];
    if (value is Map) {
      return value['animationUrl'] ??
          value['svgaUrl'] ??
          value['svga'] ??
          value['image'] ??
          value['imageUrl'] ??
          value['url'] ??
          value['frameUrl'] ??
          value['frame_url'];
    }
    return value;
  }

  String _cleanString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  bool _boolValueFromProfile(List<String> keys) {
    for (final key in keys) {
      final raw = _readProfileValue(_profileData, key);
      if (raw == true || raw == 1) return true;
      if (raw == false || raw == 0 || raw == null) continue;
      final text = raw.toString().trim().toLowerCase();
      if (text == 'true' || text == '1' || text == 'yes') return true;
      final nested = _profileData?['user'];
      if (nested is Map) {
        final nestedRaw = _readProfileValue(nested, key);
        if (nestedRaw == true || nestedRaw == 1) return true;
        final nestedText = nestedRaw?.toString().trim().toLowerCase() ?? '';
        if (nestedText == 'true' || nestedText == '1' || nestedText == 'yes') {
          return true;
        }
      }
    }
    return false;
  }

  /// Reads a formatted social counter, falling back to a compact count string.
  String _formattedSocialStat({
    required List<String> formattedKeys,
    required List<String> countKeys,
  }) {
    final formatted = _stringValueFromProfile(formattedKeys);
    if (formatted.isNotEmpty && formatted.toLowerCase() != 'null') {
      return formatted;
    }
    return _compactCount(_intFromProfile(countKeys));
  }

  int _intFromProfile(List<String> keys) {
    for (final key in keys) {
      final raw = _readProfileValue(_profileData, key);
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      final nested = _profileData?['user'];
      if (nested is Map) {
        final nestedRaw = _readProfileValue(nested, key);
        if (nestedRaw is int) return nestedRaw;
        if (nestedRaw is num) return nestedRaw.toInt();
        final nestedParsed = int.tryParse(nestedRaw?.toString() ?? '');
        if (nestedParsed != null) return nestedParsed;
      }
      final parsed = int.tryParse(raw?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return 0;
  }

  /// Compact display when the API omits `formatted*` (e.g. 10400 → 10.4K).
  String _compactCount(int value) {
    if (value < 1000) return '$value';
    if (value < 1000000) {
      return _formatWithSuffix(value / 1000, 'K');
    }
    return _formatWithSuffix(value / 1000000, 'M');
  }

  String _formatWithSuffix(double value, String suffix) {
    final oneDecimal = (value * 10).round() / 10;
    if (oneDecimal == oneDecimal.roundToDouble()) {
      return '${oneDecimal.toInt()}$suffix';
    }
    return '${oneDecimal.toStringAsFixed(1)}$suffix';
  }

  LocalStorage get _storage => LocalStorage.shared;
}
