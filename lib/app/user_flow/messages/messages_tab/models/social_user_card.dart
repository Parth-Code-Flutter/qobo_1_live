import 'package:qobo_one_live/utils/api_image_utils.dart';

/// Sanitized public user card from discover / search / public profile APIs.
class SocialUserCard {
  const SocialUserCard({
    required this.id,
    required this.name,
    this.displayPicture,
    this.gender = '',
    this.country = '',
    this.level = 0,
    this.bio = '',
    this.isFollowing = false,
    this.isFollower = false,
    this.isMutual = false,
    this.canMessage = false,
    this.isVip = false,
    this.followersCount = 0,
    this.followingCount = 0,
  });

  final String id;
  final String name;
  final String? displayPicture;
  final String gender;
  final String country;
  final int level;
  final String bio;
  final bool isFollowing;
  final bool isFollower;
  final bool isMutual;
  final bool canMessage;
  final bool isVip;
  final int followersCount;
  final int followingCount;

  SocialUserCard copyWith({
    bool? isFollowing,
    bool? isFollower,
    bool? isMutual,
    bool? canMessage,
    int? followersCount,
    int? followingCount,
  }) {
    return SocialUserCard(
      id: id,
      name: name,
      displayPicture: displayPicture,
      gender: gender,
      country: country,
      level: level,
      bio: bio,
      isFollowing: isFollowing ?? this.isFollowing,
      isFollower: isFollower ?? this.isFollower,
      isMutual: isMutual ?? this.isMutual,
      canMessage: canMessage ?? this.canMessage,
      isVip: isVip,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
    );
  }

  factory SocialUserCard.fromJson(Map<String, dynamic> json) {
    return SocialUserCard(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString().trim().isNotEmpty == true
          ? json['name'].toString().trim()
          : 'User',
      displayPicture: ApiImageUtils.normalize(
        json['displayPicture']?.toString(),
      ),
      gender: json['gender']?.toString() ?? '',
      country: json['country']?.toString() ?? '',
      level: _toInt(json['level']),
      bio: json['bio']?.toString() ?? '',
      isFollowing: json['isFollowing'] == true,
      isFollower: json['isFollower'] == true,
      isMutual: json['isMutual'] == true,
      canMessage: json['canMessage'] == true,
      isVip: json['isVip'] == true,
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
      final users = data['users'];
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
}

bool isSocialApiSuccess(Map<String, dynamic>? response) {
  if (response == null) return false;
  final code = response['statusCode'];
  if (code == 1 || code == 200 || code == 201) return true;
  if (code is String) {
    return code == '1' || code == '200' || code == '201';
  }
  return false;
}
