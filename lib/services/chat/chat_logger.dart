import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// Structured chat logs — filter in console with `[ChatSend]`, `[ChatLoad]`, etc.
abstract final class ChatLogger {
  static void bootstrap(String message, [Map<String, Object?>? fields]) {
    _info('ChatBootstrap', message, fields);
  }

  static void session(String message, [Map<String, Object?>? fields]) {
    _info('ChatSession', message, fields);
  }

  static void sessionWarn(String message, [Map<String, Object?>? fields]) {
    _warn('ChatSession', message, fields);
  }

  static void room(String message, [Map<String, Object?>? fields]) {
    _info('ChatRoom', message, fields);
  }

  static void roomWarn(String message, [Map<String, Object?>? fields]) {
    _warn('ChatRoom', message, fields);
  }

  static void load(String message, [Map<String, Object?>? fields]) {
    _info('ChatLoad', message, fields);
  }

  static void loadWarn(String message, [Map<String, Object?>? fields]) {
    _warn('ChatLoad', message, fields);
  }

  static void send(String message, [Map<String, Object?>? fields]) {
    _info('ChatSend', message, fields);
  }

  static void sendWarn(String message, [Map<String, Object?>? fields]) {
    _warn('ChatSend', message, fields);
  }

  static void sendResult({
    required String targetId,
    required String roomId,
    required String clientMessageId,
    required bool firestoreOk,
    required bool restOk,
    required bool localFallback,
    String? preview,
  }) {
    final path = localFallback
        ? 'local'
        : firestoreOk && restOk
        ? 'firestore+rest'
        : firestoreOk
        ? 'firestore'
        : restOk
        ? 'rest'
        : 'failed';
    send(
      'completed path=$path',
      {
        'targetId': _short(targetId),
        'roomId': _short(roomId),
        'clientMessageId': _short(clientMessageId),
        'firestore': firestoreOk,
        'rest': restOk,
        'local': localFallback,
        if (preview != null) 'text': _preview(preview),
      },
    );
  }

  static void live(String message, [Map<String, Object?>? fields]) {
    _info('ChatLive', message, fields);
  }

  static void liveWarn(String message, [Map<String, Object?>? fields]) {
    _warn('ChatLive', message, fields);
  }

  static void inbox(String message, [Map<String, Object?>? fields]) {
    _info('ChatInbox', message, fields);
  }

  static void inboxWarn(String message, [Map<String, Object?>? fields]) {
    _warn('ChatInbox', message, fields);
  }

  static void api(String endpoint, String message, [Map<String, Object?>? fields]) {
    _info('ChatAPI', '$endpoint — $message', fields);
  }

  static void apiWarn(String endpoint, String message, [Map<String, Object?>? fields]) {
    _warn('ChatAPI', '$endpoint — $message', fields);
  }

  static void cache(String message, [Map<String, Object?>? fields]) {
    _info('ChatCache', message, fields);
  }

  static void firestore(String message, [Map<String, Object?>? fields]) {
    _info('ChatFirestore', message, fields);
  }

  static void firestoreWarn(String message, [Map<String, Object?>? fields]) {
    _warn('ChatFirestore', message, fields);
  }

  static void _info(
    String scope,
    String message,
    Map<String, Object?>? fields,
  ) {
    LoggerUtils.logInfo(_format(scope, message, fields));
  }

  static void _warn(
    String scope,
    String message,
    Map<String, Object?>? fields,
  ) {
    LoggerUtils.logWarning(_format(scope, message, fields));
  }

  static String _format(
    String scope,
    String message,
    Map<String, Object?>? fields,
  ) {
    final buffer = StringBuffer('[$scope] $message');
    if (fields == null || fields.isEmpty) return buffer.toString();
    for (final entry in fields.entries) {
      if (entry.value == null) continue;
      buffer.write(' | ${entry.key}=${entry.value}');
    }
    return buffer.toString();
  }

  static String _short(String value, {int max = 24}) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}…';
  }

  static String _preview(String text, {int max = 40}) {
    final trimmed = text.trim().replaceAll('\n', ' ');
    if (trimmed.length <= max) return trimmed;
    return '${trimmed.substring(0, max)}…';
  }
}
