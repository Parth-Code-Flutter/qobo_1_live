import 'seller_portal_parsers.dart';
import 'seller_sale_user.dart';

/// One row from dashboard `recentSales` or sell response `data`.
class SellerSale {
  const SellerSale({
    required this.id,
    required this.userId,
    required this.amount,
    required this.price,
    required this.currency,
    this.sellerId,
    this.createdAt,
    this.user,
  });

  final String id;
  final String userId;
  final int amount;
  final num price;
  final String currency;
  final String? sellerId;
  final DateTime? createdAt;
  final SellerSaleUser? user;

  String get displayName {
    final name = user?.name.trim() ?? '';
    if (name.isNotEmpty) return name;
    final email = user?.email.trim() ?? '';
    if (email.isNotEmpty) return email;
    if (userId.isNotEmpty) return userId;
    return 'User';
  }

  String get displayUserId {
    final nested = user?.id.trim() ?? '';
    if (nested.isNotEmpty) return nested;
    return userId;
  }

  String? get avatarUrl => user?.displayPicture;

  String get formattedDate {
    final at = createdAt;
    if (at == null) return 'Just now';
    final local = at.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(local.day)}/${two(local.month)}/${local.year} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  factory SellerSale.fromJson(Map<String, dynamic> json) {
    final createdRaw = json['createdAt'] ?? json['created_at'];
    DateTime? createdAt;
    if (createdRaw != null) {
      createdAt = DateTime.tryParse(createdRaw.toString());
    }

    final userRaw = json['user'];
    SellerSaleUser? user;
    if (userRaw is Map) {
      user = SellerSaleUser.fromJson(Map<String, dynamic>.from(userRaw));
    }

    final currencyRaw = json['currency']?.toString().trim();
    return SellerSale(
      id: json['id']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? json['seller_id']?.toString(),
      userId: json['userId']?.toString() ??
          json['user_id']?.toString() ??
          user?.id ??
          '',
      amount: toInt(json['amount']),
      price: toNum(json['price']),
      currency: (currencyRaw == null || currencyRaw.isEmpty)
          ? 'INR'
          : currencyRaw,
      createdAt: createdAt,
      user: user,
    );
  }

  /// Parses sell API envelope → sale row (may omit nested `user`).
  static SellerSale? tryParseEnvelope(Map<String, dynamic>? response) {
    if (!isSellerPortalSuccess(response)) return null;
    final data = asJsonMap(response!['data']);
    if (data.isEmpty) return null;
    return SellerSale.fromJson(data);
  }
}
