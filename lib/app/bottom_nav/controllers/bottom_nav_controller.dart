import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';

/// Controller for bottom-nav state.
class BottomNavController extends GetxController {
  final selectedIndex = 0.obs;
  final _lastNavBarIndex = 0.obs;

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
}
