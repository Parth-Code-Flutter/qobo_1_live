import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:qobo_one_live/repo/economy/economy_repo.dart';
import 'package:qobo_one_live/services/api_service.dart';

class RecordingApi extends ApiService {
  String? path, token;
  dynamic body;
  bool skip401 = false;
  int responseStatus = 200;
  @override
  Future<http.Response?> postRequest({
    required String endPoint,
    dynamic requestModel,
    bool isShowLoader = true,
    bool isLoginCall = false,
    String? bearerToken,
    bool skipUnauthorizedHandling = false,
  }) async {
    path = endPoint;
    token = bearerToken;
    body = requestModel;
    skip401 = skipUnauthorizedHandling;
    return http.Response(
      jsonEncode({
        'success': true,
        'data': {'credited': true},
      }),
      responseStatus,
    );
  }
}

void main() {
  test(
    'confirm sends exact backend fields using captured owner session',
    () async {
      final api = RecordingApi();
      final result = await EconomyRepo(apiService: api)
          .confirmGooglePlayPurchase(
            productId: 'qobo_coins_4000',
            purchaseToken: 'test-token',
            bearerToken: 'owner-session',
            orderId: 'GPA.test',
          );
      expect(api.path, '/api/economy/google-play/confirm');
      expect(api.token, 'owner-session');
      expect(api.skip401, true);
      expect(api.body, {
        'packageName': 'com.qobo1live.live',
        'productId': 'qobo_coins_4000',
        'purchaseToken': 'test-token',
        'orderId': 'GPA.test',
      });
      expect(result?['success'], true);
    },
  );
  test('HTTP failure cannot be treated as successful credit', () async {
    final api = RecordingApi()..responseStatus = 500;
    final result = await EconomyRepo(apiService: api).confirmGooglePlayPurchase(
      productId: 'qobo_coins_4000',
      purchaseToken: 'test-token',
      bearerToken: 'owner-session',
    );
    expect(result?['success'], false);
  });
  test('missing order ID is omitted from confirmation', () async {
    final api = RecordingApi();
    await EconomyRepo(apiService: api).confirmGooglePlayPurchase(
      productId: 'qobo_coins_4000',
      purchaseToken: 'test-token',
      bearerToken: 'owner-session',
    );
    expect((api.body as Map).containsKey('orderId'), false);
  });
}
