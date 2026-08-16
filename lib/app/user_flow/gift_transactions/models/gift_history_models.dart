import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';

/// Backend `type` values for `GET /api/economy/gift-history`.
enum GiftHistoryType {
  audioRoom('audio_room', 'Audio'),
  liveStream('live_stream', 'Live'),
  pk('pk', 'PK'),
  call('call', 'Call');

  const GiftHistoryType(this.apiValue, this.label);

  final String apiValue;
  final String label;

  static GiftHistoryType fromApi(String? raw) {
    final value = (raw ?? '').trim().toLowerCase();
    for (final type in GiftHistoryType.values) {
      if (type.apiValue == value) return type;
    }
    if (value.contains('audio') || value.contains('video_room')) {
      return GiftHistoryType.audioRoom;
    }
    if (value.contains('live')) return GiftHistoryType.liveStream;
    if (value.contains('pk')) return GiftHistoryType.pk;
    if (value.contains('call')) return GiftHistoryType.call;
    return GiftHistoryType.audioRoom;
  }
}

class GiftHistorySummary {
  const GiftHistorySummary({
    required this.audioCount,
    required this.audioCoins,
    required this.liveCount,
    required this.liveCoins,
    required this.pkCount,
    required this.pkCoins,
    required this.callCount,
    required this.callCoins,
  });

  final int audioCount;
  final int audioCoins;
  final int liveCount;
  final int liveCoins;
  final int pkCount;
  final int pkCoins;
  final int callCount;
  final int callCoins;

  factory GiftHistorySummary.empty() => const GiftHistorySummary(
    audioCount: 0,
    audioCoins: 0,
    liveCount: 0,
    liveCoins: 0,
    pkCount: 0,
    pkCoins: 0,
    callCount: 0,
    callCoins: 0,
  );

  factory GiftHistorySummary.fromJson(Map<String, dynamic>? data) {
    if (data == null) return GiftHistorySummary.empty();
    final audio = _bucket(data, const ['audio_room', 'audioRoom', 'audio']);
    final live = _bucket(data, const [
      'live_stream',
      'liveStream',
      'live',
    ]);
    final pk = _bucket(data, const ['pk']);
    final call = _bucket(data, const ['call']);
    return GiftHistorySummary(
      audioCount: audio.count,
      audioCoins: audio.coins,
      liveCount: live.count,
      liveCoins: live.coins,
      pkCount: pk.count,
      pkCoins: pk.coins,
      callCount: call.count,
      callCoins: call.coins,
    );
  }

  int countFor(GiftHistoryType type) {
    switch (type) {
      case GiftHistoryType.audioRoom:
        return audioCount;
      case GiftHistoryType.liveStream:
        return liveCount;
      case GiftHistoryType.pk:
        return pkCount;
      case GiftHistoryType.call:
        return callCount;
    }
  }

  int coinsFor(GiftHistoryType type) {
    switch (type) {
      case GiftHistoryType.audioRoom:
        return audioCoins;
      case GiftHistoryType.liveStream:
        return liveCoins;
      case GiftHistoryType.pk:
        return pkCoins;
      case GiftHistoryType.call:
        return callCoins;
    }
  }

  int get totalCount => audioCount + liveCount + pkCount + callCount;
  int get totalCoins => audioCoins + liveCoins + pkCoins + callCoins;

  static ({int count, int coins}) _bucket(
    Map<String, dynamic> data,
    List<String> keys,
  ) {
    Map<String, dynamic>? nested;
    for (final key in keys) {
      final raw = data[key];
      if (raw is Map) {
        nested = Map<String, dynamic>.from(raw);
        break;
      }
    }
    if (nested == null) return (count: 0, coins: 0);
    return (
      count: parseWalletAmount(nested['count'] ?? nested['total']),
      coins: parseWalletAmount(
        nested['coinsSpent'] ?? nested['coins_spent'] ?? nested['coins'],
      ),
    );
  }
}

class GiftHistoryItem {
  const GiftHistoryItem({
    required this.id,
    required this.giftId,
    required this.giftName,
    required this.giftImage,
    required this.quantity,
    required this.coinsSpent,
    required this.type,
    required this.roomId,
    required this.roomTitle,
    required this.receiverId,
    required this.receiverName,
    required this.receiverAvatar,
    required this.pkId,
    required this.pkSide,
    required this.callId,
    required this.callMode,
    required this.createdAtLabel,
  });

  final String id;
  final String giftId;
  final String giftName;
  final String? giftImage;
  final int quantity;
  final int coinsSpent;
  final GiftHistoryType type;
  final String roomId;
  final String roomTitle;
  final String receiverId;
  final String receiverName;
  final String? receiverAvatar;
  final String pkId;
  final String pkSide;
  final String callId;
  final String callMode;
  final String createdAtLabel;

  factory GiftHistoryItem.fromJson(Map<String, dynamic> raw) {
    String text(List<String> keys) {
      for (final key in keys) {
        final value = raw[key]?.toString().trim();
        if (value != null && value.isNotEmpty && value != 'null') return value;
      }
      return '';
    }

    final giftName = text(['giftName', 'gift_name', 'name']);
    final created = text(['createdAt', 'created_at', 'date', 'timestamp']);
    return GiftHistoryItem(
      id: text(['id', '_id']),
      giftId: text(['giftId', 'gift_id']),
      giftName: giftName.isEmpty ? 'Gift' : giftName,
      giftImage: _nullableUrl(
        text(['giftImage', 'gift_image', 'image', 'icon']),
      ),
      quantity: parseWalletAmount(raw['quantity'] ?? raw['qty'] ?? 1),
      coinsSpent: parseWalletAmount(
        raw['coinsSpent'] ??
            raw['coins_spent'] ??
            raw['coins'] ??
            raw['amount'],
      ),
      type: GiftHistoryType.fromApi(text(['type', 'sessionType', 'session_type'])),
      roomId: text(['roomId', 'room_id']),
      roomTitle: text(['roomTitle', 'room_title', 'title']),
      receiverId: text(['receiverId', 'receiver_id']),
      receiverName: text(['receiverName', 'receiver_name', 'hostName']),
      receiverAvatar: _nullableUrl(
        text(['receiverAvatar', 'receiver_avatar', 'avatar']),
      ),
      pkId: text(['pkId', 'pk_id']),
      pkSide: text(['pkSide', 'pk_side']),
      callId: text(['callId', 'call_id']),
      callMode: text(['callMode', 'call_mode']),
      createdAtLabel: _formatDate(created),
    );
  }

  String get contextSubtitle {
    if (type == GiftHistoryType.pk) {
      final side = pkSide.trim().isEmpty ? '' : ' · ${pkSide.toUpperCase()}';
      return 'PK battle$side';
    }
    if (type == GiftHistoryType.call) {
      final mode = callMode.trim().isEmpty ? 'Call' : '${callMode.trim()} call';
      return mode[0].toUpperCase() + mode.substring(1);
    }
    if (roomTitle.trim().isNotEmpty) return roomTitle.trim();
    if (type == GiftHistoryType.liveStream) return 'Live stream';
    return 'Audio room';
  }

  static String? _nullableUrl(String value) {
    if (value.isEmpty) return null;
    return value;
  }

  static String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    final local = parsed.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    final min = local.minute.toString().padLeft(2, '0');
    return '${months[local.month - 1]} ${local.day}, ${local.year} · $hour:$min $ampm';
  }
}
