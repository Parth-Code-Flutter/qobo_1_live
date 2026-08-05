class FollowerPkPlayer {
  const FollowerPkPlayer({
    required this.userId,
    required this.name,
    this.avatarUrl,
  });

  factory FollowerPkPlayer.fromMap(Map<String, dynamic> map) {
    return FollowerPkPlayer(
      userId: _text(map, const ['user_id', 'userId', 'id']),
      name: _text(map, const ['name', 'fullName', 'username'], 'Player'),
      avatarUrl: _nullableText(map, const [
        'avatar',
        'avatarUrl',
        'displayPicture',
        'profileImage',
      ]),
    );
  }

  final String userId;
  final String name;
  final String? avatarUrl;
}

/// Server-authoritative state for the audio-room follower PK mode.
class FollowerPkBattle {
  const FollowerPkBattle({
    required this.battleId,
    required this.roomId,
    required this.status,
    required this.challenger,
    this.opponent,
    this.durationSeconds,
    this.remainingSeconds,
    this.startedAt,
    this.endsAt,
    this.inviteExpiresAt,
    this.challengerScore = 0,
    this.opponentScore = 0,
    this.result,
    this.winnerUserId,
    this.notifiedFollowerCount = 0,
  });

  factory FollowerPkBattle.fromMap(Map<String, dynamic> raw) {
    final map = _unwrapBattle(raw);
    return FollowerPkBattle(
      battleId: _text(map, const ['battle_id', 'battleId', 'id']),
      roomId: _text(map, const ['room_id', 'roomId']),
      status: _text(map, const ['status'], 'waiting_opponent').toLowerCase(),
      challenger: FollowerPkPlayer.fromMap(
        _map(map['challenger'] ?? map['challenger_user']),
      ),
      opponent: _map(map['opponent'] ?? map['opponent_user']).isEmpty
          ? null
          : FollowerPkPlayer.fromMap(
              _map(map['opponent'] ?? map['opponent_user']),
            ),
      durationSeconds: _int(map, const ['duration_seconds', 'duration']),
      remainingSeconds: _int(map, const [
        'remaining_seconds',
        'remainingSeconds',
      ]),
      startedAt: _date(map, const ['started_at', 'startedAt']),
      endsAt: _date(map, const ['ends_at', 'endsAt']),
      inviteExpiresAt: _date(map, const [
        'invite_expires_at',
        'expires_at',
        'expiresAt',
      ]),
      challengerScore:
          _int(map, const ['challenger_score', 'challengerScore']) ?? 0,
      opponentScore: _int(map, const ['opponent_score', 'opponentScore']) ?? 0,
      result: _nullableText(map, const ['result']),
      winnerUserId: _nullableText(map, const [
        'winner_user_id',
        'winnerUserId',
      ]),
      notifiedFollowerCount: _int(map, const ['notified_follower_count']) ?? 0,
    );
  }

  final String battleId;
  final String roomId;
  final String status;
  final FollowerPkPlayer challenger;
  final FollowerPkPlayer? opponent;
  final int? durationSeconds;
  final int? remainingSeconds;
  final DateTime? startedAt;
  final DateTime? endsAt;
  final DateTime? inviteExpiresAt;
  final int challengerScore;
  final int opponentScore;
  final String? result;
  final String? winnerUserId;
  final int notifiedFollowerCount;

  bool get isWaiting => status == 'waiting_opponent';
  bool get isDurationPending => status == 'duration_pending';
  bool get isActive => status == 'active';
  bool get isCompleted =>
      status == 'completed' || status == 'cancelled' || status == 'expired';

  int secondsRemaining() {
    if (remainingSeconds != null) return remainingSeconds!.clamp(0, 900);
    if (endsAt != null) {
      return endsAt!.difference(DateTime.now()).inSeconds.clamp(0, 900);
    }
    return durationSeconds ?? 0;
  }
}

Map<String, dynamic> _unwrapBattle(Map<String, dynamic> raw) {
  final battle = _map(raw['battle']);
  return battle.isNotEmpty ? battle : raw;
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const <String, dynamic>{};
}

String _text(
  Map<String, dynamic> map,
  List<String> keys, [
  String fallback = '',
]) {
  return _nullableText(map, keys) ?? fallback;
}

String? _nullableText(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key]?.toString().trim();
    if (value != null && value.isNotEmpty && value != 'null') return value;
  }
  return null;
}

int? _int(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

DateTime? _date(Map<String, dynamic> map, List<String> keys) {
  final value = _nullableText(map, keys);
  return value == null ? null : DateTime.tryParse(value)?.toLocal();
}
