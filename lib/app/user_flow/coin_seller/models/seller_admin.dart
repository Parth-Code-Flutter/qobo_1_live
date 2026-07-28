/// Seller admin profile from `POST /api/admin/login` → `data.admin`.
class SellerAdmin {
  const SellerAdmin({
    required this.id,
    required this.email,
    required this.role,
    required this.coinsBalance,
  });

  final String id;
  final String email;
  final String role;
  final int coinsBalance;

  bool get isSellerAdmin => role.toLowerCase() == 'seller_admin';

  factory SellerAdmin.fromJson(Map<String, dynamic> json) {
    return SellerAdmin(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      coinsBalance: _toInt(json['coinsBalance'] ?? json['coins_balance']),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'email': email,
        'role': role,
        'coinsBalance': coinsBalance,
      };

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
