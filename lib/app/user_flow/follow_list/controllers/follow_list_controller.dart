import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';

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
    _mockData();
  }

  void _mockData() {
    followingList.addAll([
      {'name': 'Emma', 'image': kImgTemp2, 'isFollowing': true},
      {'name': 'Ava', 'image': kImgTemp3, 'isFollowing': true},
      {'name': 'Sophia', 'image': kImgTemp4, 'isFollowing': true},
    ]);

    followersList.addAll([
      {'name': 'John Borino', 'image': kImgTemp4, 'isFollowing': false},
      {'name': 'Emma', 'image': kImgTemp2, 'isFollowing': true},
      {'name': 'Borsha', 'image': kImgTemp5, 'isFollowing': false},
      {'name': 'Afrin Sabila', 'image': kImgTemp1, 'isFollowing': true},
    ]);
  }

  void changeTab(int index) {
    tabIndex.value = index;
  }

  void toggleFollow(int listIndex, bool isFollowingTab) {
    if (isFollowingTab) {
      // Unfollow logic natively
      followingList[listIndex]['isFollowing'] = !followingList[listIndex]['isFollowing'];
      followingList.refresh();
    } else {
      followersList[listIndex]['isFollowing'] = !followersList[listIndex]['isFollowing'];
      followersList.refresh();
    }
  }
}
