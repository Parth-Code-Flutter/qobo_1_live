import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/services/chat/chat_inbox_preview.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

/// Offline cache for chat until `POST /api/chat/send` is live on backend.
class ChatLocalStore {
  ChatLocalStore({LocalStorage? storage}) : _storage = storage ?? LocalStorage.shared;

  final LocalStorage _storage;

  Future<List<Map<String, dynamic>>> readMessages(String targetId) async {
    if (targetId.isEmpty) return [];
    final map = await _storage.getJsonFromStorage(kStorageChatMessages);
    if (map == null) return [];
    final list = map[targetId];
    if (list is! List) return [];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> appendMessage({
    required String targetId,
    required String text,
    required String senderId,
    String? clientMessageId,
  }) async {
    if (targetId.isEmpty || text.isEmpty) return;
    final all = await _readAll();
    final thread = List<Map<String, dynamic>>.from(
      (all[targetId] as List?)?.whereType<Map>().map(
            (e) => Map<String, dynamic>.from(e),
          ) ??
          [],
    );
    final id = clientMessageId ?? DateTime.now().microsecondsSinceEpoch.toString();
    thread.add({
      'id': id,
      'clientMessageId': id,
      'senderId': senderId,
      'content': text,
      'type': 'text',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'localOnly': true,
    });
    all[targetId] = thread;
    await _storage.writeJsonStorage(kStorageChatMessages, all);
    await _upsertThreadPreview(
      targetId: targetId,
      lastMessage: text,
      lastMessageAt: DateTime.now().toUtc().toIso8601String(),
    );
  }

  Future<List<Map<String, dynamic>>> readInboxThreads() async {
    final map = await _storage.getJsonFromStorage(kStorageChatInboxThreads);
    if (map == null) return [];
    final list = map['threads'];
    if (list is! List) return [];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> _upsertThreadPreview({
    required String targetId,
    required String lastMessage,
    required String lastMessageAt,
    String? name,
    String? imageUrl,
  }) async {
    final map = await _storage.getJsonFromStorage(kStorageChatInboxThreads);
    final data = map != null ? Map<String, dynamic>.from(map) : <String, dynamic>{};
    final threads = List<Map<String, dynamic>>.from(
      (data['threads'] as List?)?.whereType<Map>().map(
            (e) => Map<String, dynamic>.from(e),
          ) ??
          [],
    );

    final index = threads.indexWhere((t) => t['id']?.toString() == targetId);
    final existing = index >= 0 ? threads[index] : <String, dynamic>{};
    final updated = {
      'id': targetId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageAt,
      'lastMessageType': 'text',
      'unreadCount': 0,
      'recipient': {
        'id': targetId,
        'name': name ?? existing['recipient']?['name'] ?? 'User',
        'displayPicture':
            imageUrl ?? existing['recipient']?['displayPicture'],
      },
      'localOnly': true,
    };
    if (index >= 0) {
      threads[index] = updated;
    } else {
      threads.insert(0, updated);
    }
    data['threads'] = threads;
    await _storage.writeJsonStorage(kStorageChatInboxThreads, data);
  }

  Future<void> upsertCallPreview({
    required String targetId,
    required String roomId,
    required bool isVideo,
    required String outcome,
    required bool isIncoming,
    String? name,
    String? imageUrl,
  }) async {
    if (targetId.isEmpty) return;

    final inboxType = ChatInboxPreviewType.inboxTypeForUser(
      isVideo: isVideo,
      outcome: outcome,
      isCallee: isIncoming,
    );
    final preview = ChatInboxPreviewType.displayLabel(inboxType);
    final now = DateTime.now().toUtc().toIso8601String();

    final map = await _storage.getJsonFromStorage(kStorageChatInboxThreads);
    final data = map != null ? Map<String, dynamic>.from(map) : <String, dynamic>{};
    final threads = List<Map<String, dynamic>>.from(
      (data['threads'] as List?)?.whereType<Map>().map(
            (e) => Map<String, dynamic>.from(e),
          ) ??
          [],
    );

    final index = threads.indexWhere((t) => t['id']?.toString() == targetId);
    final existing = index >= 0 ? threads[index] : <String, dynamic>{};
    final updated = {
      'id': targetId,
      'roomId': roomId.isNotEmpty ? roomId : existing['roomId']?.toString() ?? '',
      'lastMessage': preview,
      'lastMessageTime': now,
      'lastMessageType': inboxType,
      'lastCallDirection': isIncoming ? 'incoming' : 'outgoing',
      'unreadCount': 0,
      'recipient': {
        'id': targetId,
        'name': name ?? existing['recipient']?['name'] ?? 'User',
        'displayPicture':
            imageUrl ?? existing['recipient']?['displayPicture'],
      },
      'localOnly': true,
    };
    if (index >= 0) {
      threads[index] = updated;
    } else {
      threads.insert(0, updated);
    }
    data['threads'] = threads;
    await _storage.writeJsonStorage(kStorageChatInboxThreads, data);
  }

  Future<void> appendCallEntry({
    required String roomId,
    required Map<String, dynamic> entry,
  }) async {
    if (roomId.isEmpty) return;
    final map = await _storage.getJsonFromStorage(kStorageChatCallHistory);
    final all = map != null ? Map<String, dynamic>.from(map) : <String, dynamic>{};
    final list = List<Map<String, dynamic>>.from(
      (all[roomId] as List?)?.whereType<Map>().map(
            (e) => Map<String, dynamic>.from(e),
          ) ??
          [],
    );
    final callId = entry['callId']?.toString() ?? entry['id']?.toString() ?? '';
    if (callId.isNotEmpty) {
      list.removeWhere(
        (e) =>
            e['callId']?.toString() == callId || e['id']?.toString() == callId,
      );
    }
    list.add(entry);
    list.sort((a, b) {
      final ad = DateTime.tryParse(a['clientEndedAt']?.toString() ?? '') ??
          DateTime.tryParse(a['endedAt']?.toString() ?? '');
      final bd = DateTime.tryParse(b['clientEndedAt']?.toString() ?? '') ??
          DateTime.tryParse(b['endedAt']?.toString() ?? '');
      if (ad == null && bd == null) return 0;
      if (ad == null) return -1;
      if (bd == null) return 1;
      return ad.compareTo(bd);
    });
    all[roomId] = list;
    await _storage.writeJsonStorage(kStorageChatCallHistory, all);
  }

  Future<List<Map<String, dynamic>>> readCallHistory(String roomId) async {
    if (roomId.isEmpty) return [];
    final map = await _storage.getJsonFromStorage(kStorageChatCallHistory);
    if (map == null) return [];
    final list = map[roomId];
    if (list is! List) return [];
    return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> saveThreadMeta({
    required String targetId,
    required String name,
    String? imageUrl,
  }) async {
    await _upsertThreadPreview(
      targetId: targetId,
      lastMessage: '',
      lastMessageAt: DateTime.now().toUtc().toIso8601String(),
      name: name,
      imageUrl: imageUrl,
    );
  }

  /// Removes a partner thread from the local inbox cache.
  Future<void> removeInboxThread(String targetId) async {
    if (targetId.isEmpty) return;
    final map = await _storage.getJsonFromStorage(kStorageChatInboxThreads);
    if (map == null) return;
    final data = Map<String, dynamic>.from(map);
    final threads = List<Map<String, dynamic>>.from(
      (data['threads'] as List?)?.whereType<Map>().map(
            (e) => Map<String, dynamic>.from(e),
          ) ??
          [],
    );
    threads.removeWhere((t) {
      final topId = t['id']?.toString() ?? '';
      final recipient = t['recipient'];
      final peerId = recipient is Map
          ? recipient['id']?.toString() ?? ''
          : '';
      return topId == targetId || peerId == targetId;
    });
    data['threads'] = threads;
    await _storage.writeJsonStorage(kStorageChatInboxThreads, data);
  }

  /// Clears cached messages for a partner thread.
  Future<void> clearMessagesForTarget(String targetId) async {
    if (targetId.isEmpty) return;
    final all = await _readAll();
    all.remove(targetId);
    await _storage.writeJsonStorage(kStorageChatMessages, all);
  }

  Future<Map<String, dynamic>> _readAll() async {
    final map = await _storage.getJsonFromStorage(kStorageChatMessages);
    if (map == null) return {};
    return Map<String, dynamic>.from(map);
  }

  /// Whether [POST /api/chat/send] already succeeded for this partner.
  Future<bool> hasChatSendInit(String targetId) async {
    if (targetId.isEmpty) return false;
    final set = await _readChatSendInitSet();
    return set.contains(targetId);
  }

  Future<void> markChatSendInit(String targetId) async {
    if (targetId.isEmpty) return;
    final set = await _readChatSendInitSet();
    if (set.contains(targetId)) return;
    set.add(targetId);
    await _storage.writeJsonStorage(
      kStorageChatSendInit,
      {'targets': set.toList()},
    );
  }

  Future<Set<String>> _readChatSendInitSet() async {
    final map = await _storage.getJsonFromStorage(kStorageChatSendInit);
    if (map == null) return {};
    final list = map['targets'];
    if (list is! List) return {};
    return list.map((e) => e.toString()).where((id) => id.isNotEmpty).toSet();
  }
}
