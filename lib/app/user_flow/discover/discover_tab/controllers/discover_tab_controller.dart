import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/models/discover_feed_layout.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/models/discover_filter_state.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/models/discover_room_selection.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/models/explore_discover_utils.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/widgets/match_user_sheet.dart';
import 'package:qobo_one_live/models/geo/country_state_models.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/chat/chat_navigation_helper.dart';
import 'package:qobo_one_live/repo/geo/geo_repo.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_call_launcher.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/services/chat/chat_incoming_call_coordinator.dart';
import 'package:qobo_one_live/services/room/join_approval_service.dart';
import 'package:qobo_one_live/utils/app_widgets/country_state_picker_sheet.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/zego_engine_utils.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

/// Controller for Discover tab — user feed from `GET /api/discover`.
class DiscoverTabController extends GetxController {
  DiscoverTabController({
    AuthRepo? authRepo,
    UserRepo? userRepo,
    GeoRepo? geoRepo,
    RoomRepo? roomRepo,
  }) : _authRepo = authRepo ?? AuthRepo(),
       _userRepo = userRepo ?? UserRepo(),
       _geoRepo = geoRepo ?? GeoRepo(),
       _roomRepo = roomRepo ?? RoomRepo();

  final AuthRepo _authRepo;
  final UserRepo _userRepo;
  final GeoRepo _geoRepo;
  final RoomRepo _roomRepo;

  final searchController = TextEditingController();
  final searchFocusNode = FocusNode();

  final discoverUsers = <SocialUserCard>[].obs;
  final searchResults = <SocialUserCard>[].obs;
  final isDiscoverUsersLoading = false.obs;
  final isDiscoverFiltersLoading = false.obs;
  final isSearchLoading = false.obs;
  final followingUserIds = <String>{}.obs;
  final isSearchExpanded = false.obs;
  final searchQuery = ''.obs;
  final filters = const DiscoverFilterState().obs;
  final filterCountries = <CountryOption>[].obs;
  final processingFollowId = ''.obs;
  final processingFavouriteId = ''.obs;
  final selectedDiscoverMode = DiscoverRoomSelection.none.obs;
  final videoRooms = <Map<String, dynamic>>[].obs;
  final audioRooms = <Map<String, dynamic>>[].obs;
  final isVideoRoomsLoading = false.obs;
  final isAudioRoomsLoading = false.obs;

  /// Grid (default) vs single full-height profile feed under Explore.
  final feedLayout = DiscoverFeedLayout.grid.obs;

  /// Back-compat for header badge.
  String? get selectedCountry => filters.value.country;

  bool get hasActiveDiscoverFilters => filters.value.hasActiveFilters;

  bool get isGridFeedLayout => feedLayout.value == DiscoverFeedLayout.grid;

  void setFeedLayout(DiscoverFeedLayout layout) {
    if (feedLayout.value == layout) return;
    feedLayout.value = layout;
  }

  bool get isPeopleMode =>
      selectedDiscoverMode.value == DiscoverRoomSelection.none;

  bool get isVideoRoomMode =>
      selectedDiscoverMode.value == DiscoverRoomSelection.video;

  bool get isAudioRoomMode =>
      selectedDiscoverMode.value == DiscoverRoomSelection.audio;

  var _discoverPage = 1;
  var _discoverHasMore = true;

  Timer? _debounceTimer;

  @override
  void onInit() {
    super.onInit();
    searchController.addListener(_onSearchChanged);
    unawaited(loadDiscoverFilters());
    fetchDiscoverUsers();
  }

  /// Countries for filter chips — `GET /api/auth/countries`.
  Future<void> loadDiscoverFilters() async {
    try {
      isDiscoverFiltersLoading.value = true;
      filterCountries.assignAll(
        await _geoRepo.fetchCountries(isShowLoader: false),
      );
    } catch (_) {
      filterCountries.clear();
    } finally {
      isDiscoverFiltersLoading.value = false;
    }
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

  void openSearch() {
    isSearchExpanded.value = true;
    Future.microtask(() {
      if (!searchFocusNode.hasFocus) {
        searchFocusNode.requestFocus();
      }
    });
  }

  void closeSearch() {
    searchController.clear();
    searchResults.clear();
    searchQuery.value = '';
    isSearchExpanded.value = false;
    searchFocusNode.unfocus();
  }

  /// Explore grid feed — `GET /api/discover` (separate from Messages New Match).
  Future<void> fetchDiscoverUsers({bool refresh = true}) async {
    if (refresh) {
      _discoverPage = 1;
      _discoverHasMore = true;
    } else if (!_discoverHasMore || isDiscoverUsersLoading.value) {
      return;
    }

    try {
      isDiscoverUsersLoading.value = true;
      final response = await _userRepo.exploreDiscover(
        page: _discoverPage,
        limit: 30,
        country: filters.value.country,
        gender: filters.value.gender,
        excludeFollowing: filters.value.excludeFollowing,
        isShowLoader: false,
      );
      final page = ExploreDiscoverPage.fromApiResponse(response);
      if (page.users.isNotEmpty || refresh) {
        if (refresh || _discoverPage == 1) {
          discoverUsers.assignAll(page.users);
        } else {
          discoverUsers.addAll(page.users);
        }
        _discoverHasMore = page.hasMore;
        if (page.users.isNotEmpty) _discoverPage++;
        return;
      }
      if (refresh) discoverUsers.clear();
    } catch (_) {
      if (refresh) discoverUsers.clear();
    } finally {
      isDiscoverUsersLoading.value = false;
    }
  }

  Future<void> performSearch(String query) async {
    try {
      isSearchLoading.value = true;
      final response = await _authRepo.searchUsers(query: query);
      if (response != null && response['statusCode'] == 1) {
        final cards = SocialUserCard.listFromResponseData(response['data']);
        searchResults.assignAll(
          cards.map((user) {
            final following =
                user.isFollowing || followingUserIds.contains(user.id);
            if (following) {
              followingUserIds.add(user.id);
            } else {
              followingUserIds.remove(user.id);
            }
            return following ? user.copyWith(isFollowing: true) : user;
          }),
        );
      } else {
        searchResults.clear();
      }
    } catch (_) {
      searchResults.clear();
    } finally {
      isSearchLoading.value = false;
    }
  }

  Future<void> applyDiscoverFilters(DiscoverFilterState next) async {
    filters.value = next;
    await fetchDiscoverUsers(refresh: true);
  }

  Future<void> clearDiscoverFilters() async {
    filters.value = const DiscoverFilterState();
    await fetchDiscoverUsers(refresh: true);
  }

  void selectDiscoverMode(DiscoverRoomSelection mode) {
    if (selectedDiscoverMode.value == mode) return;
    selectedDiscoverMode.value = mode;
    if (mode != DiscoverRoomSelection.none) {
      searchController.clear();
      searchResults.clear();
      searchQuery.value = '';
    }
    if (mode == DiscoverRoomSelection.video) {
      unawaited(fetchVideoRooms());
    } else if (mode == DiscoverRoomSelection.audio) {
      unawaited(fetchAudioRooms());
    }
  }

  void openCreateVideoRoom() {
    Get.toNamed(Routes.LIVE_ROOM_CREATE, arguments: {'type': 'VIDEO'});
  }

  void openCreateAudioRoom() {
    Get.toNamed(Routes.LIVE_ROOM_CREATE, arguments: {'type': 'AUDIO'});
  }

  Future<void> fetchVideoRooms({bool refresh = true}) async {
    await _fetchRooms(
      type: 'video',
      target: videoRooms,
      loading: isVideoRoomsLoading,
      refresh: refresh,
    );
  }

  Future<void> fetchAudioRooms({bool refresh = true}) async {
    await _fetchRooms(
      type: 'audio',
      target: audioRooms,
      loading: isAudioRoomsLoading,
      refresh: refresh,
    );
  }

  Future<void> _fetchRooms({
    required String type,
    required RxList<Map<String, dynamic>> target,
    required RxBool loading,
    required bool refresh,
  }) async {
    if (loading.value) return;
    try {
      loading.value = true;
      final response = await _roomRepo.listActiveRooms(
        type: type,
        country: filters.value.country,
        page: 1,
        limit: 30,
        isShowLoader: false,
      );
      if (_isRoomApiSuccess(response)) {
        final rooms = _extractRoomList(
          response?['data'],
        ).map((room) => _withRoomType(room, type)).toList();
        target.assignAll(rooms);
        return;
      }
      if (refresh) target.clear();
    } catch (_) {
      if (refresh) target.clear();
    } finally {
      loading.value = false;
    }
  }

  Future<void> joinDiscoverRoom(
    BuildContext context,
    Map<String, dynamic> room,
  ) async {
    final roomId = _roomId(room);
    if (roomId.isEmpty) {
      AppToast.showError(context, 'Room id is missing');
      return;
    }

    final response = await JoinApprovalService().joinWithApprovalGate(
      roomId: roomId,
      sessionType: JoinApprovalService.sessionTypeFor(
        type: room['type']?.toString(),
        roomType: isAudioRoomMode ? 'AUDIO' : 'VIDEO',
      ),
      roomHint: room,
      forceApprovalFlow: false,
      isShowLoader: true,
    );
    if (!context.mounted) return;

    if (!_isRoomApiSuccess(response)) {
      AppToast.showError(
        context,
        response?['message']?.toString() ?? 'Could not join room',
      );
      return;
    }

    final payload = _normalizeJoinPayload(
      response?['data'],
      fallbackRoom: room,
      fallbackRoomId: roomId,
    );
    final rawType = _text(payload['type'])?.toUpperCase() ?? 'VIDEO';
    final roomType = rawType == 'AUDIO' ? 'AUDIO' : 'VIDEO';
    payload['type'] = roomType.toLowerCase();
    await ZegoEngineUtils.resetForRoomProject();
    Get.toNamed(
      Routes.LIVE_BROADCAST,
      arguments: {'isHost': false, 'roomType': roomType, 'roomData': payload},
    );
  }

  /// Join the selected Discover user's active audio / video / live session.
  Future<void> joinUserActiveSession(
    BuildContext context,
    SocialUserCard user,
  ) async {
    final session = user.activeSession;
    if (session == null || !session.isJoinable) {
      AppToast.showError(context, 'This session is no longer live');
      return;
    }

    final roomId = session.roomId!.trim();
    final roomHint = <String, dynamic>{
      'room_id': roomId,
      'roomId': roomId,
      'id': roomId,
      'type': session.normalizedRoomType,
      'title': session.title ?? user.name,
      'name': session.title ?? user.name,
      'hostId': session.hostId ?? user.id,
      'hostName': user.name,
      'joinApprovalRequired': session.joinApprovalRequired,
      'isLive': true,
      if (session.liveStreamingId != null &&
          session.liveStreamingId!.trim().isNotEmpty) ...{
        'liveStreamingId': session.liveStreamingId,
        'zegoLiveId': session.liveStreamingId,
        'channelName': session.liveStreamingId,
      },
      if (session.coverUrl != null && session.coverUrl!.trim().isNotEmpty)
        'coverUrl': session.coverUrl,
      if (session.viewerCount > 0) 'viewerCount': session.viewerCount,
    };

    final response = await JoinApprovalService().joinWithApprovalGate(
      roomId: roomId,
      sessionType: session.resolvedSessionType,
      roomHint: roomHint,
      forceApprovalFlow: session.joinApprovalRequired,
      isShowLoader: true,
    );
    if (!context.mounted) return;

    if (session.isLiveStream) {
      await _openJoinedLiveStream(
        context: context,
        response: response,
        fallback: roomHint,
        roomId: roomId,
      );
      return;
    }

    if (!_isRoomApiSuccess(response)) {
      AppToast.showError(
        context,
        response?['message']?.toString() ?? 'Could not join room',
      );
      return;
    }

    final payload = _normalizeJoinPayload(
      response?['data'],
      fallbackRoom: roomHint,
      fallbackRoomId: roomId,
    );
    final roomType =
        session.normalizedRoomType == 'AUDIO' ? 'AUDIO' : 'VIDEO';
    payload['type'] = roomType.toLowerCase();
    await ZegoEngineUtils.resetForRoomProject();
    Get.toNamed(
      Routes.LIVE_BROADCAST,
      arguments: {
        'isHost': false,
        'roomType': roomType,
        'roomData': payload,
      },
    );
  }

  Future<void> _openJoinedLiveStream({
    required BuildContext context,
    required Map<String, dynamic>? response,
    required Map<String, dynamic> fallback,
    required String roomId,
  }) async {
    if (!_isRoomApiSuccess(response)) {
      final status = response?['data'] is Map
          ? (response!['data'] as Map)['status']?.toString().toLowerCase()
          : null;
      final blocked = JoinApprovalService.isApprovalRequiredError(response) ||
          status == 'rejected' ||
          status == 'blocked' ||
          status == 'expired' ||
          status == 'cancelled';
      if (blocked) {
        AppToast.showError(
          context,
          response?['message']?.toString() ?? 'Could not join live stream',
        );
        return;
      }
      // Legacy open rooms: continue even if optional join reporting failed.
    }

    final roomData = <String, dynamic>{
      ...fallback,
      'type': 'live_stream',
      'room_id': roomId,
      'id': roomId,
      'isLive': true,
    };
    if (_isRoomApiSuccess(response) && response?['data'] is Map) {
      final joined = Map<String, dynamic>.from(response!['data'] as Map);
      roomData.addAll(joined);
      if (joined['room'] is Map) {
        roomData.addAll(Map<String, dynamic>.from(joined['room'] as Map));
      }
      roomData['type'] = 'live_stream';
      final joinRequestId =
          joined['join_request_id']?.toString() ??
          joined['request_id']?.toString();
      if (joinRequestId != null && joinRequestId.isNotEmpty) {
        roomData['join_request_id'] = joinRequestId;
      }
    }
    // Bind Zego to zegoLiveId / liveStreamingId (ls_…) from join response.
    roomData['room_id'] = roomData['room_id'] ?? roomData['roomId'] ?? roomId;
    roomData['id'] = roomData['id'] ?? roomData['room_id'];
    ZegoLiveIdUtils.applyLiveChannelId(roomData);

    await ZegoEngineUtils.resetForLiveProject();
    Get.toNamed(
      Routes.LIVE_BROADCAST,
      arguments: {
        'isHost': false,
        'roomType': 'LIVE_STREAM',
        'roomData': roomData,
      },
    );
  }

  Future<void> toggleGenderFilter(String gender) async {
    final current = filters.value;
    final nextGender = current.gender?.toLowerCase() == gender.toLowerCase()
        ? null
        : gender;
    await applyDiscoverFilters(
      current.copyWith(gender: nextGender, clearGender: nextGender == null),
    );
  }

  Future<void> toggleCountryFilter(CountryOption country) async {
    final current = filters.value;
    final code = country.code.trim();
    final isSelected =
        current.country?.toLowerCase() == code.toLowerCase() ||
        current.country?.toLowerCase() == country.name.toLowerCase();
    await applyDiscoverFilters(
      current.copyWith(
        country: isSelected ? null : code,
        clearCountry: isSelected,
      ),
    );
  }

  /// Country dropdown — passes ISO `country` code to `GET /api/discover`.
  Future<void> selectCountryFilter(CountryOption? country) async {
    await applyDiscoverFilters(
      filters.value.copyWith(
        country: country?.code.trim(),
        clearCountry: country == null,
      ),
    );
  }

  /// Opens country filter bottom sheet — `GET /api/auth/countries`.
  Future<void> openCountryFilterSheet(BuildContext context) async {
    if (filterCountries.isEmpty) {
      await loadDiscoverFilters();
    }
    if (!context.mounted) return;

    final result = await showDiscoverCountryFilterSheet(
      context,
      countries: filterCountries.toList(),
      selected: selectedCountryOption,
    );
    if (!context.mounted || result == null) return;

    if (result.clearAll) {
      await selectCountryFilter(null);
      return;
    }
    await selectCountryFilter(result.country);
  }

  CountryOption? get selectedCountryOption {
    final raw = filters.value.country?.trim();
    if (raw == null || raw.isEmpty) return null;
    for (final country in filterCountries) {
      if (country.code.toLowerCase() == raw.toLowerCase() ||
          country.name.toLowerCase() == raw.toLowerCase()) {
        return country;
      }
    }
    return null;
  }

  Future<void> toggleExcludeFollowingFilter() async {
    final current = filters.value;
    await applyDiscoverFilters(
      current.copyWith(excludeFollowing: !current.excludeFollowing),
    );
  }

  /// Legacy country-only apply from older sheet callers.
  Future<void> applyCountryFilter(String? country) async {
    final normalized = country?.trim();
    await applyDiscoverFilters(
      filters.value.copyWith(
        country: normalized == null || normalized.isEmpty ? null : normalized,
        clearCountry: normalized == null || normalized.isEmpty,
      ),
    );
  }

  Future<void> toggleFavourite(
    BuildContext context,
    SocialUserCard user,
  ) async {
    if (user.id.isEmpty) return;

    final nextFavourite = !user.isFavourite;
    processingFavouriteId.value = user.id;
    _applyFavouriteState(user.id, isFavourite: nextFavourite);

    try {
      final response = nextFavourite
          ? await _userRepo.favouriteUser(
              targetId: user.id,
              isShowLoader: false,
            )
          : await _userRepo.unfavouriteUser(
              targetId: user.id,
              isShowLoader: false,
            );
      if (!context.mounted) return;

      final result = FavouriteActionResult.fromApiResponse(response);
      if (result != null) {
        _applyFavouriteState(result.targetId, isFavourite: result.isFavourite);
        if (result.message != null && result.message!.isNotEmpty) {
          AppToast.showSuccess(context, result.message!);
        }
        return;
      }

      _applyFavouriteState(user.id, isFavourite: !nextFavourite);
      AppToast.showError(
        context,
        response?['message']?.toString() ?? 'Could not update favourite',
      );
    } catch (e) {
      if (!context.mounted) return;
      _applyFavouriteState(user.id, isFavourite: !nextFavourite);
      AppToast.showError(context, 'Error: $e');
    } finally {
      processingFavouriteId.value = '';
    }
  }

  void _applyFavouriteState(String userId, {required bool isFavourite}) {
    discoverUsers.value = discoverUsers
        .map((u) => u.id == userId ? u.copyWith(isFavourite: isFavourite) : u)
        .toList();
    searchResults.value = searchResults
        .map((u) => u.id == userId ? u.copyWith(isFavourite: isFavourite) : u)
        .toList();
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
        final data = response['data'];
        final isFollowing = data is Map
            ? data['isFollowing'] == true
            : action == 'follow';
        if (isFollowing) {
          followingUserIds.add(targetId);
          AppToast.showSuccess(context, 'Followed successfully');
        } else {
          followingUserIds.remove(targetId);
          AppToast.showSuccess(context, 'Unfollowed successfully');
        }
        _syncDiscoverUserFollowState(targetId, isFollowing: isFollowing);
      } else {
        final msg = response?['message']?.toString() ?? 'Action failed';
        AppToast.showError(context, msg);
      }
    } catch (e) {
      if (!context.mounted) return;
      AppToast.showError(context, 'Error performing action: $e');
    }
  }

  Future<void> toggleFollowUser(
    BuildContext context,
    SocialUserCard user,
  ) async {
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
        final Map<String, dynamic>? dataMap = data is Map
            ? Map<String, dynamic>.from(data)
            : null;
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

        _applyFollowState(
          user.id,
          isFollowing: isFollowing,
          isFollower: isFollower,
          isMutual: isMutual,
          canMessage: canMessage,
          followersCount: _toInt(dataMap?['followersCount']),
          followingCount: _toInt(dataMap?['followingCount']),
        );
        if (isFollowing) {
          followingUserIds.add(user.id);
        } else {
          followingUserIds.remove(user.id);
        }
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

  void _syncDiscoverUserFollowState(
    String userId, {
    required bool isFollowing,
  }) {
    discoverUsers.value = discoverUsers
        .map((u) => u.id == userId ? u.copyWith(isFollowing: isFollowing) : u)
        .toList();
    searchResults.value = searchResults
        .map((u) => u.id == userId ? u.copyWith(isFollowing: isFollowing) : u)
        .toList();
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
      final nextCanMessage =
          canMessage ??
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

    discoverUsers.value = discoverUsers.map(merge).toList();
    searchResults.value = searchResults.map(merge).toList();
  }

  SocialUserCard? userById(String id) {
    for (final u in discoverUsers) {
      if (u.id == id) return u;
    }
    for (final u in searchResults) {
      if (u.id == id) return u;
    }
    return null;
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
        var fresh = SocialUserCard.fromJson(
          Map<String, dynamic>.from(response!['data'] as Map),
        );
        if (cached != null) {
          fresh = fresh.copyWith(
            isFollowing: cached.isFollowing || fresh.isFollowing,
            isFollower: cached.isFollower || fresh.isFollower,
            isMutual: cached.isMutual || fresh.isMutual,
            canMessage: cached.canMessage || fresh.canMessage,
            isFavourite: cached.isFavourite || fresh.isFavourite,
          );
        }
        _upsertUserCard(fresh);
        return fresh;
      }
    } catch (_) {}
    return cached;
  }

  /// Keep Discover / search lists in sync so sheet Obx sees `activeSession`.
  void _upsertUserCard(SocialUserCard user) {
    if (user.id.isEmpty) return;

    SocialUserCard merge(SocialUserCard existing) {
      if (existing.id != user.id) return existing;
      return user.copyWith(
        isFollowing: existing.isFollowing || user.isFollowing,
        isFollower: existing.isFollower || user.isFollower,
        isMutual: existing.isMutual || user.isMutual,
        canMessage: existing.canMessage || user.canMessage,
        isFavourite: existing.isFavourite || user.isFavourite,
      );
    }

    var found = false;
    discoverUsers.value = discoverUsers.map((u) {
      if (u.id != user.id) return u;
      found = true;
      return merge(u);
    }).toList();
    searchResults.value = searchResults.map((u) {
      if (u.id != user.id) return u;
      found = true;
      return merge(u);
    }).toList();
    if (!found) {
      // Sheet can still render [user] directly when not in the current feed page.
    }
  }

  Future<void> openChat(BuildContext context, SocialUserCard user) async {
    if (user.id.isEmpty) return;
    if (!user.canMessage) {
      AppToast.showError(context, 'Follow each other to start messaging');
      return;
    }

    await ChatNavigationHelper.openDirectChat(
      context,
      targetId: user.id,
      name: user.name,
      imageUrl: user.displayPicture,
    );
  }

  /// Direct Zego call from Discover — rings peer but skips chat call history.
  Future<void> startDirectCall(
    BuildContext context,
    SocialUserCard user,
    ChatCallType callType,
  ) async {
    if (user.id.isEmpty) {
      AppToast.showError(context, 'Invalid user');
      return;
    }

    await ChatCallLauncher.start(
      context: context,
      targetId: user.id,
      peerName: user.name,
      peerAvatar: user.displayPicture,
      peerCountry: user.country,
      peerBio: user.bio,
      coinsPerSecond: user.coinsPerSecond,
      callType: callType,
      recordCallHistory: false,
    );
  }

  MatchUserSheetActions get matchSheetActions => MatchUserSheetActions(
    processingFollowId: processingFollowId,
    userById: userById,
    fetchPublicProfile: fetchPublicProfile,
    toggleFollow: toggleFollowUser,
    openChat: openChat,
  );

  /// Refresh discover users when user returns to this nav item.
  void refreshOnTabSelected() {
    if (!isDiscoverUsersLoading.value) {
      fetchDiscoverUsers(refresh: true);
    }
    if (isVideoRoomMode && !isVideoRoomsLoading.value) {
      unawaited(fetchVideoRooms());
    } else if (isAudioRoomMode && !isAudioRoomsLoading.value) {
      unawaited(fetchAudioRooms());
    }
    if (Get.isRegistered<ChatIncomingCallCoordinator>()) {
      unawaited(
        Get.find<ChatIncomingCallCoordinator>().syncWatchedRoomsFromFirestore(),
      );
    }
  }

  List<Map<String, dynamic>> _extractRoomList(dynamic raw) {
    final list = raw is List
        ? raw
        : raw is Map
        ? raw['rooms'] ?? raw['items'] ?? raw['list'] ?? raw['data']
        : null;
    if (list is! List) return const <Map<String, dynamic>>[];
    return list
        .whereType<Map>()
        .map((room) => Map<String, dynamic>.from(room))
        .toList();
  }

  Map<String, dynamic> _withRoomType(Map<String, dynamic> room, String type) {
    final next = Map<String, dynamic>.from(room);
    next.putIfAbsent('type', () => type);
    return next;
  }

  Map<String, dynamic> _normalizeJoinPayload(
    dynamic raw, {
    required Map<String, dynamic> fallbackRoom,
    required String fallbackRoomId,
  }) {
    final data = raw is Map ? Map<String, dynamic>.from(raw) : {};
    final joinedRoom = data['room'] is Map
        ? Map<String, dynamic>.from(data['room'] as Map)
        : <String, dynamic>{};
    final payload = <String, dynamic>{
      ...fallbackRoom,
      ...joinedRoom,
      if (data['room'] is! Map) ...data,
    };
    final zegoStreaming = data['zegoStreaming'];
    if (zegoStreaming is Map) {
      payload['zegoStreaming'] = Map<String, dynamic>.from(zegoStreaming);
      payload.putIfAbsent('zegoToken', () => zegoStreaming['token']);
      payload.putIfAbsent('streamId', () => zegoStreaming['streamId']);
    }
    payload['room_id'] =
        _text(data['room_id']) ??
        _text(payload['room_id']) ??
        _text(payload['roomId']) ??
        fallbackRoomId;
    payload['id'] = _text(payload['id']) ?? payload['room_id'];
    payload['zegoLiveId'] =
        _text(data['zegoLiveId']) ??
        _text(data['channelName']) ??
        _text(payload['zegoLiveId']) ??
        _text(payload['channelName']) ??
        (zegoStreaming is Map ? _text(zegoStreaming['roomId']) : null) ??
        fallbackRoomId;
    payload['channelName'] =
        _text(data['channelName']) ??
        _text(payload['channelName']) ??
        payload['zegoLiveId'];
    payload['type'] =
        _text(payload['type']) ?? (isAudioRoomMode ? 'audio' : 'video');
    return payload;
  }

  String _roomId(Map<String, dynamic> room) {
    return _text(room['room_id']) ??
        _text(room['roomId']) ??
        _text(room['_id']) ??
        _text(room['id']) ??
        '';
  }

  bool _isRoomApiSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    final code = response['statusCode'];
    return code == 1 || code == 200 || code == 201 || code == true;
  }

  String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static int _toInt(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    searchFocusNode.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }
}
