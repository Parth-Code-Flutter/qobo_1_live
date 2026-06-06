import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';

import '../../messages_tab/models/social_user_card.dart';

class ChatMessageModel {
  ChatMessageModel({
    required this.text,
    required this.isMe,
    required this.time,
  });

  final String text;
  final bool isMe;
  final String time;
}

class ChatDetailController extends GetxController {
  ChatDetailController({ChatRepo? chatRepo})
      : _chatRepo = chatRepo ?? ChatRepo();

  final ChatRepo _chatRepo;

  final chatName = 'Chat'.obs;
  final chatImageUrl = RxnString();
  final targetId = ''.obs;

  final messages = <ChatMessageModel>[].obs;
  final isLoading = false.obs;
  final messageController = TextEditingController();

  String? get _myUserId {
    if (!Get.isRegistered<UserSessionController>()) return null;
    return Get.find<UserSessionController>().userId;
  }

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is Map) {
      if (args['name'] != null) chatName.value = args['name'].toString();
      if (args['imageUrl'] != null) {
        chatImageUrl.value = ApiImageUtils.normalize(
          args['imageUrl']?.toString(),
        );
      }
      if (args['targetId'] != null) {
        targetId.value = args['targetId'].toString();
      }
    }
    if (targetId.value.isNotEmpty) {
      loadHistory();
    }
  }

  Future<void> loadHistory() async {
    if (targetId.value.isEmpty) return;
    try {
      isLoading.value = true;
      final response = await _chatRepo.getConversation(
        targetId: targetId.value,
        isShowLoader: false,
      );
      if (isSocialApiSuccess(response)) {
        final list = response?['data'];
        if (list is List) {
          final myId = _myUserId ?? '';
          messages.assignAll(
            list.whereType<Map>().map((raw) {
              final json = Map<String, dynamic>.from(raw);
              final senderId = json['senderId']?.toString() ?? '';
              return ChatMessageModel(
                text: json['content']?.toString() ?? '',
                isMe: myId.isNotEmpty && senderId == myId,
                time: _formatTime(json['createdAt']?.toString()),
              );
            }),
          );
        }
      }
    } catch (_) {
      // Keep empty or prior messages on failure.
    } finally {
      isLoading.value = false;
    }
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;
    messages.add(
      ChatMessageModel(
        text: messageController.text.trim(),
        isMe: true,
        time: 'Now',
      ),
    );
    messageController.clear();
    // Real-time send via Firestore/WS in a later phase.
  }

  static String _formatTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return raw;
    }
  }

  @override
  void onClose() {
    messageController.dispose();
    super.onClose();
  }
}
