/// Data models for the host-vs-host PK Battle v1 API (`/api/v1/pk/*`).
///
/// All fields are parsed defensively (multiple key spellings, string/number
/// tolerance) so the UI never crashes on a slightly different backend shape.
library;

/// Which side of the PK a host / gift belongs to.
enum PkBattleSide { a, b, tie, none }

PkBattleSide pkSideFromRaw(dynamic raw) {
  final value = raw?.toString().trim().toUpperCase();
  switch (value) {
    case 'A':
    case 'SIDE_A':
    case 'SIDEA':
      return PkBattleSide.a;
    case 'B':
    case 'SIDE_B':
    case 'SIDEB':
      return PkBattleSide.b;
    case 'TIE':
    case 'DRAW':
      return PkBattleSide.tie;
    default:
      return PkBattleSide.none;
  }
}

String pkSideToApi(PkBattleSide side) {
  switch (side) {
    case PkBattleSide.a:
      return 'A';
    case PkBattleSide.b:
      return 'B';
    case PkBattleSide.tie:
      return 'TIE';
    case PkBattleSide.none:
      return '';
  }
}

/// Lifecycle of a PK session (mirrors the spec state machine).
enum PkSessionStatus {
  pending,
  accepted,
  starting,
  live,
  ended,
  cancelled,
  expired,
  unknown,
}

PkSessionStatus pkStatusFromRaw(dynamic raw) {
  final value = raw?.toString().trim().toUpperCase();
  switch (value) {
    case 'PENDING':
      return PkSessionStatus.pending;
    case 'ACCEPTED':
      return PkSessionStatus.accepted;
    case 'STARTING':
      return PkSessionStatus.starting;
    case 'LIVE':
      return PkSessionStatus.live;
    case 'ENDED':
      return PkSessionStatus.ended;
    case 'CANCELLED':
    case 'CANCELED':
      return PkSessionStatus.cancelled;
    case 'EXPIRED':
      return PkSessionStatus.expired;
    default:
      return PkSessionStatus.unknown;
  }
}

// ----- small parse helpers -------------------------------------------------

String _str(Map<String, dynamic> j, List<String> keys, [String fallback = '']) {
  for (final k in keys) {
    final v = j[k];
    if (v != null && v.toString().trim().isNotEmpty) return v.toString();
  }
  return fallback;
}

int _int(Map<String, dynamic> j, List<String> keys, [int fallback = 0]) {
  for (final k in keys) {
    final v = j[k];
    if (v is num) return v.toInt();
    final parsed = int.tryParse(v?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return fallback;
}

bool _bool(Map<String, dynamic> j, List<String> keys, [bool fallback = false]) {
  for (final k in keys) {
    final v = j[k];
    if (v is bool) return v;
    final s = v?.toString().trim().toLowerCase();
    if (s == 'true' || s == '1') return true;
    if (s == 'false' || s == '0') return false;
  }
  return fallback;
}

DateTime? _date(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v == null) continue;
    if (v is DateTime) return v.toUtc();
    final parsed = DateTime.tryParse(v.toString());
    if (parsed != null) return parsed.toUtc();
  }
  return null;
}

Map<String, dynamic> _asMap(dynamic raw) {
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}

/// A live host that can be invited to a PK.
class PkEligibleHost {
  const PkEligibleHost({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
    required this.roomId,
    required this.viewerCount,
    required this.status,
    required this.canReceivePk,
  });

  final String userId;
  final String displayName;
  final String avatarUrl;
  final String roomId;
  final int viewerCount;
  final String status;
  final bool canReceivePk;

  factory PkEligibleHost.fromJson(Map<String, dynamic> j) {
    return PkEligibleHost(
      userId: _str(j, const ['userId', 'user_id', 'id']),
      displayName: _str(j, const ['displayName', 'display_name', 'name'], 'Host'),
      avatarUrl: _str(j, const ['avatarUrl', 'avatar_url', 'avatar', 'image']),
      roomId: _str(j, const ['roomId', 'room_id']),
      viewerCount: _int(j, const ['viewerCount', 'viewer_count', 'viewers']),
      status: _str(j, const ['status'], 'LIVE'),
      canReceivePk: _bool(j, const ['canReceivePk', 'can_receive_pk'], true),
    );
  }
}

/// A pending PK invitation (incoming or outgoing).
class PkInvitation {
  const PkInvitation({
    required this.invitationId,
    required this.fromUserId,
    required this.fromUserName,
    required this.fromUserAvatar,
    required this.toUserId,
    required this.toUserName,
    required this.toUserAvatar,
    required this.fromRoomId,
    required this.toRoomId,
    required this.mode,
    required this.durationSec,
    required this.status,
    required this.expiresAt,
  });

  final String invitationId;
  final String fromUserId;
  final String fromUserName;
  final String fromUserAvatar;
  final String toUserId;
  final String toUserName;
  final String toUserAvatar;
  final String fromRoomId;
  final String toRoomId;
  final String mode;
  final int durationSec;
  final String status;
  final DateTime? expiresAt;

  factory PkInvitation.fromJson(Map<String, dynamic> j) {
    return PkInvitation(
      invitationId: _str(j, const ['invitationId', 'invitation_id', 'id']),
      fromUserId: _str(j, const ['fromUserId', 'from_user_id']),
      fromUserName: _str(j, const ['fromUserName', 'from_user_name'], 'Host'),
      fromUserAvatar: _str(j, const ['fromUserAvatar', 'from_user_avatar']),
      toUserId: _str(j, const ['toUserId', 'to_user_id', 'targetUserId']),
      toUserName: _str(j, const ['toUserName', 'to_user_name'], 'Host'),
      toUserAvatar: _str(j, const ['toUserAvatar', 'to_user_avatar']),
      fromRoomId: _str(j, const ['fromRoomId', 'from_room_id']),
      toRoomId: _str(j, const ['toRoomId', 'to_room_id']),
      mode: _str(j, const ['mode'], 'ONE_VS_ONE'),
      durationSec: _int(j, const ['durationSec', 'duration_sec', 'duration'], 180),
      status: _str(j, const ['status'], 'PENDING'),
      expiresAt: _date(j, const ['expiresAt', 'expires_at']),
    );
  }

  /// Seconds remaining until the invitation expires (0 if past/unknown).
  int get remainingSeconds {
    final exp = expiresAt;
    if (exp == null) return 0;
    final diff = exp.difference(DateTime.now().toUtc()).inSeconds;
    return diff > 0 ? diff : 0;
  }
}

/// One side (host) of a PK session with its current score.
class PkSideInfo {
  const PkSideInfo({
    required this.hostId,
    required this.displayName,
    required this.avatarUrl,
    required this.roomId,
    required this.score,
    this.audience = const [],
  });

  final String hostId;
  final String displayName;
  final String avatarUrl;
  final String roomId;
  final int score;

  /// Viewers currently in this host's live room (from PK state / sync).
  final List<PkAudienceMember> audience;

  factory PkSideInfo.fromJson(Map<String, dynamic> j) {
    final audienceRaw = j['audience'] ??
        j['viewers'] ??
        j['topViewers'] ??
        j['top_viewers'] ??
        j['roomAudience'] ??
        j['room_audience'];
    return PkSideInfo(
      hostId: _str(j, const ['hostId', 'host_id', 'userId', 'user_id']),
      displayName: _str(j, const ['displayName', 'display_name', 'name'], 'Host'),
      avatarUrl: _str(j, const ['avatarUrl', 'avatar_url', 'avatar']),
      roomId: _str(j, const ['roomId', 'room_id']),
      score: _int(j, const ['score']),
      audience: PkAudienceMember.listFrom(audienceRaw),
    );
  }

  PkSideInfo copyWith({
    int? score,
    List<PkAudienceMember>? audience,
  }) =>
      PkSideInfo(
        hostId: hostId,
        displayName: displayName,
        avatarUrl: avatarUrl,
        roomId: roomId,
        score: score ?? this.score,
        audience: audience ?? this.audience,
      );

  PkSideInfo copyWithScore(int newScore) => copyWith(score: newScore);

  static const empty = PkSideInfo(
    hostId: '',
    displayName: '',
    avatarUrl: '',
    roomId: '',
    score: 0,
  );
}

/// A viewer / floor audience member belonging to one PK side's room.
class PkAudienceMember {
  const PkAudienceMember({
    required this.userId,
    required this.displayName,
    required this.avatarUrl,
  });

  final String userId;
  final String displayName;
  final String avatarUrl;

  factory PkAudienceMember.fromJson(Map<String, dynamic> j) {
    return PkAudienceMember(
      userId: _str(j, const ['userId', 'user_id', 'id']),
      displayName:
          _str(j, const ['displayName', 'display_name', 'name'], 'Viewer'),
      avatarUrl: _str(j, const [
        'avatarUrl',
        'avatar_url',
        'avatar',
        'displayPicture',
        'profileImage',
      ]),
    );
  }

  static List<PkAudienceMember> listFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => PkAudienceMember.fromJson(
              e.map((k, v) => MapEntry(k.toString(), v)),
            ))
        .where((m) => m.userId.isNotEmpty || m.displayName.isNotEmpty)
        .toList();
  }
}

/// Authoritative PK session state.
class PkSession {
  const PkSession({
    required this.pkId,
    required this.status,
    required this.mode,
    required this.durationSec,
    required this.remainingSec,
    required this.startsAt,
    required this.endsAt,
    required this.serverTime,
    required this.currentUserSide,
    required this.sideA,
    required this.sideB,
  });

  final String pkId;
  final PkSessionStatus status;
  final String mode;
  final int durationSec;
  final int remainingSec;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final DateTime? serverTime;
  final PkBattleSide currentUserSide;
  final PkSideInfo sideA;
  final PkSideInfo sideB;

  factory PkSession.fromJson(Map<String, dynamic> j) {
    return PkSession(
      pkId: _str(j, const ['pkId', 'pk_id', 'id']),
      status: pkStatusFromRaw(j['status']),
      mode: _str(j, const ['mode'], 'ONE_VS_ONE'),
      durationSec: _int(j, const ['durationSec', 'duration_sec', 'duration'], 180),
      remainingSec: _int(j, const ['remainingSec', 'remaining_sec']),
      startsAt: _date(j, const ['startsAt', 'starts_at', 'startAt']),
      endsAt: _date(j, const ['endsAt', 'ends_at', 'endAt']),
      serverTime: _date(j, const ['serverTime', 'server_time']),
      currentUserSide: pkSideFromRaw(
        _str(j, const ['currentUserSide', 'current_user_side']),
      ),
      sideA: PkSideInfo.fromJson(_asMap(j['sideA'] ?? j['side_a'])),
      sideB: PkSideInfo.fromJson(_asMap(j['sideB'] ?? j['side_b'])),
    );
  }
}

/// Result of sending a gift to a PK side.
class PkGiftSendResult {
  const PkGiftSendResult({
    required this.success,
    required this.transactionId,
    required this.targetSide,
    required this.coinAmount,
    required this.pkPoints,
    required this.scoreA,
    required this.scoreB,
  });

  final bool success;
  final String transactionId;
  final PkBattleSide targetSide;
  final int coinAmount;
  final int pkPoints;
  final int scoreA;
  final int scoreB;

  factory PkGiftSendResult.fromJson(Map<String, dynamic> j) {
    return PkGiftSendResult(
      success: _bool(j, const ['success'], true),
      transactionId: _str(j, const ['transactionId', 'transaction_id']),
      targetSide: pkSideFromRaw(_str(j, const ['targetSide', 'target_side'])),
      coinAmount: _int(j, const ['coinAmount', 'coin_amount']),
      pkPoints: _int(j, const ['pkPoints', 'pk_points']),
      scoreA: _int(j, const ['scoreA', 'score_a']),
      scoreB: _int(j, const ['scoreB', 'score_b']),
    );
  }
}

/// Final PK result / winner.
class PkResult {
  const PkResult({
    required this.pkId,
    required this.status,
    required this.winnerSide,
    required this.winnerId,
    required this.scoreA,
    required this.scoreB,
    required this.durationSec,
  });

  final String pkId;
  final PkSessionStatus status;
  final PkBattleSide winnerSide;
  final String winnerId;
  final int scoreA;
  final int scoreB;
  final int durationSec;

  factory PkResult.fromJson(Map<String, dynamic> j) {
    return PkResult(
      pkId: _str(j, const ['pkId', 'pk_id', 'id']),
      status: pkStatusFromRaw(j['status'] ?? 'ENDED'),
      winnerSide: pkSideFromRaw(_str(j, const ['winnerSide', 'winner_side'])),
      winnerId: _str(j, const ['winnerId', 'winner_id']),
      scoreA: _int(j, const ['scoreA', 'score_a']),
      scoreB: _int(j, const ['scoreB', 'score_b']),
      durationSec: _int(j, const ['durationSec', 'duration_sec']),
    );
  }
}

/// A gift-received realtime event (for animation over the PK video).
class PkGiftEvent {
  const PkGiftEvent({
    required this.pkId,
    required this.targetSide,
    required this.giftId,
    required this.giftName,
    required this.iconUrl,
    required this.animationUrl,
    required this.soundUrl,
    required this.quantity,
    required this.pkPoints,
    required this.senderId,
    required this.senderName,
    required this.senderAvatar,
  });

  final String pkId;
  final PkBattleSide targetSide;
  final String giftId;
  final String giftName;
  final String iconUrl;
  final String animationUrl;
  final String soundUrl;
  final int quantity;
  final int pkPoints;
  final String senderId;
  final String senderName;
  final String senderAvatar;

  factory PkGiftEvent.fromJson(Map<String, dynamic> j) {
    final gift = _asMap(j['gift']);
    final sender = _asMap(j['sender']);
    return PkGiftEvent(
      pkId: _str(j, const ['pkId', 'pk_id']),
      targetSide: pkSideFromRaw(_str(j, const ['targetSide', 'target_side'])),
      giftId: _str(gift, const ['id', 'giftId']),
      giftName: _str(gift, const ['name'], 'Gift'),
      iconUrl: _str(gift, const ['iconUrl', 'icon_url', 'icon']),
      animationUrl:
          _str(gift, const ['animationUrl', 'animation_url', 'svgaUrl']),
      soundUrl: _str(gift, const ['soundUrl', 'sound_url']),
      quantity: _int(gift, const ['quantity', 'qty'], 1),
      pkPoints: _int(gift, const ['pkPoints', 'pk_points']),
      senderId: _str(sender, const ['userId', 'user_id', 'id']),
      senderName: _str(sender, const ['displayName', 'display_name', 'name']),
      senderAvatar: _str(sender, const ['avatarUrl', 'avatar_url', 'avatar']),
    );
  }
}

/// A virtual gift available to send during a PK.
class PkGiftCatalogItem {
  const PkGiftCatalogItem({
    required this.id,
    required this.name,
    required this.iconUrl,
    required this.animationUrl,
    required this.soundUrl,
    required this.coinCost,
    required this.pkPointValue,
  });

  final String id;
  final String name;
  final String iconUrl;
  final String animationUrl;
  final String soundUrl;
  final int coinCost;
  final int pkPointValue;

  factory PkGiftCatalogItem.fromJson(Map<String, dynamic> j) {
    return PkGiftCatalogItem(
      id: _str(j, const ['id', 'giftId', 'gift_id']),
      name: _str(j, const ['name'], 'Gift'),
      iconUrl: _str(j, const ['iconUrl', 'icon_url', 'icon', 'image']),
      animationUrl:
          _str(j, const ['animationUrl', 'animation_url', 'svgaUrl', 'svga']),
      soundUrl: _str(j, const ['soundUrl', 'sound_url']),
      coinCost: _int(j, const ['coinCost', 'coin_cost', 'price', 'coins']),
      pkPointValue:
          _int(j, const ['pkPointValue', 'pk_point_value', 'pkPoints', 'points']),
    );
  }
}
