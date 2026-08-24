import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/models/social_user_card.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/repo/chat/models/chat_room_model.dart';
import 'package:qobo_one_live/services/chat/chat_logger.dart';
import 'package:qobo_one_live/services/firebase/firebase_bootstrap.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// Keeps Firebase Auth in sync with the REST JWT session for Firestore access.
class ChatSessionService extends GetxController {
  ChatSessionService({ChatRepo? chatRepo}) : _chatRepo = chatRepo ?? ChatRepo();

  final ChatRepo _chatRepo;

  Future<bool>? _signInFuture;

  /// Call after REST login or when opening chat.
  Future<bool> ensureSignedIn({bool isShowLoader = false}) async {
    if (!FirebaseBootstrap.isAvailable) {
      await FirebaseBootstrap.tryInitialize();
    }
    if (!FirebaseBootstrap.isAvailable) {
      ChatLogger.sessionWarn('Firebase not available on this platform');
      return false;
    }

    final appUserId = _appUserId;
    if (appUserId.isEmpty) {
      ChatLogger.sessionWarn('skipped — empty app userId');
      return false;
    }

    final current = FirebaseAuth.instance.currentUser;
    if (current != null) {
      if (current.uid == appUserId) {
        ChatLogger.session('already signed in', {'uid': current.uid});
        return true;
      }
      ChatLogger.sessionWarn('uid mismatch — re-signing in', {
        'firebaseUid': current.uid,
        'appUserId': appUserId,
      });
      await FirebaseAuth.instance.signOut();
    }

    // Wait for an in-flight sign-in instead of returning false (fixes send race).
    if (_signInFuture != null) {
      return _signInFuture!;
    }

    _signInFuture = _signIn(appUserId: appUserId, isShowLoader: isShowLoader);
    try {
      return await _signInFuture!;
    } finally {
      _signInFuture = null;
    }
  }

  Future<bool> _signIn({
    required String appUserId,
    required bool isShowLoader,
  }) async {
    try {
      final response = await _chatRepo.getFirebaseToken(
        isShowLoader: isShowLoader,
      );
      if (!isSocialApiSuccess(response)) {
        ChatLogger.apiWarn('POST /api/chat/firebase-token', 'failed', {
          'message': response?['message']?.toString() ?? 'unknown',
        });
        return false;
      }

      final tokenModel = FirebaseTokenModel.fromResponseData(response?['data']);
      if (tokenModel.firebaseCustomToken.isEmpty) {
        ChatLogger.sessionWarn('empty custom token from API');
        return false;
      }

      if (tokenModel.firebaseUid.isNotEmpty &&
          tokenModel.firebaseUid != appUserId) {
        ChatLogger.sessionWarn('firebaseUid mismatch in token response', {
          'tokenUid': tokenModel.firebaseUid,
          'appUserId': appUserId,
        });
      }

      await FirebaseAuth.instance.signInWithCustomToken(
        tokenModel.firebaseCustomToken,
      );
      ChatLogger.session('signed in', {
        'uid': FirebaseAuth.instance.currentUser?.uid ?? appUserId,
      });
      return true;
    } catch (e) {
      ChatLogger.sessionWarn('sign-in exception', {'error': e});
      LoggerUtils.logException('ChatSessionService.ensureSignedIn', e);
      return false;
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
