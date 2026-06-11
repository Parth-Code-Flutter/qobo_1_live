import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/repo/chat/chat_local_store.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/repo/chat/models/chat_room_model.dart';
import 'package:qobo_one_live/services/chat/chat_firebase_service.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
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
  }) : _chatRepo = chatRepo ?? ChatRepo(),
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
  final timelineEntries = <ChatTimelineEntry>[].obs;
  final isLoading = false.obs;
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
  bool _sendInFlight = false;
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

  final ScrollController scrollController = ScrollController();

  @override
  void onInit() {
    super.onInit();
    ever(messages, (_) => _refreshTimeline());
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
    await _ensureRoomReady();
    await _ensureFirebaseSession();
    await loadHistory();
    await _startFirebaseIfReady();
  }

  Future<bool> _ensureFirebaseSession() async {
    if (!_firebaseService.isAvailable) return false;
    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    return Get.find<ChatSessionService>().ensureSignedIn(isShowLoader: false);
  }

  Future<bool> _ensureRoomReady() async {
    if (targetId.value.isEmpty) return false;
    if (roomId.value.isNotEmpty || firestorePath.value.isNotEmpty) return true;

    final response = await _chatRepo.createRoom(
      targetId: targetId.value,
      isShowLoader: false,
    );
    if (!isSocialApiSuccess(response)) return false;

    final room = ChatRoomModel.fromResponseData(response?['data']);
    if (room.roomId.isNotEmpty) {
      roomId.value = room.roomId;
    }
    if (room.firestorePath.isNotEmpty) {
      firestorePath.value = room.firestorePath;
    }
    return roomId.value.isNotEmpty || firestorePath.value.isNotEmpty;
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

      // Firestore bootstrap when REST/local are empty but messages exist in Firebase.
      if (_firebaseService.isAvailable && _effectiveRoomId.isNotEmpty) {
        final signedIn = await _ensureFirebaseSession();
        if (signedIn) {
          final firestoreRaw = await _firebaseService.fetchMessagesOnce(
            _effectiveRoomId,
          );
          if (firestoreRaw.isNotEmpty) {
            final fromFirestore =
                firestoreRaw.map((raw) => _mapMessage(raw, myId)).toList();
            _restBootstrap = _mergeMessages(_restBootstrap, fromFirestore);
          }
        }
      }

      if (!isFirebaseLive.value) {
        messages.assignAll(_restBootstrap);
      } else {
        messages.assignAll(_mergeMessages(_restBootstrap, messages.toList()));
      }
    } catch (_) {
      final cached = await _localStore.readMessages(targetId.value);
      final myId = _myUserId ?? '';
      _restBootstrap = cached.map((raw) => _mapMessage(raw, myId)).toList();
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

    final signedIn = await _ensureFirebaseSession();
    if (!signedIn) {
      LoggerUtils.logWarning(
        'ChatDetailController: Firestore listener skipped — not signed in',
      );
      return;
    }

    final myId = _myUserId ?? '';
    if (myId.isEmpty) return;

    await _firebaseSub?.cancel();
    await _typingSub?.cancel();
    await _presenceSub?.cancel();

    isFirebaseLive.value = true;

    await _firebaseService.setMyPresence(userId: myId, isOnline: true);

    _presenceSub = _firebaseService
        .watchPeerPresence(targetId.value)
        .listen(_applyPeerPresence, onError: (_) {});

    _typingSub = _firebaseService
        .watchPeerTyping(roomId: effectiveRoomId, myUserId: myId)
        .listen(
          (typing) => peerIsTyping.value = typing,
          onError: (_) => peerIsTyping.value = false,
        );

    _firebaseSub = _firebaseService
        .watchMessages(effectiveRoomId)
        .listen(
          (rawMessages) {
            _applyFirestoreMessages(rawMessages, myId);
            _scrollToBottom();

            unawaited(
              _firebaseService.ackIncomingMessages(
                roomId: effectiveRoomId,
                myUserId: myId,
                rawMessages: rawMessages,
                markRead: true,
              ),
            );
          },
          onError: (e) {
            LoggerUtils.logWarning(
              'ChatDetailController: Firestore listener error — $e',
            );
            isFirebaseLive.value = false;
          },
        );
  }

  /// Merges REST/local bootstrap + in-flight optimistic + Firestore live data.
  /// Firestore wins on duplicate keys (last in merge order).
  void _applyFirestoreMessages(
    List<Map<String, dynamic>> rawMessages,
    String myId,
  ) {
    final live =
        rawMessages.map((raw) => _mapMessage(raw, myId)).toList();
    final merged = _mergeMessages(
      _mergeMessages(_restBootstrap, messages.toList()),
      live,
    );
    messages.assignAll(merged);
  }

  void _refreshTimeline() {
    final entries = <ChatTimelineEntry>[];
    int? lastDayKey;

    for (final msg in messages) {
      final dayKey = _messageDayKey(msg);
      if (lastDayKey == null || dayKey != lastDayKey) {
        entries.add(
          ChatTimelineEntry.dateHeader(_formatDateGroupLabel(_dayFromKey(dayKey))),
        );
        lastDayKey = dayKey;
      }
      entries.add(ChatTimelineEntry.message(msg));
    }
    timelineEntries.assignAll(entries);
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!scrollController.hasClients) return;
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
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
    if (text.isEmpty || targetId.value.isEmpty || _sendInFlight) return;

    final myId = _myUserId ?? '';
    final clientMessageId = '${DateTime.now().millisecondsSinceEpoch}_$myId';

    _sendInFlight = true;
    messageController.clear();

    final now = DateTime.now();
    messages.add(
      ChatMessageModel(
        text: text,
        isMe: true,
        time: _formatTime(now),
        createdAt: now,
        clientMessageId: clientMessageId,
        deliveryStatus: ChatDeliveryStatus.sent,
      ),
    );
    _scrollToBottom();

    // Fire-and-forget — UI stays responsive; no spinner blocking send button.
    unawaited(_dispatchSend(text: text, myId: myId, clientMessageId: clientMessageId));
  }

  Future<void> _dispatchSend({
    required String text,
    required String myId,
    required String clientMessageId,
  }) async {
    try {
      final sentViaFirestore = await _performSend(
        text: text,
        myId: myId,
        clientMessageId: clientMessageId,
      );
      if (sentViaFirestore && !isFirebaseLive.value) {
        await _startFirebaseIfReady();
      }
    } catch (e) {
      LoggerUtils.logWarning('ChatDetailController: send failed — $e');
      await _persistLocalFallback(
        text: text,
        myId: myId,
        clientMessageId: clientMessageId,
      );
    } finally {
      _sendInFlight = false;
    }
  }

  /// Returns true when message was written to Firestore.
  Future<bool> _performSend({
    required String text,
    required String myId,
    required String clientMessageId,
  }) async {
    var effectiveRoomId = _effectiveRoomId;
    if (effectiveRoomId.isEmpty) {
      await _ensureRoomReady();
      effectiveRoomId = _effectiveRoomId;
    }

    if (_firebaseService.isAvailable &&
        effectiveRoomId.isNotEmpty &&
        myId.isNotEmpty) {
      final signedIn = await _ensureFirebaseSession();
      if (signedIn) {
        final authUid = FirebaseAuth.instance.currentUser?.uid ?? myId;
        if (authUid != myId) {
          LoggerUtils.logWarning(
            'ChatDetailController: auth uid $authUid != app user $myId',
          );
        }
        await _firebaseService.sendTextMessage(
          roomId: effectiveRoomId,
          senderId: authUid,
          text: text,
          clientMessageId: clientMessageId,
          recipientId: targetId.value,
        );
        await _localStore.saveThreadMeta(
          targetId: targetId.value,
          name: chatName.value,
          imageUrl: chatImageUrl.value,
        );
        return true;
      }
      LoggerUtils.logWarning(
        'ChatDetailController: Firebase sign-in failed — using REST/local fallback',
      );
    }

    final response = await _chatRepo.sendMessage(
      targetId: targetId.value,
      content: text,
      roomId: effectiveRoomId.isNotEmpty ? effectiveRoomId : null,
    );

    if (isSocialApiSuccess(response)) {
      await loadHistory();
      return false;
    }

    await _persistLocalFallback(
      text: text,
      myId: myId,
      clientMessageId: clientMessageId,
    );
    return false;
  }

  Future<void> _persistLocalFallback({
    required String text,
    required String myId,
    required String clientMessageId,
  }) async {
    await _localStore.appendMessage(
      targetId: targetId.value,
      text: text,
      senderId: myId,
      clientMessageId: clientMessageId,
    );
    await _localStore.saveThreadMeta(
      targetId: targetId.value,
      name: chatName.value,
      imageUrl: chatImageUrl.value,
    );
    final localMsg = ChatMessageModel(
      text: text,
      isMe: true,
      time: _formatTime(DateTime.now()),
      createdAt: DateTime.now(),
      clientMessageId: clientMessageId,
      deliveryStatus: ChatDeliveryStatus.sent,
    );
    _restBootstrap = _mergeMessages(_restBootstrap, [localMsg]);
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
    final authUid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isMe = myId.isNotEmpty &&
        (senderId == myId || (authUid.isNotEmpty && senderId == authUid));

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
      final key = msg.clientMessageId?.isNotEmpty == true
          ? msg.clientMessageId!
          : msg.id?.isNotEmpty == true
          ? msg.id!
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

  static int _messageDayKey(ChatMessageModel msg) {
    final dt = msg.createdAt?.toLocal() ?? DateTime.now();
    return dt.year * 10000 + dt.month * 100 + dt.day;
  }

  static DateTime _dayFromKey(int key) {
    final year = key ~/ 10000;
    final month = (key % 10000) ~/ 100;
    final day = key % 100;
    return DateTime(year, month, day);
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

  void openContactProfile() {
    if (targetId.value.isEmpty) return;
    Get.toNamed(
      Routes.CHAT_CONTACT_PROFILE,
      arguments: {
        'targetId': targetId.value,
        'name': chatName.value,
        'imageUrl': chatImageUrl.value,
        'roomId': _effectiveRoomId,
        'presenceLabel': presenceStatusLabel,
        'presenceColor': presenceStatusColor,
      },
    );
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
    scrollController.dispose();
    super.onClose();
  }
}
