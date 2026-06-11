import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/chat/chat_local_store.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/text_utils/text_styles.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// WhatsApp-style contact info for a 1:1 chat partner.
class ChatContactProfileController extends GetxController {
  ChatContactProfileController({
    ChatRepo? chatRepo,
    ChatLocalStore? localStore,
    UserRepo? userRepo,
  })  : _chatRepo = chatRepo ?? ChatRepo(),
        _localStore = localStore ?? ChatLocalStore(),
        _userRepo = userRepo ?? UserRepo();

  final ChatRepo _chatRepo;
  final ChatLocalStore _localStore;
  final UserRepo _userRepo;

  final name = 'User'.obs;
  final imageUrl = RxnString();
  final targetId = ''.obs;
  final roomId = ''.obs;
  final presenceLabel = 'Offline'.obs;
  final presenceColor = kColorHint.obs;
  final bio = ''.obs;
  final country = ''.obs;
  final level = 0.obs;
  final isLoadingProfile = false.obs;
  final isActionInFlight = false.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['name'] != null) name.value = args['name'].toString();
      if (args['targetId'] != null) targetId.value = args['targetId'].toString();
      if (args['roomId'] != null) roomId.value = args['roomId'].toString();
      if (args['imageUrl'] != null) {
        imageUrl.value = ApiImageUtils.normalize(args['imageUrl']?.toString());
      }
      if (args['presenceLabel'] != null) {
        presenceLabel.value = args['presenceLabel'].toString();
      }
      if (args['presenceColor'] is Color) {
        presenceColor.value = args['presenceColor'] as Color;
      }
    }
    _loadPublicProfile();
  }

  Future<void> _loadPublicProfile() async {
    if (targetId.value.isEmpty) return;
    try {
      isLoadingProfile.value = true;
      final response = await _userRepo.getPublicProfile(
        userId: targetId.value,
        isShowLoader: false,
      );
      if (!isSocialApiSuccess(response) || response?['data'] is! Map) return;

      final data = Map<String, dynamic>.from(response!['data'] as Map);
      final profile = SocialUserCard.fromJson(data);
      if (profile.name.isNotEmpty) name.value = profile.name;
      if (profile.displayPicture != null && profile.displayPicture!.isNotEmpty) {
        imageUrl.value = profile.displayPicture;
      }
      if (profile.bio.isNotEmpty) bio.value = profile.bio;
      if (profile.country.isNotEmpty) country.value = profile.country;
      if (profile.level > 0) level.value = profile.level;
    } catch (_) {
    } finally {
      isLoadingProfile.value = false;
    }
  }

  Future<void> deleteChat(BuildContext context) async {
    if (targetId.value.isEmpty || isActionInFlight.value) return;

    final confirmed = await _confirmAction(
      context,
      title: 'Delete chat?',
      message:
          'This removes the conversation from your inbox. ${name.value} can still message you.',
    );
    if (!confirmed || !context.mounted) return;

    isActionInFlight.value = true;
    try {
      final response = await _chatRepo.deleteChat(
        targetId: targetId.value,
        roomId: roomId.value.isNotEmpty ? roomId.value : null,
      );
      if (!context.mounted) return;

      if (isSocialApiSuccess(response)) {
        await _localStore.removeInboxThread(targetId.value);
        await _localStore.clearMessagesForTarget(targetId.value);
        _popToMessagesTab();
        AppToast.showSuccess(context, 'Chat deleted');
        return;
      }

      AppToast.showError(
        context,
        response?['message']?.toString() ?? 'Could not delete chat',
      );
    } catch (e) {
      if (!context.mounted) return;
      AppToast.showError(context, 'Error deleting chat: $e');
    } finally {
      isActionInFlight.value = false;
    }
  }

  Future<void> blockUser(BuildContext context) async {
    if (targetId.value.isEmpty || isActionInFlight.value) return;

    final confirmed = await _confirmAction(
      context,
      title: 'Block ${name.value}?',
      message:
          'They will no longer be able to message you. You can unblock them from Settings > Block List.',
    );
    if (!confirmed || !context.mounted) return;

    isActionInFlight.value = true;
    try {
      final response = await _chatRepo.blockUserFromChat(
        targetId: targetId.value,
        roomId: roomId.value.isNotEmpty ? roomId.value : null,
        deleteChat: true,
      );
      if (!context.mounted) return;

      if (isSocialApiSuccess(response)) {
        await _localStore.removeInboxThread(targetId.value);
        await _localStore.clearMessagesForTarget(targetId.value);
        _popToMessagesTab();
        AppToast.showSuccess(context, '${name.value} blocked');
        return;
      }

      AppToast.showError(
        context,
        response?['message']?.toString() ?? 'Could not block user',
      );
    } catch (e) {
      if (!context.mounted) return;
      AppToast.showError(context, 'Error blocking user: $e');
    } finally {
      isActionInFlight.value = false;
    }
  }

  void _popToMessagesTab() {
    Get.until(
      (route) =>
          route.settings.name == Routes.BOTTOM_NAV ||
          route.settings.name == Routes.CHAT_DETAIL,
    );
    if (Get.currentRoute == Routes.CHAT_DETAIL) {
      Get.back();
    }
  }

  static Future<bool> _confirmAction(
    BuildContext context, {
    required String title,
    required String message,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: kColorWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: TextStyles.kSemiBoldPoppins(
            fontSize: TextStyles.k16FontSize,
            colors: kColorText,
          ),
        ),
        content: Text(
          message,
          style: TextStyles.kRegularPoppins(
            fontSize: TextStyles.k14FontSize,
            colors: kColorHint,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    return result == true;
  }
}
