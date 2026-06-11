import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';

class BlockListController extends GetxController {
  BlockListController({UserRepo? userRepo}) : _userRepo = userRepo ?? UserRepo();

  final UserRepo _userRepo;

  final blockedUsers = <Map<String, dynamic>>[].obs;
  final isLoading = false.obs;
  final processingUserId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchBlockList();
  }

  Future<void> fetchBlockList() async {
    try {
      isLoading.value = true;
      final response = await _userRepo.getBlockList(isShowLoader: false);
      if (!isSocialApiSuccess(response)) {
        blockedUsers.clear();
        return;
      }

      final list = response?['data'];
      if (list is! List) {
        blockedUsers.clear();
        return;
      }

      blockedUsers.assignAll(
        list.whereType<Map>().map((raw) {
          final json = Map<String, dynamic>.from(raw);
          return {
            'id': json['id']?.toString() ?? '',
            'name': json['name']?.toString() ?? 'User',
            'displayPicture': ApiImageUtils.normalize(
              json['displayPicture']?.toString(),
            ),
          };
        }).where((u) => u['id'].toString().isNotEmpty),
      );
    } catch (_) {
      blockedUsers.clear();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> unblockUser(int index) async {
    if (index < 0 || index >= blockedUsers.length) return;
    final user = blockedUsers[index];
    final userId = user['id']?.toString() ?? '';
    if (userId.isEmpty) return;

    processingUserId.value = userId;
    try {
      final response = await _userRepo.unblockUser(
        targetId: userId,
        isShowLoader: false,
      );
      if (isSocialApiSuccess(response)) {
        blockedUsers.removeAt(index);
        Get.snackbar('Unblocked', '${user['name']} has been unblocked.');
        return;
      }
      Get.snackbar(
        'Error',
        response?['message']?.toString() ?? 'Could not unblock user',
      );
    } catch (e) {
      Get.snackbar('Error', 'Could not unblock user: $e');
    } finally {
      processingUserId.value = '';
    }
  }
}
