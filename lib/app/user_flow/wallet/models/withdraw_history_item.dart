/// Single withdrawal request from `GET /api/withdraw/history`.
class WithdrawHistoryItem {
  const WithdrawHistoryItem({
    required this.transactionId,
    required this.amount,
    required this.status,
    this.requestedAt,
  });

  final String transactionId;
  final num amount;
  final String status;
  final DateTime? requestedAt;

  factory WithdrawHistoryItem.fromJson(Map<String, dynamic> json) {
    final atRaw = json['requestedAt'] ?? json['requested_at'];
    DateTime? requestedAt;
    if (atRaw != null) {
      requestedAt = DateTime.tryParse(atRaw.toString());
    }

    final amountRaw = json['amount'];
    return WithdrawHistoryItem(
      transactionId:
          json['transactionId']?.toString() ??
          json['transaction_id']?.toString() ??
          '',
      amount: amountRaw is num
          ? amountRaw
          : num.tryParse(amountRaw?.toString() ?? '') ?? 0,
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
      requestedAt: requestedAt,
    );
  }
}
