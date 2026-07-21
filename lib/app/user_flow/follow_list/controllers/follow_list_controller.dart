import 'package:get/get.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';

import '../../messages/messages_tab/models/social_user_card.dart';

/// Connections screen — Friends / Following / Followers from dedicated APIs.
class FollowListController extends GetxController {
  FollowListController({
    UserRepo? userRepo,
    AuthRepo? authRepo,
  }) : _userRepo = userRepo ?? UserRepo(),
       _authRepo = authRepo ?? AuthRepo();

  final UserRepo _userRepo;
  final AuthRepo _authRepo;

  /// 0 = Friends, 1 = Following, 2 = Followers
  final tabIndex = 0.obs;
  final isLoading = false.obs;
  final processingFollowId = ''.obs;

  final friendsList = <SocialUserCard>[].obs;
  final followingList = <SocialUserCard>[].obs;
  final followersList = <SocialUserCard>[].obs;

  static const int friendsTab = 0;
  static const int followingTab = 1;
  static const int followersTab = 2;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args.containsKey('initialTab')) {
      final raw = args['initialTab'];
      final index = raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0;
      tabIndex.value = index.clamp(0, 2);
    }
    loadFollowLists();
  }

  Future<void> loadFollowLists() async {
    try {
      isLoading.value = true;
      // Parallel fetch keeps the screen snappy when switching tabs.
      final results = await Future.wait([
        _userRepo.getFriends(page: 1, limit: 50, isShowLoader: false),
        _userRepo.getFollowing(page: 1, limit: 50, isShowLoader: false),
        _userRepo.getFollowers(page: 1, limit: 50, isShowLoader: false),
      ]);

      friendsList.assignAll(_itemsFrom(results[0]));
      followingList.assignAll(_itemsFrom(results[1]));
      followersList.assignAll(_itemsFrom(results[2]));

      // Soft fallback: if dedicated endpoints are empty/unavailable, try legacy
      // combined follow-list so older backends still populate Following/Followers.
      if (followingList.isEmpty && followersList.isEmpty) {
        await _loadLegacyFollowList();
      }
    } catch (_) {
      friendsList.clear();
      followingList.clear();
      followersList.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLegacyFollowList() async {
    final response = await _userRepo.getFollowList(isShowLoader: false);
    if (!isSocialApiSuccess(response)) return;
    final data = response?['data'];
    if (data is! Map) return;
    followingList.assignAll(
      SocialUserCard.listFromResponseData(data['following']),
    );
    followersList.assignAll(
      SocialUserCard.listFromResponseData(data['followers']),
    );
  }

  List<SocialUserCard> _itemsFrom(Map<String, dynamic>? response) {
    if (!isSocialApiSuccess(response)) return const [];
    return SocialUserCard.listFromResponseData(response?['data']);
  }

  void changeTab(int index) {
    tabIndex.value = index.clamp(0, 2);
  }

  List<SocialUserCard> listForCurrentTab() {
    switch (tabIndex.value) {
      case friendsTab:
        return friendsList;
      case followersTab:
        return followersList;
      case followingTab:
      default:
        return followingList;
    }
  }

  Future<void> toggleFollow(SocialUserCard user) async {
    if (user.id.isEmpty) return;
    final action = user.isFollowing ? 'unfollow' : 'follow';
    processingFollowId.value = user.id;
    try {
      final response = await _authRepo.followUnfollow(
        targetId: user.id,
        action: action,
        isShowLoader: false,
      );
      if (isSocialApiSuccess(response)) {
        final data = response?['data'];
        final isFollowing = data is Map
            ? data['isFollowing'] == true
            : action == 'follow';
        _updateUserInLists(user.id, isFollowing: isFollowing);

        // Unfollow removes them from Following; mutual friends drop when either side unfollows.
        if (!isFollowing) {
          followingList.removeWhere((u) => u.id == user.id);
          friendsList.removeWhere((u) => u.id == user.id);
        }
      }
    } finally {
      processingFollowId.value = '';
    }
  }

  void _updateUserInLists(String userId, {required bool isFollowing}) {
    friendsList.value = friendsList
        .map(
          (u) => u.id == userId
              ? u.copyWith(
                  isFollowing: isFollowing,
                  isMutual: isFollowing && u.isFollower,
                  canMessage: isFollowing || u.isFollower,
                )
              : u,
        )
        .toList();
    followingList.value = followingList
        .map(
          (u) => u.id == userId
              ? u.copyWith(
                  isFollowing: isFollowing,
                  canMessage: isFollowing || u.isFollower,
                )
              : u,
        )
        .toList();
    followersList.value = followersList
        .map(
          (u) => u.id == userId
              ? u.copyWith(
                  isFollowing: isFollowing,
                  isMutual: isFollowing && u.isFollower,
                  canMessage: isFollowing || u.isFollower,
                )
              : u,
        )
        .toList();
  }
}
