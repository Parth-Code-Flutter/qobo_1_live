import 'package:qobo_one_live/constants/local_storage_constants.dart';
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
}
