import 'package:qobo_one_live/app/user_flow/live_broadcast/utils/live_room_profile_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/services/session/session_earnings_tracker.dart';
import 'package:qobo_one_live/utils/gift_share_economics.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_media_utils.dart';

/// Parse session-earnings fields from room join, gift, and poll responses.
abstract final class SessionEarningsUtils {
  SessionEarningsUtils._();

  static const sessionFieldKeys = [
    'sessionCoinsEarned',
    'session_coins_earned',
    'hostSessionCoins',
    'host_session_coins',
    'currentSessionCoins',
    'current_session_coins',
    'coinsEarnedThisSession',
    'coins_earned_this_session',
    'giftCoinsEarned',
    'gift_coins_earned',
  ];

  static const diamondFieldKeys = [
    'sessionDiamondsEarned',
    'session_diamonds_earned',
    'hostSessionDiamonds',
    'host_session_diamonds',
    'diamondsEarnedThisSession',
    'diamonds_earned_this_session',
  ];

  /// Nested objects that also carry [sessionFieldKeys] (join / poll payloads).
  static const _nestedSessionMapKeys = [
    'sessionEarnings',
    'session_earnings',
    'hostEarnings',
    'host_earnings',
    'earnings',
  ];

  static void ingestRoomData(
    SessionEarningsTracker tracker,
    Map<String, dynamic>? roomData,
  ) {
    if (roomData == null || roomData.isEmpty) return;
    final coins = _readHostSessionCoinTotal([
      roomData,
      ..._nestedSessionMaps(roomData),
    ]);
    final diamonds = _readHostSessionDiamondTotal([
      roomData,
      ..._nestedSessionMaps(roomData),
    ]);
    if (coins != null || diamonds != null) {
      _applyIngestedTotals(
        tracker,
        coins: coins,
        diamonds: diamonds,
      );
    }
  }

  static void ingestApiEnvelope(
    SessionEarningsTracker tracker,
    Map<String, dynamic>? response,
  ) {
    if (!isEconomyApiSuccess(response)) return;
    var data = _asMap(response?['data']);
    // Some builds return host totals on the envelope itself.
    if (data.isEmpty) data = _asMap(response);
    if (data.isEmpty) return;

    final coins = _readHostSessionCoinTotal([
      data,
      ..._nestedSessionMaps(data),
    ]);
    final diamonds = _readHostSessionDiamondTotal([
      data,
      ..._nestedSessionMaps(data),
    ]);
    if (coins != null || diamonds != null) {
      _applyIngestedTotals(
        tracker,
        coins: coins,
        diamonds: diamonds,
      );
    }
  }

  /// Copies backend host-session aliases onto the live-room join payload.
  static void copyHostSessionFields(
    Map<String, dynamic> payload, {
    required Map<String, dynamic> data,
    Map<String, dynamic> joinedRoom = const {},
  }) {
    for (final key in [
      ..._nestedSessionMapKeys,
      ...sessionFieldKeys,
      ...diamondFieldKeys,
    ]) {
      payload[key] = data[key] ?? joinedRoom[key] ?? payload[key];
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

    if (!isRoomGiftToParticipant && !isDirectGiftToEarner) {
      // Room / split gift: credit when this user is listed in credited_user_ids.
      final credited = _readCreditedUserIds(data);
      final isCredited =
          credited.isNotEmpty &&
          credited.any((id) => _idsMatch(earnerId, id));
      if (!isCredited) return;

      final amountEach = _readIntFromMaps(
        [data],
        const ['amount_each', 'amountEach', 'amountPerUser', 'amount_per_user'],
      );
      if (amountEach != null && amountEach > 0) {
        tracker.applyDelta(coins: amountEach, diamonds: amountEach);
        return;
      }
      if (fallbackGiftPrice > 0 && credited.isNotEmpty) {
        final share = GiftShareEconomics.shareEach(
          coinsSpent: fallbackGiftPrice,
          recipientCount: credited.length,
        );
        if (share > 0) {
          tracker.applyDelta(coins: share, diamonds: share);
        }
      }
      return;
    }

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
        'amount_each',
        'amountEach',
      ],
    );
    final deltaDiamonds = _readIntFromMaps(
      [data, hostBlock],
      [
        ...diamondFieldKeys,
        'diamondsAdded',
        'diamonds_added',
        'amount_each',
        'amountEach',
      ],
    );

    if (deltaCoins != null || deltaDiamonds != null) {
      tracker.applyDelta(coins: deltaCoins ?? 0, diamonds: deltaDiamonds ?? 0);
      return;
    }

    if (fallbackGiftPrice > 0) {
      final net = GiftShareEconomics.netAfterCommission(fallbackGiftPrice);
      tracker.applyDelta(coins: net > 0 ? net : fallbackGiftPrice);
    }
  }

  static List<String> _readCreditedUserIds(Map<String, dynamic> data) {
    final raw =
        data['credited_user_ids'] ??
        data['creditedUserIds'] ??
        data['seated_user_ids'] ??
        data['seatedUserIds'];
    if (raw is! List) return const [];
    return raw
        .map((e) => e?.toString().trim() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
  }

  /// Peer gift chat line — estimate share from catalog / embedded price.
  ///
  /// Prefers `amount_each` for room gifts (split among seated users).
  /// Returns coins applied to [tracker] (0 when nothing earned).
  static int ingestIncomingGiftChat({
    required SessionEarningsTracker tracker,
    required String chatMessage,
    required List<Map<String, String>> giftCatalog,
    required bool earnsGift,
  }) {
    if (!earnsGift || !GiftMediaUtils.isGiftChatMessage(chatMessage)) return 0;
    final amountEach = parseGiftAmountEach(chatMessage);
    final embedded = parseGiftPrice(chatMessage);
    final catalogPrice = _giftPriceFromCatalog(giftCatalog, chatMessage);
    final price = (embedded != null && embedded > 0)
        ? embedded
        : (catalogPrice ?? 0);
    final scope = parseGiftScope(chatMessage);
    final credited = parseGiftCreditedUserIds(chatMessage);
    final credit = GiftShareEconomics.creditAmount(
      coinsSpent: price > 0 ? price : (amountEach ?? 0),
      isRoomShare: scope == 'room',
      recipientCount: credited.isNotEmpty ? credited.length : 1,
      apiAmountEach: amountEach,
    );
    if (credit <= 0) return 0;
    tracker.applyDelta(coins: credit);
    return credit;
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

  /// Never wipe a known host session total with a 0 placeholder (audience join).
  static void _applyIngestedTotals(
    SessionEarningsTracker tracker, {
    int? coins,
    int? diamonds,
  }) {
    final nextCoins = coins ?? tracker.coinsEarned.value;
    final nextDiamonds = diamonds ?? tracker.diamondsEarned.value;
    if (nextCoins == 0 &&
        nextDiamonds == 0 &&
        tracker.displayCoins > 0) {
      return;
    }
    tracker.setFromTotals(coins: nextCoins, diamonds: nextDiamonds);
  }

  static int? _readHostSessionCoinTotal(List<Map<String, dynamic>> maps) =>
      _readMaxIntFromMaps(maps, sessionFieldKeys);

  static int? _readHostSessionDiamondTotal(List<Map<String, dynamic>> maps) =>
      _readMaxIntFromMaps(maps, diamondFieldKeys);

  /// Join/poll often send `sessionCoinsEarned: 0` (caller) plus
  /// `hostSessionCoins: 1280`. First-key wins would keep the AppBar at 0.
  static int? _readMaxIntFromMaps(
    List<Map<String, dynamic>> maps,
    List<String> keys,
  ) {
    int? best;
    for (final map in maps) {
      for (final key in keys) {
        final parsed = _parsePlainInt(map[key]);
        if (parsed == null) continue;
        if (best == null || parsed > best) best = parsed;
      }
    }
    return best;
  }

  static List<Map<String, dynamic>> _nestedSessionMaps(
    Map<String, dynamic> source,
  ) {
    return _nestedSessionMapKeys
        .map((key) => _asMap(source[key]))
        .where((map) => map.isNotEmpty)
        .toList();
  }

  static int? _parsePlainInt(dynamic value) {
    if (value == null || value is Map || value is List) return null;
    if (value is num) return value.round();
    return int.tryParse(value.toString().replaceAll(',', ''));
  }

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
