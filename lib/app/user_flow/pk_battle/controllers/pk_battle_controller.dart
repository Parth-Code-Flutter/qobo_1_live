import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/constants/color_constants.dart';

enum PKState {
  idle,
  searching,
  incomingRequest,
  outgoingRequest,
  inBattle,
  completed,
}

class PKBattleController extends GetxController {
  final pkState = PKState.idle.obs;

  // Search/Opponent selection state
  final searchQuery = ''.obs;
  final mockOpponents = <Map<String, dynamic>>[].obs;
  final filteredOpponents = <Map<String, dynamic>>[].obs;
  final isLoadingOpponents = false.obs;

  // Active Battle States
  final myPoints = 0.obs;
  final opponentPoints = 0.obs;
  final timerSeconds = 180.obs; // 3 minutes
  Timer? _battleTimer;
  Timer? _matchTimer;

  // Current Challenger/Opponent info
  final currentOpponentName = ''.obs;
  final currentOpponentAvatar = ''.obs;
  final currentOpponentLevel = 1.obs;
  final currentOpponentVip = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadOpponents();
    debounce(
      searchQuery,
      (_) => filterOpponentsList(),
      time: const Duration(milliseconds: 300),
    );
  }

  @override
  void onClose() {
    _battleTimer?.cancel();
    _matchTimer?.cancel();
    super.onClose();
  }

  void loadOpponents() {
    mockOpponents.clear();
    filteredOpponents.assignAll(mockOpponents);
  }

  void filterOpponentsList() {
    if (searchQuery.value.trim().isEmpty) {
      filteredOpponents.assignAll(mockOpponents);
    } else {
      filteredOpponents.assignAll(
        mockOpponents
            .where(
              (o) => o['name'].toString().toLowerCase().contains(
                searchQuery.value.toLowerCase(),
              ),
            )
            .toList(),
      );
    }
  }

  // Action: Start matchmaking radar
  void startMatchmaking() {
    pkState.value = PKState.searching;
    isLoadingOpponents.value = true;

    // Simulate auto-matching after 4 seconds
    _matchTimer = Timer(const Duration(seconds: 4), () {
      final onlineOpponents = mockOpponents
          .where((o) => o['isOnline'] == true)
          .toList();
      if (onlineOpponents.isNotEmpty) {
        // Match with a random online opponent
        onlineOpponents.shuffle();
        final matched = onlineOpponents.first;
        setupOpponent(matched);
        pkState.value = PKState.incomingRequest;
      } else {
        pkState.value = PKState.idle;
        Get.snackbar('Matchmaking', 'No opponents found. Try again later.');
      }
      isLoadingOpponents.value = false;
    });
  }

  void setupOpponent(Map<String, dynamic> opponent) {
    currentOpponentName.value = opponent['name'] ?? '';
    currentOpponentAvatar.value =
        opponent['avatar'] ?? 'assets/images/temp_img_2.png';
    currentOpponentLevel.value = opponent['level'] ?? 1;
    currentOpponentVip.value = opponent['vip'] ?? '';
  }

  // Action: Send invite to a specific user
  void sendInvitation(Map<String, dynamic> opponent) {
    setupOpponent(opponent);
    pkState.value = PKState.outgoingRequest;

    // Simulate opponent accepting the challenge after 3 seconds
    Timer(const Duration(seconds: 3), () {
      if (pkState.value == PKState.outgoingRequest) {
        startBattle();
      }
    });
  }

  // Action: Accept Incoming Challenge
  void acceptChallenge() {
    startBattle();
  }

  // Action: Reject Incoming Challenge
  void rejectChallenge() {
    pkState.value = PKState.idle;
    Get.snackbar(
      'Challenge Rejected',
      'You declined the challenge request.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent,
      colorText: kColorWhite,
    );
  }

  // Action: Cancel outgoing request
  void cancelOutgoing() {
    pkState.value = PKState.idle;
  }

  // Start the battle loop
  void startBattle() {
    pkState.value = PKState.inBattle;
    myPoints.value = 100; // Starting baseline
    opponentPoints.value = 100;
    timerSeconds.value = 180;

    _battleTimer?.cancel();
    _battleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
        // Randomly simulate occasional opponent gift points
        if (timerSeconds.value % 15 == 0) {
          simulateGift(150, false);
        }
      } else {
        timer.cancel();
        endBattle();
      }
    });
  }

  // Action: Simulate sending/receiving a gift
  void simulateGift(int points, bool isMe) {
    if (pkState.value != PKState.inBattle) return;

    if (isMe) {
      myPoints.value += points;
    } else {
      opponentPoints.value += points;
    }
  }

  // Complete battle
  void endBattle() {
    pkState.value = PKState.completed;

    final bool won = myPoints.value > opponentPoints.value;
    final bool draw = myPoints.value == opponentPoints.value;

    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E2C),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: won
                  ? Colors.amber
                  : (draw ? Colors.grey : Colors.redAccent),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                won ? '👑 VICTORY! 👑' : (draw ? '🤝 DRAW 🤝' : '💔 DEFEAT 💔'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: won
                      ? Colors.amber
                      : (draw ? Colors.white : Colors.redAccent),
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(
                radius: 44,
                backgroundImage: AssetImage(currentOpponentAvatar.value),
              ),
              const SizedBox(height: 12),
              Text(
                'vs ${currentOpponentName.value}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    children: [
                      const Text(
                        'My Points',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${myPoints.value}',
                        style: const TextStyle(
                          color: Colors.blueAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Container(width: 1, height: 40, color: Colors.white24),
                  Column(
                    children: [
                      const Text(
                        'Opponent',
                        style: TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${opponentPoints.value}',
                        style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kColorPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Get.back();
                    pkState.value = PKState.idle;
                  },
                  child: const Text(
                    'Back to Lobby',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  String get formattedTime {
    final minutes = timerSeconds.value ~/ 60;
    final seconds = timerSeconds.value % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get myPercentage {
    final total = myPoints.value + opponentPoints.value;
    if (total == 0) return 0.5;
    return myPoints.value / total;
  }
}
