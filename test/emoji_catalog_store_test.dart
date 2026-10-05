import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
// Test-only stand-in for the app support folder. Already in the app via path_provider.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:qobo_one_live/repo/emoji/emoji_repo.dart';
import 'package:qobo_one_live/services/emojis/emoji_catalog_store.dart';
import 'package:qobo_one_live/services/emojis/emoji_file_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('emoji_catalog_test');
    PathProviderPlatform.instance = _FakePath(support.path);
    Get.reset();
  });

  tearDown(() async {
    Get.reset();
    if (await support.exists()) {
      await support.delete(recursive: true);
    }
  });

  test('keeps the loader up until the first list arrives', () async {
    final release = Completer<Map<String, dynamic>?>();
    final repo = _FakeEmojiRepo(() => release.future);
    final store = EmojiCatalogStore(emojiRepo: repo);
    final target = <Map<String, String>>[].obs;
    final loading = false.obs;

    final done = store.applyTo(target: target, isLoading: loading);
    await _until(() => repo.calls == 1);

    expect(loading.value, isTrue);
    expect(target, isEmpty);

    release.complete(_body('emoji_001', 'Kiss'));
    await done;

    expect(loading.value, isFalse);
    expect(target.single['name'], 'Kiss');
    expect(target.single['image'], contains('.gif'));
    expect(target.single['code'], ':kiss:');
    expect(repo.calls, 1);
  });

  test('shows the saved list immediately, then the newer list', () async {
    await File('${support.path}/emoji_catalog.json').writeAsString(
      jsonEncode([
        {
          'id': 'emoji_001',
          'name': 'Old',
          'image': 'https://example.com/old.gif',
          'code': ':old:',
        },
      ]),
    );
    final release = Completer<Map<String, dynamic>?>();
    final repo = _FakeEmojiRepo(() => release.future);
    final store = EmojiCatalogStore(emojiRepo: repo);
    final target = <Map<String, String>>[].obs;
    final loading = true.obs;

    final done = store.applyTo(target: target, isLoading: loading);
    await done;

    expect(loading.value, isFalse);
    expect(target.single['name'], 'Old');
    expect(repo.calls, 1);

    release.complete(_body('emoji_002', 'New'));
    await _until(() => target.single['name'] == 'New');

    expect(target.single['name'], 'New');
    expect(repo.calls, 1);
  });

  test('a failed list is retried the next time a sheet opens', () async {
    var fail = true;
    final repo = _FakeEmojiRepo(() async {
      if (fail) return {'success': false, 'message': 'down'};
      return _body('emoji_001', 'Kiss');
    });
    final store = EmojiCatalogStore(emojiRepo: repo);
    final target = <Map<String, String>>[].obs;
    final loading = false.obs;

    await store.applyTo(target: target, isLoading: loading);
    expect(target, isEmpty);
    expect(loading.value, isFalse);
    expect(repo.calls, 1);

    fail = false;
    await store.applyTo(target: target, isLoading: loading);
    expect(target.single['name'], 'Kiss');
    expect(repo.calls, 2);
  });

  test('one login fetches once, the next login fetches again', () async {
    final repo = _FakeEmojiRepo(() async => _body('emoji_001', 'Kiss'));
    final store = EmojiCatalogStore(emojiRepo: repo);
    final target = <Map<String, String>>[].obs;
    final loading = false.obs;

    await store.applyTo(target: target, isLoading: loading);
    await store.applyTo(target: target, isLoading: loading);
    expect(repo.calls, 1);

    store.endSession();
    await store.applyTo(target: target, isLoading: loading);
    expect(repo.calls, 2);
    expect(target.single['name'], 'Kiss');
  });

  test('reads the animated gif nested under animation', () async {
    final repo = _FakeEmojiRepo(() async => _body('emoji_001', 'Kiss'));
    final store = EmojiCatalogStore(emojiRepo: repo);
    final target = <Map<String, String>>[].obs;
    final loading = false.obs;

    await store.applyTo(target: target, isLoading: loading);
    expect(
      target.single['image'],
      'https://api.qobo1live.in/uploads/emojis/kiss.gif',
    );
    expect(target.single['animationUrl'], target.single['image']);
  });

  test('seat playback query does not change the saved file key', () {
    const url = 'https://api.qobo1live.in/uploads/emojis/kiss.gif';
    expect(
      EmojiFileStore.cacheKey('$url?emoji_playback=1'),
      EmojiFileStore.cacheKey(url),
    );
  });
}

Map<String, dynamic> _body(String id, String name) {
  return {
    'success': true,
    'statusCode': 1,
    'data': [
      {
        'id': id,
        'name': name,
        'code': ':kiss:',
        'image': 'https://api.qobo1live.in/uploads/emojis/kiss.gif',
        'category': 'expressive',
        'animation': {
          'animationType': 'gif',
          'animationUrl': 'https://api.qobo1live.in/uploads/emojis/kiss.gif',
        },
      },
    ],
  };
}

Future<void> _until(bool Function() ready) async {
  for (var i = 0; i < 50; i++) {
    if (ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('condition was not met');
}

class _FakeEmojiRepo extends EmojiRepo {
  _FakeEmojiRepo(this._handler);

  final Future<Map<String, dynamic>?> Function() _handler;
  int calls = 0;

  @override
  Future<Map<String, dynamic>?> getEmojiCatalog({
    String? category,
    int? packVersion,
    bool isShowLoader = false,
  }) {
    calls++;
    return _handler();
  }
}

class _FakePath extends PathProviderPlatform {
  _FakePath(this.root);

  final String root;

  @override
  Future<String?> getApplicationSupportPath() async => root;
}
