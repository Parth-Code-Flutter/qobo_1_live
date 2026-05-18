import 'package:get/get.dart';

class VisitorsController extends GetxController {
  final visitors = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadMockVisitors();
  }

  void loadMockVisitors() async {
    isLoading.value = true;
    await Future<void>.delayed(const Duration(milliseconds: 800));
    visitors.assignAll([
      {
        'name': 'Sarah Connor',
        'avatar': 'assets/images/temp_img_2.png', // Fallback to temp images
        'time': '2 minutes ago',
        'isFollowing': false,
        'level': 12,
        'vip': 'SVIP',
      },
      {
        'name': 'Alex Mercer',
        'avatar': 'assets/images/temp_img_4.png',
        'time': '1 hour ago',
        'isFollowing': true,
        'level': 25,
        'vip': 'VIP',
      },
      {
        'name': 'Bruce Wayne',
        'avatar': 'assets/images/temp_img_3.png',
        'time': '3 hours ago',
        'isFollowing': false,
        'level': 45,
        'vip': 'SVIP',
      },
      {
        'name': 'Diana Prince',
        'avatar': 'assets/images/temp_img_2.png',
        'time': 'Yesterday',
        'isFollowing': false,
        'level': 8,
        'vip': '',
      },
      {
        'name': 'Tony Stark',
        'avatar': 'assets/images/temp_img_4.png',
        'time': '2 days ago',
        'isFollowing': true,
        'level': 60,
        'vip': 'SVIP',
      },
    ]);
    isLoading.value = false;
  }

  void toggleFollow(int index) {
    final visitor = visitors[index];
    visitor['isFollowing'] = !visitor['isFollowing'];
    visitors[index] = Map<String, dynamic>.from(visitor);
  }
}
