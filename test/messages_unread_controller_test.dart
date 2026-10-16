import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/app/user_flow/messages/chat_detail/controllers/chat_detail_controller.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/messages/messages_tab/controllers/messages_tab_controller.dart';
import 'package:qobo_one_live/repo/chat/chat_local_store.dart';
import 'package:qobo_one_live/repo/chat/chat_repo.dart';
import 'package:qobo_one_live/services/chat/chat_firebase_service.dart';
import 'package:qobo_one_live/services/chat/chat_session_service.dart';
import 'package:qobo_one_live/services/user_session_controller.dart';

class Session extends UserSessionController {
  @override
  String get userId => 'me';
}

class FirebaseSession extends ChatSessionService {
  @override
  Future<bool> ensureSignedIn({bool isShowLoader = false}) async => true;
}

class Store extends ChatLocalStore {
  final marks = <String, DateTime>{};
  @override
  Future<List<Map<String, dynamic>>> readInboxThreads() async => [];
  @override
  Future<void> writeInboxReadMark(String targetId, DateTime activityAt) async {
    marks[targetId] = activityAt;
  }
}

class Repo extends ChatRepo {
  int calls = 0;
  Completer<Map<String, dynamic>?>? pending;
  bool fail = false;
  @override
  Future<Map<String, dynamic>?> getInbox({bool isShowLoader = true}) async {
    calls++;
    if (fail) throw Exception('offline');
    if (pending != null) return pending!.future;
    return {
      'statusCode': 1,
      'data': [
        for (final peer in ['alice', 'bob'])
          {
            'id': peer,
            'roomId': peer,
            'lastMessage': 'Hello',
            'lastMessageTime': '2026-10-16T10:00:00Z',
            'unreadCount': 42,
            'recipient': {'id': peer, 'name': peer},
          },
      ],
    };
  }
}

class Firebase extends ChatFirebaseService {
  final streams = <String, StreamController<List<Map<String, dynamic>>>>{};
  @override
  bool get isAvailable => true;
  @override
  Future<List<Map<String, dynamic>>> fetchInboxRoomsForUser(
    String userId,
  ) async => [];
  @override
  Stream<List<Map<String, dynamic>>> watchUserChatRooms(String userId) =>
      const Stream.empty();
  @override
  Stream<List<Map<String, dynamic>>> watchInboxMessages(
    String roomId, {
    DateTime? after,
  }) => (streams[roomId] ??= StreamController.broadcast()).stream;
  void emit(String room, List<Map<String, dynamic>> messages) =>
      streams[room]!.add(messages);
}

Map<String, dynamic> message(
  String id,
  DateTime at, {
  String sender = 'alice',
  bool read = false,
}) => {
  'id': id,
  'clientMessageId': id,
  'senderId': sender,
  'createdAt': at.toIso8601String(),
  'activityAt': at,
  'type': 'text',
  'content': {'text': 'same message'},
  'status': {
    'me': {if (read) 'readAt': at.toIso8601String()},
  },
};

class ReadRepo extends Repo {
  int readCalls = 0;
  @override
  Future<Map<String, dynamic>?> getConversation({
    required String targetId,
    int page = 1,
    bool isShowLoader = true,
  }) async => {
    'statusCode': 1,
    'data': [
      {
        'id': 'incoming',
        'senderId': 'alice',
        'type': 'text',
        'content': 'hello',
        'createdAt': '2026-10-16T10:00:00Z',
      },
    ],
  };
  @override
  Future<Map<String, dynamic>?> markThreadRead({
    required String targetId,
    String? roomId,
    bool isShowLoader = false,
  }) async {
    readCalls++;
    return {'statusCode': 1};
  }
}

class ReadStore extends Store {
  @override
  Future<List<Map<String, dynamic>>> readMessages(String targetId) async => [];
  @override
  Future<List<Map<String, dynamic>>> readCallHistory(String roomId) async => [];
  @override
  Future<void> markChatSendInit(String targetId) async {}
}

class OfflineFirebase extends Firebase {
  @override
  bool get isAvailable => false;
  @override
  Future<void> ackIncomingMessages({
    required String roomId,
    required String myUserId,
    required List<Map<String, dynamic>> rawMessages,
    required bool markRead,
  }) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Repo repo;
  late Store store;
  late Firebase firebase;
  late MessagesTabController controller;
  setUp(() {
    Get.testMode = true;
    Get.put<UserSessionController>(Session());
    Get.put<ChatSessionService>(FirebaseSession());
    repo = Repo();
    store = Store();
    firebase = Firebase();
    // Explicit fetch keeps unrelated discovery/network initialization out of tests.
    controller = MessagesTabController(
      chatRepo: repo,
      localStore: store,
      firebaseService: firebase,
    );
  });
  tearDown(() async {
    controller.onClose();
    for (final stream in firebase.streams.values) {
      await stream.close();
    }
    Get.reset();
  });
  Future<void> flush() async {
    await Future<void>.delayed(Duration.zero);
  }

  int count(String peer) =>
      controller.inboxThreads.firstWhere((t) => t.targetId == peer).unreadCount;
  final at = DateTime.utc(2026, 10, 16, 10);

  test(
    'bursts, duplicate snapshots, own replies, read and next incoming update list and total',
    () async {
      await controller.fetchInbox();
      final burst = [
        for (var i = 0; i < 3; i++)
          message('$i', at.add(Duration(milliseconds: i))),
      ];
      firebase.emit('alice', burst);
      firebase.emit('bob', [message('b', at, sender: 'bob')]);
      await flush();
      expect(count('alice'), 3);
      expect(count('bob'), 1);
      expect(
        controller.inboxThreads.fold<int>(0, (sum, t) => sum + t.unreadCount),
        4,
      );
      firebase.emit('alice', [
        ...burst,
        message('mine', at.add(const Duration(milliseconds: 5)), sender: 'me'),
      ]);
      await flush();
      expect(count('alice'), 3);
      controller.markConversationRead(
        'alice',
        at.add(const Duration(milliseconds: 5)),
      );
      expect(count('alice'), 0);
      expect(count('bob'), 1);
      firebase.emit('alice', [
        ...burst,
        message('new', at.add(const Duration(milliseconds: 6))),
      ]);
      await flush();
      expect(count('alice'), 1);
      await controller
          .fetchInbox(); // stale server count 42 must not overwrite exact live count
      expect(count('alice'), 1);
      firebase.emit('alice', [
        ...burst,
        message('new', at.add(const Duration(milliseconds: 6)), read: true),
      ]);
      await flush();
      expect(count('alice'), 0);
    },
  );

  test('network failure preserves known badges', () async {
    await controller.fetchInbox();
    firebase.emit('alice', [message('one', at)]);
    await flush();
    repo.fail = true;
    await controller.fetchInbox(silent: true);
    expect(count('alice'), 1);
  });

  test(
    'overlapping refreshes share the request instead of starving responses',
    () async {
      repo.pending = Completer<Map<String, dynamic>?>();
      final first = controller.fetchInbox();
      final second = controller.fetchInbox(silent: true);
      expect(repo.calls, 1);
      repo.pending!.complete({'statusCode': 1, 'data': []});
      await Future.wait([first, second]);
      expect(controller.isInboxLoading.value, false);
    },
  );
  testWidgets(
    'background chat is not read; visible foreground history acknowledges it',
    (tester) async {
      final readRepo = ReadRepo();
      final detail = ChatDetailController(
        chatRepo: readRepo,
        localStore: ReadStore(),
        firebaseService: OfflineFirebase(),
      );
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: Routes.CHAT_DETAIL,
          getPages: [
            GetPage(
              name: Routes.CHAT_DETAIL,
              page: () => const Scaffold(body: Text('chat')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      detail.targetId.value = 'alice';
      detail.roomId.value = 'alice';
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      final backgroundLoad = detail.loadHistory();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await backgroundLoad;
      expect(readRepo.readCalls, 0);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      detail.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pump();
      expect(readRepo.readCalls, 1);
      await tester.pump(const Duration(seconds: 1));
      detail.onClose();
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
    },
  );
}
