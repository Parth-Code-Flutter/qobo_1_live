import 'package:get/get.dart';
import 'package:qobo_one_live/app/user_flow/gift_transactions/models/gift_history_models.dart';
import 'package:qobo_one_live/repo/economy/economy_api_utils.dart';
import 'package:qobo_one_live/repo/economy/economy_repo.dart';

class _TabCache {
  final items = <GiftHistoryItem>[];
  int page = 1;
  int total = 0;
  bool hasMore = true;
  bool loaded = false;
}

class GiftTransactionsController extends GetxController {
  GiftTransactionsController({EconomyRepo? economyRepo})
    : _economyRepo = economyRepo ?? EconomyRepo();

  final EconomyRepo _economyRepo;
  static const _pageSize = 20;

  final selectedType = GiftHistoryType.audioRoom.obs;
  final summary = GiftHistorySummary.empty().obs;
  final items = <GiftHistoryItem>[].obs;
  final isLoading = false.obs;
  final isLoadingMore = false.obs;
  final loadError = ''.obs;

  final Map<GiftHistoryType, _TabCache> _cache = {
    for (final type in GiftHistoryType.values) type: _TabCache(),
  };

  @override
  void onInit() {
    super.onInit();
    selectedType.value = GiftHistoryType.fromApi(_initialTypeArg());
    items.assignAll(_cache[selectedType.value]!.items);
    loadSummary();
    loadHistory(refresh: true);
  }

  String? _initialTypeArg() {
    final args = Get.arguments;
    if (args is Map) {
      return args['type']?.toString() ?? args['sessionType']?.toString();
    }
    if (args is String) return args;
    return null;
  }

  Future<void> loadSummary() async {
    try {
      final response = await _economyRepo.getGiftHistorySummary(
        isShowLoader: false,
      );
      if (!isEconomyApiSuccess(response)) return;
      final data = response?['data'];
      if (data is Map) {
        summary.value = GiftHistorySummary.fromJson(
          Map<String, dynamic>.from(data),
        );
      }
    } catch (_) {}
  }

  Future<void> selectType(GiftHistoryType type) async {
    if (selectedType.value == type) return;
    selectedType.value = type;
    final cache = _cache[type]!;
    items.assignAll(cache.items);
    loadError.value = '';
    if (!cache.loaded) {
      await loadHistory(refresh: true);
    }
  }

  Future<void> loadHistory({bool refresh = false}) async {
    final type = selectedType.value;
    final cache = _cache[type]!;

    if (refresh) {
      cache.page = 1;
      cache.hasMore = true;
      cache.loaded = false;
      isLoading.value = true;
      loadError.value = '';
    } else {
      if (!cache.hasMore || isLoadingMore.value || isLoading.value) return;
      isLoadingMore.value = true;
    }

    try {
      final response = await _economyRepo.getGiftHistory(
        type: type.apiValue,
        page: cache.page,
        limit: _pageSize,
        isShowLoader: false,
      );

      if (!isEconomyApiSuccess(response)) {
        if (refresh) {
          cache.items.clear();
          items.clear();
          loadError.value =
              response?['message']?.toString() ?? 'Unable to load history.';
        }
        return;
      }

      final parsed = _parsePage(response?['data']);
      if (refresh) {
        cache.items
          ..clear()
          ..addAll(parsed.items);
      } else {
        cache.items.addAll(parsed.items);
      }
      cache.total = parsed.total;
      cache.loaded = true;
      cache.hasMore =
          cache.items.length < parsed.total && parsed.items.isNotEmpty;
      if (parsed.items.isNotEmpty) cache.page += 1;
      if (selectedType.value == type) {
        items.assignAll(cache.items);
        loadError.value = '';
      }
    } catch (_) {
      if (refresh) {
        loadError.value = 'Network error. Please try again.';
      }
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  ({List<GiftHistoryItem> items, int total}) _parsePage(dynamic data) {
    if (data is! Map) {
      if (data is List) {
        return (
          items: data
              .whereType<Map>()
              .map((e) => GiftHistoryItem.fromJson(Map<String, dynamic>.from(e)))
              .toList(),
          total: data.length,
        );
      }
      return (items: const <GiftHistoryItem>[], total: 0);
    }
    final map = Map<String, dynamic>.from(data);
    final rawItems = map['items'] ?? map['list'] ?? map['gifts'] ?? map['data'];
    final list = rawItems is List
        ? rawItems
              .whereType<Map>()
              .map((e) => GiftHistoryItem.fromJson(Map<String, dynamic>.from(e)))
              .toList()
        : <GiftHistoryItem>[];
    final total = parseWalletAmount(
      map['total'] ?? map['count'] ?? list.length,
    );
    return (items: list, total: total);
  }
}
