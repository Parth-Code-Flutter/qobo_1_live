import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/repo/auth/auth_repo.dart';
import 'package:qobo_one_live/repo/chat/chat_local_store.dart';
import 'package:qobo_one_live/repo/chat/chat_navigation_helper.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/repo/user/user_repo.dart';
import 'package:qobo_one_live/app/user_flow/messages/chat_detail/controllers/chat_detail_controller.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/services/chat/chat_firebase_service.dart';
import 'package:qobo_one_live/services/chat/chat_inbox_preview.dart';
import 'package:qobo_one_live/services/chat/chat_incoming_call_coordinator.dart';
import 'package:qobo_one_live/services/chat/chat_logger.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/chat/inbox_live_patch.dart';
import 'package:qobo_one_live/services/chat/inbox_unread.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';
import 'package:qobo_one_live/utils/api_image_utils.dart';
import 'package:qobo_one_live/utils/toast_utils/app_toast.dart';
import 'package:qobo_one_live/app/user_flow/discover/discover_tab/models/explore_discover_utils.dart';

import '../models/social_user_card.dart';
import '../widgets/match_user_sheet.dart';
import '../widgets/messages_common_widgets.dart';

/// Messages tab: New Match discover feed + chat inbox.
class MessagesTabController extends GetxController with WidgetsBindingObserver {
  MessagesTabController({
    AuthRepo? authRepo,
    UserRepo? userRepo,
    ChatRepo? chatRepo,
    ChatLocalStore? localStore,
    ChatFirebaseService? firebaseService,
  }) : _authRepo = authRepo ?? AuthRepo(),
       _userRepo = userRepo ?? UserRepo(),
       _chatRepo = chatRepo ?? ChatRepo(),
       _localStore = localStore ?? ChatLocalStore(),
       _firebaseService = firebaseService ?? ChatFirebaseService();

  final AuthRepo _authRepo;
  final UserRepo _userRepo;
  final ChatRepo _chatRepo;
  final ChatLocalStore _localStore;
  final ChatFirebaseService _firebaseService;

  final searchController = TextEditingController();

  final newMatches = <SocialUserCard>[].obs;
  final searchResults = <SocialUserCard>[].obs;
  final inboxThreads = <MessageListItemModel>[].obs;

  /// `data.total` from `GET /api/user/discover`, not the loaded page size.
  final newMatchesTotal = 0.obs;
  final isNewMatchesLoading = false.obs;
  final isNewMatchesLoadingMore = false.obs;
  int _newMatchesPage = 1;
  bool _newMatchesHasMore = true;
  int _newMatchesGen = 0;
  final isInboxLoading = false.obs;
  final isSearchLoading = false.obs;
  final isSearchMode = false.obs;
  final searchQuery = ''.obs;
  final processingFollowId = ''.obs;

  /// Latest API / local / Firestore rows, kept so a live message can be
  /// merged again after the next list refresh.
  List<MessageListItemModel> _apiThreads = const [];
  List<MessageListItemModel> _localThreads = const [];
  List<MessageListItemModel> _firestoreRoomThreads = const [];
  final Map<String, MessageListItemModel> _roomsById = {};
  final Map<String, _LiveHit> _liveHits = {};

  /// Partner id → latest activity the user has already opened.
  final Map<String, DateTime> _readThrough = {};

  /// Distinct incoming messages seen since the chat was last opened.
  final Map<String, Set<String>> _incomingKeys = {};

  Timer? _inboxPoll;

  StreamSubscription<List<Map<String, dynamic>>>? _inboxRoomsSub;
  final Map<String, StreamSubscription<List<Map<String, dynamic>>>>
  _latestMessageSubs = {};
  final _roomMessages = <String, List<Map<String, dynamic>>>{};
  Future<void>? _inboxFetch;
  int _fetchGen = 0;
  bool _inboxWatchStarted = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    searchController.addListener(_onSearchChanged);
    unawaited(_loadReadMarksThenRefresh());
    unawaited(_syncCoverIfMissing());
  }

  /// Same cover Profile uses, so Messages can paint it on a cold start.
  Future<void> _syncCoverIfMissing() async {
    if (!Get.isRegistered<UserSessionController>()) return;
    final session = Get.find<UserSessionController>();
    if (session.profileBackgroundUrl.trim().isNotEmpty) return;
    await session.syncEquippedProfileBackgroundFromBackpack();
  }

  Future<void> _loadReadMarksThenRefresh() async {
    _readThrough.addAll(await _localStore.readInboxReadMarks());
    await refreshAll();
  }

  Future<void> refreshAll() async {
    await Future.wait([fetchNewMatches(), fetchInbox()]);
  }

  void _onSearchChanged() {
    final text = searchController.text.trim();
    searchQuery.value = text;
    isSearchMode.value = text.isNotEmpty;
    if (text.isEmpty) {
      searchResults.clear();
      return;
    }
    performSearch(text);
  }

  /// `GET /api/user/discover` for the New sparks row.
  ///
  /// [refresh] reloads page 1. Further pages append only for this row.
  Future<void> fetchNewMatches({bool refresh = true}) async {
    if (!refresh) {
      if (!_newMatchesHasMore ||
          isNewMatchesLoading.value ||
          isNewMatchesLoadingMore.value) {
        return;
      }
    }

    final page = refresh ? 1 : _newMatchesPage;
    final gen = refresh ? ++_newMatchesGen : _newMatchesGen;
    try {
      if (refresh) {
        _newMatchesHasMore = true;
        if (newMatches.isEmpty) isNewMatchesLoading.value = true;
      } else {
        isNewMatchesLoadingMore.value = true;
      }
      final response = await _userRepo.discoverUsers(
        page: page,
        limit: 20,
        isShowLoader: false,
      );
      if (gen != _newMatchesGen) return;
      final parsed = ExploreDiscoverPage.fromApiResponse(response);
      if (refresh) {
        newMatches.assignAll(parsed.users);
      } else {
        final seen = newMatches.map((user) => user.id).toSet();
        final added = parsed.users
            .where((user) => user.id.isEmpty || seen.add(user.id))
            .toList();
        if (added.isEmpty) {
          _newMatchesHasMore = false;
          return;
        }
        newMatches.addAll(added);
      }
      newMatchesTotal.value = parsed.total > 0
          ? parsed.total
          : newMatches.length;
      final loadedAll =
          parsed.total > 0 && newMatches.length >= parsed.total;
      _newMatchesHasMore = parsed.hasMore && !loadedAll;
      if (parsed.users.isNotEmpty) _newMatchesPage = page + 1;
    } catch (_) {
      if (refresh && gen == _newMatchesGen) {
        newMatches.clear();
        newMatchesTotal.value = 0;
      }
    } finally {
      if (gen == _newMatchesGen) {
        isNewMatchesLoading.value = false;
        isNewMatchesLoadingMore.value = false;
      }
    }
  }

  /// Next New sparks page. Chats stay on their own list.
  Future<void> loadMoreNewMatches() => fetchNewMatches(refresh: false);

  /// `GET /api/user/search` when user types in header search bar.
  Future<void> performSearch(String query) async {
    try {
      isSearchLoading.value = true;
      final response = await _authRepo.searchUsers(
        query: query,
        isShowLoader: false,
      );
      if (isSocialApiSuccess(response)) {
        searchResults.assignAll(
          SocialUserCard.listFromResponseData(response!['data']),
        );
        return;
      }
      searchResults.clear();
    } catch (_) {
      searchResults.clear();
    } finally {
      isSearchLoading.value = false;
    }
  }

  /// `GET /api/chat/list` for Message section (+ local cache until send API live).
  Future<void> fetchInbox({bool silent = false}) {
    return _inboxFetch ??= _fetchInbox(silent: silent).whenComplete(() {
      _inboxFetch = null;
    });
  }

  Future<void> _fetchInbox({bool silent = false}) async {
    final gen = ++_fetchGen;
    final showLoading = !silent || inboxThreads.isEmpty;
    try {
      if (showLoading) isInboxLoading.value = true;
      ChatLogger.inbox('fetch start');
      final apiThreads = <MessageListItemModel>[];
      final response = await _chatRepo.getInbox(isShowLoader: false);
      if (isSocialApiSuccess(response)) {
        final list = response!['data'];
        if (list is List) {
          apiThreads.addAll(
            list.whereType<Map>().toList().asMap().entries.map((entry) {
              return _mapInboxThread(
                Map<String, dynamic>.from(entry.value),
                entry.key,
              );
            }),
          );
        }
      } else {
        ChatLogger.apiWarn('GET /api/chat/list', 'failed', {
          'message': response?['message']?.toString() ?? 'unknown',
        });
      }

      final localRaw = await _localStore.readInboxThreads();
      final localThreads = localRaw
          .where((t) {
            final message = t['lastMessage']?.toString().trim() ?? '';
            final type = t['lastMessageType']?.toString();
            return message.isNotEmpty || ChatInboxPreviewType.isCallType(type);
          })
          .map((json) => _mapInboxThread(json, 0))
          .toList();

      var firestoreThreads = <MessageListItemModel>[];
      if (_firebaseService.isAvailable) {
        firestoreThreads = await _fetchInboxFromFirestore();
      }

      if (gen != _fetchGen) return;

      _apiThreads = apiThreads;
      _localThreads = localThreads;
      _rememberRooms(apiThreads);
      _rememberRooms(localThreads);
      _rememberRooms(firestoreThreads);
      if (firestoreThreads.isNotEmpty) {
        _firestoreRoomThreads = _mergeAllInboxSources(
          _firestoreRoomThreads,
          firestoreThreads,
          const [],
        );
      }
      _publishInbox();
      _startInboxPoll();
      unawaited(_ensureInboxWatch());
      ChatLogger.inbox('fetch merged', {
        'api': apiThreads.length,
        'firestore': firestoreThreads.length,
        'local': localThreads.length,
        'total': inboxThreads.length,
      });
    } catch (e) {
      ChatLogger.inboxWarn('fetch failed', {'error': e});
      // Keep the last known counts during temporary network failures.
    } finally {
      if (gen == _fetchGen && showLoading) isInboxLoading.value = false;
    }
  }

  void _startInboxPoll() {
    if (_inboxPoll != null) return;
    _inboxPoll = Timer.periodic(const Duration(seconds: 3), (_) {
      if (isInboxLoading.value) return;
      unawaited(fetchInbox(silent: true));
    });
  }

  void _rememberRooms(Iterable<MessageListItemModel> threads) {
    for (final thread in threads) {
      if (thread.roomId.isEmpty || thread.targetId.isEmpty) continue;
      final existing = _roomsById[thread.roomId];
      _roomsById[thread.roomId] = existing == null
          ? thread
          : _mergeTwoInboxThreads(existing, thread);
    }
  }

  void _publishInbox() {
    final merged = _mergeAllInboxSources(
      _apiThreads,
      _firestoreRoomThreads,
      _localThreads,
    );
    final next = <MessageListItemModel>[];
    final usedRooms = <String>{};

    for (final thread in merged) {
      final hit = thread.roomId.isEmpty ? null : _liveHits[thread.roomId];
      if (hit == null) {
        next.add(_applyReadMark(thread));
        continue;
      }
      usedRooms.add(thread.roomId);
      next.add(_applyReadMark(_applyHit(thread, hit)));
    }

    for (final hit in _liveHits.values) {
      if (usedRooms.contains(hit.roomId)) continue;
      final known = _roomsById[hit.roomId];
      if (known == null || known.targetId.isEmpty) continue;
      final patched = _applyReadMark(_applyHit(known, hit));
      if (!_hasInboxPreview(patched)) continue;
      next.add(patched);
    }

    next.sort((a, b) {
      final ad = a.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bd = b.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bd.compareTo(ad);
    });
    inboxThreads.assignAll(
      next.map((thread) {
        final snapshot = _roomMessages[thread.roomId];
        if (snapshot == null ||
            (snapshot.isEmpty && !_readThrough.containsKey(thread.targetId))) {
          return thread;
        }
        return _withUnread(
          thread,
          _isViewingChat(thread.targetId)
              ? 0
              : countUnreadMessages(
                  messages: snapshot,
                  myUserId: _myUserId ?? '',
                  readThrough: _readThrough[thread.targetId],
                ),
        );
      }),
    );
    _syncLatestMessageWatchers();
    _syncIncomingCallWatchers();
  }

  MessageListItemModel _applyHit(MessageListItemModel thread, _LiveHit hit) {
    final update = InboxLiveUpdate.resolve(
      currentActivityAt: thread.lastActivityAt,
      currentPreview: thread.message,
      messageAt: hit.activityAt,
      preview: hit.preview,
      messageType: hit.messageType,
      shownUnread: thread.unreadCount > hit.unreadCount
          ? thread.unreadCount
          : hit.unreadCount,
      fromMe: true,
      chatOpen: _isViewingChat(thread.targetId),
      alreadyCounted: true,
    );
    if (update == null) return thread;
    return MessageListItemModel(
      targetId: thread.targetId,
      name: thread.name,
      message: update.preview,
      time: _formatThreadTime(update.activityAt.toUtc().toIso8601String()),
      imageUrl: thread.imageUrl,
      avatarFrameUrl: thread.avatarFrameUrl,
      unreadCount: update.unreadCount,
      roomId: thread.roomId.isNotEmpty ? thread.roomId : hit.roomId,
      lastMessageType: update.messageType,
      lastCallDirection: hit.callDirection ?? thread.lastCallDirection,
      lastActivityAt: update.activityAt,
    );
  }

  Future<void> _ensureInboxWatch() async {
    if (_inboxWatchStarted || !_firebaseService.isAvailable) return;
    final myId = _myUserId;
    if (myId == null || myId.isEmpty) return;

    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    final signedIn = await Get.find<ChatSessionService>().ensureSignedIn(
      isShowLoader: false,
    );
    if (!signedIn || _inboxWatchStarted) return;

    _inboxWatchStarted = true;
    _inboxRoomsSub = _firebaseService
        .watchUserChatRooms(myId)
        .listen(
          _onUserChatRooms,
          onError: (Object e) {
            _inboxWatchStarted = false;
            unawaited(_inboxRoomsSub?.cancel());
            ChatLogger.inboxWarn('inbox watch failed', {'error': e});
          },
        );
  }

  void _onUserChatRooms(List<Map<String, dynamic>> rows) {
    final threads = rows
        .map((raw) => _mapInboxThread(Map<String, dynamic>.from(raw), 0))
        .toList();
    _rememberRooms(threads);
    final withPreview = threads.where(_hasInboxPreview).toList();
    if (withPreview.isNotEmpty) {
      _firestoreRoomThreads = _mergeAllInboxSources(
        _firestoreRoomThreads,
        withPreview,
        const [],
      );
    }
    _publishInbox();
  }

  void _syncLatestMessageWatchers() {
    if (!_firebaseService.isAvailable) return;
    final roomIds = _roomsById.keys.toSet();
    final stale = _latestMessageSubs.keys
        .where((roomId) => !roomIds.contains(roomId))
        .toList();
    for (final roomId in stale) {
      unawaited(_latestMessageSubs.remove(roomId)?.cancel());
    }

    for (final roomId in roomIds) {
      if (_latestMessageSubs.containsKey(roomId)) continue;
      _latestMessageSubs[roomId] = _firebaseService
          .watchInboxMessages(
            roomId,
            after: _readThrough[_roomsById[roomId]?.targetId],
          )
          .listen(
            (rows) {
              _roomMessages[roomId] = rows;
              if (rows.isNotEmpty) _onLatestMessage(roomId, rows.last);
              _publishInbox();
            },
            onError: (Object e) {
              unawaited(_latestMessageSubs.remove(roomId)?.cancel());
              ChatLogger.inboxWarn('latest message watch failed', {
                'roomId': roomId,
                'error': e,
              });
            },
          );
    }
  }

  void _onLatestMessage(String roomId, Map<String, dynamic>? raw) {
    if (raw == null) return;
    final messageId =
        raw['id']?.toString() ?? raw['messageId']?.toString() ?? '';
    if (messageId.isEmpty) return;

    final current = _threadForRoom(roomId) ?? _roomsById[roomId];
    if (current == null || current.targetId.isEmpty) return;

    final type = _inboxTypeForMessage(raw);
    final preview = ChatFirebaseService.messagePreview(raw);
    final text = preview.isNotEmpty
        ? preview
        : ChatInboxPreviewType.displayLabel(type);
    final fromMe = (raw['senderId']?.toString() ?? '') == (_myUserId ?? '');
    final messageAt = ChatFirebaseService.messageActivityAt(raw);
    if (!fromMe &&
        !_isViewingChat(current.targetId) &&
        _activityIsUnread(current.targetId, messageAt)) {
      final key = incomingMessageKey(
        preview: text,
        activityAt: messageAt,
        messageId: messageId,
      );
      if (key.isNotEmpty) {
        _incomingKeys.putIfAbsent(current.targetId, () => <String>{}).add(key);
      }
    }
    final update = InboxLiveUpdate.resolve(
      currentActivityAt: current.lastActivityAt,
      currentPreview: current.message,
      messageAt: ChatFirebaseService.messageActivityAt(raw),
      preview: text,
      messageType: type,
      shownUnread: unreadBadgeCount(
        reportedCount: _readThrough.containsKey(current.targetId)
            ? 0
            : _shownUnread(roomId, current),
        seenIncomingCount: _incomingKeys[current.targetId]?.length ?? 0,
        alreadyRead: fromMe || !_activityIsUnread(current.targetId, messageAt),
        sinceRead: _readThrough.containsKey(current.targetId),
      ),
      fromMe: fromMe,
      chatOpen: _isViewingChat(current.targetId),
      // The badge count already includes this message. Do not add it again.
      alreadyCounted: true,
    );
    if (update == null) return;

    _liveHits[roomId] = _LiveHit(
      messageId: messageId,
      roomId: roomId,
      preview: update.preview,
      messageType: update.messageType,
      activityAt: update.activityAt,
      unreadCount: update.unreadCount,
      callDirection: _callDirection(raw),
    );
    _roomsById[roomId] = _applyHit(
      _roomsById[roomId] ?? current,
      _liveHits[roomId]!,
    );
    _publishInbox();
    ChatLogger.inbox('live row', {
      'roomId': roomId,
      'messageId': messageId,
      'fromMe': fromMe,
    });
  }

  int _shownUnread(String roomId, MessageListItemModel fallback) {
    final shown = _threadForRoom(roomId)?.unreadCount ?? fallback.unreadCount;
    final live = _liveHits[roomId]?.unreadCount ?? 0;
    return shown > live ? shown : live;
  }

  MessageListItemModel? _threadForRoom(String roomId) {
    for (final thread in inboxThreads) {
      if (thread.roomId == roomId) return thread;
    }
    return null;
  }

  bool _isViewingChat(String targetId) {
    if (WidgetsBinding.instance.lifecycleState != null &&
        WidgetsBinding.instance.lifecycleState != AppLifecycleState.resumed) {
      return false;
    }
    if (targetId.isEmpty || Get.currentRoute != Routes.CHAT_DETAIL) {
      return false;
    }
    if (!Get.isRegistered<ChatDetailController>()) return false;
    return Get.find<ChatDetailController>().targetId.value == targetId;
  }

  String _inboxTypeForMessage(Map<String, dynamic> raw) {
    final type = raw['type']?.toString() ?? ChatInboxPreviewType.text;
    if (type != 'voice_call' && type != 'video_call') return type;
    final content = raw['content'];
    if (content is! Map) {
      return type == 'video_call'
          ? ChatInboxPreviewType.videoCall
          : ChatInboxPreviewType.voiceCall;
    }
    return ChatInboxPreviewType.inboxTypeForUser(
      isVideo: type == 'video_call',
      outcome: content['status']?.toString() ?? 'completed',
      isCallee: content['calleeId']?.toString() == (_myUserId ?? ''),
    );
  }

  String? _callDirection(Map<String, dynamic> raw) {
    final type = raw['type']?.toString() ?? '';
    if (type != 'voice_call' && type != 'video_call') return null;
    final content = raw['content'];
    if (content is! Map) return null;
    return content['calleeId']?.toString() == (_myUserId ?? '')
        ? 'incoming'
        : 'outgoing';
  }

  List<MessageListItemModel> _mergeAllInboxSources(
    List<MessageListItemModel> api,
    List<MessageListItemModel> firestore,
    List<MessageListItemModel> local,
  ) {
    final byId = <String, MessageListItemModel>{};
    for (final thread in [...api, ...firestore, ...local]) {
      if (thread.targetId.isEmpty) continue;
      final existing = byId[thread.targetId];
      byId[thread.targetId] = existing == null
          ? thread
          : _mergeTwoInboxThreads(existing, thread);
    }

    final merged = byId.values.toList()
      ..sort((a, b) {
        final ad = a.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bd = b.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bd.compareTo(ad);
      });
    return merged;
  }

  MessageListItemModel _mergeTwoInboxThreads(
    MessageListItemModel a,
    MessageListItemModel b,
  ) {
    final aTime = a.lastActivityAt;
    final bTime = b.lastActivityAt;
    final pickB = bTime != null && (aTime == null || !bTime.isBefore(aTime));
    final newer = pickB ? b : a;
    final older = pickB ? a : b;
    // Only inherit an older call preview when both sources report the same
    // moment (one lacks call info); a genuinely newer text must win.
    final sameMoment =
        aTime == null || bTime == null || aTime.isAtSameMomentAs(bTime);

    return MessageListItemModel(
      targetId: newer.targetId,
      name: _resolveInboxName(newer.name, older.name),
      message: newer.message.isNotEmpty ? newer.message : older.message,
      time: newer.time.isNotEmpty ? newer.time : older.time,
      imageUrl: _resolveInboxImageUrl(newer, older),
      avatarFrameUrl: _resolveInboxFrameUrl(newer, older),
      unreadCount: newer.unreadCount > older.unreadCount
          ? newer.unreadCount
          : older.unreadCount,
      roomId: newer.roomId.isNotEmpty ? newer.roomId : older.roomId,
      lastMessageType: newer.lastMessageType != ChatInboxPreviewType.text
          ? newer.lastMessageType
          : (sameMoment &&
                    ChatInboxPreviewType.isCallType(older.lastMessageType)
                ? older.lastMessageType
                : newer.lastMessageType),
      lastCallDirection: newer.lastCallDirection ?? older.lastCallDirection,
      lastActivityAt: newer.lastActivityAt ?? older.lastActivityAt,
    );
  }

  /// Prefers real profile names from API over Firestore/local placeholder "User".
  static String _resolveInboxName(String primary, String fallback) {
    final primaryGeneric = _isGenericInboxName(primary);
    final fallbackGeneric = _isGenericInboxName(fallback);
    if (!primaryGeneric && fallbackGeneric) return primary;
    if (primaryGeneric && !fallbackGeneric) return fallback;
    if (!primaryGeneric) return primary;
    return fallback.isNotEmpty ? fallback : primary;
  }

  static String? _resolveInboxImageUrl(
    MessageListItemModel primary,
    MessageListItemModel fallback,
  ) {
    if (!_isGenericInboxName(primary.name) &&
        primary.imageUrl != null &&
        primary.imageUrl!.isNotEmpty) {
      return primary.imageUrl;
    }
    if (!_isGenericInboxName(fallback.name) &&
        fallback.imageUrl != null &&
        fallback.imageUrl!.isNotEmpty) {
      return fallback.imageUrl;
    }
    return primary.imageUrl ?? fallback.imageUrl;
  }

  /// Prefer a real API frame over an empty/missing value when merging sources.
  static String? _resolveInboxFrameUrl(
    MessageListItemModel primary,
    MessageListItemModel fallback,
  ) {
    final primaryFrame = primary.avatarFrameUrl?.trim();
    if (primaryFrame != null && primaryFrame.isNotEmpty) return primaryFrame;
    final fallbackFrame = fallback.avatarFrameUrl?.trim();
    if (fallbackFrame != null && fallbackFrame.isNotEmpty) return fallbackFrame;
    return null;
  }

  static bool _isGenericInboxName(String name) {
    final trimmed = name.trim().toLowerCase();
    return trimmed.isEmpty || trimmed == 'user';
  }

  void _syncIncomingCallWatchers() {
    if (!Get.isRegistered<ChatIncomingCallCoordinator>()) return;
    final roomIds = inboxThreads
        .map((thread) => thread.roomId)
        .where((id) => id.isNotEmpty);
    Get.find<ChatIncomingCallCoordinator>().syncWatchedRooms(
      roomIds,
      replace: true,
    );
  }

  Future<List<MessageListItemModel>> _fetchInboxFromFirestore() async {
    final myId = _myUserId;
    if (myId == null || myId.isEmpty) return [];

    if (!Get.isRegistered<ChatSessionService>()) {
      Get.put(ChatSessionService(), permanent: true);
    }
    final signedIn = await Get.find<ChatSessionService>().ensureSignedIn(
      isShowLoader: false,
    );
    if (!signedIn) return [];

    final rows = await _firebaseService.fetchInboxRoomsForUser(myId);
    return rows
        .whereType<Map>()
        .map((raw) => _mapInboxThread(Map<String, dynamic>.from(raw), 0))
        .where(_hasInboxPreview)
        .toList();
  }

  /// Called only after chat content was displayed in the foreground.
  void markConversationRead(String targetId, DateTime activityAt) {
    _stampRead(targetId, activityAt);
  }

  MessageListItemModel _withUnread(MessageListItemModel thread, int count) =>
      MessageListItemModel(
        targetId: thread.targetId,
        name: thread.name,
        message: thread.message,
        time: thread.time,
        imageUrl: thread.imageUrl,
        avatarFrameUrl: thread.avatarFrameUrl,
        unreadCount: count,
        roomId: thread.roomId,
        lastMessageType: thread.lastMessageType,
        lastCallDirection: thread.lastCallDirection,
        lastActivityAt: thread.lastActivityAt,
      );

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(fetchInbox(silent: true));
    _publishInbox();
  }

  /// Everything up to this moment has been seen. The old API total is dropped.
  void _stampRead(String targetId, DateTime cutoff) {
    if (targetId.isEmpty) return;
    final previous = _readThrough[targetId];
    final mark = previous == null || cutoff.isAfter(previous)
        ? cutoff
        : previous;
    _readThrough[targetId] = mark;
    _incomingKeys.remove(targetId);
    unawaited(_localStore.writeInboxReadMark(targetId, mark));
    _publishInbox();
  }

  MessageListItemModel _applyReadMark(MessageListItemModel thread) {
    if (thread.unreadCount == 0) return thread;
    final seen = _readThrough[thread.targetId];
    if (seen == null) return thread;
    final activity = thread.lastActivityAt;
    if (activity != null && activity.isAfter(seen)) return thread;
    return MessageListItemModel(
      targetId: thread.targetId,
      name: thread.name,
      message: thread.message,
      time: thread.time,
      imageUrl: thread.imageUrl,
      avatarFrameUrl: thread.avatarFrameUrl,
      unreadCount: 0,
      roomId: thread.roomId,
      lastMessageType: thread.lastMessageType,
      lastCallDirection: thread.lastCallDirection,
      lastActivityAt: thread.lastActivityAt,
    );
  }

  bool _hasInboxPreview(MessageListItemModel thread) {
    if (thread.targetId.isEmpty) return false;
    if (thread.message.trim().isNotEmpty) return true;
    return ChatInboxPreviewType.isCallType(thread.lastMessageType);
  }

  String? get _myUserId {
    if (!Get.isRegistered<UserSessionController>()) return null;
    return Get.find<UserSessionController>().userId;
  }

  MessageListItemModel _mapInboxThread(Map<String, dynamic> json, int index) {
    final recipient = json['recipient'];
    final Map<String, dynamic>? recipientMap = recipient is Map
        ? Map<String, dynamic>.from(recipient)
        : null;

    final name =
        recipientMap?['name']?.toString().trim() ??
        json['name']?.toString().trim() ??
        'User';
    final targetId =
        json['id']?.toString() ??
        json['peerId']?.toString() ??
        recipientMap?['id']?.toString() ??
        '';
    final picture = recipientMap?['displayPicture']?.toString();
    // Same frame parsing as New Match (`SocialUserCard` / recipient.avatarFrame).
    final avatarFrameUrl = recipientMap == null
        ? null
        : SocialUserCard.fromJson(recipientMap).avatarFrameUrl;

    final rawLastMessageType = json['lastMessageType']?.toString();
    var lastMessageType = rawLastMessageType ?? ChatInboxPreviewType.text;
    final previewRaw =
        json['lastMessage']?.toString() ??
        json['lastMessagePreview']?.toString() ??
        '';

    final callStatus = json['lastCallStatus']?.toString();
    final callDirection = json['lastCallDirection']?.toString();
    final callMediaType = json['lastCallType']?.toString();
    // Call fields linger after a call; only use them when the last item is a
    // call (or the type is unknown), not when a newer text came after it.
    final lastItemIsCall =
        rawLastMessageType == null ||
        ChatInboxPreviewType.isCallType(rawLastMessageType);
    if (lastItemIsCall &&
        callStatus != null &&
        callStatus.isNotEmpty &&
        callMediaType != null &&
        callMediaType.isNotEmpty) {
      lastMessageType = ChatInboxPreviewType.inboxTypeForUser(
        isVideo: callMediaType == 'video',
        outcome: callStatus,
        isCallee: callDirection == 'incoming',
      );
    }

    final preview = ChatInboxPreviewType.displayLabel(
      lastMessageType,
      fallbackPreview: previewRaw,
    );
    final activityRaw =
        json['lastMessageTime']?.toString() ??
        json['lastMessageAt']?.toString();
    final activityAt = _parseThreadDateTime(activityRaw);

    return MessageListItemModel(
      targetId: targetId,
      name: name.isNotEmpty ? name : 'User',
      message: preview,
      time: _formatThreadTime(activityRaw),
      imageUrl: ApiImageUtils.normalize(picture),
      avatarFrameUrl: avatarFrameUrl,
      unreadCount: _noteIncomingUnread(
        json: json,
        targetId: targetId,
        preview: preview,
        activityRaw: activityRaw,
        activityAt: activityAt,
      ),
      roomId: json['roomId']?.toString() ?? '',
      lastMessageType: lastMessageType,
      lastCallDirection: json['lastCallDirection']?.toString(),
      lastActivityAt: activityAt,
    );
  }

  int _noteIncomingUnread({
    required Map<String, dynamic> json,
    required String targetId,
    required String preview,
    required String? activityRaw,
    required DateTime? activityAt,
  }) {
    final myId = _myUserId ?? '';
    final reported = reportedInboxUnread(json);
    final sender = inboxLastSenderId(json);
    final fromMe =
        json['localOnly'] == true ||
        json['lastMessageFromMe'] == true ||
        json['sentByMe'] == true ||
        (sender.isNotEmpty && myId.isNotEmpty && sender == myId);
    if (fromMe) {
      return reported;
    }

    final alreadyRead = !_activityIsUnread(targetId, activityAt);
    if (alreadyRead) return 0;

    if (inboxPayloadIsIncoming(json: json, myUserId: myId)) {
      final key = incomingMessageKey(
        preview: preview,
        activityAt: activityAt,
        activityRaw: activityRaw,
        messageId: json['lastMessageId']?.toString(),
      );
      if (key.isNotEmpty && targetId.isNotEmpty) {
        _incomingKeys.putIfAbsent(targetId, () => <String>{}).add(key);
      }
    }

    return unreadBadgeCount(
      reportedCount: reported,
      seenIncomingCount: _incomingKeys[targetId]?.length ?? 0,
      alreadyRead: false,
    );
  }

  bool _activityIsUnread(String targetId, DateTime? activityAt) {
    final seen = _readThrough[targetId];
    if (seen == null) return true;
    if (activityAt == null) return false;
    return activityAt.isAfter(seen);
  }

  Future<void> toggleFollow(BuildContext context, SocialUserCard user) async {
    if (user.id.isEmpty) return;
    final action = user.isFollowing ? 'unfollow' : 'follow';
    processingFollowId.value = user.id;
    try {
      final response = await _authRepo.followUnfollow(
        targetId: user.id,
        action: action,
        isShowLoader: false,
      );
      if (!context.mounted) return;
      if (isSocialApiSuccess(response)) {
        final data = response?['data'];
        final Map<String, dynamic>? dataMap = data is Map
            ? Map<String, dynamic>.from(data)
            : null;
        final isFollowing =
            dataMap?['isFollowing'] == true ||
            (action == 'follow' && dataMap == null);
        final isFollower = dataMap?['isFollower'] == true || user.isFollower;
        final isMutual =
            dataMap?['isMutual'] == true || (isFollowing && isFollower);
        final canMessage =
            dataMap?['canMessage'] == true ||
            isFollowing ||
            isFollower ||
            isMutual;

        _applyFollowState(
          user.id,
          isFollowing: isFollowing,
          isFollower: isFollower,
          isMutual: isMutual,
          canMessage: canMessage,
          followersCount: _toInt(dataMap?['followersCount']),
          followingCount: _toInt(dataMap?['followingCount']),
        );
        AppToast.showSuccess(
          context,
          isFollowing ? 'Followed successfully' : 'Unfollowed successfully',
        );
        return;
      }
      AppToast.showError(
        context,
        response?['message']?.toString() ?? 'Action failed',
      );
    } catch (e) {
      if (!context.mounted) return;
      AppToast.showError(context, 'Error: $e');
    } finally {
      processingFollowId.value = '';
    }
  }

  void _applyFollowState(
    String userId, {
    required bool isFollowing,
    bool? isFollower,
    bool? isMutual,
    bool? canMessage,
    int? followersCount,
    int? followingCount,
  }) {
    SocialUserCard merge(SocialUserCard u) {
      if (u.id != userId) return u;
      final nextFollower = isFollower ?? u.isFollower;
      final nextFollowing = isFollowing;
      final nextMutual =
          isMutual ?? ((nextFollowing && nextFollower) || u.isMutual);
      final nextCanMessage =
          canMessage ??
          (nextFollowing || nextFollower || nextMutual || u.canMessage);
      return u.copyWith(
        isFollowing: nextFollowing,
        isFollower: nextFollower,
        isMutual: nextMutual,
        canMessage: nextCanMessage,
        followersCount: followersCount ?? u.followersCount,
        followingCount: followingCount ?? u.followingCount,
      );
    }

    newMatches.value = newMatches.map(merge).toList();
    searchResults.value = searchResults.map(merge).toList();
  }

  SocialUserCard? userById(String id) {
    for (final u in newMatches) {
      if (u.id == id) return u;
    }
    for (final u in searchResults) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Opens chat when allowed (`canMessage` = either follows the other).
  Future<void> openChat(BuildContext context, SocialUserCard user) async {
    if (user.id.isEmpty) return;
    if (!user.canMessage) {
      AppToast.showError(context, 'Follow each other to start messaging');
      return;
    }

    await ChatNavigationHelper.openDirectChat(
      context,
      targetId: user.id,
      name: user.name,
      imageUrl: user.displayPicture,
      avatarFrameUrl: user.avatarFrameUrl,
    );
    fetchInbox();
  }

  Future<void> openChatFromInbox(
    BuildContext context,
    MessageListItemModel thread,
  ) async {
    if (thread.targetId.isEmpty) {
      AppToast.showError(context, 'Invalid chat partner');
      return;
    }

    await ChatNavigationHelper.openDirectChat(
      context,
      targetId: thread.targetId,
      name: thread.name,
      imageUrl: thread.imageUrl,
      avatarFrameUrl: thread.avatarFrameUrl,
      roomId: thread.roomId.isNotEmpty ? thread.roomId : null,
    );
    fetchInbox();
  }

  Future<SocialUserCard?> fetchPublicProfile(String userId) async {
    if (userId.isEmpty) return null;
    final cached = userById(userId);
    try {
      final response = await _userRepo.getPublicProfile(
        userId: userId,
        isShowLoader: false,
      );
      if (isSocialApiSuccess(response) && response?['data'] is Map) {
        final fresh = SocialUserCard.fromJson(
          Map<String, dynamic>.from(response!['data'] as Map),
        );
        if (cached != null) {
          return fresh.copyWith(
            isFollowing: cached.isFollowing || fresh.isFollowing,
            isFollower: cached.isFollower || fresh.isFollower,
            isMutual: cached.isMutual || fresh.isMutual,
            canMessage: cached.canMessage || fresh.canMessage,
          );
        }
        return fresh;
      }
    } catch (_) {}
    return cached;
  }

  static DateTime? _parseThreadDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw).toLocal();
    } catch (_) {
      return null;
    }
  }

  static String _formatThreadTime(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw).toLocal();
      final now = DateTime.now();
      if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  static int _toInt(dynamic raw) {
    if (raw is int) return raw;
    return int.tryParse(raw?.toString() ?? '') ?? 0;
  }

  MatchUserSheetActions get matchSheetActions => MatchUserSheetActions(
    processingFollowId: processingFollowId,
    userById: userById,
    fetchPublicProfile: fetchPublicProfile,
    toggleFollow: toggleFollow,
    openChat: openChat,
  );

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _inboxPoll?.cancel();
    unawaited(_inboxRoomsSub?.cancel());
    for (final sub in _latestMessageSubs.values) {
      unawaited(sub.cancel());
    }
    _latestMessageSubs.clear();
    searchController.dispose();
    super.onClose();
  }
}

class _LiveHit {
  const _LiveHit({
    required this.messageId,
    required this.roomId,
    required this.preview,
    required this.messageType,
    required this.activityAt,
    required this.unreadCount,
    this.callDirection,
  });

  final String messageId;
  final String roomId;
  final String preview;
  final String messageType;
  final DateTime activityAt;
  final int unreadCount;
  final String? callDirection;
}
