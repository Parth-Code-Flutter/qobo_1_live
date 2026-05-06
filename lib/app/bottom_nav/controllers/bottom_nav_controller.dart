import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/constants/local_storage_constants.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';

/// Controller for bottom-nav state.
class BottomNavController extends GetxController {
  BottomNavController({AuthRepo? authRepo})
      : _authRepo = authRepo ?? AuthRepo();

  final AuthRepo _authRepo;
  final selectedIndex = 0.obs;
  final _lastNavBarIndex = 0.obs;
  Map<String, dynamic>? profileData;

  /// Keep tabs centralized so view stays clean.
  final items = const <({String label, String iconPath})>[
    (label: 'Discover', iconPath: kIconDiscover),
    (label: 'Live Rooms', iconPath: kIconLiveRoom),
    (label: '', iconPath: kIconHeart),
    (label: 'Messages', iconPath: kIconChat),
    (label: 'Profile', iconPath: kIconUser),
  ];

  /// Tabs rendered by AnimatedBottomNavigationBar (center heart is FAB).
  final navTabIndices = const <int>[0, 1, 3, 4];

  @override
  void onInit() {
    super.onInit();
    _fetchProfileOnInit();
  }

  int navBarIndexFromSelected() {
    // Heart uses center FAB (index 2) and should not force-select
    // any bottom bar tab. Keep previous tab highlighted.
    if (selectedIndex.value == 2) return _lastNavBarIndex.value;
    if (selectedIndex.value <= 1) return selectedIndex.value;
    return selectedIndex.value - 1;
  }

  void onNavBarTabSelected(int navBarIndex) {
    _lastNavBarIndex.value = navBarIndex;
    selectedIndex.value = navTabIndices[navBarIndex];
  }

  void onCenterHeartSelected() {
    selectedIndex.value = 2;
  }

  void onTabSelected(int index) {
    selectedIndex.value = index;
  }

  Future<void> onLogoutPressed() async {
    final storage = Get.isRegistered<LocalStorage>()
        ? Get.find<LocalStorage>()
        : Get.put(LocalStorage(), permanent: true);
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
    final storage = Get.isRegistered<LocalStorage>()
        ? Get.find<LocalStorage>()
        : Get.put(LocalStorage(), permanent: true);
    await storage.writeJsonStorage(kStorageUserData, data);
  }
}
