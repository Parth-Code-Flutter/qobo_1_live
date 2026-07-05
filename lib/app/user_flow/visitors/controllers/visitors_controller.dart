import 'package:get/get.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';

class VisitorsController extends GetxController {
  VisitorsController({UserRepo? userRepo}) : _userRepo = userRepo ?? UserRepo();

  final UserRepo _userRepo;

  final visitors = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadVisitors();
  }

  Future<void> loadVisitors() async {
    isLoading.value = true;
    try {
      final response = await _userRepo.getVisitors(isShowLoader: false);
      final data = response?['data'];
      final items = data is Map ? data['items'] : data;
      if (items is List) {
        visitors.assignAll(
          items.whereType<Map>().map((item) {
            final visitor = Map<String, dynamic>.from(item);
            final visitedAt = visitor['visitedAt']?.toString() ?? '';
            return <String, dynamic>{
              'id':
                  visitor['userId']?.toString() ??
                  visitor['id']?.toString() ??
                  '',
              'name': visitor['name']?.toString() ?? 'Unknown User',
              'avatarUrl': visitor['displayPicture']?.toString() ?? '',
              'country': visitor['country']?.toString() ?? '',
              'level': _toInt(visitor['level']),
              'vip': visitor['vip']?.toString() ?? '',
              'time': _formatVisitedAt(visitedAt),
              'isFollowing': visitor['isFollowing'] == true,
            };
          }),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleFollow(int index) async {
    final visitor = visitors[index];
    final userId = visitor['id']?.toString() ?? '';
    if (userId.isEmpty) return;

    final wasFollowing = visitor['isFollowing'] == true;
    visitor['isFollowing'] = !wasFollowing;
    visitors[index] = Map<String, dynamic>.from(visitor);

    final response = await _userRepo.followUnfollowUser(
      targetId: userId,
      isShowLoader: false,
    );

    if (response == null || response['statusCode'] == 0) {
      visitor['isFollowing'] = wasFollowing;
      visitors[index] = Map<String, dynamic>.from(visitor);
      Get.snackbar('Visitors', 'Could not update follow status.');
    }
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String _formatVisitedAt(String value) {
    if (value.isEmpty) return 'Just now';
    final date = DateTime.tryParse(value);
    if (date == null) return value;
    final diff = DateTime.now().difference(date.toLocal());
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}
