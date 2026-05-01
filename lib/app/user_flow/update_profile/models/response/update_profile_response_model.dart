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
    );
  }
}
