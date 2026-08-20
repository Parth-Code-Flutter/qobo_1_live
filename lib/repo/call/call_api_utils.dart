import 'package:qobo_one_live/utils/api_response_utils.dart';

bool isCallModuleApiSuccess(Map<String, dynamic>? response) {
  return ApiResponseUtils.isBodySuccess(response);
}

String callModuleApiMessage(Map<String, dynamic>? response, String fallback) {
  return ApiResponseUtils.tryGetMessage(response) ?? fallback;
}

/// Parsed `POST /api/call/direct/start` payload.
class DirectCallStartResult {
  const DirectCallStartResult({
    required this.callId,
    this.coinsPerSecond,
    this.chatRoomId,
  });

  factory DirectCallStartResult.fromResponse(Map<String, dynamic>? response) {
    final data = response?['data'];
    if (data is! Map) {
      return const DirectCallStartResult(callId: '');
    }
    final map = Map<String, dynamic>.from(data);
    final callId = map['zegoCallId']?.toString() ??
        map['callId']?.toString() ??
        map['id']?.toString() ??
        '';
    final coinsRaw = map['coinsPerSecond'] ?? map['coins_per_second'];
    double? coins;
    if (coinsRaw is num) {
      coins = coinsRaw.toDouble();
    } else {
      coins = double.tryParse(coinsRaw?.toString() ?? '');
    }
    final roomId =
        map['roomId']?.toString() ?? map['chatRoomId']?.toString() ?? '';
    return DirectCallStartResult(
      callId: callId.trim(),
      coinsPerSecond: coins != null && coins > 0 ? coins : null,
      chatRoomId: roomId.trim().isEmpty ? null : roomId.trim(),
    );
  }

  final String callId;
  final double? coinsPerSecond;
  final String? chatRoomId;

  bool get isValid => callId.isNotEmpty;
}
