import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:qobo_one_live/constants/razorpay_config.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

/// Result of a Razorpay Checkout session.
class RazorpayCheckoutResult {
  const RazorpayCheckoutResult._({
    required this.success,
    this.paymentId,
    this.orderId,
    this.signature,
    this.errorCode,
    this.errorMessage,
    this.cancelled = false,
  });

  factory RazorpayCheckoutResult.success({
    required String paymentId,
    String? orderId,
    String? signature,
  }) {
    return RazorpayCheckoutResult._(
      success: true,
      paymentId: paymentId,
      orderId: orderId,
      signature: signature,
    );
  }

  factory RazorpayCheckoutResult.failure({
    String? errorCode,
    String? errorMessage,
    bool cancelled = false,
  }) {
    return RazorpayCheckoutResult._(
      success: false,
      errorCode: errorCode,
      errorMessage: errorMessage,
      cancelled: cancelled,
    );
  }

  final bool success;
  final String? paymentId;
  final String? orderId;
  final String? signature;
  final String? errorCode;
  final String? errorMessage;
  final bool cancelled;
}

/// Thin wrapper around [Razorpay] so wallet / mall can open Checkout.
class RazorpayPaymentService {
  RazorpayPaymentService() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
  }

  late final Razorpay _razorpay;
  Completer<RazorpayCheckoutResult>? _pending;

  /// Opens Razorpay Checkout for [amountMinorUnits] (paise for INR).
  ///
  /// Pass [orderId] when the backend creates a Razorpay order; until then
  /// checkout runs with amount + key only (test / interim mode).
  Future<RazorpayCheckoutResult> openCheckout({
    required int amountMinorUnits,
    required String currency,
    required String description,
    String? orderId,
    String? customerName,
    String? email,
    String? contact,
    String? receipt,
  }) async {
    if (amountMinorUnits <= 0) {
      return RazorpayCheckoutResult.failure(
        errorCode: 'INVALID_AMOUNT',
        errorMessage: 'Invalid payment amount.',
      );
    }
    if (RazorpayConfig.isPlaceholderKey &&
        !RazorpayConfig.allowPlaceholderCheckout) {
      return RazorpayCheckoutResult.failure(
        errorCode: 'MISSING_KEY',
        errorMessage:
            'Razorpay Key ID is not configured. Ask the client for rzp_test_/rzp_live_ key.',
      );
    }
    if (_pending != null && !_pending!.isCompleted) {
      return RazorpayCheckoutResult.failure(
        errorCode: 'IN_PROGRESS',
        errorMessage: 'Another payment is already in progress.',
      );
    }

    final completer = Completer<RazorpayCheckoutResult>();
    _pending = completer;

    final options = <String, dynamic>{
      'key': RazorpayConfig.keyId,
      'amount': amountMinorUnits,
      'currency': currency.toUpperCase(),
      'name': RazorpayConfig.companyName,
      'description': description,
      'timeout': 300,
      'retry': {'enabled': true, 'max_count': 1},
      'prefill': <String, dynamic>{
        if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
        if (contact != null && contact.trim().isNotEmpty)
          'contact': contact.trim(),
        if (customerName != null && customerName.trim().isNotEmpty)
          'name': customerName.trim(),
      },
      'notes': <String, dynamic>{
        if (receipt != null && receipt.isNotEmpty) 'receipt': receipt,
        'product': 'coin_recharge',
      },
    };
    final oid = orderId?.trim() ?? '';
    if (oid.isNotEmpty) {
      options['order_id'] = oid;
    }

    try {
      if (kDebugMode) {
        debugPrint(
          'Razorpay openCheckout amount=$amountMinorUnits '
          'currency=$currency key=${RazorpayConfig.keyId}',
        );
      }
      _razorpay.open(options);
    } catch (error, stack) {
      if (kDebugMode) {
        debugPrint('Razorpay open failed: $error\n$stack');
      }
      if (!completer.isCompleted) {
        completer.complete(
          RazorpayCheckoutResult.failure(
            errorCode: 'OPEN_FAILED',
            errorMessage: error.toString(),
          ),
        );
      }
    }

    return completer.future;
  }

  void _onSuccess(PaymentSuccessResponse response) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    pending.complete(
      RazorpayCheckoutResult.success(
        paymentId: response.paymentId?.trim() ?? '',
        orderId: response.orderId?.trim(),
        signature: response.signature?.trim(),
      ),
    );
    _pending = null;
  }

  void _onError(PaymentFailureResponse response) {
    final pending = _pending;
    if (pending == null || pending.isCompleted) return;
    final code = response.code?.toString() ?? '';
    final message = response.message?.toString() ?? 'Payment failed';
    final cancelled =
        code.contains('2') ||
        message.toLowerCase().contains('cancel') ||
        message.toLowerCase().contains('dismiss');
    pending.complete(
      RazorpayCheckoutResult.failure(
        errorCode: code.isEmpty ? 'PAYMENT_ERROR' : code,
        errorMessage: message,
        cancelled: cancelled,
      ),
    );
    _pending = null;
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (kDebugMode) {
      debugPrint('Razorpay external wallet: ${response.walletName}');
    }
  }

  void dispose() {
    if (_pending != null && !_pending!.isCompleted) {
      _pending!.complete(
        RazorpayCheckoutResult.failure(
          errorCode: 'DISPOSED',
          errorMessage: 'Payment cancelled.',
          cancelled: true,
        ),
      );
    }
    _pending = null;
    _razorpay.clear();
  }
}
