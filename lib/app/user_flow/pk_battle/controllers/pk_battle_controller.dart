import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_broadcast/controllers/live_broadcast_controller.dart';
import 'package:qobo_one_live/constants/color_constants.dart';
import 'package:qobo_one_live/repo/pk/pk_repo.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

enum PKState {
  idle,
  searching,
  incomingRequest,
  outgoingRequest,
  inBattle,
  completed,
}

class PKBattleController extends GetxController {
  PKBattleController({PkRepo? pkRepo}) : _pkRepo = pkRepo ?? PkRepo();

  final PkRepo _pkRepo;

  final pkState = PKState.idle.obs;
  final searchQuery = ''.obs;
  final opponents = <Map<String, dynamic>>[].obs;
  final filteredOpponents = <Map<String, dynamic>>[].obs;
  final isLoadingOpponents = false.obs;

  final myRoomId = ''.obs;
  final myRoomName = 'My Room'.obs;
  final myAvatarUrl = ''.obs;
  final currentBattleId = ''.obs;
  final currentOpponentRoomId = ''.obs;
  final currentRequestId = ''.obs;

  final myPoints = 0.obs;
  final opponentPoints = 0.obs;
  final timerSeconds = 300.obs;
  final battleStatus = ''.obs;

  final currentOpponentName = ''.obs;
  final currentOpponentAvatar = ''.obs;
  final currentOpponentLevel = 1.obs;
  final currentOpponentVip = ''.obs;

  Timer? _battleTimer;
  Timer? _statusPollTimer;

  @override
  void onInit() {
    super.onInit();
    _hydrateContext();
    loadOpponents(isShowLoader: false);
    debounce(
      searchQuery,
      (_) => filterOpponentsList(),
      time: const Duration(milliseconds: 300),
    );
  }

  @override
  void onClose() {
    _battleTimer?.cancel();
    _statusPollTimer?.cancel();
    super.onClose();
  }

  Future<void> loadOpponents({bool isShowLoader = true}) async {
    if (myRoomId.value.isEmpty) {
      opponents.clear();
      filteredOpponents.clear();
      return;
    }

    isLoadingOpponents.value = true;
    final response = await _pkRepo.searchOpponents(
      roomId: myRoomId.value,
      isShowLoader: isShowLoader,
    );
    isLoadingOpponents.value = false;

    if (!_isSuccess(response)) {
      opponents.clear();
      filteredOpponents.clear();
      if (isShowLoader) {
        _showError(_message(response, 'No PK opponent found right now.'));
      }
      return;
    }

    final parsedOpponents = _parseOpponentPayload(response?['data']);
    opponents.assignAll(parsedOpponents);
    filterOpponentsList();
  }

  void filterOpponentsList() {
    final query = searchQuery.value.trim().toLowerCase();
    if (query.isEmpty) {
      filteredOpponents.assignAll(opponents);
      return;
    }

    filteredOpponents.assignAll(
      opponents.where((opponent) {
        final name = opponent['name']?.toString().toLowerCase() ?? '';
        final roomId = opponent['room_id']?.toString().toLowerCase() ?? '';
        return name.contains(query) || roomId.contains(query);
      }).toList(),
    );
  }

  /// Search one active room and immediately send a PK request, matching the
  /// backend flow: search opponent first, then challenge that room.
  Future<void> startMatchmaking() async {
    pkState.value = PKState.searching;
    await loadOpponents(isShowLoader: true);

    if (opponents.isEmpty) {
      pkState.value = PKState.idle;
      return;
    }

    await sendInvitation(opponents.first);
  }

  void setupOpponent(Map<String, dynamic> opponent) {
    currentOpponentRoomId.value = _readText(opponent, ['room_id', 'roomId']);
    currentOpponentName.value =
        _readText(opponent, ['name', 'title', 'hostName']).trim().isNotEmpty
        ? _readText(opponent, ['name', 'title', 'hostName'])
        : 'PK Opponent';
    currentOpponentAvatar.value = _readText(opponent, [
      'avatar',
      'displayPicture',
      'coverImage',
    ]);
    currentOpponentLevel.value =
        int.tryParse(opponent['level']?.toString() ?? '') ?? 1;
    currentOpponentVip.value = opponent['vip']?.toString() ?? '';
  }

  Future<void> sendInvitation(Map<String, dynamic> opponent) async {
    setupOpponent(opponent);
    final targetRoomId = currentOpponentRoomId.value.trim();
    if (myRoomId.value.isEmpty || targetRoomId.isEmpty) {
      pkState.value = PKState.idle;
      _showError('Missing room id for PK battle.');
      return;
    }

    pkState.value = PKState.outgoingRequest;
    final response = await _pkRepo.sendPkRequest(
      roomId: myRoomId.value,
      targetRoomId: targetRoomId,
      duration: 300,
    );

    if (!_isSuccess(response)) {
      pkState.value = PKState.idle;
      _showError(_message(response, 'Unable to send PK request.'));
      return;
    }

    final data = _asMap(response?['data']);
    currentRequestId.value =
        _readText(data, ['request_id', 'room_id', 'id']).isNotEmpty
        ? _readText(data, ['request_id', 'room_id', 'id'])
        : myRoomId.value;
    _showInfo(_message(response, 'PK request sent. Waiting for response.'));
  }

  Future<void> acceptChallenge() async {
    final requestId = currentRequestId.value.trim();
    if (myRoomId.value.isEmpty || requestId.isEmpty) {
      _showError('Missing PK request details.');
      return;
    }

    final response = await _pkRepo.acceptRejectPkRequest(
      roomId: myRoomId.value,
      requestId: requestId,
      action: 'accept',
      duration: 300,
    );

    if (!_isSuccess(response)) {
      _showError(_message(response, 'Unable to accept PK request.'));
      return;
    }

    _startBattleFromPayload(_asMap(response?['data']));
  }

  Future<void> rejectChallenge() async {
    final requestId = currentRequestId.value.trim();
    if (myRoomId.value.isEmpty || requestId.isEmpty) {
      pkState.value = PKState.idle;
      return;
    }

    final response = await _pkRepo.acceptRejectPkRequest(
      roomId: myRoomId.value,
      requestId: requestId,
      action: 'reject',
      duration: 300,
    );

    pkState.value = PKState.idle;
    _showInfo(_message(response, 'PK request rejected.'));
  }

  void cancelOutgoing() {
    pkState.value = PKState.idle;
  }

  void startBattle() {
    _startBattleFromPayload(<String, dynamic>{
      'id': currentBattleId.value,
      'room1Id': myRoomId.value,
      'room2Id': currentOpponentRoomId.value,
      'room1Score': myPoints.value,
      'room2Score': opponentPoints.value,
      'duration': timerSeconds.value,
      'status': 'active',
    });
  }

  void simulateGift(int points, bool isMe) {
    if (pkState.value != PKState.inBattle) return;
    if (isMe) {
      myPoints.value += points;
    } else {
      opponentPoints.value += points;
    }
  }

  void endBattle({String? winnerId}) {
    _battleTimer?.cancel();
    _statusPollTimer?.cancel();
    pkState.value = PKState.completed;

    final bool won = winnerId != null
        ? winnerId == myRoomId.value
        : myPoints.value > opponentPoints.value;
    final bool draw =
        winnerId == null && myPoints.value == opponentPoints.value;

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
                won ? 'Victory!' : (draw ? 'Draw' : 'Defeat'),
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: won
                      ? Colors.amber
                      : (draw ? Colors.white : Colors.redAccent),
                ),
              ),
              const SizedBox(height: 16),
              CircleAvatar(radius: 44, backgroundImage: opponentImageProvider),
              const SizedBox(height: 12),
              Text(
                'vs ${currentOpponentName.value}',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _scoreColumn('My Points', myPoints.value, Colors.blueAccent),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _scoreColumn(
                    'Opponent',
                    opponentPoints.value,
                    Colors.redAccent,
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
    if (total <= 0) return 0.5;
    return myPoints.value / total;
  }

  ImageProvider get opponentImageProvider {
    final avatar = currentOpponentAvatar.value.trim();
    if (avatar.startsWith('http')) return NetworkImage(avatar);
    if (avatar.isNotEmpty) return AssetImage(avatar);
    return const AssetImage('assets/images/temp_img_2.png');
  }

  ImageProvider get myImageProvider {
    final avatar = myAvatarUrl.value.trim();
    if (avatar.startsWith('http')) return NetworkImage(avatar);
    if (avatar.isNotEmpty) return AssetImage(avatar);
    return const AssetImage('assets/images/temp_img_2.png');
  }

  void handleIncomingPkRequest(Map<String, dynamic> payload) {
    currentRequestId.value = _readText(payload, [
      'request_id',
      'sender_room_id',
    ]);
    currentOpponentRoomId.value = _readText(payload, ['sender_room_id']);
    currentOpponentName.value =
        _readText(payload, ['sender_host_name', 'senderName']).isNotEmpty
        ? _readText(payload, ['sender_host_name', 'senderName'])
        : 'PK Opponent';
    timerSeconds.value =
        int.tryParse(payload['duration']?.toString() ?? '') ?? 300;
    pkState.value = PKState.incomingRequest;
  }

  void handlePkStarted(Map<String, dynamic> payload) {
    currentBattleId.value = _readText(payload, ['battleId', 'battle_id', 'id']);
    currentOpponentRoomId.value = _readText(payload, [
      'opponentRoomId',
      'opponent_room_id',
    ]);
    timerSeconds.value =
        int.tryParse(payload['duration']?.toString() ?? '') ?? 300;
    _startLocalBattleClock();
    _startStatusPolling();
    pkState.value = PKState.inBattle;
  }

  void handlePkScoreUpdate(Map<String, dynamic> payload) {
    _applyScores(payload);
  }

  void handlePkCompleted(Map<String, dynamic> payload) {
    _applyScores(payload);
    endBattle(winnerId: _readNullableText(payload, ['winnerId', 'winner_id']));
  }

  void _hydrateContext() {
    final args = Get.arguments;
    if (args is Map) {
      final argsMap = Map<String, dynamic>.from(args);
      myRoomId.value = _readText(argsMap, ['room_id', 'roomId', 'id']);
      myRoomName.value =
          _readText(argsMap, ['title', 'name', 'roomName']).isNotEmpty
          ? _readText(argsMap, ['title', 'name', 'roomName'])
          : myRoomName.value;
    }

    if (Get.isRegistered<LiveBroadcastController>()) {
      final live = Get.find<LiveBroadcastController>();
      // Prefer backend room id so /api/pk/* matches the active live room.
      final backendRoomId = live.audioRoomApiId.trim();
      if (backendRoomId.isNotEmpty) {
        myRoomId.value = backendRoomId;
      } else if (myRoomId.value.isEmpty) {
        myRoomId.value = live.roomId.value;
      }
      if (myRoomName.value == 'My Room') {
        myRoomName.value = live.streamTitle.value.isNotEmpty
            ? live.streamTitle.value
            : live.hostName.value;
      }
      myAvatarUrl.value = live.hostAvatarUrl.value ?? '';
    }

    if (Get.isRegistered<UserSessionController>()) {
      final session = Get.find<UserSessionController>();
      if (myRoomName.value == 'My Room') {
        myRoomName.value = session.displayName.isNotEmpty
            ? session.displayName
            : 'My Room';
      }
      if (myAvatarUrl.value.isEmpty) {
        myAvatarUrl.value = session.displayPictureUrl ?? '';
      }
    }
  }

  void _startBattleFromPayload(Map<String, dynamic> data) {
    currentBattleId.value = _readText(data, ['id', 'battleId', 'battle_id']);
    battleStatus.value = _readText(data, ['status']);
    timerSeconds.value =
        int.tryParse(data['duration']?.toString() ?? '') ?? 300;

    final room1Id = _readText(data, ['room1Id', 'room1_id']);
    final room2Id = _readText(data, ['room2Id', 'room2_id']);
    if (currentOpponentRoomId.value.isEmpty) {
      currentOpponentRoomId.value = room1Id == myRoomId.value
          ? room2Id
          : room1Id;
    }
    _applyScores(data);

    pkState.value = PKState.inBattle;
    _startLocalBattleClock();
    _startStatusPolling();
  }

  void _startLocalBattleClock() {
    _battleTimer?.cancel();
    _battleTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timerSeconds.value > 0) {
        timerSeconds.value--;
      } else {
        timer.cancel();
        if (pkState.value == PKState.inBattle) endBattle();
      }
    });
  }

  void _startStatusPolling() {
    _statusPollTimer?.cancel();
    if (currentBattleId.value.isEmpty) return;

    _statusPollTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final response = await _pkRepo.getPkStatus(
        battleId: currentBattleId.value,
        isShowLoader: false,
      );
      if (!_isSuccess(response)) return;

      final data = _asMap(response?['data']);
      _applyScores(data);
      battleStatus.value = _readText(data, ['status']);
      if (battleStatus.value.toLowerCase() == 'completed' ||
          battleStatus.value.toLowerCase() == 'ended') {
        endBattle(winnerId: _readNullableText(data, ['winnerId', 'winner_id']));
      }
    });
  }

  void _applyScores(Map<String, dynamic> data) {
    final room1Id = _readText(data, ['room1Id', 'room1_id']);
    final room2Id = _readText(data, ['room2Id', 'room2_id']);
    final room1Score = int.tryParse(data['room1Score']?.toString() ?? '') ?? 0;
    final room2Score = int.tryParse(data['room2Score']?.toString() ?? '') ?? 0;

    if (room2Id == myRoomId.value || room1Id == currentOpponentRoomId.value) {
      myPoints.value = room2Score;
      opponentPoints.value = room1Score;
    } else {
      myPoints.value = room1Score;
      opponentPoints.value = room2Score;
    }
  }

  List<Map<String, dynamic>> _parseOpponentPayload(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map>()
          .map((item) => _normalizeOpponent(Map<String, dynamic>.from(item)))
          .where((item) => item['room_id'].toString().isNotEmpty)
          .toList();
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      if (map['rooms'] is List) return _parseOpponentPayload(map['rooms']);
      if (map['opponents'] is List) {
        return _parseOpponentPayload(map['opponents']);
      }
      final normalized = _normalizeOpponent(map);
      return normalized['room_id'].toString().isEmpty ? [] : [normalized];
    }
    return [];
  }

  Map<String, dynamic> _normalizeOpponent(Map<String, dynamic> map) {
    final host = _asMap(map['host']);
    return <String, dynamic>{
      ...map,
      'room_id': _readText(map, ['room_id', 'roomId', 'id']),
      'name': _readText(map, ['name', 'title']).isNotEmpty
          ? _readText(map, ['name', 'title'])
          : _readText(host, ['name', 'hostName']),
      'avatar':
          _readText(map, ['avatar', 'displayPicture', 'coverImage']).isNotEmpty
          ? _readText(map, ['avatar', 'displayPicture', 'coverImage'])
          : _readText(host, ['displayPicture', 'avatar', 'profileImage']),
      'level': map['level'] ?? host['level'] ?? 1,
      'followers': map['followers']?.toString() ?? 'Live now',
      'isOnline': true,
    };
  }

  Widget _scoreColumn(String label, int value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  bool _isSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    if (response['success'] == true) return true;
    final code = response['statusCode'];
    return code == 1 ||
        code == 200 ||
        code == 201 ||
        code?.toString() == '1' ||
        code?.toString() == '200' ||
        code?.toString() == '201';
  }

  String _message(Map<String, dynamic>? response, String fallback) {
    final message = response?['message']?.toString().trim();
    return message == null || message.isEmpty ? fallback : message;
  }

  Map<String, dynamic> _asMap(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    return <String, dynamic>{};
  }

  String _readText(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key]?.toString().trim();
      if (value != null && value.isNotEmpty && value != 'null') return value;
    }
    return '';
  }

  String? _readNullableText(Map<String, dynamic> map, List<String> keys) {
    final value = _readText(map, keys);
    return value.isEmpty ? null : value;
  }

  void _showInfo(String message) {
    Get.snackbar(
      'PK Battle',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.black.withValues(alpha: 0.82),
      colorText: kColorWhite,
    );
  }

  void _showError(String message) {
    Get.snackbar(
      'PK Battle',
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.redAccent.withValues(alpha: 0.92),
      colorText: kColorWhite,
    );
  }
}
