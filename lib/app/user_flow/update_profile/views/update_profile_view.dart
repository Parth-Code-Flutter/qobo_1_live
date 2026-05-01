import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/update_profile_controller.dart';

/// Screen scaffold for update profile (replace body when UI is ready).
class UpdateProfileView extends GetView<UpdateProfileController> {
  const UpdateProfileView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text('Update profile'),
      ),
    );
  }
}
