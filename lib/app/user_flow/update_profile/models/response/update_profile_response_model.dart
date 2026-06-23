/// Response envelope for `PUT /api/user/update`.
class UpdateProfileResponseModel {
  const UpdateProfileResponseModel({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  final int statusCode;
  final String message;
  final UpdateProfileUser? data;

  factory UpdateProfileResponseModel.fromJson(Map<String, dynamic> json) {
    return UpdateProfileResponseModel(
      statusCode: (json['statusCode'] as num?)?.toInt() ?? 0,
      message: (json['message'] as String?) ?? '',
      data: json['data'] == null
          ? null
          : UpdateProfileUser.fromJson(json['data'] as Map<String, dynamic>),
    );
  }
}

/// Updated user object returned by the API.
class UpdateProfileUser {
  const UpdateProfileUser({
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
    this.relationshipStatus,
    this.languages,
    this.interests,
    this.currentLocation,
    this.coinsPerSecond,
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
  final String? relationshipStatus;
  final String? languages;
  final String? interests;
  final String? currentLocation;
  final double? coinsPerSecond;

  factory UpdateProfileUser.fromJson(Map<String, dynamic> json) {
    return UpdateProfileUser(
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
      relationshipStatus: json['relationshipStatus'] as String?,
      languages: _stringOrJoinedList(json['languages']),
      interests: _stringOrJoinedList(json['interests']),
      currentLocation: json['currentLocation'] as String?,
      coinsPerSecond: _toDouble(json['coinsPerSecond'] ?? json['coins_per_second']),
    );
  }

  static double? _toDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw.toString().trim());
  }

  Map<String, dynamic> toProfileMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'phone': phone,
      if (email != null) 'email': email,
      if (displayPicture != null) 'displayPicture': displayPicture,
      'level': level,
      'vipLevel': vipLevel,
      'role': role,
      'isOnline': isOnline,
      if (country != null) 'country': country,
      if (bio != null) 'bio': bio,
      if (gender != null) 'gender': gender,
      if (dob != null) 'dob': dob,
      if (createdAt != null) 'createdAt': createdAt,
      if (relationshipStatus != null) 'relationshipStatus': relationshipStatus,
      if (languages != null) 'languages': languages,
      if (interests != null) 'interests': interests,
      if (currentLocation != null) 'currentLocation': currentLocation,
      if (coinsPerSecond != null) 'coinsPerSecond': coinsPerSecond,
    };
  }

  static String? _stringOrJoinedList(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      final parts = raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (parts.isEmpty) return null;
      return parts.join(', ');
    }
    final s = raw.toString().trim();
    return s.isEmpty ? null : s;
  }
}
