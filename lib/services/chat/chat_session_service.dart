import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/repo/chat/models/chat_room_model.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// Keeps Firebase Auth in sync with the REST JWT session for Firestore access.
class ChatSessionService extends GetxController {
  ChatSessionService({ChatRepo? chatRepo})
      : _chatRepo = chatRepo ?? ChatRepo();

  final ChatRepo _chatRepo;

  bool _isSigningIn = false;

  /// Call after REST login or when opening chat.
  Future<bool> ensureSignedIn({bool isShowLoader = false}) async {
    if (_isSigningIn) return false;

    if (!FirebaseBootstrap.isAvailable) {
      return false;
    }

    final appUserId = _appUserId;
    if (appUserId.isEmpty) {
      return false;
    }

    _isSigningIn = true;
    try {
      if (FirebaseAuth.instance.currentUser != null) return true;

      final response = await _chatRepo.getFirebaseToken(
        isShowLoader: isShowLoader,
      );
      if (!isSocialApiSuccess(response)) {
        LoggerUtils.logWarning(
          'ChatSessionService: firebase-token failed — ${response?['message']}',
        );
        return false;
      }

      final tokenModel = FirebaseTokenModel.fromResponseData(response?['data']);
      if (tokenModel.firebaseCustomToken.isEmpty) {
        LoggerUtils.logWarning('ChatSessionService: empty custom token');
        return false;
      }

      if (tokenModel.firebaseUid.isNotEmpty &&
          tokenModel.firebaseUid != appUserId) {
        LoggerUtils.logWarning(
          'ChatSessionService: firebaseUid mismatch app user id',
        );
      }

      await FirebaseAuth.instance.signInWithCustomToken(
        tokenModel.firebaseCustomToken,
      );
      LoggerUtils.logInfo('ChatSessionService: Firebase signed in');
      return true;
    } catch (e) {
      LoggerUtils.logException('ChatSessionService.ensureSignedIn', e);
      return false;
    } finally {
      _isSigningIn = false;
    }
  }

  Future<void> signOut() async {
    if (!FirebaseBootstrap.isAvailable) return;
    try {
      if (FirebaseAuth.instance.currentUser != null) {
        await FirebaseAuth.instance.signOut();
      }
    } catch (e) {
      LoggerUtils.logException('ChatSessionService.signOut', e);
    }
  }

  String get _appUserId {
    if (!Get.isRegistered<UserSessionController>()) return '';
    return Get.find<UserSessionController>().userId;
  }
}
