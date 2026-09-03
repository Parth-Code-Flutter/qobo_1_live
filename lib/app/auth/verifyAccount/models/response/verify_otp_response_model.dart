/// Top-level envelope for `POST /api/auth/verify-otp`.
class VerifyOtpResponseModel {
  const VerifyOtpResponseModel({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  final int statusCode;
  final String message;
  final VerifyOtpData? data;

  factory VerifyOtpResponseModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    final hasSessionData =
        rawData is Map<String, dynamic> && rawData['user'] is Map;
    return VerifyOtpResponseModel(
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      message: (json['message'] as String?) ?? '',
      data: hasSessionData ? VerifyOtpData.fromJson(rawData) : null,
    );
  }
}

/// Successful payload: authenticated user + JWT.
class VerifyOtpData {
  const VerifyOtpData({required this.user, required this.token});

  final VerifyOtpUser user;
  final String token;

  factory VerifyOtpData.fromJson(Map<String, dynamic> json) {
    return VerifyOtpData(
      user: VerifyOtpUser.fromJson(json['user'] as Map<String, dynamic>),
      token: (json['token'] as String?) ?? '',
    );
  }
}

/// User returned after OTP verification (matches backend shape).
class VerifyOtpUser {
  const VerifyOtpUser({
    required this.id,
    required this.name,
    required this.phone,
    this.email,
    this.displayPicture,
    required this.level,
    required this.vipLevel,
    required this.role,
    required this.isOnline,
    this.country,
    this.bio,
    this.gender,
    this.dob,
    this.createdAt,
  });

  final String id;
  final String name;
  final String phone;
  final String? email;
  final String? displayPicture;
  final int level;
  final int vipLevel;
  final String role;
  final bool isOnline;
  final String? country;
  final String? bio;
  final String? gender;
  final String? dob;
  final String? createdAt;

  factory VerifyOtpUser.fromJson(Map<String, dynamic> json) {
    return VerifyOtpUser(
      id: (json['id'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      phone: (json['phone'] as String?) ?? '',
      email: json['email'] as String?,
      displayPicture: json['displayPicture'] as String?,
      level: (json['level'] as num?)?.toInt() ?? 0,
      vipLevel: (json['vipLevel'] as num?)?.toInt() ?? 0,
      role: (json['role'] as String?) ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      country: json['country'] as String?,
      bio: json['bio'] as String?,
      gender: json['gender'] as String?,
      dob: json['dob'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }

  /// Shape aligned with API JSON for local persistence.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'name': name,
    'phone': phone,
    'email': email,
    'displayPicture': displayPicture,
    'level': level,
    'vipLevel': vipLevel,
    'role': role,
    'isOnline': isOnline,
    'country': country,
    'bio': bio,
    'gender': gender,
    'dob': dob,
    'createdAt': createdAt,
  };
}
