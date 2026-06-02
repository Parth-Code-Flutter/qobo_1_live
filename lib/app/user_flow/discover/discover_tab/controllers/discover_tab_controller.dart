import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

import '../models/discover_room_selection.dart';

/// Controller for discover tab local UI state.
class DiscoverTabController extends GetxController {
  final roomSelection = DiscoverRoomSelection.video.obs;

  final searchController = TextEditingController();

  final AuthRepo _authRepo = AuthRepo();
  final RoomRepo _roomRepo = RoomRepo();
  final searchResults = <dynamic>[].obs;
  final videoRooms = <Map<String, dynamic>>[].obs;
  final audioRooms = <Map<String, dynamic>>[].obs;
  final isSearchLoading = false.obs;
  final isVideoRoomsLoading = false.obs;
  final isAudioRoomsLoading = false.obs;
  final followingUserIds = <String>{}.obs;
  final searchQuery = ''.obs;

  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    fetchVideoRooms();
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

  Future<void> fetchVideoRooms() async {
    try {
      isVideoRoomsLoading.value = true;
      var response = await _roomRepo.getVideoSwiper(isShowLoader: false);
      if (response == null ||
          response['statusCode'] != 1 ||
          response['data'] is! List ||
          (response['data'] as List).isEmpty) {
        response = await _roomRepo.listActiveRooms(
          type: 'video',
          isShowLoader: false,
        );
      }
      if (response != null && response['statusCode'] == 1) {
        final list = response['data'];
        if (list is List) {
          videoRooms.assignAll(
            list.whereType<Map>().map(
              (item) => Map<String, dynamic>.from(item),
            ),
          );
          return;
        }
      }
      videoRooms.clear();
    } catch (_) {
      videoRooms.clear();
    } finally {
      isVideoRoomsLoading.value = false;
    }
  }

  Future<void> fetchAudioRooms() async {
    try {
      isAudioRoomsLoading.value = true;
      final response = await _roomRepo.listActiveRooms(
        type: 'audio',
        isShowLoader: false,
      );
      if (response != null && response['statusCode'] == 1) {
        final list = response['data'];
        if (list is List) {
          audioRooms.assignAll(
            list.whereType<Map>().map(
              (item) => Map<String, dynamic>.from(item),
            ),
          );
          return;
        }
      }
      audioRooms.clear();
    } catch (_) {
      audioRooms.clear();
    } finally {
      isAudioRoomsLoading.value = false;
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
      if (!context.mounted) return;
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
      if (!context.mounted) return;
      AppToast.showError(context, 'Error performing action: $e');
    }
  }

  void selectVideoRoom() {
    roomSelection.value = DiscoverRoomSelection.video;
    if (videoRooms.isEmpty && !isVideoRoomsLoading.value) {
      fetchVideoRooms();
    }
  }

  void selectAudioRoom() {
    roomSelection.value = DiscoverRoomSelection.audio;
    if (audioRooms.isEmpty && !isAudioRoomsLoading.value) {
      fetchAudioRooms();
    }
  }

  Future<void> joinLiveRoom(
    BuildContext context,
    Map<String, dynamic> room,
  ) async {
    final roomId = _extractRoomId(room);
    if (roomId == null) {
      AppToast.showError(
        context,
        'Cannot join this live room because room id is missing.',
      );
      return;
    }

    try {
      final response = await _roomRepo.joinRoom(roomId: roomId);
      if (!context.mounted) return;

      if (response != null && response['statusCode'] == 1) {
        final responseData = response['data'];
        final mergedRoomData = <String, dynamic>{
          ...room,
          if (responseData is Map) ...Map<String, dynamic>.from(responseData),
          'room_id': roomId,
        };

        Get.toNamed(
          Routes.LIVE_BROADCAST,
          arguments: {
            'isHost': false,
            'roomType': _extractRoomType(mergedRoomData),
            'roomData': mergedRoomData,
          },
        );
        return;
      }

      AppToast.showError(
        context,
        response?['message']?.toString() ?? 'Unable to join live room.',
      );
    } catch (e) {
      if (!context.mounted) return;
      AppToast.showError(context, 'Unable to join live room: $e');
    }
  }

  String? _extractRoomId(Map<String, dynamic> room) {
    const keys = [
      'room_id',
      'roomId',
      'zegoLiveId',
      'zego_live_id',
      'zegoRoomId',
      'zego_room_id',
      'channelName',
      'channel_name',
      'liveStreamingId',
      'livestreamingId',
      'live_streaming_id',
      'liveStreamId',
      'live_id',
      'liveId',
      '_id',
      'id',
    ];

    for (final key in keys) {
      final value = room[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return null;
  }

  String _extractRoomType(Map<String, dynamic> room) {
    final type = room['type']?.toString().trim().toUpperCase();
    if (type == 'AUDIO') return 'AUDIO';
    return 'VIDEO';
  }

  /// Resets Discover to the default Video Room tab when user returns to this nav item.
  void clearRoomMode() {
    selectVideoRoom();
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }
}
