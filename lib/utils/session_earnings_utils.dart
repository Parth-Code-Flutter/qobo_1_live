import 'package:qobo_one_live/app/user_flow/live_broadcast/utils/live_room_profile_utils.dart';
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

  /// After `POST /api/economy/send-gift`, apply earnings for this device's earner.
  ///
  /// - `scope=user`: credits when [earnerUserId] is the gift receiver.
  /// - `scope=room`: credits when [roomParticipantsEarn] is true (everyone in
  ///   the room except the sender — caller must set this).
  static void ingestGiftResponse({
    required SessionEarningsTracker tracker,
    required Map<String, dynamic>? response,
    required String hostUserId,
    required String earnerUserId,
    required bool hostReceivesRoomGifts,
    bool roomParticipantsEarn = false,
    int fallbackGiftPrice = 0,
    String scope = 'user',
    String? receiverId,
  }) {
    if (!isEconomyApiSuccess(response)) return;
    final data = _asMap(response?['data']);
    final earnerId = earnerUserId.trim();
    final receiver = (receiverId ?? data['receiverId'] ?? data['receiver_id'])
        ?.toString()
        .trim();
    final normalizedScope = scope.trim().toLowerCase();

    if (earnerId.isEmpty) return;

    final isRoomGiftToParticipant =
        normalizedScope == 'room' && roomParticipantsEarn;
    final isDirectGiftToEarner = receiver != null &&
        receiver.isNotEmpty &&
        _idsMatch(earnerId, receiver);

    if (!isRoomGiftToParticipant && !isDirectGiftToEarner) return;

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

  /// Peer gift chat line — estimate share from catalog / embedded price.
  ///
  /// Returns coins applied to [tracker] (0 when nothing earned).
  static int ingestIncomingGiftChat({
    required SessionEarningsTracker tracker,
    required String chatMessage,
    required List<Map<String, String>> giftCatalog,
    required bool earnsGift,
  }) {
    if (!earnsGift || !GiftMediaUtils.isGiftChatMessage(chatMessage)) return 0;
    final embedded = parseGiftPrice(chatMessage);
    if (embedded != null && embedded > 0) {
      tracker.applyDelta(coins: embedded);
      return embedded;
    }
    final price = _giftPriceFromCatalog(giftCatalog, chatMessage);
    if (price != null && price > 0) {
      tracker.applyDelta(coins: price);
      return price;
    }
    return 0;
  }

  static int? _giftPriceFromCatalog(
    List<Map<String, String>> catalog,
    String chatMessage,
  ) {
    final name = GiftMediaUtils.giftNameFromChatLabel(chatMessage).toLowerCase();
    if (name.isNotEmpty && name != 'gift') {
      for (final gift in catalog) {
        if ((gift['name'] ?? '').trim().toLowerCase() == name) {
          return int.tryParse(gift['price'] ?? '0');
        }
      }
    }

    // Chat may show a generic "sent gift" label — match via embedded SVGA URL.
    final animUrl = parseGiftAnimUrl(chatMessage)?.trim();
    if (animUrl != null && animUrl.isNotEmpty) {
      for (final gift in catalog) {
        final catalogAnim = (gift['animationUrl'] ?? '').trim();
        if (catalogAnim.isEmpty) continue;
        if (animUrl == catalogAnim ||
            animUrl.endsWith(catalogAnim.split('/').last)) {
          return int.tryParse(gift['price'] ?? '0');
        }
      }
    }

    final soundUrl = parseGiftSoundUrl(chatMessage)?.trim();
    if (soundUrl != null && soundUrl.isNotEmpty) {
      for (final gift in catalog) {
        final catalogSound = (gift['soundUrl'] ?? '').trim();
        if (catalogSound.isEmpty) continue;
        if (soundUrl == catalogSound ||
            soundUrl.endsWith(catalogSound.split('/').last)) {
          return int.tryParse(gift['price'] ?? '0');
        }
      }
    }

    return null;
  }

  /// Compact amount for tight pills (app bar badges, call chips).
  static String formatAmountForPill(int value) {
    if (value >= 1000000) {
      final millions = value / 1000000;
      return '${millions >= 10 ? millions.round() : millions.toStringAsFixed(1)}M';
    }
    if (value >= 10000) {
      return '${(value / 1000).round()}k';
    }
    if (value >= 1000) {
      final thousands = value / 1000;
      return thousands == thousands.roundToDouble()
          ? '${thousands.round()}k'
          : '${thousands.toStringAsFixed(1)}k';
    }
    return value.toString();
  }

  /// Readable amount for wider banners (commas, no abbreviation under 100k).
  static String formatAmountForBanner(int value) {
    if (value >= 100000) {
      return formatAmountForPill(value);
    }
    return formatLedgerAmount(value);
  }

  static String formatAmount(int value) => formatAmountForPill(value);

  static Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  static bool _idsMatch(String left, String right) {
    final a = left.trim();
    final b = right.trim();
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;
    final aSan = a.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    final bSan = b.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
    return aSan.isNotEmpty && aSan == bSan;
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
