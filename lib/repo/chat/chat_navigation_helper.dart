import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/repo/chat/models/chat_room_model.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';

/// Shared flow: bootstrap chat room, then open detail screen.
abstract final class ChatNavigationHelper {
  ChatNavigationHelper._();

  static Future<void> openDirectChat(
    BuildContext context, {
    required String targetId,
    required String name,
    String? imageUrl,
    bool showLoader = true,
    ChatRepo? chatRepo,
  }) async {
    if (targetId.isEmpty) {
      AppToast.showError(context, 'Invalid chat partner');
      return;
    }

    try {
      // Best-effort — REST chat still works if Firebase config is missing.
      await _ensureFirebaseSession();

      final repo = chatRepo ?? ChatRepo();
      var roomId = '';
      var firestorePath = '';

      final roomResponse = await repo.createRoom(
        targetId: targetId,
        isShowLoader: showLoader,
      );

      if (isSocialApiSuccess(roomResponse)) {
        final room = ChatRoomModel.fromResponseData(roomResponse?['data']);
        roomId = room.roomId;
        firestorePath = room.firestorePath;
      } else if (context.mounted) {
        AppToast.showError(
          context,
          roomResponse?['message']?.toString() ??
              'Could not open chat. Check follow status or try again.',
        );
        return;
      }

      if (!context.mounted) return;
      await Get.toNamed(
        Routes.CHAT_DETAIL,
        arguments: {
          'targetId': targetId,
          'roomId': roomId,
          'firestorePath': firestorePath,
          'name': name,
          'imageUrl': imageUrl,
        },
      );
    } catch (e) {
      if (!context.mounted) return;
      AppToast.showError(context, 'Error opening chat: $e');
    }
  }

  static Future<void> _ensureFirebaseSession() async {
    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    await Get.find<ChatSessionService>().ensureSignedIn();
  }
}
