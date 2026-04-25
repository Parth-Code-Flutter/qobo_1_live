import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../app/auth/login/bindings/auth_login_binding.dart';
import '../app/auth/login/views/auth_login_view.dart';
import '../app/auth/signUp/bindings/auth_sign_up_binding.dart';
import '../app/auth/signUp/views/auth_sign_up_view.dart';
import '../app/auth/verifyAccount/bindings/auth_verify_account_binding.dart';
import '../app/auth/verifyAccount/views/auth_verify_account_view.dart';
import '../app/splash/splash/bindings/splash_binding.dart';
import '../app/splash/splash/views/splash_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.SPLASH;

  static final routes = <GetPage<dynamic>>[
    GetPage(
      name: _Paths.SPLASH,
      page: () => const SplashView(),
      binding: SplashBinding(),
    ),
    GetPage(
      name: _Paths.AUTH_LOGIN,
      page: () => const AuthLoginView(),
      binding: AuthLoginBinding(),
    ),
    GetPage(
      name: _Paths.AUTH_SIGN_UP,
      page: () => const AuthSignUpView(),
      binding: AuthSignUpBinding(),
    ),
    GetPage(
      name: _Paths.AUTH_VERIFY_ACCOUNT,
      page: () => const AuthVerifyAccountView(),
      binding: AuthVerifyAccountBinding(),
    ),
  ];
}
