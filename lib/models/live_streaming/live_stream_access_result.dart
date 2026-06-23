/// Result from `GET /api/live-streaming/verify-access`.
class LiveStreamAccessResult {
  const LiveStreamAccessResult({
    required this.accessAllowed,
    required this.isHost,
    required this.coins,
    this.message = '',
  });

  final bool accessAllowed;
  final bool isHost;
  final double coins;
  final String message;

  static LiveStreamAccessResult? fromApiResponse(Map<String, dynamic>? response) {
    if (response == null) return null;

    final code = response['statusCode'];
    final ok = code == 1 || code == 200 || code == '1' || code == '200';
    if (!ok) {
      return LiveStreamAccessResult(
        accessAllowed: false,
        isHost: false,
        coins: 0,
        message: response['message']?.toString().trim() ?? '',
      );
    }

    final data = response['data'];
    if (data is! Map) {
      return LiveStreamAccessResult(
        accessAllowed: false,
        isHost: false,
        coins: 0,
        message: response['message']?.toString() ?? '',
      );
    }
    final map = Map<String, dynamic>.from(data);
    return LiveStreamAccessResult(
      accessAllowed: map['accessAllowed'] == true,
      isHost: map['isHost'] == true,
      coins: _toDouble(map['coins']),
      message: map['message']?.toString() ??
          response['message']?.toString() ??
          '',
    );
  }

  static double _toDouble(dynamic raw) {
    if (raw is num) return raw.toDouble();
    return double.tryParse(raw?.toString() ?? '') ?? 0;
  }
}
