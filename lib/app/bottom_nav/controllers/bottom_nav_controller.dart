import 'package:get/get.dart';
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
  final UserSessionController _userSession = Get.isRegistered<UserSessionController>()
      ? Get.find<UserSessionController>()
      : Get.put(UserSessionController(), permanent: true);
  final selectedIndex = 0.obs;
  Map<String, dynamic>? profileData;

  /// Bottom-nav tabs (Figma-style labels + centered heart action).
  final items = const <({String label, String iconPath, String selectedIconPath})>[
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
    (
      label: '',
      iconPath: kIconHeart,
      selectedIconPath: kIconHeart,
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
  }

  void onNavBarTabSelected(int index) {
    selectedIndex.value = index;
  }

  void onTabSelected(int index) {
    selectedIndex.value = index;
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

    final statusCode = (response['statusCode'] as num?)?.toInt() ?? 0;
    if (statusCode != 1) return;

    final data = response['data'];
    if (data is! Map<String, dynamic>) return;

    profileData = data;
    await _userSession.saveProfile(data);
    update();
  }
}
