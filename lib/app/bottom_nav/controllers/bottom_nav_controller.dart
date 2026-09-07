import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/controllers/discover_tab_controller.dart';
import 'package:qobo_one_live/app/user_flow/live_room/controllers/live_room_controller.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/controllers/messages_tab_controller.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/widgets/match_user_sheet.dart';
import 'package:qobo_one_live/constants/status_code_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/services/agency_session_controller.dart';
import 'package:qobo_one_live/services/chat/chat_incoming_call_coordinator.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/firebase/fcm_token_sync_service.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/app_media_permissions.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

/// Controller for bottom-nav state.
class BottomNavController extends GetxController {
  BottomNavController({AuthRepo? authRepo})
    : _authRepo = authRepo ?? AuthRepo();

  final AuthRepo _authRepo;
  final UserSessionController _userSession =
      Get.isRegistered<UserSessionController>()
      ? Get.find<UserSessionController>()
      : Get.put(UserSessionController(), permanent: true);
  final selectedIndex = goLiveTabIndex.obs;
  final permissionBlocked = false.obs;
  final showOpenSettings = false.obs;
  Map<String, dynamic>? profileData;
  bool _isOpeningOwnProfileSheet = false;

  static const int roomsTabIndex = 1;
  static const int goLiveTabIndex = 2;
  static const int messagesTabIndex = 3;
  static const int profileTabIndex = 4;

  /// Bottom-nav tabs.
  final items =
      const <({String label, String iconPath, String selectedIconPath})>[
        (
          label: 'Discover',
          iconPath: kIconDiscover,
          selectedIconPath: kIconDiscoverEnable,
        ),
        (
          label: 'Rooms',
          iconPath: kIconLiveRoom,
          selectedIconPath: kIconLiveRoomEnable,
        ),
        (
          label: 'Go Live',
          iconPath: kIconVideoCamera,
          selectedIconPath: kIconVideoCamera,
        ),
        (
          label: 'Messages',
          iconPath: kIconChat,
          selectedIconPath: kIconChatEnable,
        ),
        (
          label: 'Profile',
          iconPath: kIconUser,
          selectedIconPath: kIconUserEnable,
        ),
      ];

  @override
  void onInit() {
    super.onInit();
    _userSession.loadFromStorage();
    _fetchProfileOnInit();
    _prefetchAgencySession();
    _syncIncomingCallWatchers();
  }

  @override
  void onReady() {
    super.onReady();
    unawaited(_requestMediaPermissions());
  }

  void _syncIncomingCallWatchers() {
    if (!Get.isRegistered<ChatIncomingCallCoordinator>()) return;
    unawaited(
      Get.find<ChatIncomingCallCoordinator>().syncWatchedRoomsFromFirestore(),
    );
  }

  Future<void> _requestMediaPermissions() async {
    if (await AppMediaPermissions.areGranted()) {
      permissionBlocked.value = false;
      showOpenSettings.value = false;
      return;
    }

    final granted = await AppMediaPermissions.requestRequired();
    if (granted) {
      permissionBlocked.value = false;
      showOpenSettings.value = false;
      return;
    }

    permissionBlocked.value = true;
    showOpenSettings.value = await AppMediaPermissions.isPermanentlyDenied();
  }

  Future<void> retryMediaPermissions() async {
    await _requestMediaPermissions();
  }

  Future<void> openDeviceSettings() async {
    await AppMediaPermissions.openSettings();
  }

  Future<void> _prefetchAgencySession() async {
    // Isolation: only agency owners hydrate `/api/agency/dashboard`.
    final userSession = Get.isRegistered<UserSessionController>()
        ? Get.find<UserSessionController>()
        : null;
    if (userSession == null || !userSession.isAgency) return;
    if (!Get.isRegistered<AgencySessionController>()) return;
    await Get.find<AgencySessionController>().ensureHydratedFromDashboard();
  }

  void onNavBarTabSelected(int index) {
    _applyTabSelection(index);
  }

  void onTabSelected(int index) {
    _applyTabSelection(index);
  }

  /// Opens the current user's information from an app-bar profile control.
  Future<void> openOwnProfileSheet(BuildContext context) async {
    if (_isOpeningOwnProfileSheet) return;
    _isOpeningOwnProfileSheet = true;
    try {
      await showOwnUserSheet(
        context,
        loadProfile: () async {
          await _userSession.refreshProfileFromApi(isShowLoader: false);
          final raw = _userSession.profileData;
          if (raw == null) return null;

          final profile = Map<String, dynamic>.from(raw);
          final nestedUser = profile['user'];
          if (nestedUser is Map) {
            profile.addAll(Map<String, dynamic>.from(nestedUser));
          }
          final stats = profile['stats'];
          if (stats is Map) {
            profile.putIfAbsent(
              'followersCount',
              () => stats['followers'] ?? stats['followersCount'] ?? 0,
            );
            profile.putIfAbsent(
              'followingCount',
              () => stats['following'] ?? stats['followingCount'] ?? 0,
            );
          }
          profile['profileFrameUrl'] = _userSession.profileFrameUrl;
          profile['profileBackgroundUrl'] = _userSession.profileBackgroundUrl;

          final location = <String>[
            _profileValue(profile, const ['city', 'cityName']),
            _profileValue(profile, const ['state', 'stateName']),
            _profileValue(profile, const ['country', 'countryName']),
          ].where((value) => value.isNotEmpty).toSet().join(', ');
          final gender = _profileValue(profile, const ['gender', 'sex']);
          final birthday = _profileValue(profile, const [
            'dob',
            'dateOfBirth',
            'birthDate',
            'birthday',
          ]);
          final age = _profileValue(profile, const ['age']);
          final coins = _profileValue(profile, const [
            'formattedCoins',
            'coins',
            'coinBalance',
            'wallet.coins',
            'balances.coins',
          ]);
          final diamonds = _profileValue(profile, const [
            'formattedDiamonds',
            'diamonds',
            'diamondBalance',
            'wallet.diamonds',
            'balances.diamonds',
          ]);
          final callRate = _profileValue(profile, const [
            'coinsPerSecond',
            'coinPerSecond',
            'callRate',
          ]);
          final status = _profileValue(profile, const [
            'status',
            'accountStatus',
          ]);
          final details = <String, String>{
            if (_userSession.userId.isNotEmpty) 'User ID': _userSession.userId,
            if (_userSession.email.isNotEmpty) 'Email': _userSession.email,
            if (_userSession.phone.isNotEmpty) 'Phone': _userSession.phone,
            if (gender.isNotEmpty) 'Gender': _titleCase(gender),
            if (birthday.isNotEmpty) 'Birthday': _formatProfileDate(birthday),
            if (age.isNotEmpty) 'Age': age,
            if (location.isNotEmpty) 'Location': location,
            if (coins.isNotEmpty) 'Coins': _formatProfileNumber(coins),
            if (diamonds.isNotEmpty) 'Diamonds': _formatProfileNumber(diamonds),
            if (_userSession.agencyCode.isNotEmpty)
              'Agency code': _userSession.agencyCode,
            if (callRate.isNotEmpty) 'Call rate': '$callRate coins/sec',
            if (status.isNotEmpty) 'Status': _titleCase(status),
          };
          return OwnUserSheetData(
            user: SocialUserCard.fromJson(profile),
            levelLabel: _userSession.levelBadge,
            roleLabel: _titleCase(_userSession.role),
            visitors: _userSession.formattedVisitors,
            friends: _userSession.formattedFriends,
            following: _userSession.formattedFollowing,
            followers: _userSession.formattedFollowers,
            details: details,
          );
        },
      );
    } finally {
      _isOpeningOwnProfileSheet = false;
    }
  }

  static String _profileValue(Map<String, dynamic> profile, List<String> keys) {
    for (final key in keys) {
      dynamic raw = profile;
      for (final part in key.split('.')) {
        if (raw is! Map) {
          raw = null;
          break;
        }
        raw = raw[part];
      }
      final value = raw?.toString().trim() ?? '';
      if (value.isNotEmpty && value.toLowerCase() != 'null') return value;
    }
    return '';
  }

  static String _titleCase(String value) {
    return value
        .trim()
        .replaceAll('_', ' ')
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map(
          (word) =>
              '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}',
        )
        .join(' ');
  }

  static String _formatProfileDate(String value) {
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} ${months[date.month - 1]} ${date.year}';
  }

  static String _formatProfileNumber(String value) {
    final number = int.tryParse(value);
    if (number == null) return value;
    final digits = number.abs().toString();
    final buffer = StringBuffer();
    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(',');
      buffer.write(digits[index]);
    }
    return '${number.isNegative ? '-' : ''}$buffer';
  }

  void onGoLivePressed() {
    if (Get.isRegistered<LiveRoomController>()) {
      Get.find<LiveRoomController>().openGoLive();
      return;
    }
    Get.put(LiveRoomController()).openGoLive();
  }

  void _applyTabSelection(int index) {
    selectedIndex.value = index;
    if (index == 0 && Get.isRegistered<DiscoverTabController>()) {
      Get.find<DiscoverTabController>().refreshOnTabSelected();
    }
    if (index == roomsTabIndex && Get.isRegistered<LiveRoomController>()) {
      unawaited(Get.find<LiveRoomController>().fetchSelectedRoomMode());
    }
    if (index == goLiveTabIndex && Get.isRegistered<LiveRoomController>()) {
      unawaited(Get.find<LiveRoomController>().fetchActiveRooms());
    }
    if (index == messagesTabIndex &&
        Get.isRegistered<MessagesTabController>()) {
      Get.find<MessagesTabController>().fetchInbox();
    }
    // Refresh social counters (Visitors / Friends / Following / Followers).
    if (index == profileTabIndex) {
      unawaited(_userSession.refreshProfileFromApi(isShowLoader: false));
    }
  }

  /// Legacy helper for callers that used to open the removed center heart tab.
  void openHeartTabForAgencyHosts() {
    _popToBottomNavIfNeeded();
    onNavBarTabSelected(0);
  }

  bool _popToBottomNavIfNeeded() {
    if (Get.currentRoute == Routes.BOTTOM_NAV) return false;
    var popped = false;
    while (Get.key.currentState?.canPop() ?? false) {
      final route = Get.currentRoute;
      if (route == Routes.BOTTOM_NAV) break;
      Get.back<void>();
      popped = true;
      if (Get.currentRoute == Routes.BOTTOM_NAV) break;
    }
    return popped;
  }

  Future<void> onLogoutPressed() async {
    final storage = LocalStorage.shared;
    await _authRepo.logout(isShowLoader: false);
    if (Get.isRegistered<ChatSessionService>()) {
      await Get.find<ChatSessionService>().signOut();
    }
    await UserRealtimeSocketService.ensureDisconnected();
    if (Get.isRegistered<FcmTokenSyncService>()) {
      Get.find<FcmTokenSyncService>().clearCachedToken();
    }
    await _userSession.clearSession();
    await storage.clearAllData();
    Get.offAllNamed(Routes.AUTH_LOGIN);
  }

  /// Fetch profile once when bottom nav initializes, and cache it for easy access.
  Future<void> _fetchProfileOnInit() async {
    final response = await _authRepo.getProfile(isShowLoader: false);
    if (response == null) return;

    final rawCode = response['statusCode'];
    final statusCode = rawCode is int
        ? rawCode
        : int.tryParse(rawCode?.toString() ?? '') ?? 0;
    if (statusCode != 1 && statusCode != StatusCodeConstants.success) return;

    final raw = response['data'];
    final Map<String, dynamic>? data = raw is Map<String, dynamic>
        ? raw
        : raw is Map
        ? Map<String, dynamic>.from(raw)
        : null;
    if (data == null) return;

    profileData = data;
    await _userSession.saveProfile(data);
    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    // Non-blocking; fails softly if Firebase config files are not on device yet.
    unawaited(Get.find<ChatSessionService>().ensureSignedIn());
    update();
  }
}
