import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:qobo_one_live/services/api_service.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';

class LuckyGift {
  LuckyGift.fromJson(Map json)
    : id = (json['giftId'] ?? json['id'] ?? '').toString(),
      name = (json['name'] ?? 'Lucky Gift').toString(),
      price = parseWalletAmount(
        json['price'] ?? json['coinCost'] ?? json['coins'],
      ),
      threshold = parseWalletAmount(json['luckyThreshold']),
      rate = (json['luckyRewardRate'] ?? 0).toString(),
      icon =
          ApiImageUtils.normalize(
            (json['iconUrl'] ?? json['animationUrl'])?.toString(),
          ) ??
          '🎁',
      sound = json['soundUrl']?.toString();
  final String id, name, icon, rate;
  final String? sound;
  final int price, threshold;
  int get estimatedBase => price * threshold;
  int get estimatedBonus =>
      (estimatedBase * (double.tryParse(rate) ?? 0) / 100).floor();
  int get estimatedReward => estimatedBase + estimatedBonus;
  int remaining(int combo) => threshold > 0 ? threshold - combo % threshold : 0;
  String guidance(int combo) => threshold > 0
      ? '${remaining(combo)} more sends • Est. $estimatedReward coins (+$rate%)'
      : 'Tap to send this gift';
}

class LuckyGiftRepo {
  LuckyGiftRepo({ApiService? api}) : api = api ?? ApiService();
  final ApiService api;
  Future<Map<String, dynamic>?> catalog() async {
    final r = await api.getRequest(
      endPoint: '/api/gifts/lucky',
      isShowLoader: false,
    );
    return r == null ? null : Map<String, dynamic>.from(jsonDecode(r.body));
  }

  Future<Map<String, dynamic>?> send(
    Map<String, dynamic> body,
    String token,
  ) async {
    final r = await api.postRequest(
      endPoint: '/api/gifts/lucky/send',
      requestModel: body,
      bearerToken: token,
      skipUnauthorizedHandling: true,
      isShowLoader: false,
    );
    if (r == null) return null;
    final result = Map<String, dynamic>.from(jsonDecode(r.body));
    if (r.statusCode >= 500) {
      return null; // Ambiguous outcome: retry identical ID.
    }
    return result;
  }
}

class _LuckyTap {
  _LuckyTap(this.gift, this.host, this.channel);
  final LuckyGift gift;
  final String host, channel;
  Map<String, dynamic>? body;
}

/// Serializes paid taps. Failed/uncertain sends block later taps until retried.
/// A retry preserves clientGiftId and combo; the server owns reward/balance math.
class LuckyGiftSession extends ChangeNotifier {
  LuckyGiftSession({
    required this.repo,
    required this.token,
    required this.isOwner,
    required this.onSuccess,
  });
  final LuckyGiftRepo repo;
  final String token;
  final bool Function() isOwner;
  final void Function(LuckyGift gift, Map data, String host) onSuccess;
  List<LuckyGift> gifts = [];
  bool loading = false, busy = false, _disposed = false;
  String message = '';
  int? balance;
  final Map<String, int> combos = {};
  String? _previewGift;
  int _previewCount = 0;
  bool previewing = false;
  int displayedCombo(String id) =>
      previewing ? (_previewGift == id ? _previewCount : 0) : (combos[id] ?? 0);
  bool previewTap(LuckyGift gift) {
    previewing = true;
    if (_previewGift != gift.id) {
      _previewGift = gift.id;
      _previewCount = 0;
    }
    _previewCount++;
    message = 'Preview only • No coins charged. Select a recipient to send.';
    _notify();
    return gift.threshold > 0 && _previewCount % gift.threshold == 0;
  }

  void resetPreview() {
    previewing = false;
    _previewGift = null;
    _previewCount = 0;
  }

  final List<_LuckyTap> _queue = [];
  _LuckyTap? _pending;
  bool get needsRetry => _pending != null && !busy;
  int get queued => _queue.length;
  void _notify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    message = '';
    _notify();
    try {
      final r = await repo.catalog();
      if (!isEconomyApiSuccess(r) || r?['data'] is! List) {
        throw StateError('catalog unavailable');
      }
      gifts = (r!['data'] as List)
          .whereType<Map>()
          .where((j) => j['status'] == null || j['status'] == 'active')
          .map(LuckyGift.fromJson)
          .where((g) => g.id.isNotEmpty && g.price > 0)
          .toList();
      if (gifts.isEmpty) message = 'No Lucky gifts available yet.';
    } catch (_) {
      message = 'Unable to load Lucky gifts. Please retry.';
    } finally {
      loading = false;
      _notify();
    }
  }

  void tap(LuckyGift gift, {String host = '', String channel = ''}) {
    if (_disposed || !isOwner() || needsRetry) return;
    if (_queue.length >= 20) {
      message = 'Please wait for your queued gifts.';
      _notify();
      return;
    }
    resetPreview();
    _queue.add(_LuckyTap(gift, host, channel));
    unawaited(_drain());
  }

  Future<void> retry() => _drain();
  void updateBalance(int value) {
    balance = value;
    _notify();
  }

  void showMessage(String value) {
    message = value;
    _notify();
  }

  void cancelQueued() {
    _queue.clear();
  }

  static String newId() {
    final r = Random.secure();
    final bytes = List.generate(16, (_) => r.nextInt(256));
    bytes[6] = (bytes[6] & 15) | 64;
    bytes[8] = (bytes[8] & 63) | 128;
    final h = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
  }

  Future<void> _drain() async {
    if (busy || _disposed || !isOwner()) return;
    busy = true;
    _notify();
    try {
      while (!_disposed &&
          isOwner() &&
          (_pending != null || _queue.isNotEmpty)) {
        final tap = _pending ?? _queue.removeAt(0);
        _pending = tap;
        final combo = (combos[tap.gift.id] ?? 0) + 1;
        tap.body ??= {
          'gift_id': tap.gift.id,
          'quantity': 1,
          'combo': combo,
          'comboCount': combo,
          'clientGiftId': newId(),
          if (tap.host.isNotEmpty) 'host_id': tap.host,
          if (tap.channel.isNotEmpty) 'channel_id': tap.channel,
        };
        Map<String, dynamic>? r;
        try {
          r = await repo
              .send(tap.body!, token)
              .timeout(const Duration(seconds: 30));
        } catch (_) {
          r = null;
        }
        if (_disposed || !isOwner()) return;
        if (r == null) {
          message =
              'Confirmation pending. Retry this send before sending more.';
          _queue.clear();
          break;
        }
        if (!isEconomyApiSuccess(r) || r['data'] is! Map) {
          message = r['message']?.toString() ?? 'Lucky gift could not be sent.';
          _queue.clear();
          _pending = null;
          break;
        }
        final data = Map<String, dynamic>.from(r['data']);
        final reward = data['luckyReward'] is Map
            ? data['luckyReward'] as Map
            : {};
        combos[tap.gift.id] = parseWalletAmount(
          data['combo'] ?? reward['currentCombo'] ?? tap.body!['combo'],
        );
        final coins = data['userCoins'] ?? reward['userCoins'];
        if (coins != null) balance = parseWalletAmount(coins);
        final won =
            data['luckyRewardTriggered'] == true ||
            reward['rewardTriggered'] == true;
        message = data['idempotent'] == true
            ? 'Previous send confirmed. Refreshing balance…'
            : won
            ? 'You won ${data['luckyRewardCoins'] ?? reward['rewardCoins'] ?? 0} Coins (includes ${data['luckyRewardBonus'] ?? reward['rewardBonus'] ?? 0} bonus)!'
            : 'Combo ${combos[tap.gift.id]} • ${reward['comboRemaining'] ?? tap.gift.remaining(combos[tap.gift.id] ?? 0)} more for a Lucky win';
        _pending = null;
        onSuccess(tap.gift, data, tap.host);
        _notify();
      }
    } finally {
      busy = false;
      _notify();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _queue.clear();
    super.dispose();
  }
}
