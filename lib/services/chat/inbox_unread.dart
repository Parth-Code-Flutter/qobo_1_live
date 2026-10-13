/// Unread count for one inbox row.
///
/// A positive `unreadCount` wins. When that count is 0 but the last message
/// was sent by the other person, the row still counts as one unread. Opening
/// the chat clears it separately.
int inboxUnreadCount({
  required Map<String, dynamic> json,
  required String myUserId,
}) {
  final parsed = _asInt(
    json['unreadCount'] ?? json['unread_count'] ?? json['unread'],
  );
  if (parsed > 0) return parsed;

  if (json['isRead'] == true || json['read'] == true) return 0;
  if (json['lastMessageFromMe'] == true || json['sentByMe'] == true) {
    return 0;
  }

  final preview = _previewText(json);
  final type = json['lastMessageType']?.toString() ?? '';
  final hasBody = preview.isNotEmpty || type.contains('call');
  if (!hasBody) return 0;

  final sender = inboxLastSenderId(json);
  if (sender.isEmpty || myUserId.isEmpty || sender == myUserId) return 0;
  return 1;
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
