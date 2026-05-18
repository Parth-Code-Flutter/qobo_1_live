import 'package:get/get.dart';

class LiveModerationController extends GetxController {
  final isLoading = false.obs;

  // Active moderation role
  final adminRole = 'Host/Creator'.obs;

  // Live room viewers list to moderate
  final liveViewers = <Map<String, dynamic>>[
    {'username': 'Usman Ali', 'level': 'Lv 14', 'status': 'Active', 'isMuted': false},
    {'username': 'Sara Khan', 'level': 'Lv 28', 'status': 'Active', 'isMuted': false},
    {'username': 'John Doe', 'level': 'Lv 3', 'status': 'Spamming', 'isMuted': false},
    {'username': 'Amina Malik', 'level': 'Lv 42', 'status': 'Active', 'isMuted': true},
  ].obs;

  // Banned users records
  final bannedUsers = <String>[
    'Spammer_99',
    'Bad_Actor_x',
  ].obs;

  @override
  void onInit() {
    super.onInit();
    loadModerationData();
  }

  void loadModerationData() async {
    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 400));
    isLoading.value = false;
  }

  void toggleMuteUser(int index) {
    final viewer = liveViewers[index];
    final updatedViewer = Map<String, dynamic>.from(viewer);
    updatedViewer['isMuted'] = !(viewer['isMuted'] as bool);
    liveViewers[index] = updatedViewer;

    Get.snackbar(
      updatedViewer['isMuted'] ? 'User Muted' : 'User Unmuted',
      '${viewer['username']} has been ${updatedViewer['isMuted'] ? 'muted' : 'unmuted'} successfully.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void kickUser(int index) {
    final username = liveViewers[index]['username'];
    liveViewers.removeAt(index);
    Get.snackbar(
      'User Kicked!',
      '$username has been removed from this live broadcast room.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void banUser(int index) {
    final username = liveViewers[index]['username'];
    bannedUsers.add(username);
    liveViewers.removeAt(index);
    Get.snackbar(
      'User Banned!',
      '$username has been blacklisted and blocked from joining again.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void issueWarning(int index) {
    final username = liveViewers[index]['username'];
    Get.snackbar(
      'Official Warning Issued!',
      'System warning alert message sent to $username.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
