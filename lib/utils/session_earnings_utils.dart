import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/services/session/session_earnings_tracker.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_media_utils.dart';

/// Parse session-earnings fields from room join, gift, and poll responses.
abstract final class SessionEarningsUtils {
  SessionEarningsUtils._();

  static const sessionFieldKeys = [
    'sessionCoinsEarned',
    'session_coins_earned',
    'hostSessionCoins',
    'host_session_coins',
    'sessionEarnings',
    'session_earnings',
    'currentSessionCoins',
    'current_session_coins',
    'coinsEarnedThisSession',
    'coins_earned_this_session',
  ];

  static const diamondFieldKeys = [
    'sessionDiamondsEarned',
    'session_diamonds_earned',
    'hostSessionDiamonds',
    'host_session_diamonds',
    'diamondsEarnedThisSession',
    'diamonds_earned_this_session',
  ];

  static void ingestRoomData(
    SessionEarningsTracker tracker,
    Map<String, dynamic>? roomData,
  ) {
    if (roomData == null || roomData.isEmpty) return;
    final nested = _asMap(
      roomData['sessionEarnings'] ?? roomData['session_earnings'],
    );
    final coins = _readIntFromMaps([roomData, nested], sessionFieldKeys);
    final diamonds = _readIntFromMaps([roomData, nested], diamondFieldKeys);
    if (coins != null || diamonds != null) {
      tracker.setFromTotals(
        coins: coins ?? tracker.coinsEarned.value,
        diamonds: diamonds ?? tracker.diamondsEarned.value,
      );
    }
  }

  static void ingestApiEnvelope(
    SessionEarningsTracker tracker,
    Map<String, dynamic>? response,
  ) {
    if (!isEconomyApiSuccess(response)) return;
    final data = _asMap(response?['data']);
    if (data.isEmpty) return;

    final nested = _asMap(
      data['sessionEarnings'] ?? data['session_earnings'] ?? data['earnings'],
    );
    final coins = _readIntFromMaps([data, nested], sessionFieldKeys);
    final diamonds = _readIntFromMaps([data, nested], diamondFieldKeys);
    if (coins != null || diamonds != null) {
      tracker.setFromTotals(
        coins: coins ?? tracker.coinsEarned.value,
        diamonds: diamonds ?? tracker.diamondsEarned.value,
      );
    }
  }

  /// After `POST /api/economy/send-gift`, apply host earnings when present.
  static void ingestGiftResponse({
    required SessionEarningsTracker tracker,
    required Map<String, dynamic>? response,
    required String hostUserId,
    required bool hostReceivesRoomGifts,
    int fallbackGiftPrice = 0,
    String scope = 'user',
    String? receiverId,
  }) {
    if (!isEconomyApiSuccess(response)) return;
    final data = _asMap(response?['data']);
    final hostId = hostUserId.trim();
    final receiver = (receiverId ?? data['receiverId'] ?? data['receiver_id'])
        ?.toString()
        .trim();
    final normalizedScope = scope.trim().toLowerCase();

    final earnsGift = hostId.isNotEmpty &&
        (normalizedScope == 'room' && hostReceivesRoomGifts ||
            (receiver != null && receiver.isNotEmpty && receiver == hostId));

    if (!earnsGift) return;

    final hostBlock = _asMap(
      data['hostEarnings'] ??
          data['host_earnings'] ??
          data['receiverEarnings'] ??
          data['receiver_earnings'],
    );

    final deltaCoins = _readIntFromMaps(
      [data, hostBlock],
      [
        ...sessionFieldKeys,
        'coinsAdded',
        'coins_added',
        'hostCoinsAdded',
        'host_coins_added',
      ],
    );
    final deltaDiamonds = _readIntFromMaps(
      [data, hostBlock],
      [
        ...diamondFieldKeys,
        'diamondsAdded',
        'diamonds_added',
      ],
    );

    if (deltaCoins != null || deltaDiamonds != null) {
      tracker.applyDelta(coins: deltaCoins ?? 0, diamonds: deltaDiamonds ?? 0);
      return;
    }

    if (fallbackGiftPrice > 0) {
      tracker.applyDelta(coins: fallbackGiftPrice);
    }
  }

  /// Peer gift chat line — estimate host/callee share from catalog when API
  /// response is only available on the sender device.
  static void ingestIncomingGiftChat({
    required SessionEarningsTracker tracker,
    required String chatMessage,
    required List<Map<String, String>> giftCatalog,
    required bool earnsGift,
  }) {
    if (!earnsGift || !GiftMediaUtils.isGiftChatMessage(chatMessage)) return;
    final price = _giftPriceFromCatalog(giftCatalog, chatMessage);
    if (price != null && price > 0) {
      tracker.applyDelta(coins: price);
    }
  }

  static int? _giftPriceFromCatalog(
    List<Map<String, String>> catalog,
    String chatMessage,
  ) {
    final name = GiftMediaUtils.giftNameFromChatLabel(chatMessage).toLowerCase();
    if (name.isEmpty) return null;
    for (final gift in catalog) {
      if ((gift['name'] ?? '').trim().toLowerCase() == name) {
        return int.tryParse(gift['price'] ?? '0');
      }
    }
    return null;
  }

  static String formatAmount(int value) {
    if (value >= 1000000) {
      final millions = value / 1000000;
      return '${millions >= 10 ? millions.round() : millions.toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      final thousands = value / 1000;
      return '${thousands >= 10 ? thousands.round() : thousands.toStringAsFixed(1)}k';
    }
    return value.toString();
  }

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static int? _readIntFromMaps(
    List<Map<String, dynamic>> maps,
    List<String> keys,
  ) {
    for (final map in maps) {
      for (final key in keys) {
        final value = map[key];
        if (value == null) continue;
        if (value is num) return value.round();
        final parsed = int.tryParse(value.toString().replaceAll(',', ''));
        if (parsed != null) return parsed;
      }
    }
    return null;
  }
}
