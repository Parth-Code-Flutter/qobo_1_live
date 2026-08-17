import 'package:get/get.dart';

/// Coins/diamonds earned during the **current** room or call session only.
///
/// Never mix with wallet balance — use [SessionEarningsTracker] for UI badges.
class SessionEarningsTracker {
  SessionEarningsTracker();

  final coinsEarned = 0.obs;
  final diamondsEarned = 0.obs;

  /// Primary value shown in compact badges (coins preferred).
  int get displayCoins => coinsEarned.value;

  void reset() {
    coinsEarned.value = 0;
    diamondsEarned.value = 0;
  }

  void seed({int coins = 0, int diamonds = 0}) {
    coinsEarned.value = coins < 0 ? 0 : coins;
    diamondsEarned.value = diamonds < 0 ? 0 : diamonds;
  }

  void applyDelta({int coins = 0, int diamonds = 0}) {
    if (coins != 0) {
      coinsEarned.value = (coinsEarned.value + coins).clamp(0, 1 << 30);
    }
    if (diamonds != 0) {
      diamondsEarned.value = (diamondsEarned.value + diamonds).clamp(0, 1 << 30);
    }
  }

  void setFromTotals({required int coins, required int diamonds}) {
    seed(coins: coins, diamonds: diamonds);
  }
}

/// Host AppBar totals keyed by room id. Survives leave/rejoin in this process.
abstract final class HostSessionRoomStore {
  static final Map<String, int> _coinsByRoom = {};

  static void remember(String roomId, int coins) {
    final id = roomId.trim();
    if (id.isEmpty || coins <= 0) return;
    final prev = _coinsByRoom[id] ?? 0;
    if (coins > prev) _coinsByRoom[id] = coins;
  }

  static int peek(String roomId) {
    final id = roomId.trim();
    if (id.isEmpty) return 0;
    return _coinsByRoom[id] ?? 0;
  }
}
