import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/chat/chat_local_store.dart';
import 'package:qobo_one_live/repo/chat/chat_navigation_helper.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

import '../models/social_user_card.dart';
import '../widgets/messages_common_widgets.dart';

/// Messages tab: New Match discover feed + chat inbox.
class MessagesTabController extends GetxController {
  MessagesTabController({
    AuthRepo? authRepo,
    UserRepo? userRepo,
    ChatRepo? chatRepo,
    ChatLocalStore? localStore,
  })  : _authRepo = authRepo ?? AuthRepo(),
        _userRepo = userRepo ?? UserRepo(),
        _chatRepo = chatRepo ?? ChatRepo(),
        _localStore = localStore ?? ChatLocalStore();

  final AuthRepo _authRepo;
  final UserRepo _userRepo;
  final ChatRepo _chatRepo;
  final ChatLocalStore _localStore;

  final searchController = TextEditingController();

  final newMatches = <SocialUserCard>[].obs;
  final searchResults = <SocialUserCard>[].obs;
  final inboxThreads = <MessageListItemModel>[].obs;

  final isNewMatchesLoading = false.obs;
  final isInboxLoading = false.obs;
  final isSearchLoading = false.obs;
  final isSearchMode = false.obs;
  final searchQuery = ''.obs;
  final processingFollowId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait([
      fetchNewMatches(),
      fetchInbox(),
    ]);
  }

  void _onSearchChanged() {
    final text = searchController.text.trim();
    searchQuery.value = text;
    isSearchMode.value = text.isNotEmpty;
    if (text.isEmpty) {
      searchResults.clear();
      return;
    }
    performSearch(text);
  }

  /// `GET /api/user/discover` for horizontal New Match row.
  Future<void> fetchNewMatches() async {
    try {
      isNewMatchesLoading.value = true;
      final response = await _userRepo.discoverUsers(
        page: 1,
        limit: 20,
        isShowLoader: false,
      );
      if (isSocialApiSuccess(response)) {
        newMatches.assignAll(
          SocialUserCard.listFromResponseData(response!['data']).take(20),
        );
        return;
      }
      newMatches.clear();
    } catch (_) {
      newMatches.clear();
    } finally {
      isNewMatchesLoading.value = false;
    }
  }

  /// `GET /api/user/search` when user types in header search bar.
  Future<void> performSearch(String query) async {
    try {
      isSearchLoading.value = true;
      final response = await _authRepo.searchUsers(
        query: query,
        isShowLoader: false,
      );
      if (isSocialApiSuccess(response)) {
        searchResults.assignAll(
          SocialUserCard.listFromResponseData(response!['data']),
        );
        return;
      }
      searchResults.clear();
    } catch (_) {
      searchResults.clear();
    } finally {
      isSearchLoading.value = false;
    }
  }

  /// `GET /api/chat/list` for Message section (+ local cache until send API live).
  Future<void> fetchInbox() async {
    try {
      isInboxLoading.value = true;
      final apiThreads = <MessageListItemModel>[];
      final response = await _chatRepo.getInbox(isShowLoader: false);
      if (isSocialApiSuccess(response)) {
        final list = response!['data'];
        if (list is List) {
          apiThreads.addAll(
            list.whereType<Map>().toList().asMap().entries.map((entry) {
              return _mapInboxThread(
                Map<String, dynamic>.from(entry.value),
                entry.key,
              );
            }),
          );
        }
      }

      final localRaw = await _localStore.readInboxThreads();
      final localThreads = localRaw
          .where((t) => (t['lastMessage']?.toString().trim().isNotEmpty ?? false))
          .map((json) => _mapInboxThread(json, 0))
          .toList();

      inboxThreads.assignAll(_mergeInboxThreads(apiThreads, localThreads));
    } catch (_) {
      inboxThreads.clear();
    } finally {
      isInboxLoading.value = false;
    }
  }

  List<MessageListItemModel> _mergeInboxThreads(
    List<MessageListItemModel> api,
    List<MessageListItemModel> local,
  ) {
    final byId = <String, MessageListItemModel>{};
    for (final thread in api) {
      if (thread.targetId.isNotEmpty) {
        byId[thread.targetId] = thread;
      }
    }
    for (final thread in local) {
      if (thread.targetId.isEmpty) continue;
      final existing = byId[thread.targetId];
      if (existing == null || thread.message.isNotEmpty) {
        byId[thread.targetId] = existing == null
            ? thread
            : MessageListItemModel(
                targetId: thread.targetId,
                name: existing.name.isNotEmpty ? existing.name : thread.name,
                message: thread.message.isNotEmpty
                    ? thread.message
                    : existing.message,
                time: thread.time.isNotEmpty ? thread.time : existing.time,
                imageUrl: existing.imageUrl ?? thread.imageUrl,
                unreadCount: existing.unreadCount,
              );
      }
    }
    return byId.values.toList();
  }

  MessageListItemModel _mapInboxThread(Map<String, dynamic> json, int index) {
    final recipient = json['recipient'];
    final Map<String, dynamic>? recipientMap = recipient is Map
        ? Map<String, dynamic>.from(recipient)
        : null;

    final name = recipientMap?['name']?.toString().trim() ??
        json['name']?.toString().trim() ??
        'User';
    final targetId =
        json['id']?.toString() ??
        recipientMap?['id']?.toString() ??
        '';
    final picture = recipientMap?['displayPicture']?.toString();

    return MessageListItemModel(
      targetId: targetId,
      name: name.isNotEmpty ? name : 'User',
      message: json['lastMessage']?.toString() ?? '',
      time: _formatThreadTime(json['lastMessageTime']?.toString()),
      imageUrl: picture,
      unreadCount: _toInt(json['unreadCount']),
    );
  }

  Future<void> toggleFollow(
    BuildContext context,
    SocialUserCard user,
  ) async {
    if (user.id.isEmpty) return;
    final action = user.isFollowing ? 'unfollow' : 'follow';
    processingFollowId.value = user.id;
    try {
      final response = await _authRepo.followUnfollow(
        targetId: user.id,
        action: action,
        isShowLoader: false,
      );
      if (!context.mounted) return;
      if (isSocialApiSuccess(response)) {
        final data = response?['data'];
        final Map<String, dynamic>? dataMap =
            data is Map ? Map<String, dynamic>.from(data) : null;
        final isFollowing = dataMap?['isFollowing'] == true ||
            (action == 'follow' && dataMap == null);
        final isFollower = dataMap?['isFollower'] == true ||
            user.isFollower;
        final isMutual = dataMap?['isMutual'] == true ||
            (isFollowing && isFollower);
        final canMessage = dataMap?['canMessage'] == true ||
            isFollowing ||
            isFollower ||
            isMutual;

        _applyFollowState(
          user.id,
          isFollowing: isFollowing,
          isFollower: isFollower,
          isMutual: isMutual,
          canMessage: canMessage,
          followersCount: _toInt(dataMap?['followersCount']),
          followingCount: _toInt(dataMap?['followingCount']),
        );
        AppToast.showSuccess(
          context,
          isFollowing ? 'Followed successfully' : 'Unfollowed successfully',
        );
        return;
      }
      AppToast.showError(
        context,
        response?['message']?.toString() ?? 'Action failed',
      );
    } catch (e) {
      if (!context.mounted) return;
      AppToast.showError(context, 'Error: $e');
    } finally {
      processingFollowId.value = '';
    }
  }

  void _applyFollowState(
    String userId, {
    required bool isFollowing,
    bool? isFollower,
    bool? isMutual,
    bool? canMessage,
    int? followersCount,
    int? followingCount,
  }) {
    SocialUserCard merge(SocialUserCard u) {
      if (u.id != userId) return u;
      final nextFollower = isFollower ?? u.isFollower;
      final nextFollowing = isFollowing;
      final nextMutual =
          isMutual ?? ((nextFollowing && nextFollower) || u.isMutual);
      final nextCanMessage = canMessage ??
          (nextFollowing || nextFollower || nextMutual || u.canMessage);
      return u.copyWith(
        isFollowing: nextFollowing,
        isFollower: nextFollower,
        isMutual: nextMutual,
        canMessage: nextCanMessage,
        followersCount: followersCount ?? u.followersCount,
        followingCount: followingCount ?? u.followingCount,
      );
    }

    newMatches.value = newMatches.map(merge).toList();
    searchResults.value = searchResults.map(merge).toList();
  }

  SocialUserCard? userById(String id) {
    for (final u in newMatches) {
      if (u.id == id) return u;
    }
    for (final u in searchResults) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Opens chat when allowed (`canMessage` = either follows the other).
  Future<void> openChat(
    BuildContext context,
    SocialUserCard user,
  ) async {
    if (user.id.isEmpty) return;
    if (!user.canMessage) {
      AppToast.showError(
        context,
        'Follow each other to start messaging',
      );
      return;
    }

    await ChatNavigationHelper.openDirectChat(
      context,
      targetId: user.id,
      name: user.name,
      imageUrl: user.displayPicture,
    );
    fetchInbox();
  }

  Future<void> openChatFromInbox(
    BuildContext context,
    MessageListItemModel thread,
  ) async {
    if (thread.targetId.isEmpty) {
      AppToast.showError(context, 'Invalid chat partner');
      return;
    }
    await ChatNavigationHelper.openDirectChat(
      context,
      targetId: thread.targetId,
      name: thread.name,
      imageUrl: thread.imageUrl,
    );
    fetchInbox();
  }

  Future<SocialUserCard?> fetchPublicProfile(String userId) async {
    if (userId.isEmpty) return null;
    final cached = userById(userId);
    try {
      final response = await _userRepo.getPublicProfile(
        userId: userId,
        isShowLoader: false,
      );
      if (isSocialApiSuccess(response) && response?['data'] is Map) {
        final fresh = SocialUserCard.fromJson(
          Map<String, dynamic>.from(response!['data'] as Map),
        );
        if (cached != null) {
          return fresh.copyWith(
            isFollowing: cached.isFollowing || fresh.isFollowing,
            isFollower: cached.isFollower || fresh.isFollower,
            isMutual: cached.isMutual || fresh.isMutual,
            canMessage: cached.canMessage || fresh.canMessage,
          );
        }
        return fresh;
      }
    } catch (_) {}
    return cached;
  }

  static String _formatThreadTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year &&
          dt.month == now.month &&
          dt.day == now.day) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  static int _toInt(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
