import 'seller_portal_parsers.dart';

/// Aggregate metrics from seller portal dashboard.
class SellerMetrics {
  const SellerMetrics({
    required this.totalRevenue,
    required this.totalCoinsSold,
    required this.totalTransactions,
  });

  final num totalRevenue;
  final int totalCoinsSold;
  final int totalTransactions;

  factory SellerMetrics.fromJson(Map<String, dynamic> json) {
    return SellerMetrics(
      totalRevenue: toNum(
        json['totalRevenue'] ?? json['total_revenue'],
      ),
      totalCoinsSold: toInt(
        json['totalCoinsSold'] ?? json['total_coins_sold'],
      ),
      totalTransactions: toInt(
        json['totalTransactions'] ?? json['total_transactions'],
      ),
    );
  }

  factory SellerMetrics.empty() => const SellerMetrics(
        totalRevenue: 0,
        totalCoinsSold: 0,
        totalTransactions: 0,
      );
}
