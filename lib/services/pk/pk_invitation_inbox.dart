import 'package:qobo_one_live/app/user_flow/pk_battle/models/v1/pk_v1_models.dart';

/// Flattens a socket, push, or list item into the keys [PkInvitation.fromJson]
/// already understands.
///
/// The server sometimes nests the invite under `data` or `invitation`, and
/// older `pk_request` payloads use `request_id` / `sender_host_name`.
Map<String, dynamic> pkInvitationFields(Map<dynamic, dynamic> raw) {
  final root = _stringKeyed(raw);
  final merged = Map<String, dynamic>.from(root);
  for (final key in const ['invitation', 'payload', 'data']) {
    final nested = root[key];
    if (nested is! Map) continue;
    final map = _stringKeyed(nested);
    if (map.containsKey('invitations') ||
        map.containsKey('items') ||
        map.containsKey('list')) {
      continue;
    }
    merged.addAll(map);
    final inner = map['invitation'];
    if (inner is Map) merged.addAll(_stringKeyed(inner));
  }

  _copyIfEmpty(merged, 'invitationId', const [
    'invitation_id',
    'request_id',
    'requestId',
    'id',
  ]);
  _copyIfEmpty(merged, 'fromUserId', const [
    'sender_host_id',
    'senderHostId',
    'sender_id',
  ]);
  _copyIfEmpty(merged, 'fromUserName', const [
    'sender_host_name',
    'senderHostName',
    'sender_name',
  ]);
  _copyIfEmpty(merged, 'fromUserAvatar', const [
    'sender_avatar',
    'senderAvatar',
    'sender_host_avatar',
  ]);
  _copyIfEmpty(merged, 'fromRoomId', const [
    'sender_room_id',
    'senderRoomId',
  ]);
  _copyIfEmpty(merged, 'toRoomId', const [
    'target_room_id',
    'targetRoomId',
    'room_id',
  ]);
  _copyIfEmpty(merged, 'durationSec', const [
    'battle_duration',
    'duration',
    'duration_sec',
  ]);
  _copyIfEmpty(merged, 'expiresAt', const ['expires_at']);
  return merged;
}

/// Pending invites from `GET /api/v1/pk/invitations?type=incoming`.
List<PkInvitation> pendingIncomingPkInvitations(Map<dynamic, dynamic>? body) {
  if (body == null || body.isEmpty) return const [];
  final root = _stringKeyed(body);
  final lists = <dynamic>[
    root['invitations'],
    root['items'],
    root['list'],
    root['incoming'],
    if (root['data'] is List) root['data'],
  ];
  final data = root['data'];
  if (data is Map) {
    final map = _stringKeyed(data);
    lists.addAll([
      map['invitations'],
      map['items'],
      map['list'],
      map['incoming'],
    ]);
  }

  final found = <PkInvitation>[];
  final seen = <String>{};
  for (final list in lists) {
    if (list is! List) continue;
    for (final item in list) {
      if (item is! Map) continue;
      final invitation = PkInvitation.fromJson(pkInvitationFields(item));
      if (!_isPending(invitation) || !seen.add(invitation.invitationId)) {
        continue;
      }
      found.add(invitation);
    }
  }
  if (found.isNotEmpty) return found;

  final single = PkInvitation.fromJson(pkInvitationFields(root));
  if (_isPending(single)) return [single];
  return const [];
}

bool _isPending(PkInvitation invitation) {
  if (invitation.invitationId.isEmpty) return false;
  final status = invitation.status.trim().toUpperCase();
  if (status.isNotEmpty &&
      status != 'PENDING' &&
      status != 'INVITED' &&
      status != 'WAITING') {
    return false;
  }
  if (invitation.expiresAt != null && invitation.remainingSeconds <= 0) {
    return false;
  }
  return true;
}

Map<String, dynamic> _stringKeyed(Map<dynamic, dynamic> raw) {
  return raw.map((key, value) => MapEntry(key.toString(), value));
}

/// What the challenger should do while "Waiting for them to accept" is up.
enum PkOutgoingWaitAction { keepWaiting, startBattle, declined, timedOut }

class PkOutgoingWaitDecision {
  const PkOutgoingWaitDecision(this.action, {this.pkId = ''});

  final PkOutgoingWaitAction action;
  final String pkId;
}

/// Reads an outgoing-invitations response for [invitationId].
///
/// Accept used to arrive only on the socket. This lets the waiting screen
/// leave as soon as the invitation itself says the other host accepted.
PkOutgoingWaitDecision outgoingInvitationWaitDecision({
  required String invitationId,
  Map<dynamic, dynamic>? body,
}) {
  final wanted = invitationId.trim();
  if (wanted.isEmpty || body == null || body.isEmpty) {
    return const PkOutgoingWaitDecision(PkOutgoingWaitAction.keepWaiting);
  }

  final match = _findInvitationMap(body, wanted);
  if (match == null) {
    return const PkOutgoingWaitDecision(PkOutgoingWaitAction.keepWaiting);
  }

  final status = (match['status'] ?? '').toString().trim().toUpperCase();
  final pkId = _pkIdFrom(match);

  if (_isDeclinedStatus(status)) {
    return const PkOutgoingWaitDecision(PkOutgoingWaitAction.declined);
  }
  if (_isTimedOutStatus(status)) {
    return const PkOutgoingWaitDecision(PkOutgoingWaitAction.timedOut);
  }
  if (status == 'PENDING' || status == 'INVITED' || status == 'WAITING') {
    return const PkOutgoingWaitDecision(PkOutgoingWaitAction.keepWaiting);
  }
  if (_isStartedStatus(status) || (status.isEmpty && pkId.isNotEmpty)) {
    final id = pkId.isNotEmpty ? pkId : wanted;
    if (id.isEmpty) {
      return const PkOutgoingWaitDecision(PkOutgoingWaitAction.keepWaiting);
    }
    return PkOutgoingWaitDecision(
      PkOutgoingWaitAction.startBattle,
      pkId: id,
    );
  }
  return const PkOutgoingWaitDecision(PkOutgoingWaitAction.keepWaiting);
}

/// Battle id from `GET /api/pk/active?room_id=`, or empty while still pending.
String activeBattleIdFromRoomPk(Map<dynamic, dynamic>? body) {
  final battle = _liveBattleMap(body);
  if (battle == null) return '';
  return _battleId(battle);
}

/// Maps a legacy active-battle payload into the v1 session shape.
Map<String, dynamic> legacyBattleAsSession({
  required Map<dynamic, dynamic> body,
  required String selfRoomId,
  String selfName = '',
  String selfAvatar = '',
  String opponentName = '',
  String opponentAvatar = '',
}) {
  final battle = _liveBattleMap(body);
  if (battle == null) return const {};
  final battleId = _battleId(battle);
  if (battleId.isEmpty) return const {};

  final room1 = _text(battle, const ['room1Id', 'room1_id']);
  final room2 = _text(battle, const ['room2Id', 'room2_id']);
  final score1 = _number(battle, const ['room1Score', 'room1_score']);
  final score2 = _number(battle, const ['room2Score', 'room2_score']);
  final mine = selfRoomId.trim();
  final selfIsRoom2 = mine.isNotEmpty && mine == room2;

  Map<String, dynamic> side({
    required String roomId,
    required int score,
    required bool isSelf,
  }) {
    return {
      'roomId': roomId,
      'score': score,
      'displayName': isSelf
          ? (selfName.trim().isEmpty ? 'Host' : selfName.trim())
          : (opponentName.trim().isEmpty ? 'Host' : opponentName.trim()),
      'avatarUrl': isSelf ? selfAvatar : opponentAvatar,
    };
  }

  return {
    'pkId': battleId,
    'status': 'ACTIVE',
    'durationSec': _number(battle, const [
      'duration',
      'durationSec',
      'duration_sec',
    ]),
    'remainingSec': _number(battle, const [
      'remainingSeconds',
      'remainingSec',
      'remaining_seconds',
    ]),
    'sideA': side(
      roomId: selfIsRoom2 ? room2 : room1,
      score: selfIsRoom2 ? score2 : score1,
      isSelf: true,
    ),
    'sideB': side(
      roomId: selfIsRoom2 ? room1 : room2,
      score: selfIsRoom2 ? score1 : score2,
      isSelf: false,
    ),
  };
}

String _text(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final text = map[key]?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

int _number(Map<String, dynamic> map, List<String> keys) {
  for (final key in keys) {
    final value = map[key];
    if (value is num) return value.toInt();
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}

/// pkId from a socket accept / start payload, including a nested session.
String pkIdFromPkPayload(Map<dynamic, dynamic> raw) {
  return _pkIdFrom(pkInvitationFields(raw));
}

Map<String, dynamic>? _findInvitationMap(
  Map<dynamic, dynamic> body,
  String invitationId,
) {
  final root = _stringKeyed(body);
  final candidates = <Map<String, dynamic>>[];

  void takeList(dynamic list) {
    if (list is! List) return;
    for (final item in list) {
      if (item is Map) candidates.add(pkInvitationFields(item));
    }
  }

  takeList(root['invitations']);
  takeList(root['items']);
  takeList(root['list']);
  takeList(root['outgoing']);
  if (root['data'] is List) takeList(root['data']);
  final data = root['data'];
  if (data is Map) {
    final map = _stringKeyed(data);
    takeList(map['invitations']);
    takeList(map['items']);
    takeList(map['list']);
    takeList(map['outgoing']);
    candidates.add(pkInvitationFields(map));
  }
  candidates.add(pkInvitationFields(root));

  for (final item in candidates) {
    final id = (item['invitationId'] ?? '').toString().trim();
    if (id == invitationId) return item;
  }
  return null;
}

String _pkIdFrom(Map<String, dynamic> map) {
  for (final key in const [
    'pkId',
    'pk_id',
    'battleId',
    'battle_id',
    'sessionId',
    'session_id',
  ]) {
    final text = map[key]?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  for (final key in const ['session', 'pk', 'battle']) {
    final nested = map[key];
    if (nested is Map) {
      final id = _pkIdFrom(_stringKeyed(nested));
      if (id.isNotEmpty) return id;
    }
  }
  final invitationId = (map['invitationId'] ?? '').toString().trim();
  final bareId = (map['id'] ?? '').toString().trim();
  if (bareId.isNotEmpty && bareId != invitationId) return bareId;
  return '';
}

Map<String, dynamic>? _liveBattleMap(Map<dynamic, dynamic>? body) {
  if (body == null || body.isEmpty) return null;
  final root = _stringKeyed(body);
  final data = root['data'];
  final map = data is Map ? _stringKeyed(data) : root;
  final nested = map['battle'];
  if (nested is Map && nested.isNotEmpty) {
    final battle = _stringKeyed(nested);
    if (_isClosedBattle(battle) || _battleId(battle).isEmpty) return null;
    return battle;
  }
  if (map['request'] != null) return null;
  if (_isClosedBattle(map) || _isPendingStatusText(map)) return null;
  if (_battleId(map).isEmpty) return null;
  final status = (map['status'] ?? '').toString().trim().toUpperCase();
  if (status.isNotEmpty && !_isStartedStatus(status)) return null;
  return map;
}

String _battleId(Map<String, dynamic> map) {
  for (final key in const [
    'battleId',
    'battle_id',
    'pkId',
    'pk_id',
    'id',
  ]) {
    final text = map[key]?.toString().trim() ?? '';
    if (text.isNotEmpty && text != 'null') return text;
  }
  return '';
}

bool _isClosedBattle(Map<String, dynamic> map) {
  final status = (map['status'] ?? '').toString().trim().toUpperCase();
  return _isDeclinedStatus(status) || _isTimedOutStatus(status);
}

bool _isPendingStatusText(Map<String, dynamic> map) {
  final status = (map['status'] ?? '').toString().trim().toUpperCase();
  return status == 'PENDING' || status == 'INVITED' || status == 'WAITING';
}

bool _isStartedStatus(String status) {
  switch (status) {
    case 'ACCEPTED':
    case 'ACTIVE':
    case 'STARTED':
    case 'STARTING':
    case 'LIVE':
    case 'COUNTDOWN':
    case 'BATTLE_ACTIVE':
    case 'BATTLEACTIVE':
    case 'IN_PROGRESS':
    case 'ONGOING':
      return true;
    default:
      return false;
  }
}

bool _isDeclinedStatus(String status) {
  switch (status) {
    case 'REJECTED':
    case 'DECLINED':
    case 'REJECT':
      return true;
    default:
      return false;
  }
}

bool _isTimedOutStatus(String status) {
  switch (status) {
    case 'TIMEOUT':
    case 'TIMED_OUT':
    case 'TIMEDOUT':
    case 'EXPIRED':
    case 'CANCELLED':
    case 'CANCELED':
      return true;
    default:
      return false;
  }
}

void _copyIfEmpty(
  Map<String, dynamic> target,
  String key,
  List<String> sources,
) {
  final current = target[key]?.toString().trim() ?? '';
  if (current.isNotEmpty && current != 'null') return;
  for (final source in sources) {
    final value = target[source];
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty || text == 'null') continue;
    target[key] = value;
    return;
  }
}
