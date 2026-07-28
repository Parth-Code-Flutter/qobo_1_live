import 'package:flutter/material.dart';
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
    this.status = 'completed',
    this.note,
    this.createdAt,
    this.user,
  });

  final String id;
  final String userId;
  final int amount;
  final num price;
  final String currency;
  final String? sellerId;
  final String status;
  final String? note;
  final DateTime? createdAt;
  final SellerSaleUser? user;

  bool get isReversed {
    final s = status.trim().toLowerCase();
    return s == 'reversed' || s == 'refunded' || s == 'cancelled';
  }

  bool get canReverse => id.trim().isNotEmpty && !isReversed;

  bool get canEdit => canReverse;

  String get statusLabel {
    final s = status.trim().toLowerCase();
    if (s.isEmpty || s == 'completed') return 'Completed';
    if (s == 'reversed') return 'Reversed';
    if (s == 'pending') return 'Pending';
    if (s == 'failed') return 'Failed';
    return status[0].toUpperCase() + status.substring(1);
  }

  Color get statusColor {
    final s = status.trim().toLowerCase();
    if (isReversed) return const Color(0xFFFF6B6B);
    if (s == 'pending') return const Color(0xFFFFB74D);
    if (s == 'failed') return const Color(0xFFEF5350);
    return const Color(0xFF4ADE80);
  }

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

    // New API uses `buyer`; older portal used `user`.
    final buyerRaw = json['buyer'] ?? json['user'];
    SellerSaleUser? user;
    if (buyerRaw is Map) {
      user = SellerSaleUser.fromJson(Map<String, dynamic>.from(buyerRaw));
    }

    final currencyRaw = json['currency']?.toString().trim();
    final statusRaw = json['status']?.toString().trim();
    return SellerSale(
      id: json['id']?.toString() ?? '',
      sellerId: json['sellerId']?.toString() ?? json['seller_id']?.toString(),
      userId: json['buyerId']?.toString() ??
          json['buyer_id']?.toString() ??
          json['userId']?.toString() ??
          json['user_id']?.toString() ??
          user?.id ??
          '',
      amount: toInt(json['amount']),
      price: toNum(json['price']),
      currency: (currencyRaw == null || currencyRaw.isEmpty)
          ? 'INR'
          : currencyRaw,
      status: (statusRaw == null || statusRaw.isEmpty) ? 'completed' : statusRaw,
      note: json['note']?.toString(),
      createdAt: createdAt,
      user: user,
    );
  }

  /// Parses sell API envelope → sale row (may omit nested buyer).
  static SellerSale? tryParseEnvelope(Map<String, dynamic>? response) {
    if (!isSellerPortalSuccess(response)) return null;
    final data = asJsonMap(response!['data']);
    if (data.isEmpty) return null;
    return SellerSale.fromJson(data);
  }

  SellerSale copyWith({
    String? status,
    num? price,
    String? note,
  }) {
    return SellerSale(
      id: id,
      userId: userId,
      amount: amount,
      price: price ?? this.price,
      currency: currency,
      sellerId: sellerId,
      status: status ?? this.status,
      note: note ?? this.note,
      createdAt: createdAt,
      user: user,
    );
  }
}
