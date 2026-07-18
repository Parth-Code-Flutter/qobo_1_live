import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/controllers/discover_tab_controller.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/chat/chat_navigation_helper.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// Full-screen public profile opened from Discover (View Profile).
class DiscoverPublicProfileController extends GetxController {
  DiscoverPublicProfileController({
    UserRepo? userRepo,
    AuthRepo? authRepo,
  }) : _userRepo = userRepo ?? UserRepo(),
       _authRepo = authRepo ?? AuthRepo();

  final UserRepo _userRepo;
  final AuthRepo _authRepo;

  final profile = Rxn<SocialUserCard>();
  final rawData = <String, dynamic>{}.obs;
  final isLoading = false.obs;
  final isFollowProcessing = false.obs;

  String get userId => profile.value?.id ?? _argUserId;
  String _argUserId = '';

  @override
  void onInit() {
    super.onInit();
    _readArgs();
    // ignore: discarded_futures
    loadProfile();
  }

  void _readArgs() {
    final args = Get.arguments;
    if (args is! Map) return;

    _argUserId = args['userId']?.toString().trim() ?? '';
    final seed = args['user'];
    if (seed is SocialUserCard) {
      profile.value = seed;
      _argUserId = seed.id;
    }
  }

  Future<void> loadProfile() async {
    final id = userId;
    if (id.isEmpty) return;

    isLoading.value = true;
    try {
      final response = await _userRepo.getPublicProfile(
        userId: id,
        isShowLoader: false,
      );
      if (!isSocialApiSuccess(response) || response?['data'] is! Map) return;

      final data = Map<String, dynamic>.from(response!['data'] as Map);
      rawData.assignAll(data);
      final fresh = SocialUserCard.fromJson(data);
      final cached = profile.value;
      if (cached != null) {
        profile.value = fresh.copyWith(
          isFollowing: cached.isFollowing || fresh.isFollowing,
          isFollower: cached.isFollower || fresh.isFollower,
          isMutual: cached.isMutual || fresh.isMutual,
          canMessage: cached.canMessage || fresh.canMessage,
          isFavourite: cached.isFavourite || fresh.isFavourite,
        );
      } else {
        profile.value = fresh;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFollow(BuildContext context) async {
    final user = profile.value;
    if (user == null || user.id.isEmpty || isFollowProcessing.value) return;

    // Prefer Discover tab helper so the feed stays in sync.
    if (Get.isRegistered<DiscoverTabController>()) {
      isFollowProcessing.value = true;
      try {
        await Get.find<DiscoverTabController>().toggleFollowUser(context, user);
        final live = Get.find<DiscoverTabController>().userById(user.id);
        if (live != null) profile.value = live;
      } finally {
        isFollowProcessing.value = false;
      }
      return;
    }

    final action = user.isFollowing ? 'unfollow' : 'follow';
    isFollowProcessing.value = true;
    try {
      final response = await _authRepo.followUnfollow(
        targetId: user.id,
        action: action,
        isShowLoader: false,
      );
      if (!context.mounted) return;

      if (isSocialApiSuccess(response)) {
        final data = response?['data'];
        final dataMap =
            data is Map ? Map<String, dynamic>.from(data) : null;
        final isFollowing =
            dataMap?['isFollowing'] == true ||
            (action == 'follow' && dataMap == null);
        final isFollower = dataMap?['isFollower'] == true || user.isFollower;
        final isMutual =
            dataMap?['isMutual'] == true || (isFollowing && isFollower);
        final canMessage =
            dataMap?['canMessage'] == true ||
            isFollowing ||
            isFollower ||
            isMutual;

        profile.value = user.copyWith(
          isFollowing: isFollowing,
          isFollower: isFollower,
          isMutual: isMutual,
          canMessage: canMessage,
          followersCount:
              _toInt(dataMap?['followersCount']) ?? user.followersCount,
          followingCount:
              _toInt(dataMap?['followingCount']) ?? user.followingCount,
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
      isFollowProcessing.value = false;
    }
  }

  Future<void> openChat(BuildContext context) async {
    final user = profile.value;
    if (user == null || user.id.isEmpty) return;

    if (Get.isRegistered<DiscoverTabController>()) {
      await Get.find<DiscoverTabController>().openChat(context, user);
      return;
    }

    if (!user.canMessage) {
      AppToast.showError(
        context,
        user.isFollowing
            ? 'Waiting for them to follow you back'
            : 'Follow to connect — message when either follows',
      );
      return;
    }

    await ChatNavigationHelper.openDirectChat(
      context,
      targetId: user.id,
      name: user.name,
      imageUrl: user.displayPicture,
    );
  }

  int? _toInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    return int.tryParse(raw.toString());
  }
}
