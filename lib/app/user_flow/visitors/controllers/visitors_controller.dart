import 'package:get/get.dart';
import 'package:qobo_one_live/repo/frame/frame_urls.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';

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
          items.whereType<Map>().map(_mapVisitor).where(
                (item) =>
                    item['id'].toString().isNotEmpty ||
                    item['name'].toString().isNotEmpty,
              ),
        );
      } else {
        visitors.clear();
      }
    } finally {
      isLoading.value = false;
    }
  }

  Map<String, dynamic> _mapVisitor(Map raw) {
    final nested = raw['visitor'];
    final profile = nested is Map
        ? Map<String, dynamic>.from(nested)
        : <String, dynamic>{};
    final merged = <String, dynamic>{
      ...profile,
      ...Map<String, dynamic>.from(raw),
    };

    final id = merged['userId']?.toString() ??
        merged['visitorId']?.toString() ??
        merged['id']?.toString() ??
        profile['id']?.toString() ??
        '';

    final visitedAt = merged['visitedAt']?.toString() ??
        merged['visited_at']?.toString() ??
        '';

    return <String, dynamic>{
      'id': id,
      'name': merged['name']?.toString() ??
          merged['userName']?.toString() ??
          'Unknown User',
      'avatarUrl': ApiImageUtils.normalize(
            merged['displayPicture']?.toString() ??
                merged['avatarUrl']?.toString() ??
                merged['avatar']?.toString(),
          ) ??
          '',
      'frameUrl': _pickFrameUrl(merged, profile),
      'country': merged['country']?.toString() ?? '',
      'level': _toInt(merged['level']),
      'vip': merged['vip']?.toString() ?? merged['vipBadge']?.toString() ?? '',
      'time': _formatVisitedAt(visitedAt),
      'isFollowing':
          merged['isFollowing'] == true || merged['following'] == true,
    };
  }

  /// Avatar border only. Entry-frame SVGs stay off the profile circle.
  String? _pickFrameUrl(
    Map<String, dynamic> merged,
    Map<String, dynamic> profile,
  ) {
    return readAvatarFrameUrl(merged) ?? readAvatarFrameUrl(profile);
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
