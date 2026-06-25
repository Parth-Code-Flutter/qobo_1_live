/// Response payload from `POST /api/withdraw/request`.
class WithdrawRequestResult {
  const WithdrawRequestResult({
    required this.transactionId,
    required this.status,
  });

  final String transactionId;
  final String status;

  factory WithdrawRequestResult.fromJson(Map<String, dynamic> json) {
    return WithdrawRequestResult(
      transactionId:
          json['transactionId']?.toString() ??
          json['transaction_id']?.toString() ??
          '',
      status: json['status']?.toString().toUpperCase() ?? 'PENDING',
    );
  }
}
