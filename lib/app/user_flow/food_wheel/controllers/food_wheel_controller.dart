import 'dart:async';
import 'dart:math';

import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../models/food_wheel_item.dart';

enum FoodWheelPhase { betting, counting, revealing, result }

/// Phone-only Food Wheel. Coins are play coins and never leave the device.
///
/// [pickWinner] is the only piece the backend will replace. The screen already
/// treats the winning index as an input, so a server round can drop in later.
class FoodWheelController extends GetxController {
  static const startingCoins = 5000;
  static const chips = [10, 50, 100, 1000];
  static const countdownSeconds = 5;

  final coins = startingCoins.obs;
  final profit = 0.obs;
  final round = 1.obs;
  final selectedChip = chips.first.obs;
  final bets = <int, int>{}.obs;
  final phase = FoodWheelPhase.betting.obs;
  final secondsLeft = 0.obs;
  final highlightIndex = (-1).obs;
  final winnerIndex = RxnInt();
  final lastPayout = 0.obs;

  final _random = Random();
  Timer? _countdown;
  int _revealToken = 0;

  int get totalStake => bets.values.fold(0, (sum, amount) => sum + amount);

  bool get canBet =>
      phase.value == FoodWheelPhase.betting ||
      phase.value == FoodWheelPhase.counting;

  void selectChip(int chip) {
    if (!canBet) return;
    if (selectedChip.value != chip) {
      HapticFeedback.selectionClick();
    }
    selectedChip.value = chip;
  }

  /// Adds the selected chip onto [index]. Stake is taken from play coins now.
  void placeBet(int index) {
    if (!canBet) return;
    final chip = selectedChip.value;
    if (coins.value < chip) {
      Get.snackbar(
        'Not enough play coins',
        'Lower the chip, or refill the demo balance.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    coins.value -= chip;
    bets[index] = (bets[index] ?? 0) + chip;
    HapticFeedback.lightImpact();
  }

  void startRound() {
    if (phase.value != FoodWheelPhase.betting) return;
    if (bets.isEmpty) {
      Get.snackbar(
        'Place a bet',
        'Pick a chip, then tap a food.',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
      return;
    }
    HapticFeedback.mediumImpact();
    phase.value = FoodWheelPhase.counting;
    secondsLeft.value = countdownSeconds;
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft.value <= 1) {
        timer.cancel();
        unawaited(_reveal());
        return;
      }
      secondsLeft.value -= 1;
    });
  }

  /// Local stand-in. A later API should return this index instead.
  int pickWinner() => _random.nextInt(kFoodWheelItems.length);

  Future<void> _reveal() async {
    final token = ++_revealToken;
    phase.value = FoodWheelPhase.revealing;
    secondsLeft.value = 0;
    final winner = pickWinner();
    const laps = 4;
    final steps = laps * kFoodWheelItems.length + winner;
    for (var step = 0; step <= steps; step++) {
      if (isClosed || token != _revealToken) return;
      highlightIndex.value = step % kFoodWheelItems.length;
      final remaining = steps - step;
      final millis = remaining < 10 ? 70 + (10 - remaining) * 55 : 48;
      await Future<void>.delayed(Duration(milliseconds: millis));
    }
    if (isClosed || token != _revealToken) return;
    _settle(winner);
  }

  void _settle(int winner) {
    final item = kFoodWheelItems[winner];
    final stake = bets[winner] ?? 0;
    final payout = stake * item.multiplier;
    final staked = totalStake;
    coins.value += payout;
    profit.value += payout - staked;
    winnerIndex.value = winner;
    highlightIndex.value = winner;
    lastPayout.value = payout;
    phase.value = FoodWheelPhase.result;
    HapticFeedback.heavyImpact();
  }

  void nextRound() {
    _revealToken++;
    _countdown?.cancel();
    bets.clear();
    winnerIndex.value = null;
    highlightIndex.value = -1;
    lastPayout.value = 0;
    secondsLeft.value = 0;
    round.value += 1;
    phase.value = FoodWheelPhase.betting;
  }

  void refillCoins() {
    if (phase.value == FoodWheelPhase.counting ||
        phase.value == FoodWheelPhase.revealing) {
      return;
    }
    coins.value = startingCoins;
  }

  @override
  void onClose() {
    _revealToken++;
    _countdown?.cancel();
    super.onClose();
  }
}
