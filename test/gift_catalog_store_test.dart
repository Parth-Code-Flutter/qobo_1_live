import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
// Test-only stand-in for the app support folder. Already in the app via path_provider.
// ignore: depend_on_referenced_packages
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/services/gifts/gift_catalog_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory support;

  setUp(() async {
    support = await Directory.systemTemp.createTemp('gift_catalog_test');
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
    final repo = _FakeEconomyRepo(() => release.future);
    final store = GiftCatalogStore(economyRepo: repo);
    final target = <Map<String, String>>[].obs;
    final loading = false.obs;

    final done = store.applyTo(target: target, isLoading: loading);
    await _until(() => repo.calls == 1);

    expect(loading.value, isTrue);
    expect(target, isEmpty);

    release.complete(_body('1', 'Rose'));
    await done;

    expect(loading.value, isFalse);
    expect(target.single['name'], 'Rose');
    expect(repo.calls, 1);
  });

  test('shows the saved list immediately, then the newer list', () async {
    await File('${support.path}/gift_catalog.json').writeAsString(
      jsonEncode([_gift('1', 'Old')]),
    );
    final release = Completer<Map<String, dynamic>?>();
    final repo = _FakeEconomyRepo(() => release.future);
    final store = GiftCatalogStore(economyRepo: repo);
    final target = <Map<String, String>>[].obs;
    final loading = true.obs;

    final done = store.applyTo(target: target, isLoading: loading);
    await done;

    expect(loading.value, isFalse);
    expect(target.single['name'], 'Old');
    expect(repo.calls, 1);

    release.complete(_body('2', 'New'));
    await _until(() => target.single['name'] == 'New');

    expect(target.single['name'], 'New');
    expect(repo.calls, 1);
  });

  test('a failed list is retried the next time a sheet opens', () async {
    var fail = true;
    final repo = _FakeEconomyRepo(() async {
      if (fail) return {'success': false, 'message': 'down'};
      return _body('1', 'Rose');
    });
    final store = GiftCatalogStore(economyRepo: repo);
    final target = <Map<String, String>>[].obs;
    final loading = false.obs;

    await store.applyTo(target: target, isLoading: loading);
    expect(target, isEmpty);
    expect(loading.value, isFalse);
    expect(repo.calls, 1);

    fail = false;
    await store.applyTo(target: target, isLoading: loading);
    expect(target.single['name'], 'Rose');
    expect(repo.calls, 2);
  });

  test('one login fetches once, the next login fetches again', () async {
    final repo = _FakeEconomyRepo(() async => _body('1', 'Rose'));
    final store = GiftCatalogStore(economyRepo: repo);
    final target = <Map<String, String>>[].obs;
    final loading = false.obs;

    await store.applyTo(target: target, isLoading: loading);
    await store.applyTo(target: target, isLoading: loading);
    expect(repo.calls, 1);

    store.endSession();
    await store.applyTo(target: target, isLoading: loading);
    expect(repo.calls, 2);
    expect(target.single['name'], 'Rose');
  });

  test('reads gifts nested under data.gifts', () async {
    final repo = _FakeEconomyRepo(
      () async => {
        'success': true,
        'data': {
          'gifts': [_gift('9', 'Dragon')],
        },
      },
    );
    final store = GiftCatalogStore(economyRepo: repo);
    final target = <Map<String, String>>[].obs;
    final loading = false.obs;

    await store.applyTo(target: target, isLoading: loading);
    expect(target.single['name'], 'Dragon');
    expect(target.single['category'], 'Lucky');
  });
}

Map<String, dynamic> _gift(String id, String name) {
  return {
    'id': id,
    'name': name,
    'price': 10,
    'icon': '🎁',
    'category': 'Lucky',
  };
}

Map<String, dynamic> _body(String id, String name) {
  return {
    'success': true,
    'data': [_gift(id, name)],
  };
}

Future<void> _until(bool Function() ready) async {
  for (var i = 0; i < 50; i++) {
    if (ready()) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  fail('condition was not met');
}

class _FakeEconomyRepo extends EconomyRepo {
  _FakeEconomyRepo(this._handler);

  final Future<Map<String, dynamic>?> Function() _handler;
  int calls = 0;

  @override
  Future<Map<String, dynamic>?> getGiftList({bool isShowLoader = true}) {
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
