import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/live_room/controllers/live_room_controller.dart';
import 'package:qobo_one_live/constants/image_constants.dart';
import 'package:qobo_one_live/repo/call/call_repo.dart';
import 'package:qobo_one_live/repo/room/room_repo.dart';
import 'package:qobo_one_live/services/chat/chat_call_launcher.dart';
import 'package:qobo_one_live/services/chat/chat_call_service.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/utils/zego_live_id_utils.dart';

/// Profile → Call hub.
///
/// Tabs: 0 Live streaming · 1 Video Rooms · 2 Audio Rooms · 3 Calls (history).
class CallController extends GetxController {
  final hubTab = 0.obs;

  final rooms = <Map<String, dynamic>>[].obs;
  final isRoomsLoading = false.obs;

  final historyFilter = 'all'.obs;
  final historyItems = <Map<String, dynamic>>[].obs;
  final isHistoryLoading = false.obs;
  final isCallsSearchOpen = false.obs;

  final searchQuery = ''.obs;
  final searchResults = <Map<String, dynamic>>[].obs;
  final isSearchLoading = false.obs;
  final isStartingCall = false.obs;
  final searchFieldController = TextEditingController();
  Timer? _searchDebounce;

  final RoomRepo _roomRepo = RoomRepo();
  final CallRepo _callRepo = CallRepo();

  String get currentRoomType {
    switch (hubTab.value) {
      case 1:
        return 'video';
      case 2:
        return 'audio';
      case 0:
      default:
        return 'live_stream';
    }
  }

  String get currentRoomTitle {
    switch (hubTab.value) {
      case 1:
        return 'Video Rooms';
      case 2:
        return 'Audio Rooms';
      case 0:
      default:
        return 'Live Streaming';
    }
  }

  String get currentRoomSubtitle {
    switch (hubTab.value) {
      case 1:
        return 'Jump into an active video party room';
      case 2:
        return 'Join a live audio hangout';
      case 0:
      default:
        return 'Watch and chat in live streams';
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchRooms();
  }

  @override
  void onClose() {
    _searchDebounce?.cancel();
    searchFieldController.dispose();
    super.onClose();
  }

  void selectHubTab(int index) {
    if (hubTab.value == index) return;
    hubTab.value = index;
    if (index == 3) {
      isCallsSearchOpen.value = false;
      searchFieldController.clear();
      searchQuery.value = '';
      searchResults.clear();
      fetchHistory(refresh: true);
    } else {
      fetchRooms();
    }
  }

  Future<void> fetchRooms() async {
    if (hubTab.value == 3) return;
    if (isRoomsLoading.value) return;
    try {
      isRoomsLoading.value = true;
      final type = currentRoomType;
      var response = await _roomRepo.listActiveRooms(
        type: type,
        page: 1,
        limit: 40,
        isShowLoader: false,
      );

      // Fallback: mixed list + client filter when live_stream type empty.
      if (type == 'live_stream' && !_hasRoomList(response)) {
        response = await _roomRepo.listActiveRooms(
          page: 1,
          limit: 40,
          isShowLoader: false,
        );
      }

      final mapped = <Map<String, dynamic>>[];
      if (_hasRoomList(response)) {
        for (final item in response!['data'] as List) {
          if (item is! Map) continue;
          final room = _mapRoom(item);
          if (type == 'live_stream' && room['roomType'] != 'LIVE_STREAM') {
            continue;
          }
          if (type == 'video' && room['roomType'] != 'VIDEO') continue;
          if (type == 'audio' && room['roomType'] != 'AUDIO') continue;
          mapped.add(room);
        }
      }
      rooms.assignAll(mapped);
    } catch (_) {
      rooms.clear();
    } finally {
      isRoomsLoading.value = false;
    }
  }

  void joinRoom(Map<String, dynamic> room) {
    final live = Get.isRegistered<LiveRoomController>()
        ? Get.find<LiveRoomController>()
        : Get.put(LiveRoomController(), permanent: false);
    live.joinRoom(room);
  }

  void selectHistoryFilter(String filter) {
    final normalized = filter.trim().toLowerCase();
    if (historyFilter.value == normalized) return;
    historyFilter.value = normalized;
    fetchHistory(refresh: true);
  }

  void toggleCallsSearch() {
    isCallsSearchOpen.value = !isCallsSearchOpen.value;
    if (!isCallsSearchOpen.value) {
      searchFieldController.clear();
      searchQuery.value = '';
      searchResults.clear();
    }
  }

  Future<void> fetchHistory({bool refresh = true}) async {
    if (isHistoryLoading.value) return;
    try {
      isHistoryLoading.value = true;
      final response = await _callRepo.getHistory(
        filter: historyFilter.value,
        page: 1,
        limit: 40,
        isShowLoader: false,
      );

      if (!_isApiSuccess(response) || response?['data'] is! List) {
        historyItems.clear();
        return;
      }

      historyItems.assignAll(
        (response!['data'] as List)
            .whereType<Map>()
            .map(_mapHistoryItem)
            .toList(),
      );
    } catch (_) {
      historyItems.clear();
    } finally {
      isHistoryLoading.value = false;
    }
  }

  /// WhatsApp-style call button — voice for voice history, video for video.
  Future<void> callBackFromHistory(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final kind = item['kind']?.toString() ?? '';
    if (kind == 'room_join') {
      await _rejoinRoomFromHistory(context, item);
      return;
    }

    final peer = item['peer'] is Map
        ? Map<String, dynamic>.from(item['peer'] as Map)
        : <String, dynamic>{};
    final userId = peer['userId']?.toString() ?? '';
    if (userId.isEmpty) {
      AppToast.showError(context, 'User unavailable for callback');
      return;
    }
    final callType = (item['callType']?.toString() ?? 'voice').toLowerCase();
    await startDirectCall(
      context,
      user: {
        'userId': userId,
        'name': peer['name'] ?? 'User',
        'avatar': peer['avatar'],
        'acceptsVoiceCall': true,
        'acceptsVideoCall': true,
        'voiceCoinsPerSecond': item['coinsPerSecond'],
        'videoCoinsPerSecond': item['coinsPerSecond'],
        'busy': false,
      },
      callType: callType == 'video' ? ChatCallType.video : ChatCallType.voice,
    );
  }

  Future<void> _rejoinRoomFromHistory(
    BuildContext context,
    Map<String, dynamic> item,
  ) async {
    final room = item['room'] is Map
        ? Map<String, dynamic>.from(item['room'] as Map)
        : <String, dynamic>{};
    final isLive = room['isLiveNow'] == true;
    final roomId =
        room['roomId']?.toString() ??
        room['_id']?.toString() ??
        room['id']?.toString() ??
        '';
    if (!isLive || roomId.isEmpty) {
      AppToast.showWarning(context, 'This session is no longer live');
      return;
    }
    final type = (room['type']?.toString() ?? 'audio').toLowerCase();
    final isLiveStream = _isLiveStreamType(type);
    joinRoom({
      'roomType': isLiveStream
          ? 'LIVE_STREAM'
          : (type == 'audio' ? 'AUDIO' : 'VIDEO'),
      'roomData': {
        ...room,
        'id': roomId,
        'room_id': roomId,
        'type': isLiveStream ? 'live_stream' : type,
        'name': room['name'] ?? 'Room',
        'coverImage': room['coverImage'],
      },
    });
  }

  void onSearchChanged(String value) {
    searchQuery.value = value;
    _searchDebounce?.cancel();
    final q = value.trim();
    if (q.isEmpty) {
      searchResults.clear();
      isSearchLoading.value = false;
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
      searchCallUsers(q);
    });
  }

  Future<void> searchCallUsers(String query) async {
    final q = query.trim();
    if (q.isEmpty) {
      searchResults.clear();
      return;
    }
    try {
      isSearchLoading.value = true;
      final response = await _callRepo.searchUsers(
        query: q,
        page: 1,
        limit: 20,
        isShowLoader: false,
      );
      if (!_isApiSuccess(response) || response?['data'] is! List) {
        searchResults.clear();
        return;
      }
      searchResults.assignAll(
        (response!['data'] as List)
            .whereType<Map>()
            .map(_mapSearchUser)
            .toList(),
      );
    } catch (_) {
      searchResults.clear();
    } finally {
      isSearchLoading.value = false;
    }
  }

  Future<void> startDirectCall(
    BuildContext context, {
    required Map<String, dynamic> user,
    required ChatCallType callType,
  }) async {
    if (isStartingCall.value) return;

    final userId = user['userId']?.toString().trim() ?? '';
    final name = user['name']?.toString() ?? 'User';
    if (userId.isEmpty) {
      AppToast.showError(context, 'Invalid user');
      return;
    }

    final isVideo = callType == ChatCallType.video;
    if (isVideo && user['acceptsVideoCall'] == false) {
      AppToast.showError(context, '$name is not accepting video calls');
      return;
    }
    if (!isVideo && user['acceptsVoiceCall'] == false) {
      AppToast.showError(context, '$name is not accepting voice calls');
      return;
    }
    if (user['busy'] == true) {
      AppToast.showError(context, '$name is busy right now');
      return;
    }

    isStartingCall.value = true;
    String? serverCallId;
    try {
      final clientCallId = ZegoLiveIdUtils.sanitize(
        'vc_${DateTime.now().millisecondsSinceEpoch}_${userId.hashCode.abs()}',
      );

      final response = await _callRepo.startDirectCall(
        calleeUserId: userId,
        callType: isVideo ? 'video' : 'voice',
        clientCallId: clientCallId,
        isShowLoader: true,
      );

      if (!_isApiSuccess(response)) {
        if (context.mounted) {
          AppToast.showError(
            context,
            response?['message']?.toString() ?? 'Could not start call',
          );
        }
        return;
      }

      final data = response?['data'] is Map
          ? Map<String, dynamic>.from(response!['data'] as Map)
          : <String, dynamic>{};
      serverCallId = data['callId']?.toString();
      final chatRoomId = data['chatRoomId']?.toString() ?? '';
      final coins =
          _asDouble(data['coinsPerSecond']) ??
          _asDouble(
            isVideo ? user['videoCoinsPerSecond'] : user['voiceCoinsPerSecond'],
          );

      if (!context.mounted) return;

      await ChatCallLauncher.start(
        context: context,
        targetId: userId,
        peerName: name,
        peerAvatar: user['avatar']?.toString(),
        peerCountry: user['countryCode']?.toString(),
        coinsPerSecond: coins,
        roomId: chatRoomId.isNotEmpty ? chatRoomId : null,
        callType: callType,
      );

      if (serverCallId != null && serverCallId.isNotEmpty) {
        await _callRepo.endDirectCall(
          callId: serverCallId,
          reason: 'completed',
          isShowLoader: false,
        );
      }
      unawaited(fetchHistory(refresh: true));
    } catch (_) {
      if (serverCallId != null && serverCallId.isNotEmpty) {
        await _callRepo.endDirectCall(
          callId: serverCallId,
          reason: 'cancelled',
          isShowLoader: false,
        );
      }
      if (context.mounted) {
        AppToast.showError(context, 'Call failed to start');
      }
    } finally {
      isStartingCall.value = false;
    }
  }

  bool _hasRoomList(Map<String, dynamic>? response) {
    return response != null &&
        response['statusCode'] == 1 &&
        response['data'] is List &&
        (response['data'] as List).isNotEmpty;
  }

  bool _isApiSuccess(Map<String, dynamic>? response) {
    if (response == null) return false;
    final code = response['statusCode'];
    return code == 1 || code == 200 || code == 201;
  }

  bool _isLiveStreamType(String? type) {
    final normalized = type?.trim().toLowerCase() ?? '';
    return normalized == 'live_stream' ||
        normalized == 'livestream' ||
        normalized == 'live-stream';
  }

  Map<String, dynamic> _mapRoom(Map room) {
    final rawType = room['type']?.toString() ?? 'video';
    final isLiveStream = _isLiveStreamType(rawType);
    final type = rawType.toUpperCase();
    final rankBadge = room['roomRankBadge'];
    final image = ApiImageUtils.normalize(
      room['coverImage']?.toString() ??
          room['image']?.toString() ??
          room['thumbnail']?.toString(),
    );
    final title =
        room['name']?.toString() ?? room['title']?.toString() ?? 'Room';
    final seats = room['maxSeats'] ?? room['seatConfig'] ?? 0;
    final count =
        room['heatScore'] ??
        room['viewerCount'] ??
        room['onlineCount'] ??
        room['listenerCount'] ??
        room['audienceCount'] ??
        0;

    String badge = '';
    if (rankBadge is Map) {
      final label = rankBadge['label']?.toString().trim() ?? '';
      if (label.isNotEmpty && !_isLiveStreamType(label)) {
        badge = label;
      }
    } else if (!isLiveStream) {
      badge = type;
    }

    return {
      'id': room['_id'] ?? room['id'] ?? '',
      'roomData': Map<String, dynamic>.from(room),
      'nameAge': seats == 0 ? title : '$title · $seats seats',
      'badge': badge,
      'roomType': isLiveStream ? 'LIVE_STREAM' : type,
      'location':
          room['countryName']?.toString() ??
          room['countryCode']?.toString() ??
          room['country']?.toString() ??
          '—',
      'points': count.toString(),
      'favorite': room['isFavorite'] == true || room['isFollowed'] == true,
      'image': image ?? (type == 'AUDIO' ? kImgTemp2 : kImgTemp3),
      'typeLabel': isLiveStream
          ? 'Live'
          : (type == 'AUDIO' ? 'Audio' : 'Video'),
    };
  }

  Map<String, dynamic> _mapHistoryItem(Map raw) {
    final peer = raw['peer'] is Map
        ? Map<String, dynamic>.from(raw['peer'] as Map)
        : <String, dynamic>{};
    if (peer['avatar'] != null) {
      peer['avatar'] =
          ApiImageUtils.normalize(peer['avatar']?.toString()) ?? peer['avatar'];
    }
    final room = raw['room'] is Map
        ? Map<String, dynamic>.from(raw['room'] as Map)
        : <String, dynamic>{};
    if (room['coverImage'] != null) {
      room['coverImage'] =
          ApiImageUtils.normalize(room['coverImage']?.toString()) ??
          room['coverImage'];
    }

    final duration = int.tryParse('${raw['durationSeconds'] ?? 0}') ?? 0;
    final mins = duration ~/ 60;
    final secs = duration % 60;
    final durationLabel =
        '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';

    final direction = raw['direction']?.toString() ?? '';
    final status = raw['status']?.toString() ?? '';
    final callType = raw['callType']?.toString() ?? '';
    final kind = raw['kind']?.toString() ?? 'direct_call';
    final isMissed = status == 'missed' || direction == 'missed';
    final isVideo = callType.contains('video');

    return {
      'id': raw['id']?.toString() ?? '',
      'kind': kind,
      'direction': direction,
      'status': status,
      'callType': callType,
      'peer': peer,
      'room': room,
      'startedAt': raw['startedAt']?.toString() ?? '',
      'endedAt': raw['endedAt']?.toString() ?? '',
      'durationSeconds': duration,
      'durationLabel': durationLabel,
      'coinsCharged': raw['coinsCharged'] ?? 0,
      'coinsPerSecond': raw['coinsPerSecond'],
      'chatRoomId': raw['chatRoomId']?.toString() ?? '',
      'title':
          peer['name']?.toString() ?? room['name']?.toString() ?? 'Session',
      'timeLabel': _relativeTime(raw['startedAt']?.toString()),
      'isMissed': isMissed,
      'isVideo': isVideo,
      'detailLine': _whatsAppDetailLine(
        kind: kind,
        direction: direction,
        status: status,
        callType: callType,
        durationLabel: durationLabel,
        isMissed: isMissed,
      ),
    };
  }

  String _whatsAppDetailLine({
    required String kind,
    required String direction,
    required String status,
    required String callType,
    required String durationLabel,
    required bool isMissed,
  }) {
    if (kind == 'room_join') {
      return '${callType.replaceAll('_', ' ')} · $durationLabel';
    }
    if (isMissed) return 'Missed ${callType.contains('video') ? 'video' : 'voice'} call';
    if (direction == 'incoming') {
      return 'Incoming · $durationLabel';
    }
    if (direction == 'outgoing') {
      return 'Outgoing · $durationLabel';
    }
    return '${status.isEmpty ? callType : status} · $durationLabel';
  }

  String _relativeTime(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24 && now.day == dt.day) {
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Map<String, dynamic> _mapSearchUser(Map raw) {
    final avatar =
        ApiImageUtils.normalize(raw['avatar']?.toString()) ??
        raw['avatar']?.toString() ??
        '';
    return {
      'userId': raw['userId']?.toString() ?? raw['_id']?.toString() ?? '',
      'name': raw['name']?.toString() ?? 'User',
      'username': raw['username']?.toString() ?? '',
      'avatar': avatar,
      'countryCode': raw['countryCode']?.toString() ?? '',
      'isOnline': raw['isOnline'] == true,
      'acceptsVoiceCall': raw['acceptsVoiceCall'] != false,
      'acceptsVideoCall': raw['acceptsVideoCall'] != false,
      'voiceCoinsPerSecond': _asDouble(raw['voiceCoinsPerSecond']),
      'videoCoinsPerSecond': _asDouble(raw['videoCoinsPerSecond']),
      'busy': raw['busy'] == true,
      'minWalletCoinsRequired': raw['minWalletCoinsRequired'] ?? 0,
    };
  }

  double? _asDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
