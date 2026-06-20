import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/repo/chat/models/chat_room_model.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_logger.dart';
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
    String? roomId,
    bool showLoader = true,
    ChatRepo? chatRepo,
  }) async {
    if (targetId.isEmpty) {
      _toastError(context, 'Invalid chat partner');
      return;
    }

    try {
      ChatLogger.bootstrap('navigate openDirectChat', {
        'targetId': targetId,
        'roomId': roomId ?? '',
        'name': name,
      });
      await _ensureFirebaseSession();

      final repo = chatRepo ?? ChatRepo();
      var resolvedRoomId = roomId?.trim() ?? '';
      var firestorePath = '';

      if (resolvedRoomId.isNotEmpty) {
        firestorePath = 'chatRooms/$resolvedRoomId';
      } else {
        final roomResponse = await repo.createRoom(
          targetId: targetId,
          isShowLoader: showLoader,
        );

        if (isSocialApiSuccess(roomResponse)) {
          final room = ChatRoomModel.fromResponseData(roomResponse?['data']);
          resolvedRoomId = room.roomId;
          firestorePath = room.firestorePath.isNotEmpty
              ? room.firestorePath
              : 'chatRooms/${room.roomId}';
        } else {
          _toastError(
            context,
            roomResponse?['message']?.toString() ??
                'Could not open chat. Check follow status or try again.',
          );
          return;
        }
      }

      if (resolvedRoomId.isEmpty) {
        _toastError(context, 'Chat room is not ready yet');
        return;
      }

      await Get.toNamed(
        Routes.CHAT_DETAIL,
        arguments: {
          'targetId': targetId,
          'roomId': resolvedRoomId,
          'firestorePath': firestorePath,
          'name': name,
          'imageUrl': imageUrl,
        },
      );
    } catch (e) {
      _toastError(context, 'Error opening chat: $e');
    }
  }

  static void _toastError(BuildContext context, String message) {
    final ctx = _activeContext(context);
    if (ctx == null) return;
    AppToast.showError(ctx, message);
  }

  static BuildContext? _activeContext(BuildContext context) {
    if (context.mounted) return context;
    final root = Get.context;
    if (root != null && root.mounted) return root;
    return null;
  }

  static Future<void> _ensureFirebaseSession() async {
    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    await Get.find<ChatSessionService>().ensureSignedIn();
  }
}
