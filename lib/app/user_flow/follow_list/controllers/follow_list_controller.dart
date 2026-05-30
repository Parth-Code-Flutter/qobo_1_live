import 'package:get/get.dart';

class FollowListController extends GetxController {
  final tabIndex = 0.obs;

  final followingList = <Map<String, dynamic>>[].obs;
  final followersList = <Map<String, dynamic>>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args != null && args is Map) {
      if (args.containsKey('initialTab')) {
        tabIndex.value = args['initialTab'];
      }
    }
  }

  void changeTab(int index) {
    tabIndex.value = index;
  }

  void toggleFollow(int listIndex, bool isFollowingTab) {
    if (isFollowingTab) {
      // Unfollow logic natively
      followingList[listIndex]['isFollowing'] =
          !followingList[listIndex]['isFollowing'];
      followingList.refresh();
    } else {
      followersList[listIndex]['isFollowing'] =
          !followersList[listIndex]['isFollowing'];
      followersList.refresh();
    }
  }
}
