import 'package:aligned_rewards/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:aligned_rewards/utils/logger_utils/logger_utils.dart';
import 'package:get/get.dart';

import '../constants/local_storage_constants.dart';

class HeaderData {
  Future<Map<String, String>> headers() async {
    try {
      var token = await Get.find<LocalStorage>().getToken();
      
      var headers = {
        'Content-Type': 'application/json',
      };
      
      // Add authorization header only if token exists
      if (token.isNotEmpty) {
        headers['Authorization'] = token;
      }
      
      LoggerUtils.logger.i('Headers generated with token: ${token.isNotEmpty ? 'Present' : 'Not present'}');
      return headers;
    } catch (e) {
      LoggerUtils.logException('common headers', e);
    }
    return <String, String>{};
  }
}
