import 'package:get/get.dart';

class VisitorsController extends GetxController {
  final visitors = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadVisitors();
  }

  void loadVisitors() async {
    isLoading.value = true;
    visitors.clear();
    isLoading.value = false;
  }

  void toggleFollow(int index) {
    final visitor = visitors[index];
    visitor['isFollowing'] = !visitor['isFollowing'];
    visitors[index] = Map<String, dynamic>.from(visitor);
  }
}
