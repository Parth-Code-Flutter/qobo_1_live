/// How many unread messages the badge should show.
///
/// Before the chat is opened, a higher API count is kept. After it is read,
/// [sinceRead] ignores that old total and counts only messages seen since.
int unreadBadgeCount({
  required int reportedCount,
  required int seenIncomingCount,
  required bool alreadyRead,
  bool sinceRead = false,
}) {
  if (alreadyRead) return 0;
  final seen = seenIncomingCount < 0 ? 0 : seenIncomingCount;
  if (sinceRead) return seen;
  if (reportedCount > seen) return reportedCount;
  return seen;
}

/// Server-reported unread count. This does not guess from the last line.
int reportedInboxUnread(Map<String, dynamic> json) {
  return _asInt(json['unreadCount'] ?? json['unread_count'] ?? json['unread']);
}

/// True when this payload is a message from the other person.
bool inboxPayloadIsIncoming({
  required Map<String, dynamic> json,
  required String myUserId,
}) {
  if (json['isRead'] == true || json['read'] == true) return false;
  if (json['localOnly'] == true ||
      json['lastMessageFromMe'] == true ||
      json['sentByMe'] == true) {
    return false;
  }

  final preview = _previewText(json);
  final type = json['lastMessageType']?.toString() ?? '';
  final hasBody = preview.isNotEmpty || type.contains('call');
  if (!hasBody) return false;

  final sender = inboxLastSenderId(json);
  if (sender.isEmpty || myUserId.isEmpty || sender == myUserId) return false;
  return true;
}

/// Stable id for one incoming line, so a repeat fetch is not counted twice.
///
/// The same message from the list and from Firestore can differ by a few
/// milliseconds, so the time is kept only to the second.
String incomingMessageKey({
  required String preview,
  DateTime? activityAt,
  String? activityRaw,
  String? messageId,
}) {
  final stableId = messageId?.trim() ?? '';
  if (stableId.isNotEmpty) return stableId;
  final parsed = activityAt ?? DateTime.tryParse(activityRaw ?? '');
  final text = preview.trim();
  if (parsed != null) {
    final second = parsed.toUtc().millisecondsSinceEpoch ~/ 1000;
    return '$second|$text';
  }
  return text;
}

/// Who sent the last inbox line, when the payload includes it.
String inboxLastSenderId(Map<String, dynamic> json) {
  for (final key in [
    'lastMessageSenderId',
    'lastSenderId',
    'senderId',
    'fromUserId',
  ]) {
    final value = json[key]?.toString().trim() ?? '';
    if (value.isNotEmpty) return value;
  }

  final last = json['lastMessage'];
  if (last is Map) {
    for (final key in ['senderId', 'sender_id', 'fromUserId']) {
      final value = last[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
  }
  return '';
}

String _previewText(Map<String, dynamic> json) {
  final last = json['lastMessage'];
  if (last is String && last.trim().isNotEmpty) return last.trim();
  final preview = json['lastMessagePreview']?.toString().trim() ?? '';
  return preview;
}

int _asInt(dynamic raw) {
  if (raw is int) return raw;
  if (raw is double) return raw.round();
  return int.tryParse(raw?.toString() ?? '') ?? 0;
}

/// Counts actual incoming documents, including bursts missed by a latest-only
/// listener. Read receipts take precedence over stale inbox summary totals.
int countUnreadMessages({
  required Iterable<Map<String, dynamic>> messages,
  required String myUserId,
  DateTime? readThrough,
}) {
  if (myUserId.isEmpty) return 0;
  final ids = <String>{};
  for (final message in messages) {
    final sender = message['senderId']?.toString() ?? '';
    if (sender.isEmpty || sender == myUserId) continue;
    final status = message['status'];
    final mine = status is Map ? status[myUserId] : null;
    if (mine is Map && mine['readAt'] != null) continue;
    final time = message['activityAt'];
    if (readThrough != null && time is DateTime && !time.isAfter(readThrough)) {
      continue;
    }
    final id = ['clientMessageId', 'id', 'messageId']
        .map((key) => message[key]?.toString().trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    if (id.isNotEmpty) ids.add(id);
  }
  return ids.length;
}
