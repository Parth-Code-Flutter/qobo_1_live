import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/services/gifts/gift_icon_preview_store.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';
import 'package:qobo_one_live/utils/ui_utils/gift_media_utils.dart';

/// One shared copy of `GET /api/economy/gift-list`.
///
/// Fetched once per login (and once on a cold start while already logged in),
/// in the background with no loader. Screens read this cache. A loader is only
/// needed when nothing is stored yet and the request is still running.
class GiftCatalogStore extends GetxService {
  GiftCatalogStore({EconomyRepo? economyRepo})
    : _economyRepo = economyRepo ?? EconomyRepo();

  final EconomyRepo _economyRepo;

  final gifts = <Map<String, String>>[].obs;

  bool _hydrated = false;
  bool _fetchedThisSession = false;
  int _generation = 0;
  Future<void>? _inFlight;

  static GiftCatalogStore ensureRegistered() {
    if (Get.isRegistered<GiftCatalogStore>()) {
      return Get.find<GiftCatalogStore>();
    }
    return Get.put(GiftCatalogStore(), permanent: true);
  }

  bool get hasGifts => gifts.isNotEmpty;

  /// Starts the single background fetch for this login / app session,
  /// then builds a small picture for every gift icon.
  void warmUp() {
    unawaited(
      _hydrate().then((_) {
        if (gifts.isNotEmpty) _preloadGiftFiles(gifts.toList());
      }),
    );
    // Start the request now. Waiting until after disk read left a gap where
    // a gift sheet could miss the in-flight future and stay empty.
    _startFetch();
  }

  Future<void> _startFetch() {
    if (_fetchedThisSession) return Future<void>.value();
    return _inFlight ??= _download();
  }

  /// Next login should fetch again. The saved list stays so the panel can
  /// open immediately while that new request runs.
  void endSession() {
    _generation++;
    _fetchedThisSession = false;
    _inFlight = null;
  }

  /// Copies the catalog into [target].
  ///
  /// Shows [isLoading] only when there is nothing saved yet.
  Future<void> applyTo({
    required RxList<Map<String, String>> target,
    required RxBool isLoading,
  }) async {
    await _hydrate();
    if (gifts.isNotEmpty) {
      _assign(target, gifts);
      _setLoading(isLoading, false);
      _preloadGiftFiles(gifts.toList());
      if (!_fetchedThisSession) {
        final pending = _startFetch();
        unawaited(
          pending.then((_) {
            if (gifts.isNotEmpty) _assign(target, gifts);
          }),
        );
      }
      return;
    }

    _setLoading(isLoading, true);
    try {
      await _startFetch();
      _assign(target, gifts);
    } finally {
      _setLoading(isLoading, false);
    }
  }

  Future<void> _download() async {
    final generation = _generation;
    try {
      final response = await _economyRepo.getGiftList(isShowLoader: false);
      if (generation != _generation) return;

      final parsed = _parse(response);
      if (parsed == null) {
        LoggerUtils.logWarning(
          'GiftCatalogStore: gift-list response was empty or failed',
        );
        return;
      }

      gifts.assignAll(parsed);
      _fetchedThisSession = true;
      await _persist(parsed);
      _preloadGiftFiles(parsed);
    } catch (e) {
      LoggerUtils.logWarning('GiftCatalogStore: gift-list fetch failed — $e');
    } finally {
      if (generation == _generation) _inFlight = null;
    }
  }

  /// `null` means the response could not be used (keep the saved list).
  List<Map<String, String>>? _parse(Map<String, dynamic>? response) {
    if (!isEconomyApiSuccess(response)) return null;
    final data = response?['data'];
    List<dynamic>? rawList;
    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      for (final key in const [
        'gifts',
        'giftList',
        'gift_list',
        'items',
        'list',
      ]) {
        final nested = data[key];
        if (nested is List) {
          rawList = nested;
          break;
        }
      }
    }
    if (rawList == null) return null;

    return rawList
        .whereType<Map>()
        .map(
          (raw) =>
              GiftMediaUtils.mapGiftFromApi(Map<String, dynamic>.from(raw)),
        )
        .where((gift) => (gift['id'] ?? '').trim().isNotEmpty)
        .toList();
  }

  Future<void> _hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List || gifts.isNotEmpty) return;
      final stored = decoded
          .whereType<Map>()
          .map(_stringMap)
          .where((gift) => (gift['id'] ?? '').trim().isNotEmpty)
          .toList();
      // A fresher network response may have landed while the file was read.
      if (stored.isNotEmpty && gifts.isEmpty && !_fetchedThisSession) {
        gifts.assignAll(stored);
      }
    } catch (e) {
      LoggerUtils.logWarning('GiftCatalogStore: could not read cache — $e');
    }
  }

  Future<void> _persist(List<Map<String, String>> items) async {
    try {
      final file = await _cacheFile();
      await file.writeAsString(jsonEncode(items));
    } catch (e) {
      LoggerUtils.logWarning('GiftCatalogStore: could not save cache — $e');
    }
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/gift_catalog.json');
  }

  /// Downloads each gift file after login so the panel can play it from disk.
  /// A small picture is saved only as a stand-in until that clip starts.
  void _preloadGiftFiles(List<Map<String, String>> items) {
    final urls = <String>[];
    for (final gift in items) {
      final url = gift['icon']?.trim() ?? '';
      if (!url.startsWith('http://') && !url.startsWith('https://')) continue;
      if (!urls.contains(url)) urls.add(url);
    }
    if (urls.isEmpty) return;
    GiftIconPreviewStore.warm(urls);
  }

  Map<String, String> _stringMap(Map raw) {
    return raw.map(
      (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
    );
  }

  void _assign(
    RxList<Map<String, String>> target,
    List<Map<String, String>> items,
  ) {
    if (target.subject.isClosed) return;
    target.assignAll(items);
  }

  void _setLoading(RxBool isLoading, bool value) {
    if (isLoading.subject.isClosed) return;
    isLoading.value = value;
  }
}
