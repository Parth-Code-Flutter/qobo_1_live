import 'seller_portal_parsers.dart';
import 'seller_sale.dart';

/// Paginated transactions from `GET /api/user/coins-seller/transactions`.
class SellerTransactionsPage {
  const SellerTransactionsPage({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.hasMore,
  });

  final List<SellerSale> items;
  final int page;
  final int totalPages;
  final bool hasMore;

  static SellerTransactionsPage? tryParseEnvelope(Map<String, dynamic>? response) {
    if (!isSellerPortalSuccess(response)) return null;
    final root = asJsonMap(response!['data']);
    if (root.isEmpty) return null;

    final listRaw = root['transactions'] ??
        root['recentSales'] ??
        root['recent_sales'] ??
        root['sales'] ??
        root['items'];
    final items = _parseList(listRaw);

    final pagination = asJsonMap(root['pagination'] ?? root['meta']);
    final page = toInt(pagination['page'] ?? pagination['currentPage'] ?? 1);
    final totalPages = toInt(
      pagination['totalPages'] ??
          pagination['total_pages'] ??
          pagination['lastPage'] ??
          1,
    );
    final hasMore = pagination['hasMore'] == true ||
        pagination['has_more'] == true ||
        page < totalPages;

    return SellerTransactionsPage(
      items: items,
      page: page < 1 ? 1 : page,
      totalPages: totalPages < 1 ? 1 : totalPages,
      hasMore: hasMore,
    );
  }

  static List<SellerSale> _parseList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => SellerSale.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
