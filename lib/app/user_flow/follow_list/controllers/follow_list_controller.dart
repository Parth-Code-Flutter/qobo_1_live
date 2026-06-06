import 'package:get/get.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';

import '../../messages/messages_tab/models/social_user_card.dart';

class FollowListController extends GetxController {
  FollowListController({
    UserRepo? userRepo,
    AuthRepo? authRepo,
  })  : _userRepo = userRepo ?? UserRepo(),
        _authRepo = authRepo ?? AuthRepo();

  final UserRepo _userRepo;
  final AuthRepo _authRepo;

  final tabIndex = 0.obs;
  final isLoading = false.obs;
  final processingFollowId = ''.obs;

  final followingList = <SocialUserCard>[].obs;
  final followersList = <SocialUserCard>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map && args.containsKey('initialTab')) {
      tabIndex.value = args['initialTab'] as int? ?? 0;
    }
    loadFollowLists();
  }

  Future<void> loadFollowLists() async {
    try {
      isLoading.value = true;
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
    } catch (_) {
      followingList.clear();
      followersList.clear();
    } finally {
      isLoading.value = false;
    }
  }

  void changeTab(int index) {
    tabIndex.value = index;
  }

  Future<void> toggleFollow(SocialUserCard user, {required bool isFollowingTab}) async {
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
        if (isFollowingTab && !isFollowing) {
          followingList.removeWhere((u) => u.id == user.id);
        }
      }
    } finally {
      processingFollowId.value = '';
    }
  }

  void _updateUserInLists(String userId, {required bool isFollowing}) {
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
                  canMessage: isFollowing || u.isFollower,
                )
              : u,
        )
        .toList();
  }
}
