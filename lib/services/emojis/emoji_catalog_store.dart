import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get/get.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/emoji/emoji_repo.dart';
import 'package:qobo_one_live/services/emojis/emoji_file_store.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// One shared copy of `GET /api/emojis/public-list`.
///
/// Fetched once per login (and once on a cold start while already logged in),
/// in the background with no loader. Screens read this cache, and the GIF
/// files are saved so the emoji panel does not download them on open.
class EmojiCatalogStore extends GetxService {
  EmojiCatalogStore({EmojiRepo? emojiRepo})
    : _emojiRepo = emojiRepo ?? EmojiRepo();

  final EmojiRepo _emojiRepo;

  final emojis = <Map<String, String>>[].obs;

  bool _hydrated = false;
  bool _fetchedThisSession = false;
  int _generation = 0;
  int _packVersion = 1;
  Future<void>? _inFlight;

  static EmojiCatalogStore ensureRegistered() {
    if (Get.isRegistered<EmojiCatalogStore>()) {
      return Get.find<EmojiCatalogStore>();
    }
    return Get.put(EmojiCatalogStore(), permanent: true);
  }

  int get packVersion => _packVersion;

  /// Starts the single background fetch for this login / app session,
  /// then saves every emoji file.
  void warmUp() {
    unawaited(
      _hydrate().then((_) {
        if (emojis.isNotEmpty) _preload(emojis.toList());
      }),
    );
    _startFetch();
  }

  Future<void> _startFetch() {
    if (_fetchedThisSession) return Future<void>.value();
    return _inFlight ??= _download();
  }

  /// Next login should fetch again. The saved list and files stay so the
  /// panel can open immediately while that new request runs.
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
    if (emojis.isNotEmpty) {
      _assign(target, emojis);
      _setLoading(isLoading, false);
    } else {
      _setLoading(isLoading, true);
    }
    await _hydrate();
    if (emojis.isNotEmpty) {
      _assign(target, emojis);
      _setLoading(isLoading, false);
      _preload(emojis.toList());
      if (!_fetchedThisSession) {
        final pending = _startFetch();
        unawaited(
          pending.then((_) {
            if (emojis.isNotEmpty) _assign(target, emojis);
          }),
        );
      }
      return;
    }

    _setLoading(isLoading, true);
    try {
      await _startFetch();
      _assign(target, emojis);
    } finally {
      _setLoading(isLoading, false);
    }
  }

  Future<void> _download() async {
    final generation = _generation;
    try {
      final response = await _emojiRepo.getEmojiCatalog(isShowLoader: false);
      if (generation != _generation) return;

      final parsed = _parse(response);
      if (parsed == null) {
        LoggerUtils.logWarning(
          'EmojiCatalogStore: emoji list response was empty or failed',
        );
        return;
      }

      emojis.assignAll(parsed);
      _fetchedThisSession = true;
      await _persist(parsed);
      _preload(parsed);
    } catch (e) {
      LoggerUtils.logWarning('EmojiCatalogStore: emoji list fetch failed — $e');
    } finally {
      if (generation == _generation) _inFlight = null;
    }
  }

  /// `null` means the response could not be used (keep the saved list).
  List<Map<String, String>>? _parse(Map<String, dynamic>? response) {
    if (!isEconomyApiSuccess(response)) return null;
    final data = response?['data'];
    List<dynamic>? rawList;
    var version = _packVersion;
    if (data is List) {
      rawList = data;
    } else if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      final nestedVersion = int.tryParse(
        '${map['packVersion'] ?? map['pack_version'] ?? ''}',
      );
      if (nestedVersion != null && nestedVersion > 0) version = nestedVersion;
      for (final key in const ['emojis', 'items', 'list', 'emojiList']) {
        final nested = map[key];
        if (nested is List) {
          rawList = nested;
          break;
        }
      }
    }
    if (rawList == null) return null;
    _packVersion = version;

    return rawList
        .whereType<Map>()
        .map((raw) => _mapEmoji(Map<String, dynamic>.from(raw), version))
        .where((emoji) => (emoji['id'] ?? '').trim().isNotEmpty)
        .toList();
  }

  Map<String, String> _mapEmoji(Map<String, dynamic> item, int packVersion) {
    final image = _media(item) ?? '';
    final code = _read(item, const ['code', 'unicode', 'emoji']) ?? '';
    final ownVersion = _read(item, const ['packVersion', 'pack_version']);
    return {
      'id': _read(item, const ['id', '_id', 'emojiId', 'emoji_id']) ?? '',
      'name': _read(item, const ['name', 'title', 'label']) ?? 'Emoji',
      'image': image.isNotEmpty ? image : (code.isNotEmpty ? code : '😊'),
      'animationUrl': image,
      'code': code,
      'packVersion': ownVersion ?? packVersion.toString(),
      'category': _read(item, const ['category', 'type']) ?? 'emoji',
    };
  }

  /// Prefer the animated file. Seat reactions and tiles both play that GIF.
  String? _media(Map<String, dynamic> item) {
    final direct = _read(item, const [
      'gifUrl',
      'gif_url',
      'animationUrl',
      'animation_url',
      'emojiAnimation',
      'emoji_animation',
      'animatedImage',
      'animated_image',
      'mediaUrl',
      'media_url',
    ]);
    if (direct != null) return direct;

    final animationRaw = item['animation'];
    if (animationRaw is Map) {
      final nested = _read(Map<String, dynamic>.from(animationRaw), const [
        'animationUrl',
        'animation_url',
        'gifUrl',
        'gif_url',
        'mediaUrl',
        'media_url',
        'url',
      ]);
      if (nested != null) return nested;
    }

    return _read(item, const [
      'image',
      'emojiImage',
      'emoji_image',
      'previewUrl',
      'thumbnailUrl',
      'url',
    ]);
  }

  String? _read(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }

  Future<void> _hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final file = await _cacheFile();
      if (!await file.exists()) return;
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! List || emojis.isNotEmpty) return;
      final stored = decoded
          .whereType<Map>()
          .map(
            (raw) => raw.map(
              (key, value) => MapEntry(key.toString(), value?.toString() ?? ''),
            ),
          )
          .where((emoji) => (emoji['id'] ?? '').trim().isNotEmpty)
          .toList();
      if (stored.isNotEmpty && emojis.isEmpty && !_fetchedThisSession) {
        emojis.assignAll(stored);
      }
    } catch (e) {
      LoggerUtils.logWarning('EmojiCatalogStore: could not read cache — $e');
    }
  }

  Future<void> _persist(List<Map<String, String>> items) async {
    try {
      final file = await _cacheFile();
      await file.writeAsString(jsonEncode(items));
    } catch (e) {
      LoggerUtils.logWarning('EmojiCatalogStore: could not save cache — $e');
    }
  }

  Future<File> _cacheFile() async {
    final dir = await getApplicationSupportDirectory();
    return File('${dir.path}/emoji_catalog.json');
  }

  void _preload(List<Map<String, String>> items) {
    final urls = <String>[];
    for (final emoji in items) {
      final url = emoji['image']?.trim() ?? '';
      if (!url.startsWith('http://') && !url.startsWith('https://')) continue;
      if (!urls.contains(url)) urls.add(url);
    }
    if (urls.isEmpty) return;
    EmojiFileStore.warm(urls);
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
