import 'dart:async';

import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/controllers/discover_tab_controller.dart';
import 'package:qobo_one_live/app/user_flow/live_room/controllers/live_room_controller.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/controllers/messages_tab_controller.dart';
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

  static const int roomsTabIndex = 1;
  static const int goLiveTabIndex = 2;
  static const int messagesTabIndex = 3;

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
    if (!Get.isRegistered<AgencySessionController>()) return;
    await Get.find<AgencySessionController>().ensureHydratedFromDashboard();
  }

  void onNavBarTabSelected(int index) {
    _applyTabSelection(index);
  }

  void onTabSelected(int index) {
    _applyTabSelection(index);
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
