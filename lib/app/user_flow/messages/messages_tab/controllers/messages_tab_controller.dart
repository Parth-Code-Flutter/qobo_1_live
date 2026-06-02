import 'package:get/get.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';

import '../widgets/messages_common_widgets.dart';

/// Messages tab: new matches + inbox (inbox wired later).
class MessagesTabController extends GetxController {
  MessagesTabController({AuthRepo? authRepo}) : _authRepo = authRepo ?? AuthRepo();

  final AuthRepo _authRepo;

  final newMatches = <MessageMatchUser>[].obs;
  final isNewMatchesLoading = false.obs;

  static const _fallbackImages = [kImgTemp2, kImgTemp3, kImgTemp4, kImgTemp5];

  @override
  void onInit() {
    super.onInit();
    fetchNewMatches();
  }

  /// Loads suggested / new users for the horizontal "New Match" row.
  Future<void> fetchNewMatches() async {
    try {
      isNewMatchesLoading.value = true;
      final response = await _authRepo.searchUsers(query: 'a');
      if (response != null && response['statusCode'] == 1) {
        final list = response['data'];
        if (list is List) {
          newMatches.assignAll(
            list.whereType<Map>().toList().asMap().entries.map((entry) {
              return _mapToMatchUser(
                Map<String, dynamic>.from(entry.value),
                entry.key,
              );
            }).take(12),
          );
          return;
        }
      }
      newMatches.clear();
    } catch (_) {
      newMatches.clear();
    } finally {
      isNewMatchesLoading.value = false;
    }
  }

  MessageMatchUser _mapToMatchUser(Map<String, dynamic> user, int index) {
    final name = user['name']?.toString().trim();
    return MessageMatchUser(
      name: name != null && name.isNotEmpty ? name : 'User',
      imagePath: _fallbackImages[index % _fallbackImages.length],
      imageUrl: ApiImageUtils.normalize(user['displayPicture']?.toString()),
    );
  }
}
