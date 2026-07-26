import 'package:qobo_one_live/utils/api_image_utils.dart';

/// Sanitized public user card from discover / search / public profile APIs.
class SocialUserCard {
  const SocialUserCard({
    required this.id,
    required this.name,
    this.displayPicture,
    this.avatarFrameUrl,
    this.profileBackgroundUrl,
    this.gender = '',
    this.country = '',
    this.level = 0,
    this.bio = '',
    this.isFollowing = false,
    this.isFollower = false,
    this.isMutual = false,
    this.canMessage = false,
    this.isVip = false,
    this.isFavourite = false,
    this.coins = 0,
    this.coinsPerSecond = 0,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  final String id;
  final String name;
  final String? displayPicture;
  final String? avatarFrameUrl;
  final String? profileBackgroundUrl;
  final String gender;
  final String country;
  final int level;
  final String bio;
  final bool isFollowing;
  final bool isFollower;
  final bool isMutual;
  final bool canMessage;
  final bool isVip;
  final bool isFavourite;
  final double coins;
  final double coinsPerSecond;
  final int followersCount;
  final int followingCount;

  SocialUserCard copyWith({
    bool? isFollowing,
    bool? isFollower,
    bool? isMutual,
    bool? canMessage,
    Object? isFavourite = _copyWithUnset,
    int? followersCount,
    int? followingCount,
    Object? profileBackgroundUrl = _copyWithUnset,
  }) {
    return SocialUserCard(
      id: id,
      name: name,
      displayPicture: displayPicture,
      avatarFrameUrl: avatarFrameUrl,
      profileBackgroundUrl: identical(profileBackgroundUrl, _copyWithUnset)
          ? this.profileBackgroundUrl
          : profileBackgroundUrl as String?,
      gender: gender,
      country: country,
      level: level,
      bio: bio,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollower: isFollower ?? this.isFollower,
      isMutual: isMutual ?? this.isMutual,
      canMessage: canMessage ?? this.canMessage,
      isVip: isVip,
      isFavourite: identical(isFavourite, _copyWithUnset)
          ? this.isFavourite
          : isFavourite as bool,
      coins: coins,
      coinsPerSecond: coinsPerSecond,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  static const _copyWithUnset = Object();

  factory SocialUserCard.fromJson(Map<String, dynamic> json) {
    final isFollowing = json['isFollowing'] == true;
    final isFollower = json['isFollower'] == true;
    // Friends API may only send `isFriend: true` for mutuals.
    final isMutual =
        json['isMutual'] == true ||
        json['isFriend'] == true ||
        (isFollowing && isFollower);
    final apiCanMessage = json['canMessage'] == true;

    // Visitors list uses `userId` for the person; friends/follow lists use `id`.
    final userId = json['userId']?.toString().trim() ?? '';
    final rowId = json['id']?.toString().trim() ?? '';
    final id = userId.isNotEmpty ? userId : rowId;

    return SocialUserCard(
      id: id,
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'User',
      displayPicture: ApiImageUtils.normalize(
        json['displayPicture']?.toString(),
      ),
      avatarFrameUrl: ApiImageUtils.normalize(_readAvatarFrameUrl(json)),
      profileBackgroundUrl: ApiImageUtils.normalize(
        _readProfileBackgroundUrl(json),
      ),
      gender: json['gender']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      level: _toInt(json['level']),
      bio: json['bio']?.toString() ?? '',
      isFollowing: isFollowing || isMutual,
      isFollower: isFollower || isMutual,
      isMutual: isMutual,
      canMessage: apiCanMessage || isFollowing || isFollower || isMutual,
      isVip: json['isVip'] == true,
      isFavourite: json['isFavourite'] == true || json['isFavorite'] == true,
      coins: _toDouble(json['coins']),
      coinsPerSecond: _toDouble(json['coinsPerSecond']),
      followersCount: _toInt(json['followersCount']),
      followingCount: _toInt(json['followingCount']),
    );
  }

  static List<SocialUserCard> listFromResponseData(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => SocialUserCard.fromJson(Map<String, dynamic>.from(e)))
          .where((u) => u.id.isNotEmpty)
          .toList();
    }
    if (data is Map) {
      // New social list APIs nest rows under `items`; older ones use `users`.
      final users = data['items'] ?? data['users'] ?? data['list'];
      if (users is List) {
        return users
            .whereType<Map>()
            .map((e) => SocialUserCard.fromJson(Map<String, dynamic>.from(e)))
            .where((u) => u.id.isNotEmpty)
            .toList();
      }
    }
    return [];
  }

  static int _toInt(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static double _toDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }

  static String? _readAvatarFrameUrl(Map<String, dynamic> json) {
    final direct =
        json['avatarFrameUrl'] ??
        json['avatar_frame_url'] ??
        json['profileFrameUrl'] ??
        json['profile_frame_url'];
    final directText = direct?.toString().trim();
    if (directText != null && directText.isNotEmpty && directText != 'null') {
      return directText;
    }

    final avatarFrame = json['avatarFrame'];
    if (avatarFrame is Map) {
      final nested =
          avatarFrame['image'] ??
          avatarFrame['imageUrl'] ??
          avatarFrame['url'] ??
          avatarFrame['frameUrl'];
      final nestedText = nested?.toString().trim();
      if (nestedText != null && nestedText.isNotEmpty && nestedText != 'null') {
        return nestedText;
      }
    }

    return null;
  }

  /// Equipped theme from `profileBackground` on profile / public profile APIs.
  static String? _readProfileBackgroundUrl(Map<String, dynamic> json) {
    final direct =
        json['profileBackgroundUrl'] ??
        json['profile_background_url'] ??
        json['backgroundUrl'] ??
        json['background_url'];
    final directText = direct?.toString().trim();
    if (directText != null && directText.isNotEmpty && directText != 'null') {
      return directText;
    }

    final nested =
        json['profileBackground'] ?? json['profile_background'];
    if (nested is Map) {
      final image =
          nested['animationUrl'] ??
          nested['svgaUrl'] ??
          nested['svga'] ??
          nested['image'] ??
          nested['imageUrl'] ??
          nested['url'] ??
          nested['backgroundImage'];
      final imageText = image?.toString().trim();
      if (imageText != null && imageText.isNotEmpty && imageText != 'null') {
        return imageText;
      }
    }
    if (nested is String) {
      final text = nested.trim();
      if (text.isNotEmpty && text != 'null') return text;
    }
    return null;
  }
}

bool isSocialApiSuccess(Map<String, dynamic>? response) {
  if (response == null) return false;
  final code = response['statusCode'];
  if (code == 1 || code == 200 || code == 201) return true;
  if (code is String) {
    return code == '1' || code == '200' || code == '201';
  }
  // Legacy envelope (`success: true`) used by some chat/user endpoints.
  if (response['success'] == true) return true;
  return false;
}
