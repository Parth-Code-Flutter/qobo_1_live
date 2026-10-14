import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qobo_one_live/constants/facebook_login_config.dart';
import 'package:qobo_one_live/repo/auth/models/request/social_login_request_model.dart';
import 'package:qobo_one_live/services/social_auth/facebook_social_auth_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('app.meedu/flutter_facebook_auth');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => messenger.setMockMethodCallHandler(channel, null));

  test('production Facebook login enables backend exchange by default', () {
    expect(FacebookLoginConfig.submitFacebookLoginToBackend, isTrue);
  });

  for (final limited in [false, true]) {
    test(
      'maps ${limited ? "limited" : "classic"} login without inventing email',
      () async {
        var profileCalls = 0;
        messenger.setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'login') {
            return {
              'type': limited ? 'limited' : 'classic',
              'token': 'test-token',
              'userId': 'fb-user',
              'userName': 'Test User',
              'userEmail': null,
              'nonce': 'test-nonce',
              'expires': 2000000000000,
              'applicationId': 'test-app',
            };
          }
          if (call.method == 'getUserData') {
            profileCalls++;
          return jsonEncode({'id': 'fb-user', 'name': 'Test User'});
          }
          throw StateError('Unexpected call: ${call.method}');
        });
        final user = await FacebookSocialAuthProvider().signIn();
        expect(user, isNotNull);
        final body = SocialLoginRequestModel.fromSocialUser(user!).toJson();
        expect(body['authType'], 'facebook');
        expect(body['socialId'], 'fb-user');
        expect(body['name'], 'Test User');
        expect(body.containsKey('email'), isFalse);
        expect(profileCalls, limited ? 0 : 1);
      },
    );
  }

  test('SDK failure does not produce a social login identity', () async {
    messenger.setMockMethodCallHandler(channel, (call) async {
      throw PlatformException(code: 'FAILED', message: 'Invalid key hash');
    });
    expect(FacebookSocialAuthProvider().signIn(), throwsA(isA<Exception>()));
  });
}
