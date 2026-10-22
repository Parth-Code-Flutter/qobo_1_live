import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:crypto/crypto.dart';

/// Only PURCHASED events enter this queue. Tokens never appear in UI or logs.
class PlayPurchaseReceipt {
  const PlayPurchaseReceipt({
    required this.productId,
    required this.token,
    required this.accountId,
    this.orderId,
    this.credited = false,
  });
  final String productId;
  final String token;
  final String accountId;
  final String? orderId;
  final bool credited;

  PlayPurchaseReceipt withCredit() => PlayPurchaseReceipt(
    productId: productId,
    token: token,
    accountId: accountId,
    orderId: orderId,
    credited: true,
  );
  Map<String, dynamic> toJson() => {
    'productId': productId,
    'token': token,
    'accountId': accountId,
    'orderId': orderId,
    'credited': credited,
  };
  factory PlayPurchaseReceipt.fromJson(Map<String, dynamic> json) =>
      PlayPurchaseReceipt(
        productId: json['productId'] as String,
        token: json['token'] as String,
        accountId: json['accountId'] as String,
        orderId: json['orderId'] as String?,
        credited: json['credited'] == true,
      );
}

abstract class PlayPurchaseQueue {
  Future<List<PlayPurchaseReceipt>> read();
  Future<void> save(PlayPurchaseReceipt receipt);
  Future<void> remove(String token);
}

/// Separate Android namespace survives normal Qobo logout/deleteAll, so a
/// credited but unconsumed purchase is recoverable by its originating account.
class SecurePlayPurchaseQueue implements PlayPurchaseQueue {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      sharedPreferencesName: 'qobo_play_purchase_queue',
      preferencesKeyPrefix: 'qobo_play_',
      resetOnError: false,
    ),
  );
  @override
  Future<List<PlayPurchaseReceipt>> read() async {
    final values = await _storage.readAll();
    return values.values
        .map(
          (value) => PlayPurchaseReceipt.fromJson(
            Map<String, dynamic>.from(jsonDecode(value) as Map),
          ),
        )
        .toList();
  }

  @override
  Future<void> save(PlayPurchaseReceipt receipt) => _storage.write(
    key: sha256.convert(utf8.encode(receipt.token)).toString(),
    value: jsonEncode(receipt.toJson()),
  );
  @override
  Future<void> remove(String token) =>
      _storage.delete(key: sha256.convert(utf8.encode(token)).toString());
}
