import 'package:get/get.dart';

class AuthLoginBinding extends Bindings {
  @override
  void dependencies() {
    // AuthLoginView owns its controller so overlapping login routes cannot
    // share a form key or dispose each other's text controllers.
  }
}
