import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/models/discover_filter_state.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/models/discover_room_selection.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/models/explore_discover_utils.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/widgets/match_user_sheet.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/models/geo/country_state_models.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/chat/chat_navigation_helper.dart';
import 'package:qobo_one_live/repo/geo/geo_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_call_launcher.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/services/chat/chat_incoming_call_coordinator.dart';
import 'package:qobo_one_live/utils/app_widgets/country_state_picker_sheet.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// Controller for Discover tab — user feed from `GET /api/discover`.
class DiscoverTabController extends GetxController {
  DiscoverTabController({
    AuthRepo? authRepo,
    UserRepo? userRepo,
    GeoRepo? geoRepo,
  }) : _authRepo = authRepo ?? AuthRepo(),
       _userRepo = userRepo ?? UserRepo(),
       _geoRepo = geoRepo ?? GeoRepo();

  final AuthRepo _authRepo;
  final UserRepo _userRepo;
  final GeoRepo _geoRepo;

  final searchController = TextEditingController();

  final discoverUsers = <SocialUserCard>[].obs;
  final searchResults = <dynamic>[].obs;
  final isDiscoverUsersLoading = false.obs;
  final isDiscoverFiltersLoading = false.obs;
  final isSearchLoading = false.obs;
  final followingUserIds = <String>{}.obs;
  final searchQuery = ''.obs;
  final filters = const DiscoverFilterState().obs;
  final filterCountries = <CountryOption>[].obs;
  final processingFollowId = ''.obs;
  final processingFavouriteId = ''.obs;
  final selectedDiscoverMode = DiscoverRoomSelection.none.obs;
  final demoVideoRooms = <Map<String, dynamic>>[
    {
      'id': 'demo_video_1',
      'name': 'Creator Hangout',
      'hostName': 'Ritvik',
      'category': 'Open cam chat',
      'type': 'VIDEO',
      'countryName': 'India',
      'viewerCount': '2.1k',
      'coverImage': kImgTemp1,
      'hostAvatar': kImgTemp1,
      'maxSeats': 8,
      'status': 'live',
      'tags': ['Music', 'New friends'],
    },
    {
      'id': 'demo_video_2',
      'name': 'Late Night Live',
      'hostName': 'Jitendra',
      'category': 'Talk show',
      'type': 'VIDEO',
      'countryName': 'Global',
      'viewerCount': '846',
      'coverImage': kImgTemp2,
      'hostAvatar': kImgTemp2,
      'maxSeats': 6,
      'status': 'live',
      'tags': ['Trending', 'Co-host'],
    },
    {
      'id': 'demo_video_3',
      'name': 'Talent Stage',
      'hostName': 'Alpha Host',
      'category': 'Singing and games',
      'type': 'VIDEO',
      'countryName': 'Bangladesh',
      'viewerCount': '1.4k',
      'coverImage': kImgTemp3,
      'hostAvatar': kImgTemp3,
      'maxSeats': 12,
      'status': 'live',
      'tags': ['Talent', 'VIP'],
    },
  ].obs;

  /// Back-compat for header badge.
  String? get selectedCountry => filters.value.country;

  bool get hasActiveDiscoverFilters => filters.value.hasActiveFilters;

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
        final list = response['data'];
        if (list is List) {
          searchResults.value = list;
          for (final raw in list) {
            if (raw is! Map) continue;
            final id = raw['id']?.toString() ?? '';
            if (id.isEmpty) continue;
            if (raw['isFollowing'] == true) {
              followingUserIds.add(id);
            } else {
              followingUserIds.remove(id);
            }
          }
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
  }

  void openCreateVideoRoom() {
    Get.toNamed(Routes.LIVE_ROOM_CREATE, arguments: {'type': 'VIDEO'});
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
  }

  SocialUserCard? userById(String id) {
    for (final u in discoverUsers) {
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
    if (Get.isRegistered<ChatIncomingCallCoordinator>()) {
      unawaited(
        Get.find<ChatIncomingCallCoordinator>().syncWatchedRoomsFromFirestore(),
      );
    }
  }

  static int _toInt(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  @override
  void onClose() {
    searchController.removeListener(_onSearchChanged);
    searchController.dispose();
    _debounceTimer?.cancel();
    super.onClose();
  }
}
