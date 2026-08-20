import 'package:qobo_one_live/utils/api_image_utils.dart';

class ReferralCodePayload {
  const ReferralCodePayload({
    required this.code,
    required this.status,
    required this.shareMessage,
    this.createdAt,
  });

  factory ReferralCodePayload.fromJson(Map<String, dynamic> json) {
    return ReferralCodePayload(
      code: _readString(json, const ['code', 'referralCode', 'referral_code']),
      status: _readString(json, const ['status'], fallback: 'ACTIVE'),
      shareMessage: _readString(json, const ['shareMessage', 'share_message']),
      createdAt: _readOptionalString(json, const ['createdAt', 'created_at']),
    );
  }

  final String code;
  final String status;
  final String shareMessage;
  final String? createdAt;
}

class ReferralCompletedEntry {
  const ReferralCompletedEntry({
    required this.code,
    required this.coinsEarned,
    required this.usedAt,
    this.friendName,
    this.friendAvatarUrl,
  });

  factory ReferralCompletedEntry.fromJson(Map<String, dynamic> json) {
    final usedBy = json['usedBy'] ?? json['used_by'];
    String? name;
    String? avatar;
    if (usedBy is Map) {
      final userMap = Map<String, dynamic>.from(usedBy);
      name = _readOptionalString(userMap, const ['name', 'fullName', 'username']);
      avatar = ApiImageUtils.normalize(
        _readOptionalString(userMap, const [
          'displayPicture',
          'display_picture',
          'avatarUrl',
          'avatar_url',
          'avatar',
          'profilePicture',
          'profile_picture',
        ]),
      );
    }
    return ReferralCompletedEntry(
      code: _readString(json, const ['code', 'referralCode', 'referral_code']),
      coinsEarned: _readIntFromKeys(json, const [
        'coinsEarned',
        'coins_earned',
        'amount',
      ]),
      usedAt: _readString(json, const ['usedAt', 'used_at']),
      friendName: name,
      friendAvatarUrl: avatar,
    );
  }

  final String code;
  final int coinsEarned;
  final String usedAt;
  final String? friendName;
  final String? friendAvatarUrl;
}

class ReferralMyCodeDetails {
  const ReferralMyCodeDetails({
    this.activeCode = '',
    this.shareMessage = '',
    this.totalReferralsCompleted = 0,
    this.totalCoinsEarned = 0,
    this.completedReferralsHistory = const [],
  });

  factory ReferralMyCodeDetails.fromJson(Map<String, dynamic> json) {
    final history = _readMapList(json, const [
      'completedReferralsHistory',
      'completed_referrals_history',
      'friendsJoined',
      'friends_joined',
    ])
        .map(ReferralCompletedEntry.fromJson)
        .toList();

    return ReferralMyCodeDetails(
      activeCode: _readString(json, const [
        'activeCode',
        'active_code',
        'code',
        'referralCode',
        'referral_code',
      ]),
      shareMessage: _readString(json, const ['shareMessage', 'share_message']),
      totalReferralsCompleted: _readIntFromKeys(json, const [
        'totalReferralsCompleted',
        'total_referrals_completed',
        'totalFriendsJoined',
        'total_friends_joined',
        'totalFriends',
        'total_friends',
      ]),
      totalCoinsEarned: _readIntFromKeys(json, const [
        'totalCoinsEarned',
        'total_coins_earned',
        'totalCoins',
        'total_coins',
      ]),
      completedReferralsHistory: history,
    );
  }

  final String activeCode;
  final String shareMessage;
  final int totalReferralsCompleted;
  final int totalCoinsEarned;
  final List<ReferralCompletedEntry> completedReferralsHistory;
}

class ReferralVerifyResult {
  const ReferralVerifyResult({
    required this.valid,
    required this.code,
    required this.rewardCoins,
    required this.referrerName,
    required this.message,
  });

  factory ReferralVerifyResult.fromJson(Map<String, dynamic> json) {
    return ReferralVerifyResult(
      valid: json['valid'] == true,
      code: _readString(json, const ['code', 'referralCode', 'referral_code']),
      rewardCoins: _readIntFromKeys(json, const [
        'rewardCoins',
        'reward_coins',
      ]),
      referrerName: _readString(json, const [
        'referrerName',
        'referrer_name',
      ]),
      message: _readString(json, const ['message']),
    );
  }

  final bool valid;
  final String code;
  final int rewardCoins;
  final String referrerName;
  final String message;
}

class ReferralEarningEntry {
  const ReferralEarningEntry({
    required this.id,
    required this.amount,
    required this.type,
    required this.status,
    required this.createdAt,
    this.description,
    this.referralCode,
  });

  factory ReferralEarningEntry.fromJson(Map<String, dynamic> json) {
    final metadata = json['metadata'];
    String? description;
    String? code;
    if (metadata is Map) {
      final metadataMap = Map<String, dynamic>.from(metadata);
      description = _readOptionalString(metadataMap, const ['description']);
      code = _readOptionalString(metadataMap, const [
        'referralCode',
        'referral_code',
      ]);
    }
    return ReferralEarningEntry(
      id: _readString(json, const ['id', '_id']),
      amount: _readIntFromKeys(json, const ['amount', 'coins', 'coinsEarned']),
      type: _readString(json, const ['type']),
      status: _readString(json, const ['status']),
      createdAt: _readString(json, const ['createdAt', 'created_at']),
      description: description,
      referralCode: code,
    );
  }

  final String id;
  final int amount;
  final String type;
  final String status;
  final String createdAt;
  final String? description;
  final String? referralCode;
}

int _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int _readIntFromKeys(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json.containsKey(key)) return _readInt(json[key]);
  }
  return 0;
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value == null) continue;
    final text = value.toString().trim();
    if (text.isNotEmpty) return text;
  }
  return fallback;
}

String? _readOptionalString(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  return value.isEmpty ? null : value;
}

List<Map<String, dynamic>> _readMapList(
  Map<String, dynamic> json,
  List<String> keys,
) {
  for (final key in keys) {
    final raw = json[key];
    if (raw is! List) continue;
    return raw
        .whereType<Map>()
        .map((entry) => Map<String, dynamic>.from(entry))
        .toList();
  }
  return const [];
}
