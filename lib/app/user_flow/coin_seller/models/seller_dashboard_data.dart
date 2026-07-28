import 'seller_metrics.dart';
import 'seller_portal_parsers.dart';
import 'seller_sale.dart';

/// Parsed `data` from `GET /api/admin/seller-portal/dashboard`.
class SellerDashboardData {
  const SellerDashboardData({
    required this.coinsBalance,
    required this.metrics,
    required this.recentSales,
  });

  final int coinsBalance;
  final SellerMetrics metrics;
  final List<SellerSale> recentSales;

  factory SellerDashboardData.fromJson(Map<String, dynamic> json) {
    final metricsRaw = asJsonMap(json['metrics']);
    final salesRaw =
        json['recentSales'] ?? json['recent_sales'] ?? json['sales'];

    return SellerDashboardData(
      coinsBalance: toInt(json['coinsBalance'] ?? json['coins_balance']),
      metrics: metricsRaw.isEmpty
          ? SellerMetrics.empty()
          : SellerMetrics.fromJson(metricsRaw),
      recentSales: _parseSales(salesRaw),
    );
  }

  static List<SellerSale> _parseSales(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((e) => SellerSale.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Parses a full API envelope (`success` / `statusCode` + `data`).
  static SellerDashboardData? tryParseEnvelope(Map<String, dynamic>? response) {
    if (!isSellerPortalSuccess(response)) return null;
    final data = asJsonMap(response!['data']);
    if (data.isEmpty) return null;
    return SellerDashboardData.fromJson(data);
  }

  factory SellerDashboardData.empty() => SellerDashboardData(
        coinsBalance: 0,
        metrics: SellerMetrics.empty(),
        recentSales: const [],
      );
}
