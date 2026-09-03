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

  Future<void> _ensureFirebaseChatSession() async {
    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    await Get.find<ChatSessionService>().ensureSignedIn(isShowLoader: false);
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

  Future<void> _showCreateResultDialog({
    required String title,
    required String message,
    required bool success,
  }) {
    return CommonAppDialog.showGet<void>(
      title: title,
      message: message,
      icon: success ? Icons.check_circle_rounded : Icons.error_rounded,
      iconAccent: success ? const Color(0xFF25D98F) : const Color(0xFFFF5C8A),
      barrierDismissible: false,
      actions: const [CommonAppDialogAction(label: 'OK', isPrimary: true)],
    );
  }

  Future<void> joinFamily(Map<String, dynamic> family) async {
    final familyId = _familyId(family);
    if (familyId.isEmpty) return;

    final response = await _familyRepo.joinFamily(
      familyId: familyId,
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      _showError(_message(response, 'Could not join this family.'));
      return;
    }
    await loadFamilyHub();
    selectedTab.value = 0;
    _showSuccess(_message(response, 'Joined family group successfully.'));
  }

  Future<void> leaveFamily(Map<String, dynamic> family) async {
    final familyId = _familyId(family);
    if (familyId.isEmpty) return;

    final response = await _familyRepo.leaveFamily(
      familyId: familyId,
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      _showError(_message(response, 'Could not leave this family.'));
      return;
    }
    await loadFamilyHub();
    Get.back<void>();
    _showSuccess(_message(response, 'You have left the family.'));
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
  }) async {
    if (familyId.isEmpty || userId.isEmpty) return;

    final response = await _familyRepo.removeMember(
      familyId: familyId,
      userId: userId,
      isShowLoader: true,
    );
    if (!_isSuccess(response)) {
      _showError(_message(response, 'Could not remove this member.'));
      return;
    }
    await loadMembers(familyId);
    await loadMyGroups();
    _showSuccess(_message(response, 'Member removed from group.'));
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
    super.onClose();
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String familyId) {
    if (familyId.trim().isEmpty || !FirebaseBootstrap.isAvailable) {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('familyGroups')
        .doc(familyId.trim())
        .collection('messages')
        .snapshots()
        .map((snapshot) {
          final messages = snapshot.docs
              .map((doc) => <String, dynamic>{...doc.data(), 'id': doc.id})
              .toList();
          messages.sort((a, b) => _messageTime(a).compareTo(_messageTime(b)));
          return messages;
        });
  }

  Future<void> sendTextMessage({
    required String familyId,
    required TextEditingController textController,
  }) async {
    final text = textController.text.trim();
    if (text.isEmpty || isSendingMessage.value) return;

    isSendingMessage.value = true;
    try {
      final response = await _familyRepo.sendTextMessage(
        familyId: familyId,
        text: text,
        isShowLoader: false,
      );
      if (!_isSuccess(response)) {
        _showError(_message(response, 'Message was not sent.'));
        return;
      }
      textController.clear();
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
    }
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
    final role =
        family['myRole']?.toString().toLowerCase() ??
        family['role']?.toString().toLowerCase() ??
        '';
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

  void _showSuccess(String message) {
    Get.snackbar('Family', message, snackPosition: SnackPosition.BOTTOM);
  }

  void _showError(String message) {
    LoggerUtils.logWarning('FamilyController: $message');
    Get.snackbar('Family', message, snackPosition: SnackPosition.BOTTOM);
  }
}
