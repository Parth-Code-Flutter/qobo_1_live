import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

import '../models/discover_room_selection.dart';

/// Controller for discover tab local UI state.
class DiscoverTabController extends GetxController {
  final roomSelection = DiscoverRoomSelection.none.obs;

  final searchController = TextEditingController();

  final AuthRepo _authRepo = AuthRepo();
  final searchResults = <dynamic>[].obs;
  final isSearchLoading = false.obs;
  final followingUserIds = <String>{}.obs;
  final searchQuery = ''.obs;

  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final text = searchController.text.trim();
    searchQuery.value = text;
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 350), () {
      if (text.isNotEmpty) {
        performSearch(text);
      } else {
        searchResults.clear();
      }
    });
  }

  Future<void> performSearch(String query) async {
    try {
      isSearchLoading.value = true;
      final response = await _authRepo.searchUsers(query: query);
      if (response != null && response['statusCode'] == 1) {
        final list = response['data'];
        if (list is List) {
          searchResults.value = list;
        } else {
          searchResults.clear();
        }
      }
    } catch (_) {
      searchResults.clear();
    } finally {
      isSearchLoading.value = false;
    }
  }

  Future<void> toggleFollow(BuildContext context, String targetId) async {
    final isFollowing = followingUserIds.contains(targetId);
    final action = isFollowing ? 'unfollow' : 'follow';
    try {
      final response = await _authRepo.followUnfollow(
        targetId: targetId,
        action: action,
        isShowLoader: true,
      );
      if (response != null && response['statusCode'] == 1) {
        if (isFollowing) {
          followingUserIds.remove(targetId);
          AppToast.showSuccess(context, 'Unfollowed successfully');
        } else {
          followingUserIds.add(targetId);
          AppToast.showSuccess(context, 'Followed successfully');
        }
      } else {
        final msg = response?['message']?.toString() ?? 'Action failed';
        AppToast.showError(context, msg);
      }
    } catch (e) {
      AppToast.showError(context, 'Error performing action: $e');
    }
  }

  void selectVideoRoom() {
    roomSelection.value = DiscoverRoomSelection.video;
  }

  void selectAudioRoom() {
    roomSelection.value = DiscoverRoomSelection.audio;
  }

  /// Default feed (no room chip selected). Called when user switches to Discover tab.
  void clearRoomMode() {
    roomSelection.value = DiscoverRoomSelection.none;
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }
}
