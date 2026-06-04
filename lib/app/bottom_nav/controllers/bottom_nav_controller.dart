import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/controllers/discover_tab_controller.dart';
import 'package:qobo_one_live/app/user_flow/live_action/controllers/live_action_controller.dart';
import 'package:qobo_one_live/constants/status_code_constants.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
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
  final selectedIndex = 0.obs;
  Map<String, dynamic>? profileData;

  /// Center heart tab — live host map ([LiveActionView]).
  static const int heartTabIndex = 2;

  /// Bottom-nav tabs (Figma-style labels + centered heart action).
  final items =
      const <({String label, String iconPath, String selectedIconPath})>[
        (
          label: 'Discover',
          iconPath: kIconDiscover,
          selectedIconPath: kIconDiscoverEnable,
        ),
        (
          label: 'Live Rooms',
          iconPath: kIconLiveRoom,
          selectedIconPath: kIconLiveRoomEnable,
        ),
        (label: '', iconPath: kIconHeart, selectedIconPath: kIconHeart),
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
  }

  void onNavBarTabSelected(int index) {
    _applyTabSelection(index);
  }

  void onTabSelected(int index) {
    _applyTabSelection(index);
  }

  void onGoLivePressed() {
    Get.toNamed(
      Routes.LIVE_ROOM_CREATE,
      arguments: {'type': 'VIDEO', 'isHost': true},
    );
  }

  void _applyTabSelection(int index) {
    selectedIndex.value = index;
    if (index == 0 && Get.isRegistered<DiscoverTabController>()) {
      Get.find<DiscoverTabController>().clearRoomMode();
    }
    if (index != heartTabIndex &&
        Get.isRegistered<LiveActionController>() &&
        Get.find<LiveActionController>().isAgencyHostsView) {
      Get.find<LiveActionController>().configureDiscoverHosts();
    }
  }

  /// Opens the heart-tab host map with agency hosts (from owner dashboard).
  void openHeartTabForAgencyHosts() {
    final popped = _popToBottomNavIfNeeded();
    onNavBarTabSelected(heartTabIndex);
    _applyAgencyHostsOnLiveAction(afterPop: popped);
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

  void _applyAgencyHostsOnLiveAction({required bool afterPop}) {
    void apply() {
      if (!Get.isRegistered<LiveActionController>()) {
        Get.put(LiveActionController());
      }
      Get.find<LiveActionController>().configureAgencyHosts();
    }

    if (afterPop) {
      Future.microtask(apply);
      return;
    }
    apply();
  }

  Future<void> onLogoutPressed() async {
    final storage = Get.isRegistered<LocalStorage>()
        ? Get.find<LocalStorage>()
        : Get.put(LocalStorage(), permanent: true);
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
    update();
  }
}
