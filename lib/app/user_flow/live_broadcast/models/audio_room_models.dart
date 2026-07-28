class AudioRoomSeatModel {
  const AudioRoomSeatModel({
    required this.seatNo,
    this.userId = '',
    this.name = '',
    this.avatarUrl,
    this.avatarFrameUrl,
    this.vipFrameUrl,
    this.pattiStyle = 'classic',
    this.role = 'empty',
    this.diamonds = 0,
    this.isMuted = false,
    this.isLocked = false,
    this.isAdmin = false,
    this.isVip = false,
    this.isCoinsSeller = false,
  });

  factory AudioRoomSeatModel.empty(int seatNo) =>
      AudioRoomSeatModel(seatNo: seatNo);

  factory AudioRoomSeatModel.fromMap(Map<String, dynamic> raw) {
    final occupant = raw['occupant'];
    final occupantMap = occupant is Map
        ? Map<String, dynamic>.from(occupant)
        : null;
    final userId =
        _readString(raw, const ['userId', 'user_id', 'id']) ??
        _readString(occupantMap, const ['id', '_id', 'userId', 'user_id']) ??
        '';
    final name =
        _readString(raw, const ['name', 'fullName', 'username']) ??
        _readString(occupantMap, const [
          'name',
          'fullName',
          'username',
          'displayName',
        ]) ??
        '';
    final avatar =
        _readString(raw, const [
          'avatarUrl',
          'avatar',
          'displayPicture',
          'profileImage',
        ]) ??
        _readString(occupantMap, const [
          'avatarUrl',
          'avatar',
          'displayPicture',
          'profileImage',
          'image',
        ]);
    final avatarFrame =
        _readFrameUrl(raw['avatarFrame']) ??
        _readFrameUrl(occupantMap?['avatarFrame']) ??
        _readString(raw, const [
          'avatarFrameUrl',
          'avatar_frame_url',
          'profileFrameUrl',
          'profile_frame_url',
          'frameUrl',
          'frame_url',
        ]) ??
        _readString(occupantMap, const [
          'avatarFrameUrl',
          'avatar_frame_url',
          'profileFrameUrl',
          'profile_frame_url',
          'frameUrl',
          'frame_url',
        ]);
    final vipFrame =
        _readString(raw, const [
          'vipFrameUrl',
          'vip_frame_url',
          'vipFrame',
          'vip_frame',
        ]) ??
        _readString(occupantMap, const [
          'vipFrameUrl',
          'vip_frame_url',
          'vipFrame',
          'vip_frame',
        ]);
    final isVip = _readBool(raw, const ['isVIP', 'isVip', 'is_vip']) ||
        (occupantMap != null &&
            _readBool(occupantMap, const ['isVIP', 'isVip', 'is_vip']));
    final isCoinsSeller =
        _readBool(raw, const [
          'isCoinsSeller',
          'isCoinSeller',
          'is_coins_seller',
          'is_coin_seller',
          'coinsSeller',
          'coins_seller',
        ]) ||
        (occupantMap != null &&
            _readBool(occupantMap, const [
              'isCoinsSeller',
              'isCoinSeller',
              'is_coins_seller',
              'is_coin_seller',
              'coinsSeller',
              'coins_seller',
            ]));
    final pattiStyle =
        _readString(raw, const ['pattiStyle', 'patti_style']) ??
        _readString(occupantMap, const ['pattiStyle', 'patti_style']) ??
        'classic';

    return AudioRoomSeatModel(
      seatNo: _readInt(raw, const ['seatNo', 'seat_id', 'seatId', 'seat']) ?? 0,
      userId: userId,
      name: name,
      avatarUrl: avatar,
      avatarFrameUrl: avatarFrame,
      vipFrameUrl: vipFrame,
      pattiStyle: pattiStyle,
      role:
          _readString(raw, const ['role', 'type']) ??
          (userId.isEmpty ? 'empty' : 'speaker'),
      diamonds:
          _readInt(raw, const ['diamonds', 'diamond', 'level', 'gems']) ?? 0,
      isMuted: _readBool(raw, const ['isMuted', 'muted', 'micMuted']),
      isLocked: _readBool(raw, const ['isLocked', 'locked']),
      isAdmin: _readBool(raw, const ['isAdmin', 'admin']),
      isVip: isVip,
      isCoinsSeller: isCoinsSeller,
    );
  }

  final int seatNo;
  final String userId;
  final String name;
  final String? avatarUrl;
  final String? avatarFrameUrl;

  /// Full-screen entrance SVGA from `GET /api/room/seats` when [isVip] is true.
  final String? vipFrameUrl;

  /// Entrance nameplate style from seats / profile (`classic` by default).
  final String pattiStyle;
  final String role;
  final int diamonds;
  final bool isMuted;
  final bool isLocked;
  final bool isAdmin;
  final bool isVip;

  /// Verified P2P coins merchant from seats / join payloads.
  final bool isCoinsSeller;

  bool get occupied => userId.trim().isNotEmpty || name.trim().isNotEmpty;
  bool get isHost => role.toLowerCase() == 'host' || seatNo == 1;

  /// Non-default patti used for entrance / seat tags.
  bool get hasCustomPattiStyle {
    final style = pattiStyle.trim().toLowerCase();
    return style.isNotEmpty && style != 'classic';
  }

  AudioRoomSeatModel copyWith({
    int? seatNo,
    String? userId,
    String? name,
    String? avatarUrl,
    String? avatarFrameUrl,
    String? vipFrameUrl,
    String? pattiStyle,
    String? role,
    int? diamonds,
    bool? isMuted,
    bool? isLocked,
    bool? isAdmin,
    bool? isVip,
    bool? isCoinsSeller,
  }) {
    return AudioRoomSeatModel(
      seatNo: seatNo ?? this.seatNo,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarFrameUrl: avatarFrameUrl ?? this.avatarFrameUrl,
      vipFrameUrl: vipFrameUrl ?? this.vipFrameUrl,
      pattiStyle: pattiStyle ?? this.pattiStyle,
      role: role ?? this.role,
      diamonds: diamonds ?? this.diamonds,
      isMuted: isMuted ?? this.isMuted,
      isLocked: isLocked ?? this.isLocked,
      isAdmin: isAdmin ?? this.isAdmin,
      isVip: isVip ?? this.isVip,
      isCoinsSeller: isCoinsSeller ?? this.isCoinsSeller,
    );
  }
}

class AudioRoomInviteCandidate {
  const AudioRoomInviteCandidate({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isOnline = false,
    this.isFollower = false,
    this.isInRoom = false,
  });

  factory AudioRoomInviteCandidate.fromMap(Map<String, dynamic> raw) {
    return AudioRoomInviteCandidate(
      id: _readString(raw, const ['id', '_id', 'userId', 'user_id']) ?? '',
      name: _readString(raw, const ['name', 'fullName', 'username']) ?? 'User',
      avatarUrl: _readString(raw, const [
        'avatarUrl',
        'avatar',
        'displayPicture',
        'profileImage',
        'image',
      ]),
      isOnline: _readBool(raw, const ['isOnline', 'online']),
      isFollower: _readBool(raw, const ['isFollower', 'follower']),
      isInRoom: _readBool(raw, const ['isInRoom', 'inRoom']),
    );
  }

  final String id;
  final String name;
  final String? avatarUrl;
  final bool isOnline;
  final bool isFollower;
  final bool isInRoom;
}

String? _readString(Map<String, dynamic>? raw, List<String> keys) {
  if (raw == null) return null;
  for (final key in keys) {
    final value = raw[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value != 'null') return value;
  }
  return null;
}

String? _readFrameUrl(dynamic value) {
  if (value == null) return null;
  if (value is String) {
    final text = value.trim();
    return text.isEmpty || text == 'null' ? null : text;
  }
  if (value is Map) {
    return _readString(Map<String, dynamic>.from(value), const [
      'image',
      'url',
      'frameUrl',
      'frame_url',
      'avatarFrameUrl',
      'avatar_frame_url',
    ]);
  }
  return null;
}

int? _readInt(Map<String, dynamic> raw, List<String> keys) {
  for (final key in keys) {
    final value = raw[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

bool _readBool(Map<String, dynamic> raw, List<String> keys) {
  for (final key in keys) {
    final value = raw[key];
    if (value is bool) return value;
    final normalized = value?.toString().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
  }
  return false;
}
