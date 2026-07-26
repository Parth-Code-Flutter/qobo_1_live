import 'dart:async';

import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/services/firebase/join_request_payload.dart';
import 'package:qobo_one_live/services/realtime/user_realtime_socket_service.dart';
import 'package:qobo_one_live/utils/app_widgets/join_request_waiting_dialog.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// Coordinates viewer join-request waits across socket / FCM / polling.
abstract final class JoinRequestWaitRegistry {
  JoinRequestWaitRegistry._();

  static final Map<String, Completer<JoinRequestWaitOutcome>> _pending = {};

  static Completer<JoinRequestWaitOutcome> register(String requestId) {
    final id = requestId.trim();
    final existing = _pending[id];
    if (existing != null && !existing.isCompleted) return existing;
    final completer = Completer<JoinRequestWaitOutcome>();
    _pending[id] = completer;
    return completer;
  }

  static void complete(String requestId, JoinRequestWaitOutcome outcome) {
    final id = requestId.trim();
    if (id.isEmpty) return;
    final completer = _pending.remove(id);
    if (completer != null && !completer.isCompleted) {
      completer.complete(outcome);
    }
  }

  static void completeIfPending(
    String requestId,
    JoinRequestWaitOutcome outcome,
  ) {
    final id = requestId.trim();
    final completer = _pending[id];
    if (completer == null || completer.isCompleted) return;
    _pending.remove(id);
    completer.complete(outcome);
  }

  static void cancelLocal(String requestId) {
    completeIfPending(
      requestId,
      JoinRequestWaitOutcome(
        result: JoinRequestWaitResult.cancelled,
        requestId: requestId,
        message: 'Cancelled',
      ),
    );
  }
}

/// Shared guest join gate: direct join vs host-approval wait.
class JoinApprovalService {
  JoinApprovalService({RoomRepo? roomRepo}) : _roomRepo = roomRepo ?? RoomRepo();

  final RoomRepo _roomRepo;

  static bool isApprovalRequired(Map<String, dynamic>? room) {
    if (room == null) return false;
    final nested = room['roomData'] is Map
        ? Map<String, dynamic>.from(room['roomData'] as Map)
        : null;
    return _truthy(room['joinApprovalRequired']) ||
        _truthy(room['join_approval_required']) ||
        (nested != null &&
            (_truthy(nested['joinApprovalRequired']) ||
                _truthy(nested['join_approval_required'])));
  }

  static String sessionTypeFor({
    String? roomType,
    String? type,
    bool isLiveStream = false,
  }) {
    if (isLiveStream) return 'live_stream';
    final raw = (roomType ?? type ?? '').trim().toLowerCase();
    if (raw.contains('live')) return 'live_stream';
    if (raw.contains('audio')) return 'audio_room';
    if (raw.contains('video')) return 'video_room';
    return 'audio_room';
  }

  static String? roomIdFrom(Map<String, dynamic>? room) {
    if (room == null) return null;
    final nested = room['roomData'] is Map
        ? Map<String, dynamic>.from(room['roomData'] as Map)
        : null;
    return _text(room['room_id']) ??
        _text(room['roomId']) ??
        _text(room['_id']) ??
        _text(room['id']) ??
        (nested == null
            ? null
            : (_text(nested['room_id']) ??
                _text(nested['roomId']) ??
                _text(nested['_id']) ??
                _text(nested['id'])));
  }

  static bool isApiSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    final code = response['statusCode'];
    return code == 1 || code == 200 || code == 201 || code == true;
  }

  static bool isApprovalRequiredError(Map<String, dynamic>? response) {
    if (response == null) return false;
    final code =
        response['code']?.toString() ??
        response['errorCode']?.toString() ??
        (response['data'] is Map
            ? (response['data'] as Map)['code']?.toString()
            : null) ??
        '';
    if (code.toUpperCase() == 'APPROVAL_REQUIRED') return true;
    final message = response['message']?.toString().toLowerCase() ?? '';
    return message.contains('approval required') ||
        message.contains('waiting for host approval');
  }

  /// Join with optional host-approval gate. Returns the `/join` response map
  /// (or auto-joined join-request payload) on success.
  Future<Map<String, dynamic>?> joinWithApprovalGate({
    required String roomId,
    required String sessionType,
    Map<String, dynamic>? roomHint,
    String? password,
    String? invitationId,
    bool forceApprovalFlow = false,
    bool isShowLoader = true,
  }) async {
    await UserRealtimeSocketService.ensureConnected();

    final needsApproval =
        forceApprovalFlow || isApprovalRequired(roomHint);

    if (!needsApproval) {
      final direct = await _roomRepo.joinRoom(
        roomId: roomId,
        password: password,
        invitationId: invitationId,
        sessionType: sessionType,
        isShowLoader: isShowLoader,
      );
      if (isApiSuccess(direct)) return direct;
      if (!isApprovalRequiredError(direct)) return direct;
      // Fall through to join-request when backend gates `/join`.
    }

    final requestResponse = await _roomRepo.createJoinRequest(
      roomId: roomId,
      sessionType: sessionType,
      isShowLoader: isShowLoader,
    );
    if (!isApiSuccess(requestResponse)) {
      return requestResponse;
    }

    final data = requestResponse?['data'];
    final dataMap = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final status = (dataMap['status']?.toString() ?? '').toLowerCase();

    // Approval not required / already approved → use embedded join payload.
    if (status == 'approved' || dataMap['auto_joined'] == true) {
      final join = dataMap['join'];
      if (join is Map) {
        return <String, dynamic>{
          'statusCode': 1,
          'message': requestResponse?['message'] ?? 'Joined',
          'data': Map<String, dynamic>.from(join),
        };
      }
      // Already approved — proceed to normal join with request id.
      final approvedId =
          _text(dataMap['request_id']) ?? _text(dataMap['requestId']);
      if (approvedId != null) {
        return _roomRepo.joinRoom(
          roomId: roomId,
          password: password,
          invitationId: invitationId,
          joinRequestId: approvedId,
          sessionType: sessionType,
          isShowLoader: isShowLoader,
        );
      }
    }

    final requestId =
        _text(dataMap['request_id']) ?? _text(dataMap['requestId']) ?? '';
    if (requestId.isEmpty) {
      LoggerUtils.logWarning('JoinApproval: pending response missing request_id');
      return requestResponse;
    }

    final pollAfterMs =
        int.tryParse(dataMap['poll_after_ms']?.toString() ?? '') ?? 2000;
    final expiresAt = DateTime.tryParse(
      dataMap['expires_at']?.toString() ??
          dataMap['expiresAt']?.toString() ??
          '',
    );

    final waitOutcome = await JoinRequestWaitingDialog.showAndWait(
      roomId: roomId,
      requestId: requestId,
      sessionType: sessionType,
      expiresAt: expiresAt,
      pollAfterMs: pollAfterMs,
      roomRepo: _roomRepo,
    );

    if (!waitOutcome.isApproved) {
      return <String, dynamic>{
        'statusCode': 0,
        'message': waitOutcome.message.isNotEmpty
            ? waitOutcome.message
            : _defaultWaitMessage(waitOutcome.result),
        'data': <String, dynamic>{
          'request_id': requestId,
          'status': waitOutcome.result.name,
        },
      };
    }

    return _roomRepo.joinRoom(
      roomId: roomId,
      password: password,
      invitationId: invitationId,
      joinRequestId: requestId,
      sessionType: sessionType,
      isShowLoader: isShowLoader,
    );
  }

  static String _defaultWaitMessage(JoinRequestWaitResult result) {
    switch (result) {
      case JoinRequestWaitResult.rejected:
        return 'Host declined your request to join';
      case JoinRequestWaitResult.expired:
        return 'Your join request expired. Try again.';
      case JoinRequestWaitResult.cancelled:
        return 'Join request cancelled';
      case JoinRequestWaitResult.failed:
        return 'Could not join room';
      case JoinRequestWaitResult.approved:
        return 'Approved';
    }
  }

  static bool _truthy(dynamic value) {
    if (value == true || value == 1) return true;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  static String? _text(dynamic value) {
    final text = value?.toString().trim();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }
}

/// Convenience for call sites that already have a [BuildContext].
Future<Map<String, dynamic>?> joinRoomWithApprovalGate({
  required String roomId,
  required String sessionType,
  Map<String, dynamic>? roomHint,
  String? password,
  String? invitationId,
  bool forceApprovalFlow = false,
  bool isShowLoader = true,
  JoinApprovalService? service,
}) {
  final joinService = service ?? JoinApprovalService();
  return joinService.joinWithApprovalGate(
    roomId: roomId,
    sessionType: sessionType,
    roomHint: roomHint,
    password: password,
    invitationId: invitationId,
    forceApprovalFlow: forceApprovalFlow,
    isShowLoader: isShowLoader,
  );
}
