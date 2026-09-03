import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/repo/emoji/emoji_repo.dart';
import 'package:qobo_one_live/repo/family/family_repo.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_response_utils.dart';
import 'package:qobo_one_live/utils/app_dialogs/common_app_dialog.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_media_utils.dart';

class FamilyController extends GetxController {
  FamilyController({
    FamilyRepo? familyRepo,
    EconomyRepo? economyRepo,
    EmojiRepo? emojiRepo,
  }) : _familyRepo = familyRepo ?? FamilyRepo(),
       _economyRepo = economyRepo ?? EconomyRepo(),
       _emojiRepo = emojiRepo ?? EmojiRepo();

  final FamilyRepo _familyRepo;
  final EconomyRepo _economyRepo;
  final EmojiRepo _emojiRepo;

  final isLoading = true.obs;
  final selectedTab = 0.obs;
  final searchQuery = ''.obs;
  final isSendingMessage = false.obs;
  final isLoadingMembers = false.obs;
  final isLoadingPickerUsers = false.obs;
  final isLoadingEmojis = false.obs;
  final isLoadingGifts = false.obs;
  final isCreatingFamily = false.obs;

  final myGroups = <Map<String, dynamic>>[].obs;
  final discoverGroups = <Map<String, dynamic>>[].obs;
  final familyMembers = <Map<String, dynamic>>[].obs;
  final pickerUsers = <Map<String, dynamic>>[].obs;
  final selectedInitialMembers = <String>{}.obs;
  final pickerSearchQuery = ''.obs;
  final pickerFollowersOnly = true.obs;
  final emojiCatalog = <Map<String, String>>[].obs;
  final giftCatalog = <Map<String, String>>[].obs;

  /// Active family group chat thread (Firestore + optimistic + REST fallback).
  final activeChatMessages = <Map<String, dynamic>>[].obs;
  final isLoadingChatMessages = false.obs;
  final chatListenError = ''.obs;

  /// Other members currently typing (WhatsApp-style group indicator).
  final typingPeerNames = <String>[].obs;
  String get typingStatusLabel {
    final names = typingPeerNames;
    if (names.isEmpty) return '';
    if (names.length == 1) return '${names.first} is typing...';
    if (names.length == 2) {
      return '${names[0]} and ${names[1]} are typing...';
    }
    return '${names.first} and ${names.length - 1} others are typing...';
  }

  bool get isAnyoneTyping => typingPeerNames.isNotEmpty;

  String _activeChatFamilyId = '';
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _chatSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _typingSub;
  Timer? _typingDebounce;
  Timer? _typingClearTimer;

  Timer? _pickerSearchDebounce;

  bool get hasGroups => myGroups.isNotEmpty;

  String get currentUserId {
    if (!Get.isRegistered<UserSessionController>()) return '';
    return Get.find<UserSessionController>().userId.trim();
  }

  @override
  void onInit() {
    super.onInit();
    unawaited(_ensureFirebaseChatSession());
    loadFamilyHub();
  }

  Future<bool> _ensureFirebaseChatSession() async {
    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    return Get.find<ChatSessionService>().ensureSignedIn(isShowLoader: false);
  }

  Future<void> loadFamilyHub() async {
    isLoading.value = true;
    try {
      await Future.wait([
        loadMyGroups(isShowLoader: false),
        loadDiscoverGroups(isShowLoader: false),
      ]);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadMyGroups({bool isShowLoader = false}) async {
    final response = await _familyRepo.getMyGroups(isShowLoader: isShowLoader);
    myGroups.assignAll(_extractItems(response).map(_mapFamily));
  }

  Future<void> loadDiscoverGroups({bool isShowLoader = false}) async {
    final response = await _familyRepo.getDiscoverGroups(
      search: searchQuery.value,
      isShowLoader: isShowLoader,
    );
    discoverGroups.assignAll(_extractItems(response).map(_mapFamily));
  }

  void selectTab(int index) {
    selectedTab.value = index.clamp(0, 1);
  }

  Future<void> updateSearch(String query) async {
    searchQuery.value = query;
    await loadDiscoverGroups(isShowLoader: false);
  }

  Future<void> createFamilyGroup({
    required String name,
    required String description,
    required int joiningCoins,
  }) async {
    if (isCreatingFamily.value) return;
    final cleanName = name.trim();
    if (cleanName.isEmpty) {
      _showError('Family name is required.');
      return;
    }

    isCreatingFamily.value = true;
    Map<String, dynamic>? response;
    try {
      response = await _familyRepo.createFamily(
        name: cleanName,
        description: description.trim().isEmpty
            ? 'Welcome to $cleanName.'
            : description,
        joiningCoins: joiningCoins,
        initialMemberIds: selectedInitialMembers.toList(),
        isShowLoader: false,
      );
    } finally {
      isCreatingFamily.value = false;
    }

    if (!_isSuccess(response)) {
      await _showCreateResultDialog(
        title: 'Unable to create group',
        message: _message(response, 'Could not create this family group.'),
        success: false,
      );
      return;
    }

    selectedInitialMembers.clear();
    await loadFamilyHub();
    selectedTab.value = 0;
    await _showCreateResultDialog(
      title: 'Family group created',
      message: _message(response, 'Family group created successfully.'),
      success: true,
    );
    if (Get.key.currentState?.canPop() == true) {
      Get.back<void>();
    }
  }

  Future<void> _showResultDialog({
    required String title,
    required String message,
    required bool success,
    IconData? icon,
  }) {
    return CommonAppDialog.showGet<void>(
      title: title,
      message: message,
      icon: icon ??
          (success ? Icons.check_circle_rounded : Icons.error_rounded),
      iconAccent: success ? const Color(0xFF25D98F) : const Color(0xFFFF5C8A),
      barrierDismissible: false,
      actions: const [CommonAppDialogAction(label: 'OK', isPrimary: true)],
    );
  }

  /// Kept for create-family call sites; same presentation as [_showResultDialog].
  Future<void> _showCreateResultDialog({
    required String title,
    required String message,
    required bool success,
  }) {
    return _showResultDialog(
      title: title,
      message: message,
      success: success,
    );
  }

  Future<void> joinFamily(Map<String, dynamic> family) async {
    final familyId = _familyId(family);
    if (familyId.isEmpty) return;

    final expectedCoins = _toInt(
      family['joiningCoins'] ?? family['joining_coins'],
    );
    final response = await _familyRepo.joinFamily(
      familyId: familyId,
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      await _showResultDialog(
        title: 'Could not join',
        message: _joinFailureMessage(response, expectedCoins),
        success: false,
        icon: Icons.lock_outline_rounded,
      );
      return;
    }
    await loadFamilyHub();
    selectedTab.value = 0;
    await _showResultDialog(
      title: 'Joined group',
      message: _joinSuccessMessage(response, expectedCoins),
      success: true,
      icon: Icons.groups_rounded,
    );
  }

  String _joinFailureMessage(Map<String, dynamic>? response, int expectedCoins) {
    final message = _message(response, '');
    final upper = message.toUpperCase();
    if (upper.contains('INSUFFICIENT_COINS') ||
        upper.contains('INSUFFICIENT COINS') ||
        upper.contains('INSUFFICIENT')) {
      if (expectedCoins > 0) {
        return 'Not enough coins. You need $expectedCoins coins to join this group.';
      }
      return 'Not enough coins to join this group.';
    }
    if (upper.contains('ALREADY_JOINED')) {
      return 'You have already joined this group.';
    }
    if (upper.contains('USER_BLOCKED_FROM_GROUP') ||
        upper.contains('BLOCKED')) {
      return 'You are blocked from joining this group.';
    }
    return message.isNotEmpty
        ? message
        : 'Could not join this family.';
  }

  String _joinSuccessMessage(
    Map<String, dynamic>? response,
    int expectedCoins,
  ) {
    final data = response?['data'];
    final paid = data is Map
        ? _toInt(data['joiningCoinsPaid'] ?? data['joining_coins_paid'])
        : 0;
    final coinsPaid = paid > 0 ? paid : expectedCoins;
    final base = _message(response, 'Joined family group successfully.');
    if (coinsPaid > 0) {
      return '$base Paid $coinsPaid joining coins.';
    }
    return base;
  }

  Future<void> leaveFamily(Map<String, dynamic> family) async {
    final familyId = _familyId(family);
    if (familyId.isEmpty) return;

    final response = await _familyRepo.leaveFamily(
      familyId: familyId,
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      await _showResultDialog(
        title: 'Could not leave',
        message: _message(response, 'Could not leave this family.'),
        success: false,
      );
      return;
    }
    await loadFamilyHub();
    Get.back<void>();
    await _showResultDialog(
      title: 'Left group',
      message: _message(response, 'You have left the family.'),
      success: true,
      icon: Icons.logout_rounded,
    );
  }

  Future<void> loadMembers(
    String familyId, {
    String search = '',
    bool isShowLoader = false,
  }) async {
    if (familyId.trim().isEmpty) return;
    isLoadingMembers.value = true;
    try {
      final response = await _familyRepo.getFamilyMembers(
        familyId: familyId,
        search: search,
        isShowLoader: isShowLoader,
      );
      familyMembers.assignAll(_extractItems(response).map(_mapMember));
    } finally {
      isLoadingMembers.value = false;
    }
  }

  Future<void> removeMember({
    required String familyId,
    required String userId,
    String memberName = '',
  }) async {
    if (familyId.isEmpty || userId.isEmpty) return;

    final context = Get.context;
    if (context != null && context.mounted) {
      final label = memberName.trim().isEmpty ? 'this member' : memberName.trim();
      final confirmed = await CommonAppDialog.confirm(
        context: context,
        title: 'Remove member',
        message:
            'Remove $label from this group? They will lose chat access immediately.',
        icon: Icons.person_remove_rounded,
        iconAccent: const Color(0xFFFF5C8A),
        cancelLabel: 'Cancel',
        confirmLabel: 'Remove',
        barrierDismissible: false,
      );
      if (confirmed != true) return;
    }

    final response = await _familyRepo.removeMember(
      familyId: familyId,
      userId: userId,
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      await _showResultDialog(
        title: 'Could not remove',
        message: _message(response, 'Could not remove this member.'),
        success: false,
        icon: Icons.person_remove_rounded,
      );
      return;
    }
    familyMembers.removeWhere(
      (m) => (m['userId'] ?? m['id'] ?? '').toString().trim() == userId,
    );
    familyMembers.refresh();
    await loadMembers(familyId);
    await loadMyGroups();
    await _showResultDialog(
      title: 'Member removed',
      message: _message(response, 'Member removed from group successfully.'),
      success: true,
      icon: Icons.person_off_rounded,
    );
  }

  Future<void> loadPickerUsers({
    String query = '',
    bool followersOnly = true,
  }) async {
    pickerSearchQuery.value = query;
    pickerFollowersOnly.value = followersOnly;
    isLoadingPickerUsers.value = true;
    try {
      final response = await _familyRepo.searchUsers(
        query: query,
        followersOnly: followersOnly,
        isShowLoader: false,
      );
      pickerUsers.assignAll(
        _extractPickerUsers(
          response,
          followersOnly: followersOnly,
        ).map(_mapUser),
      );
    } finally {
      isLoadingPickerUsers.value = false;
    }
  }

  void searchPickerUsers(String query, {bool? followersOnly}) {
    final mode = followersOnly ?? pickerFollowersOnly.value;
    pickerSearchQuery.value = query;
    pickerFollowersOnly.value = mode;
    _pickerSearchDebounce?.cancel();
    _pickerSearchDebounce = Timer(const Duration(milliseconds: 350), () {
      unawaited(loadPickerUsers(query: query, followersOnly: mode));
    });
  }

  void setPickerSearchMode(bool followersOnly) {
    if (pickerFollowersOnly.value == followersOnly) return;
    pickerFollowersOnly.value = followersOnly;
    searchPickerUsers(pickerSearchQuery.value, followersOnly: followersOnly);
  }

  void toggleInitialMember(String userId) {
    final id = userId.trim();
    if (id.isEmpty) return;
    if (selectedInitialMembers.contains(id)) {
      selectedInitialMembers.remove(id);
    } else {
      selectedInitialMembers.add(id);
    }
    selectedInitialMembers.refresh();
  }

  String pickerUserId(Map<String, dynamic> user) {
    return (user['userId'] ??
            user['id'] ??
            user['_id'] ??
            user['user_id'] ??
            '')
        .toString()
        .trim();
  }

  bool isInitialMemberSelected(Map<String, dynamic> user) {
    final id = pickerUserId(user);
    return id.isNotEmpty && selectedInitialMembers.contains(id);
  }

  @override
  void onClose() {
    _pickerSearchDebounce?.cancel();
    unawaited(stopChatListen());
    super.onClose();
  }

  /// Opens realtime listen for a group chat. Always signs into Firebase first —
  /// otherwise the first snapshot can fail with permission-denied and the UI
  /// stays empty even after auth completes.
  Future<void> startChatListen(String familyId) async {
    final id = familyId.trim();
    if (id.isEmpty) return;
    if (_activeChatFamilyId == id && _chatSub != null) return;

    await stopChatListen();
    _activeChatFamilyId = id;
    chatListenError.value = '';
    isLoadingChatMessages.value = true;

    final signedIn = await _ensureFirebaseChatSession();
    if (_activeChatFamilyId != id) return;

    if (!signedIn || !FirebaseBootstrap.isAvailable) {
      chatListenError.value =
          'Could not connect to chat. Pull to refresh or try again.';
      await _loadMessagesFromApi(id);
      isLoadingChatMessages.value = false;
      return;
    }

    try {
      _chatSub = FirebaseFirestore.instance
          .collection('familyGroups')
          .doc(id)
          .collection('messages')
          .snapshots()
          .listen(
            (snapshot) {
              if (_activeChatFamilyId != id) return;
              final messages = snapshot.docs
                  .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
                  .toList();
              messages.sort(
                (a, b) => _messageTime(a).compareTo(_messageTime(b)),
              );
              activeChatMessages.assignAll(messages);
              chatListenError.value = '';
              isLoadingChatMessages.value = false;
            },
            onError: (Object error, StackTrace stack) {
              LoggerUtils.logWarning(
                'FamilyController: Firestore messages listen failed — $error',
              );
              final denied = error is FirebaseException &&
                  error.code == 'permission-denied';
              chatListenError.value = denied
                  ? 'Chat sync blocked by Firestore rules. Showing sent messages only.'
                  : 'Live chat sync failed. Showing available messages.';
              unawaited(_loadMessagesFromApi(id));
              isLoadingChatMessages.value = false;
            },
          );
      _startTypingListen(id);
    } catch (e) {
      LoggerUtils.logWarning('FamilyController: startChatListen failed — $e');
      chatListenError.value = 'Could not open live chat.';
      await _loadMessagesFromApi(id);
      isLoadingChatMessages.value = false;
    }

    // REST history fills the thread if Firestore is empty/slow on first open.
    unawaited(_loadMessagesFromApi(id, onlyIfEmpty: true));
  }

  Future<void> stopChatListen() async {
    _typingDebounce?.cancel();
    _typingClearTimer?.cancel();
    final leavingId = _activeChatFamilyId;
    if (leavingId.isNotEmpty && currentUserId.isNotEmpty) {
      unawaited(_setTyping(familyId: leavingId, isTyping: false));
    }
    await _typingSub?.cancel();
    _typingSub = null;
    typingPeerNames.clear();
    await _chatSub?.cancel();
    _chatSub = null;
    _activeChatFamilyId = '';
    chatListenError.value = '';
    activeChatMessages.clear();
    isLoadingChatMessages.value = false;
  }

  void onComposerTextChanged(String text) {
    final familyId = _activeChatFamilyId;
    if (familyId.isEmpty || currentUserId.isEmpty) return;
    if (!FirebaseBootstrap.isAvailable) return;

    final hasText = text.trim().isNotEmpty;
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_setTyping(familyId: familyId, isTyping: hasText));
      _typingClearTimer?.cancel();
      if (hasText) {
        _typingClearTimer = Timer(const Duration(seconds: 4), () {
          unawaited(_setTyping(familyId: familyId, isTyping: false));
        });
      }
    });
  }

  void _startTypingListen(String familyId) {
    unawaited(_typingSub?.cancel());
    _typingSub = FirebaseFirestore.instance
        .collection('familyGroups')
        .doc(familyId)
        .collection('typing')
        .snapshots()
        .listen(
          (snapshot) {
            if (_activeChatFamilyId != familyId) return;
            final myId = currentUserId;
            final now = DateTime.now();
            final names = <String>[];
            for (final doc in snapshot.docs) {
              if (doc.id == myId) continue;
              final data = doc.data();
              if (data['isTyping'] != true) continue;
              final updatedAt = _firestoreDate(data['updatedAt']);
              if (updatedAt != null &&
                  now.difference(updatedAt).inSeconds > 5) {
                continue;
              }
              final name = _resolveTypingDisplayName(
                userId: doc.id,
                data: data,
              );
              if (name.isNotEmpty) names.add(name);
            }
            typingPeerNames.assignAll(names);
          },
          onError: (Object error) {
            LoggerUtils.logWarning(
              'FamilyController: typing listen failed — $error',
            );
            typingPeerNames.clear();
          },
        );
  }

  String _resolveTypingDisplayName({
    required String userId,
    required Map<String, dynamic> data,
  }) {
    final fromDoc = _pickText(data, const [
      'displayName',
      'name',
      'userName',
      'senderName',
    ]);
    if (fromDoc.isNotEmpty) return fromDoc;
    for (final member in familyMembers) {
      final id = _pickText(member, const [
        'userId',
        'id',
        '_id',
        'user_id',
      ]);
      if (id != userId) continue;
      final name = _pickText(member, const ['name', 'userName', 'displayName']);
      if (name.isNotEmpty) return name;
    }
    return 'Someone';
  }

  Future<void> _setTyping({
    required String familyId,
    required bool isTyping,
  }) async {
    final userId = currentUserId;
    if (familyId.isEmpty || userId.isEmpty || !FirebaseBootstrap.isAvailable) {
      return;
    }
    final ref = FirebaseFirestore.instance
        .collection('familyGroups')
        .doc(familyId)
        .collection('typing')
        .doc(userId);
    try {
      if (!isTyping) {
        await ref.delete();
        return;
      }
      var displayName = '';
      if (Get.isRegistered<UserSessionController>()) {
        displayName = Get.find<UserSessionController>().displayName.trim();
      }
      await ref.set({
        'userId': userId,
        'isTyping': true,
        if (displayName.isNotEmpty) 'displayName': displayName,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      if (e.code == 'permission-denied') return;
      LoggerUtils.logWarning('FamilyController: setTyping failed — $e');
    } catch (e) {
      LoggerUtils.logWarning('FamilyController: setTyping failed — $e');
    }
  }

  DateTime? _firestoreDate(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '');
  }

  Future<void> _loadMessagesFromApi(
    String familyId, {
    bool onlyIfEmpty = false,
  }) async {
    if (onlyIfEmpty && activeChatMessages.isNotEmpty) return;
    final response = await _familyRepo.listMessages(
      familyId: familyId,
      isShowLoader: false,
    );
    if (!_isSuccess(response)) return;
    final items = _extractItems(response);
    if (items.isEmpty) return;
    final mapped = items.map((raw) {
      final id = _pickText(raw, const ['messageId', 'id', '_id']);
      return <String, dynamic>{
        ...raw,
        if (id.isNotEmpty) 'id': id,
        'type': (raw['type'] ?? 'text').toString(),
      };
    }).toList();
    mapped.sort((a, b) => _messageTime(a).compareTo(_messageTime(b)));
    _mergeChatMessages(mapped);
  }

  void _mergeChatMessages(List<Map<String, dynamic>> incoming) {
    if (incoming.isEmpty) return;
    final byKey = <String, Map<String, dynamic>>{};
    for (final existing in activeChatMessages) {
      final key = _messageKey(existing);
      if (key.isNotEmpty) byKey[key] = existing;
    }
    for (final item in incoming) {
      final key = _messageKey(item);
      if (key.isEmpty) continue;
      byKey[key] = item;
    }
    final merged = byKey.values.toList()
      ..sort((a, b) => _messageTime(a).compareTo(_messageTime(b)));
    activeChatMessages.assignAll(merged);
  }

  void _upsertChatMessage(Map<String, dynamic> message) {
    final key = _messageKey(message);
    if (key.isEmpty) {
      activeChatMessages.add(message);
      return;
    }
    final index = activeChatMessages.indexWhere((m) => _messageKey(m) == key);
    if (index >= 0) {
      activeChatMessages[index] = message;
      activeChatMessages.refresh();
    } else {
      activeChatMessages.add(message);
      activeChatMessages.sort(
        (a, b) => _messageTime(a).compareTo(_messageTime(b)),
      );
      activeChatMessages.refresh();
    }
  }

  String _messageKey(Map<String, dynamic> message) {
    final id = _pickText(message, const ['id', 'messageId', '_id']);
    if (id.isNotEmpty) return 'id:$id';
    final client = _pickText(message, const ['clientMessageId']);
    if (client.isNotEmpty) return 'client:$client';
    return '';
  }

  @Deprecated('Use startChatListen + activeChatMessages')
  Stream<List<Map<String, dynamic>>> watchMessages(String familyId) {
    if (familyId.trim().isEmpty || !FirebaseBootstrap.isAvailable) {
      return const Stream.empty();
    }
    return Stream.fromFuture(_ensureFirebaseChatSession()).asyncExpand((ok) {
      if (!ok) return Stream.value(const <Map<String, dynamic>>[]);
      return FirebaseFirestore.instance
          .collection('familyGroups')
          .doc(familyId.trim())
          .collection('messages')
          .snapshots()
          .map((snapshot) {
            final messages = snapshot.docs
                .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
                .toList();
            messages.sort(
              (a, b) => _messageTime(a).compareTo(_messageTime(b)),
            );
            return messages;
          });
    });
  }

  Future<void> sendTextMessage({
    required String familyId,
    required TextEditingController textController,
  }) async {
    final text = textController.text.trim();
    if (text.isEmpty || isSendingMessage.value) return;

    isSendingMessage.value = true;
    _typingDebounce?.cancel();
    _typingClearTimer?.cancel();
    unawaited(_setTyping(familyId: familyId, isTyping: false));
    final clientMessageId =
        'msg_${DateTime.now().microsecondsSinceEpoch}_$currentUserId';
    try {
      final response = await _familyRepo.sendTextMessage(
        familyId: familyId,
        text: text,
        clientMessageId: clientMessageId,
        isShowLoader: false,
      );
      if (!_isSuccess(response)) {
        _showError(_message(response, 'Message was not sent.'));
        return;
      }
      textController.clear();
      final data = response?['data'];
      final payload = data is Map
          ? Map<String, dynamic>.from(data)
          : <String, dynamic>{};
      _upsertChatMessage(<String, dynamic>{
        'id': _pickText(payload, const ['messageId', 'id']),
        'messageId': _pickText(payload, const ['messageId', 'id']),
        'clientMessageId': clientMessageId,
        'type': 'text',
        'text': _pickText(payload, const ['text']).isNotEmpty
            ? _pickText(payload, const ['text'])
            : text,
        'senderId': _pickText(payload, const ['senderId']).isNotEmpty
            ? _pickText(payload, const ['senderId'])
            : currentUserId,
        'senderName': 'You',
        'createdAt': _pickText(payload, const ['createdAt']).isNotEmpty
            ? _pickText(payload, const ['createdAt'])
            : DateTime.now().toUtc().toIso8601String(),
      });
    } finally {
      isSendingMessage.value = false;
    }
  }

  Future<void> markRead({required String familyId, String? lastReadMessageId}) {
    return _familyRepo.markRead(
      familyId: familyId,
      lastReadMessageId: lastReadMessageId,
      isShowLoader: false,
    );
  }

  Future<void> loadEmojiCatalog() async {
    if (emojiCatalog.isNotEmpty || isLoadingEmojis.value) return;
    isLoadingEmojis.value = true;
    try {
      final response = await _emojiRepo.getEmojiCatalog(isShowLoader: false);
      emojiCatalog.assignAll(_extractItems(response).map(_mapEmoji));
    } finally {
      isLoadingEmojis.value = false;
    }
  }

  Future<void> sendEmoji({
    required String familyId,
    required Map<String, String> emoji,
  }) async {
    final emojiId = emoji['id']?.trim() ?? '';
    if (emojiId.isEmpty) return;

    final response = await _familyRepo.sendEmojiMessage(
      familyId: familyId,
      emojiId: emojiId,
      isShowLoader: false,
    );
    if (!_isSuccess(response)) {
      _showError(_message(response, 'Emoji was not sent.'));
      return;
    }
    final data = response?['data'];
    final payload = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    _upsertChatMessage(<String, dynamic>{
      'id': _pickText(payload, const ['messageId', 'id']),
      'messageId': _pickText(payload, const ['messageId', 'id']),
      'type': 'emoji',
      'emojiId': emojiId,
      'emojiName': emoji['name'] ?? 'Emoji',
      'emojiUrl': emoji['image'],
      'emojiAnimationUrl': emoji['image'],
      'senderId': currentUserId,
      'senderName': 'You',
      'text': emoji['name'] ?? 'sent emoji',
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> loadGiftCatalog() async {
    if (giftCatalog.isNotEmpty || isLoadingGifts.value) return;
    isLoadingGifts.value = true;
    try {
      final response = await _economyRepo.getGiftList(isShowLoader: false);
      final gifts = _extractItems(response)
          .map((raw) => GiftMediaUtils.mapGiftFromApi(raw))
          .where((gift) => (gift['id'] ?? '').isNotEmpty)
          .toList();
      giftCatalog.assignAll(gifts);
    } finally {
      isLoadingGifts.value = false;
    }
  }

  Future<void> sendGift({
    required String familyId,
    required Map<String, String> gift,
  }) async {
    final giftId = gift['id']?.trim() ?? '';
    if (giftId.isEmpty) return;

    final response = await _familyRepo.sendGroupGift(
      familyId: familyId,
      giftId: giftId,
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      _showError(_message(response, 'Gift was not sent.'));
      return;
    }

    final animationUrl = GiftMediaUtils.animationUrlFromResponse(
      response,
      gift,
    );
    final soundUrl = GiftMediaUtils.soundUrlFromResponse(response, gift);
    await GiftMediaUtils.dismissSheetThenCelebrate(
      giftName: gift['name'],
      animationUrl: animationUrl,
      soundUrl: soundUrl,
    );
  }

  bool isAdmin(Map<String, dynamic> family) {
    if (family['canManageMembers'] == true) return true;
    final role =
        family['myRole']?.toString().toLowerCase() ??
        family['role']?.toString().toLowerCase() ??
        '';
    if (role == 'admin' || role == 'creator' || role == 'owner') return true;

    // Fallback once members roster is loaded (chat args may omit myRole).
    final myId = currentUserId;
    if (myId.isEmpty) return false;
    for (final member in familyMembers) {
      final id = (member['userId'] ?? member['id'] ?? '').toString().trim();
      if (id != myId) continue;
      final memberRole = (member['role']?.toString() ?? '').toLowerCase();
      return memberRole == 'admin' ||
          memberRole == 'creator' ||
          memberRole == 'owner';
    }
    return false;
  }

  bool isMemberAdmin(Map<String, dynamic> member) {
    final role = (member['role']?.toString() ?? '').toLowerCase();
    return role == 'admin' || role == 'creator' || role == 'owner';
  }

  String familyIdOf(Map<String, dynamic> family) => _familyId(family);

  String formatCoins(dynamic value) => formatLedgerAmount(_toInt(value));

  DateTime messageDate(Map<String, dynamic> message) => _messageTime(message);

  List<Map<String, dynamic>> _extractItems(Map<String, dynamic>? response) {
    final data = response?['data'];
    if (data is List) return data.whereType<Map>().map(_copyMap).toList();
    if (data is Map) {
      for (final key in const [
        'items',
        'groups',
        'families',
        'users',
        'data',
      ]) {
        final nested = data[key];
        if (nested is List) {
          return nested.whereType<Map>().map(_copyMap).toList();
        }
      }
      if (data.isNotEmpty) return [_copyMap(data)];
    }
    return const [];
  }

  List<Map<String, dynamic>> _extractPickerUsers(
    Map<String, dynamic>? response, {
    required bool followersOnly,
  }) {
    final data = response?['data'];
    if (data is Map) {
      final preferredKeys = followersOnly
          ? const ['followers', 'users', 'items', 'data']
          : const ['users', 'items', 'followers', 'following', 'data'];
      for (final key in preferredKeys) {
        final nested = data[key];
        if (nested is List) {
          return nested.whereType<Map>().map(_copyMap).toList();
        }
      }
    }
    return _extractItems(response);
  }

  Map<String, dynamic> _mapFamily(Map<String, dynamic> raw) {
    final id = _pickText(raw, const ['groupId', 'id', 'familyId', 'family_id']);
    final name = _pickText(raw, const ['name', 'familyName', 'title']);
    final memberCount = _toInt(
      raw['memberCount'] ?? raw['membersCount'] ?? raw['members'],
    );
    return <String, dynamic>{
      'id': id,
      'groupId': id,
      'name': name.isEmpty ? 'Family Group' : name,
      'description': _pickText(raw, const ['description', 'notice']),
      'logo': _pickText(raw, const ['logo', 'image', 'avatar']),
      'joiningCoins': _toInt(raw['joiningCoins'] ?? raw['joining_coins']),
      'adminUserId': _pickText(raw, const ['adminUserId', 'creatorId']),
      'adminName': _pickText(raw, const ['adminName', 'creatorName', 'leader']),
      'adminAvatar': _pickText(raw, const ['adminAvatar', 'creatorAvatar']),
      'memberCount': memberCount,
      'members': memberCount,
      'totalJoinCoins': _toInt(raw['totalJoinCoins']),
      'totalGiftCoins': _toInt(raw['totalGiftCoins']),
      'isJoined': raw['isJoined'] == true,
      'myRole': _pickText(raw, const ['myRole', 'role']),
      'canManageMembers': raw['canManageMembers'] == true ||
          raw['can_manage_members'] == true,
      'status': _pickText(raw, const ['status']),
      'lastMessage': _pickText(raw, const ['lastMessage']),
      'lastMessageAt': _pickText(raw, const ['lastMessageAt']),
      'unreadCount': _toInt(raw['unreadCount']),
      'firebasePath': _pickText(raw, const ['firebasePath']),
    };
  }

  Map<String, dynamic> _mapMember(Map<String, dynamic> raw) {
    final user = raw['user'] is Map ? _copyMap(raw['user'] as Map) : raw;
    final id = _pickText(user, const ['userId', 'id', 'user_id']);
    final frame = raw['avatarFrame'] is Map
        ? _pickText(_copyMap(raw['avatarFrame'] as Map), const ['image'])
        : _pickText(raw, const ['avatarFrameUrl', 'avatar_frame_url']);
    final name = _pickText(user, const ['name', 'fullName', 'username']);
    return <String, dynamic>{
      'userId': id,
      'name': name.isEmpty ? 'Member' : name,
      'displayPicture': _pickText(user, const [
        'displayPicture',
        'display_picture',
        'avatar',
        'profileImage',
      ]),
      'avatarFrameUrl': frame,
      'role': _pickText(raw, const ['role']),
      'status': _pickText(raw, const ['status']),
      'joinedAt': _pickText(raw, const ['joinedAt']),
      'level': _toInt(raw['level'] ?? user['level']),
      'contribution': _toInt(raw['contribution']),
    };
  }

  Map<String, dynamic> _mapUser(Map<String, dynamic> raw) {
    final user = _nestedUserFrom(raw);
    final id = _pickText(user, const [
      'userId',
      'id',
      '_id',
      'user_id',
      'followingId',
      'followerId',
    ]);
    final name = _pickText(user, const [
      'name',
      'fullName',
      'full_name',
      'username',
      'userName',
    ]);
    final frame = user['avatarFrame'] is Map
        ? _pickText(_copyMap(user['avatarFrame'] as Map), const ['image'])
        : _pickText(user, const ['avatarFrameUrl', 'avatar_frame_url']);
    return <String, dynamic>{
      'userId': id,
      'name': name.isEmpty ? 'User' : name,
      'displayPicture': _pickText(user, const [
        'displayPicture',
        'display_picture',
        'avatar',
        'avatarUrl',
        'profileImageUrl',
        'profileImage',
        'profile_image',
        'image',
      ]),
      'avatarFrameUrl': frame,
      'isFollowing': raw['isFollowing'] == true || user['isFollowing'] == true,
    };
  }

  Map<String, dynamic> _nestedUserFrom(Map<String, dynamic> raw) {
    for (final key in const [
      'user',
      'follower',
      'following',
      'followerUser',
      'followingUser',
      'followedUser',
      'profile',
    ]) {
      final nested = raw[key];
      if (nested is Map) {
        return {...raw, ..._copyMap(nested)};
      }
    }
    return raw;
  }

  Map<String, String> _mapEmoji(Map<String, dynamic> raw) {
    final id = _pickText(raw, const ['id', 'emojiId', 'emoji_id']);
    final name = _pickText(raw, const ['name', 'title']);
    final image = _pickText(raw, const [
      'animationUrl',
      'animation_url',
      'gifUrl',
      'gif_url',
      'image',
      'imageUrl',
      'thumbnailUrl',
    ]);
    return {'id': id, 'name': name.isEmpty ? 'Emoji' : name, 'image': image};
  }

  DateTime _messageTime(Map<String, dynamic> raw) {
    final value = raw['createdAt'] ?? raw['clientCreatedAt'];
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0);
  }

  String _familyId(Map<String, dynamic> family) {
    return _pickText(family, const ['groupId', 'id', 'familyId', 'family_id']);
  }

  String _pickText(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key]?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  Map<String, dynamic> _copyMap(Map raw) => Map<String, dynamic>.from(raw);

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  bool _isSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    final bodyStatus = ApiResponseUtils.tryGetBodyStatusCode(response);
    return bodyStatus == null || bodyStatus == 1 || bodyStatus == 200;
  }

  String _message(Map<String, dynamic>? response, String fallback) {
    final message = response?['message']?.toString().trim();
    return message == null || message.isEmpty ? fallback : message;
  }

  void _showError(String message) {
    LoggerUtils.logWarning('FamilyController: $message');
    Get.snackbar('Family', message, snackPosition: SnackPosition.BOTTOM);
  }
}
