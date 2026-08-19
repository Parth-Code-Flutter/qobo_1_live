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
      code: json['code']?.toString() ?? '',
      status: json['status']?.toString() ?? 'ACTIVE',
      shareMessage: json['shareMessage']?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
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
    final usedBy = json['usedBy'];
    String? name;
    String? avatar;
    if (usedBy is Map) {
      name = usedBy['name']?.toString();
      avatar = ApiImageUtils.normalize(
        usedBy['displayPicture']?.toString() ??
            usedBy['avatar']?.toString() ??
            usedBy['profilePicture']?.toString(),
      );
    }
    return ReferralCompletedEntry(
      code: json['code']?.toString() ?? '',
      coinsEarned: _readInt(json['coinsEarned']),
      usedAt: json['usedAt']?.toString() ?? '',
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
    final historyRaw = json['completedReferralsHistory'];
    final history = historyRaw is List
        ? historyRaw
            .whereType<Map>()
            .map((e) => ReferralCompletedEntry.fromJson(
                  Map<String, dynamic>.from(e),
                ))
            .toList()
        : <ReferralCompletedEntry>[];

    return ReferralMyCodeDetails(
      activeCode: json['activeCode']?.toString() ?? '',
      shareMessage: json['shareMessage']?.toString() ?? '',
      totalReferralsCompleted: _readInt(json['totalReferralsCompleted']),
      totalCoinsEarned: _readInt(json['totalCoinsEarned']),
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
      code: json['code']?.toString() ?? '',
      rewardCoins: _readInt(json['rewardCoins']),
      referrerName: json['referrerName']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
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
      description = metadata['description']?.toString();
      code = metadata['referralCode']?.toString();
    }
    return ReferralEarningEntry(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      amount: _readInt(json['amount']),
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
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
