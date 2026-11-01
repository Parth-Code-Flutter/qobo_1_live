import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';

/// A confirmed lucky win the backend broadcasts to the current room.
class LuckyGiftRewardNotice {
  const LuckyGiftRewardNotice({
    required this.id,
    required this.winnerId,
    required this.winnerName,
    required this.giftName,
    required this.total,
    required this.bonus,
    required this.combo,
    required this.roomId,
  });

  final String id;
  final String winnerId;
  final String winnerName;
  final String giftName;
  final int total;
  final int bonus;
  final int combo;
  final String roomId;

  String get chatLine {
    final who = winnerName.trim().isEmpty ? 'Someone' : winnerName.trim();
    final gift = giftName.trim().isEmpty ? 'a Lucky gift' : giftName.trim();
    return '$who won $total coins on $gift';
  }

  /// Returns null unless this payload is a real win (coins above zero).
  static LuckyGiftRewardNotice? tryParse(Map<dynamic, dynamic> raw) {
    final data = _unwrap(raw);
    final total = parseWalletAmount(
      _first(data, const [
        'luckyRewardCoins',
        'lucky_reward_coins',
        'rewardCoins',
        'reward_coins',
        'coins',
      ]),
    );
    if (total <= 0) return null;

    final sender =
        _map(data['sender']) ?? _map(data['winner']) ?? _map(data['user']);
    final gift = _map(data['gift']);
    final reward = _map(data['luckyReward']) ?? _map(data['lucky_reward']);

    return LuckyGiftRewardNotice(
      id: _text(data, const [
        'transaction_id',
        'transactionId',
        'clientGiftId',
        'client_gift_id',
        'id',
      ]),
      winnerId:
          _text(sender ?? const {}, const [
            'id',
            'userId',
            'user_id',
            '_id',
          ]).ifEmpty(
            _text(data, const [
              'senderId',
              'sender_id',
              'winnerId',
              'winner_id',
              'userId',
              'user_id',
            ]),
          ),
      winnerName:
          _text(sender ?? const {}, const [
            'name',
            'username',
            'displayName',
            'display_name',
          ]).ifEmpty(
            _text(data, const [
              'senderName',
              'sender_name',
              'winnerName',
              'winner_name',
              'userName',
              'username',
            ]),
          ),
      giftName: _text(gift ?? const {}, const [
        'name',
        'title',
      ]).ifEmpty(_text(data, const ['giftName', 'gift_name'])),
      total: total,
      bonus: parseWalletAmount(
        _first(data, const [
              'luckyRewardBonus',
              'lucky_reward_bonus',
              'rewardBonus',
              'reward_bonus',
            ]) ??
            _first(reward ?? const {}, const ['rewardBonus', 'reward_bonus']),
      ),
      combo: parseWalletAmount(
        _first(data, const ['combo', 'comboCount', 'combo_count']) ??
            _first(reward ?? const {}, const ['currentCombo', 'current_combo']),
      ),
      roomId: _text(data, const [
        'roomId',
        'room_id',
        'channel_id',
        'channelId',
        'liveStreamingId',
        'live_streaming_id',
        'liveId',
        'live_id',
        'zegoLiveId',
        'zego_live_id',
      ]),
    );
  }
}

/// A retried lucky send must not announce the clip or the win a second time.
bool luckySendShouldBroadcast(Map<dynamic, dynamic> data) =>
    data['idempotent'] != true;

/// Diamonds left after a lucky send. Accepts camelCase and the newer snake_case.
int? readLuckyDiamondBalance(Map<dynamic, dynamic> data) {
  final reward = _map(data['luckyReward']) ?? _map(data['lucky_reward']);
  final raw =
      data['userCoins'] ??
      data['user_coins'] ??
      data['remaining_diamonds'] ??
      data['remainingDiamonds'] ??
      reward?['userCoins'] ??
      reward?['user_coins'];
  if (raw == null) return null;
  return parseWalletAmount(raw);
}

/// True when a `gift_sent` payload is actually a lucky send.
///
/// The clip already plays from the room chat line. Playing it again from
/// `gift_sent` would show the animation twice.
bool luckySocketPayloadIsLuckyGift(Map<dynamic, dynamic> raw) {
  bool looks(Map<dynamic, dynamic> map, int depth) {
    if (depth > 3) return false;
    if (map['isLucky'] == true || map['is_lucky'] == true) return true;
    final type = (map['type'] ?? map['giftType'] ?? map['gift_type'] ?? '')
        .toString()
        .toLowerCase();
    if (type == 'lucky' || type.contains('lucky_gift')) return true;
    final gift = map['gift'];
    if (gift is Map && looks(gift, depth + 1)) return true;
    final nested = map['data'];
    if (nested is Map && looks(nested, depth + 1)) return true;
    return false;
  }

  return looks(raw, 0);
}

Map<dynamic, dynamic> _unwrap(Map<dynamic, dynamic> raw) {
  final nested = raw['data'];
  if (nested is Map &&
      (raw['luckyRewardCoins'] == null &&
          raw['lucky_reward_coins'] == null &&
          raw['rewardCoins'] == null)) {
    return nested;
  }
  return raw;
}

Map<dynamic, dynamic>? _map(dynamic value) {
  if (value is Map) return value;
  return null;
}

dynamic _first(Map<dynamic, dynamic> data, List<String> keys) {
  for (final key in keys) {
    final value = data[key];
    if (value != null && value.toString().trim().isNotEmpty) return value;
  }
  return null;
}

String _text(Map<dynamic, dynamic> data, List<String> keys) {
  final value = _first(data, keys);
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty || text == 'null') return '';
  return text;
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}
