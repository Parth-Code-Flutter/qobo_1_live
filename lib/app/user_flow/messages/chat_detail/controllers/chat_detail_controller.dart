import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/repo/chat/chat_local_store.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/services/chat/chat_firebase_service.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:intl/intl.dart';

/// WhatsApp-style delivery state for outgoing messages.
enum ChatDeliveryStatus { sent, delivered, read }

/// One row in the chat list — either a date separator or a message bubble.
class ChatTimelineEntry {
  const ChatTimelineEntry.dateHeader(this.dateLabel) : message = null;

  const ChatTimelineEntry.message(this.message) : dateLabel = null;

  final String? dateLabel;
  final ChatMessageModel? message;

  bool get isDateHeader => dateLabel != null;
}

class ChatMessageModel {
  ChatMessageModel({
    required this.text,
    required this.isMe,
    required this.time,
    this.id,
    this.createdAt,
    this.clientMessageId,
    this.deliveryStatus = ChatDeliveryStatus.sent,
  });

  final String text;
  final bool isMe;
  final String time;
  final String? id;
  final DateTime? createdAt;
  final String? clientMessageId;
  final ChatDeliveryStatus deliveryStatus;
}

class ChatDetailController extends GetxController {
  ChatDetailController({
    ChatRepo? chatRepo,
    ChatLocalStore? localStore,
    ChatFirebaseService? firebaseService,
  })  : _chatRepo = chatRepo ?? ChatRepo(),
        _localStore = localStore ?? ChatLocalStore(),
        _firebaseService = firebaseService ?? ChatFirebaseService();

  final ChatRepo _chatRepo;
  final ChatLocalStore _localStore;
  final ChatFirebaseService _firebaseService;

  final chatName = 'Chat'.obs;
  final chatImageUrl = RxnString();
  final targetId = ''.obs;
  final roomId = ''.obs;
  final firestorePath = ''.obs;

  final messages = <ChatMessageModel>[].obs;
  final isLoading = false.obs;
  final isSending = false.obs;
  final isFirebaseLive = false.obs;
  final peerIsTyping = false.obs;
  final peerIsOnline = false.obs;
  final peerLastSeenAt = Rxn<DateTime>();
  final messageController = TextEditingController();

  StreamSubscription<List<Map<String, dynamic>>>? _firebaseSub;
  StreamSubscription<bool>? _typingSub;
  StreamSubscription<Map<String, dynamic>>? _presenceSub;
  Timer? _typingDebounce;
  Timer? _typingClearTimer;
  List<ChatMessageModel> _restBootstrap = [];

  String? get _myUserId {
    if (!Get.isRegistered<UserSessionController>()) return null;
    return Get.find<UserSessionController>().userId;
  }

  String get _effectiveRoomId {
    if (roomId.value.isNotEmpty) return roomId.value;
    final path = firestorePath.value.trim();
    if (path.isEmpty) return '';
    final parts = path.split('/').where((p) => p.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.last : '';
  }

  /// Status line under chat name in the app bar.
  String get presenceStatusLabel {
    if (peerIsTyping.value) return 'typing...';
    return peerIsOnline.value ? 'Online' : 'Offline';
  }

  Color get presenceStatusColor {
    if (peerIsTyping.value) return kColorPrimary;
    return peerIsOnline.value ? kColorLiveLocation : kColorHint;
  }

  /// Messages grouped with WhatsApp-style date headers (Today, Yesterday, …).
  List<ChatTimelineEntry> get timelineEntries {
    final entries = <ChatTimelineEntry>[];
    DateTime? lastDay;

    for (final msg in messages) {
      final day = _messageDay(msg);
      if (lastDay == null || day != lastDay) {
        entries.add(ChatTimelineEntry.dateHeader(_formatDateGroupLabel(day)));
        lastDay = day;
      }
      entries.add(ChatTimelineEntry.message(msg));
    }
    return entries;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['name'] != null) chatName.value = args['name'].toString();
      if (args['imageUrl'] != null) {
        chatImageUrl.value = ApiImageUtils.normalize(
          args['imageUrl']?.toString(),
        );
      }
      if (args['targetId'] != null) {
        targetId.value = args['targetId'].toString();
      }
      if (args['roomId'] != null) {
        roomId.value = args['roomId'].toString();
      }
      if (args['firestorePath'] != null) {
        firestorePath.value = args['firestorePath'].toString();
      }
    }
    messageController.addListener(_onMessageTextChanged);
    if (targetId.value.isNotEmpty) {
      _localStore.saveThreadMeta(
        targetId: targetId.value,
        name: chatName.value,
        imageUrl: chatImageUrl.value,
      );
      _bootstrapChat();
    }
  }

  Future<void> _bootstrapChat() async {
    await loadHistory();
    await _startFirebaseIfReady();
  }

  Future<void> loadHistory() async {
    if (targetId.value.isEmpty) return;
    try {
      isLoading.value = true;
      final myId = _myUserId ?? '';
      final apiMessages = <ChatMessageModel>[];
      final response = await _chatRepo.getConversation(
        targetId: targetId.value,
        isShowLoader: false,
      );
      if (isSocialApiSuccess(response)) {
        final list = response?['data'];
        if (list is List) {
          apiMessages.addAll(
            list.whereType<Map>().map((raw) => _mapMessage(raw, myId)),
          );
        }
      }

      final cached = await _localStore.readMessages(targetId.value);
      final merged = _mergeMessages(
        apiMessages,
        cached.map((raw) => _mapMessage(raw, myId)).toList(),
      );
      _restBootstrap = merged;
      if (!isFirebaseLive.value) {
        messages.assignAll(merged);
      } else {
        messages.assignAll(
          _mergeMessages(_restBootstrap, messages.toList()),
        );
      }
    } catch (_) {
      final cached = await _localStore.readMessages(targetId.value);
      final myId = _myUserId ?? '';
      _restBootstrap =
          cached.map((raw) => _mapMessage(raw, myId)).toList();
      if (!isFirebaseLive.value) {
        messages.assignAll(_restBootstrap);
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _startFirebaseIfReady() async {
    final effectiveRoomId = _effectiveRoomId;
    if (!_firebaseService.isAvailable || effectiveRoomId.isEmpty) return;

    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    final signedIn =
        await Get.find<ChatSessionService>().ensureSignedIn(isShowLoader: false);
    if (!signedIn) return;

    final myId = _myUserId ?? '';
    if (myId.isEmpty) return;

    await _firebaseSub?.cancel();
    await _typingSub?.cancel();
    await _presenceSub?.cancel();

    isFirebaseLive.value = true;

    await _firebaseService.setMyPresence(userId: myId, isOnline: true);

    _presenceSub = _firebaseService
        .watchPeerPresence(targetId.value)
        .listen(
          _applyPeerPresence,
          onError: (_) {},
        );

    _typingSub = _firebaseService
        .watchPeerTyping(roomId: effectiveRoomId, myUserId: myId)
        .listen(
          (typing) => peerIsTyping.value = typing,
          onError: (_) => peerIsTyping.value = false,
        );

    _firebaseSub = _firebaseService.watchMessages(effectiveRoomId).listen(
      (rawMessages) async {
        final live =
            rawMessages.map((raw) => _mapMessage(raw, myId)).toList();
        messages.assignAll(_mergeMessages(_restBootstrap, live));

        await _firebaseService.ackIncomingMessages(
          roomId: effectiveRoomId,
          myUserId: myId,
          rawMessages: rawMessages,
          markRead: true,
        );
      },
      onError: (_) {
        isFirebaseLive.value = false;
      },
    );
  }

  void _applyPeerPresence(Map<String, dynamic> data) {
    peerIsOnline.value = data['isOnline'] == true;
    peerLastSeenAt.value = _parseTimestamp(data['lastSeenAt']);
  }

  void _onMessageTextChanged() {
    if (!isFirebaseLive.value) return;
    final myId = _myUserId ?? '';
    final effectiveRoomId = _effectiveRoomId;
    if (myId.isEmpty || effectiveRoomId.isEmpty) return;

    final hasText = messageController.text.trim().isNotEmpty;
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(
        _firebaseService.setTyping(
          roomId: effectiveRoomId,
          userId: myId,
          isTyping: hasText,
        ),
      );
      _typingClearTimer?.cancel();
      if (hasText) {
        _typingClearTimer = Timer(const Duration(seconds: 4), () {
          unawaited(
            _firebaseService.setTyping(
              roomId: effectiveRoomId,
              userId: myId,
              isTyping: false,
            ),
          );
        });
      }
    });
  }

  Future<void> sendMessage() async {
    final text = messageController.text.trim();
    if (text.isEmpty || targetId.value.isEmpty || isSending.value) return;

    final myId = _myUserId ?? '';
    final effectiveRoomId = _effectiveRoomId;
    final clientMessageId =
        '${DateTime.now().millisecondsSinceEpoch}_$myId';

    isSending.value = true;
    messageController.clear();
    unawaited(
      _firebaseService.setTyping(
        roomId: effectiveRoomId,
        userId: myId,
        isTyping: false,
      ),
    );

    final now = DateTime.now();
    final optimistic = ChatMessageModel(
      text: text,
      isMe: true,
      time: _formatTime(now),
      createdAt: now,
      clientMessageId: clientMessageId,
      deliveryStatus: ChatDeliveryStatus.sent,
    );
    messages.add(optimistic);

    try {
      if (_firebaseService.isAvailable &&
          effectiveRoomId.isNotEmpty &&
          myId.isNotEmpty) {
        if (!Get.isRegistered<ChatSessionService>()) {
          Get.put(ChatSessionService(), permanent: true);
        }
        final signedIn = await Get.find<ChatSessionService>().ensureSignedIn(
          isShowLoader: false,
        );
        if (signedIn) {
          await _firebaseService.sendTextMessage(
            roomId: effectiveRoomId,
            senderId: myId,
            text: text,
            clientMessageId: clientMessageId,
            recipientId: targetId.value,
          );
          await _localStore.saveThreadMeta(
            targetId: targetId.value,
            name: chatName.value,
            imageUrl: chatImageUrl.value,
          );
          return;
        }
      }

      final response = await _chatRepo.sendMessage(
        targetId: targetId.value,
        content: text,
        roomId: effectiveRoomId.isNotEmpty ? effectiveRoomId : null,
      );

      if (isSocialApiSuccess(response)) {
        await loadHistory();
        return;
      }

      await _localStore.appendMessage(
        targetId: targetId.value,
        text: text,
        senderId: myId,
      );
      await _localStore.saveThreadMeta(
        targetId: targetId.value,
        name: chatName.value,
        imageUrl: chatImageUrl.value,
      );
    } catch (_) {
      await _localStore.appendMessage(
        targetId: targetId.value,
        text: text,
        senderId: myId,
      );
    } finally {
      isSending.value = false;
    }
  }

  ChatMessageModel _mapMessage(Map<dynamic, dynamic> raw, String myId) {
    final json = Map<String, dynamic>.from(raw);
    final senderId = json['senderId']?.toString() ?? '';
    final createdAtRaw = json['createdAt'];
    DateTime? createdAt = _parseTimestamp(createdAtRaw);
    if (createdAt == null) {
      final fallback = json['clientCreatedAt'];
      createdAt = _parseTimestamp(fallback);
    }
    final isMe = myId.isNotEmpty && senderId == myId;

    return ChatMessageModel(
      id: json['id']?.toString() ?? json['messageId']?.toString(),
      text: _extractContent(json['content']),
      isMe: isMe,
      time: _formatTime(createdAt),
      createdAt: createdAt,
      clientMessageId: json['clientMessageId']?.toString(),
      deliveryStatus: isMe
          ? _parseDeliveryStatus(json['status'], targetId.value)
          : ChatDeliveryStatus.sent,
    );
  }

  static ChatDeliveryStatus _parseDeliveryStatus(
    dynamic status,
    String recipientId,
  ) {
    if (recipientId.isEmpty || status is! Map) {
      return ChatDeliveryStatus.sent;
    }
    final recipientStatus = status[recipientId];
    if (recipientStatus is! Map) return ChatDeliveryStatus.sent;
    if (recipientStatus['readAt'] != null) return ChatDeliveryStatus.read;
    if (recipientStatus['deliveredAt'] != null) {
      return ChatDeliveryStatus.delivered;
    }
    return ChatDeliveryStatus.sent;
  }

  static DateTime? _parseTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is DateTime) return raw.toLocal();
    if (raw is Timestamp) return raw.toDate().toLocal();
    final text = raw.toString();
    if (text.isEmpty) return null;
    return DateTime.tryParse(text)?.toLocal();
  }

  static String _extractContent(dynamic content) {
    if (content == null) return '';
    if (content is String) return content;
    if (content is Map) {
      final text = content['text'] ?? content['message'];
      return text?.toString() ?? '';
    }
    return content.toString();
  }

  static List<ChatMessageModel> _mergeMessages(
    List<ChatMessageModel> a,
    List<ChatMessageModel> b,
  ) {
    final byKey = <String, ChatMessageModel>{};
    for (final msg in [...a, ...b]) {
      final key = msg.id?.isNotEmpty == true
          ? msg.id!
          : msg.clientMessageId?.isNotEmpty == true
              ? msg.clientMessageId!
              : '${msg.text}_${msg.createdAt?.toIso8601String() ?? msg.time}';
      byKey[key] = msg;
    }
    final merged = byKey.values.toList();
    merged.sort((x, y) {
      final xd = x.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final yd = y.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return xd.compareTo(yd);
    });
    return merged;
  }

  static DateTime _messageDay(ChatMessageModel msg) {
    final dt = msg.createdAt?.toLocal() ?? DateTime.now();
    return DateTime(dt.year, dt.month, dt.day);
  }

  static String _formatDateGroupLabel(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (day == today) return 'Today';
    if (day == yesterday) return 'Yesterday';
    if (day.year == now.year) {
      return DateFormat('d MMMM').format(day);
    }
    return DateFormat('d MMMM yyyy').format(day);
  }

  static String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('h:mm a').format(dt.toLocal());
  }

  @override
  void onClose() {
    final myId = _myUserId ?? '';
    final effectiveRoomId = _effectiveRoomId;
    if (myId.isNotEmpty && effectiveRoomId.isNotEmpty && isFirebaseLive.value) {
      unawaited(
        _firebaseService.setTyping(
          roomId: effectiveRoomId,
          userId: myId,
          isTyping: false,
        ),
      );
    }
    if (myId.isNotEmpty && isFirebaseLive.value) {
      unawaited(_firebaseService.setMyPresence(userId: myId, isOnline: false));
    }
    _firebaseSub?.cancel();
    _typingSub?.cancel();
    _presenceSub?.cancel();
    _typingDebounce?.cancel();
    _typingClearTimer?.cancel();
    messageController.removeListener(_onMessageTextChanged);
    messageController.dispose();
    super.onClose();
  }
}
