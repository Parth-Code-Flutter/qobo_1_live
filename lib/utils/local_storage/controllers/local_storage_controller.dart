import 'dart:convert';
import 'package:aligned_rewards/constants/local_storage_constants.dart';
import 'package:aligned_rewards/utils/extensions_utils/string_extentions.dart';
import 'package:aligned_rewards/utils/logger_utils/logger_utils.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';

class LocalStorage extends GetxController {
  late final FlutterSecureStorage _mEncryptedStorage;

  @override
  void onInit() {
    super.onInit();
    initStorageBox();
  }

  /// initialize FlutterSecureStorage
  void initStorageBox() {
    _mEncryptedStorage = const FlutterSecureStorage();
  }

  /// store string values to Getx storage
  Future writeStringStorage(String key, String value) async {
    await _mEncryptedStorage.write(key: key, value: value);
  }

  /// store int values to Getx storage
  Future writeIntStorage(String key, int value) async {
    var intToString = value.toString();
    await _mEncryptedStorage.write(key: key, value: intToString);
  }

  /// store string values to Getx storage
  Future writeBoolStorage(String key, bool value) async {
    var boolToString = value.toString();
    await _mEncryptedStorage.write(key: key, value: boolToString);
  }

  /// read string values from Getx storage
  Future<String> getStringFromStorage(String key) async {
    var value = await _mEncryptedStorage.read(key: key);
    return value ?? '';
  }

  /// read int values from Getx storage
  Future<int> getIntFromStorage(String key) async {
    var value = await _mEncryptedStorage.read(key: key) ?? '0';
    var stringToInt = int.parse(value);
    return stringToInt;
  }

  /// read bool values from Getx storage
  Future<bool?> getBoolFromStorage(String key) async {
    try {
      String boolValue = await _mEncryptedStorage.read(key: key) ?? '';
      return boolValue.parseBool();
    } catch (ex) {
      return false;
    }
  }

  /// store JSON object to secure storage
  Future writeJsonStorage(String key, Map<String, dynamic> value) async {
    try {
      String jsonString = jsonEncode(value);
      await _mEncryptedStorage.write(key: key, value: jsonString);
    } catch (ex) {
      LoggerUtils.logException('writeJsonStorage', ex);
    }
  }

  /// read JSON object from secure storage
  Future<Map<String, dynamic>?> getJsonFromStorage(String key) async {
    try {
      String? jsonString = await _mEncryptedStorage.read(key: key);
      if (jsonString != null && jsonString.isNotEmpty) {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      }
      return null;
    } catch (ex) {
      LoggerUtils.logException('getJsonFromStorage', ex);
      return null;
    }
  }

  /// store user data with token
  Future saveUserData(Map<String, dynamic> userData, String token, String userType) async {
    try {
      // Create user data object excluding organization
      Map<String, dynamic> userDataWithoutOrg = Map<String, dynamic>.from(userData);
      userDataWithoutOrg.remove('organization'); // Remove organization from user data
      
      // Store user data (without organization)
      await writeJsonStorage(kStorageUserData, userDataWithoutOrg);
      
      // Store token separately
      await writeStringStorage(kStorageToken, token);
      
      // Store user type specific data (without organization)
      switch (userType.toLowerCase()) {
        case 'admin':
          await writeJsonStorage(kStorageAdminUserData, userDataWithoutOrg);
          await writeBoolStorage(kStorageIsAdmin, true);
          break;
        case 'employee':
          await writeJsonStorage(kStorageEmployeeUserData, userDataWithoutOrg);
          await writeBoolStorage(kStorageIsEmployee, true);
          break;
        case 'client':
          await writeJsonStorage(kStorageClientUserData, userDataWithoutOrg);
          await writeBoolStorage(kStorageIsClient, true);
          break;
      }
      
      // Set logged in status
      await writeBoolStorage(kStorageIsLoggedIn, true);
      
      LoggerUtils.logger.i('User data saved successfully for $userType (organization excluded)');
    } catch (ex) {
      LoggerUtils.logException('saveUserData', ex);
    }
  }

  /// get user data
  Future<Map<String, dynamic>?> getUserData() async {
    try {
      return await getJsonFromStorage(kStorageUserData);
    } catch (ex) {
      LoggerUtils.logException('getUserData', ex);
      return null;
    }
  }

  /// get admin user data
  Future<Map<String, dynamic>?> getAdminUserData() async {
    try {
      return await getJsonFromStorage(kStorageAdminUserData);
    } catch (ex) {
      LoggerUtils.logException('getAdminUserData', ex);
      return null;
    }
  }

  /// get employee user data
  Future<Map<String, dynamic>?> getEmployeeUserData() async {
    try {
      return await getJsonFromStorage(kStorageEmployeeUserData);
    } catch (ex) {
      LoggerUtils.logException('getEmployeeUserData', ex);
      return null;
    }
  }

  /// get client user data
  Future<Map<String, dynamic>?> getClientUserData() async {
    try {
      return await getJsonFromStorage(kStorageClientUserData);
    } catch (ex) {
      LoggerUtils.logException('getClientUserData', ex);
      return null;
    }
  }

  /// get stored token
  Future<String> getToken() async {
    try {
      return await getStringFromStorage(kStorageToken);
    } catch (ex) {
      LoggerUtils.logException('getToken', ex);
      return '';
    }
  }

  /// check if user is logged in
  Future<bool> isLoggedIn() async {
    try {
      return await getBoolFromStorage(kStorageIsLoggedIn) ?? false;
    } catch (ex) {
      LoggerUtils.logException('isLoggedIn', ex);
      return false;
    }
  }

  /// save login response data (for common login system)
  Future saveLoginResponseData(Map<String, dynamic> userData, String token, String userType) async {
    try {
      // Create user data object excluding organization
      Map<String, dynamic> userDataWithoutOrg = Map<String, dynamic>.from(userData);
      userDataWithoutOrg.remove('organization'); // Remove organization from user data
      
      // Store user data (without organization)
      await writeJsonStorage(kStorageUserData, userDataWithoutOrg);
      
      // Store token separately
      await writeStringStorage(kStorageToken, token);
      
      // Store user type specific data (without organization)
      switch (userType.toLowerCase()) {
        case 'admin':
          await writeJsonStorage(kStorageAdminUserData, userDataWithoutOrg);
          await writeBoolStorage(kStorageIsAdmin, true);
          await writeBoolStorage(kStorageIsEmployee, false);
          await writeBoolStorage(kStorageIsClient, false);
          break;
        case 'employee':
          await writeJsonStorage(kStorageEmployeeUserData, userDataWithoutOrg);
          await writeBoolStorage(kStorageIsEmployee, true);
          await writeBoolStorage(kStorageIsAdmin, false);
          await writeBoolStorage(kStorageIsClient, false);
          break;
        case 'client':
          await writeJsonStorage(kStorageClientUserData, userDataWithoutOrg);
          await writeBoolStorage(kStorageIsClient, true);
          await writeBoolStorage(kStorageIsAdmin, false);
          await writeBoolStorage(kStorageIsEmployee, false);
          break;
      }
      
      // Set logged in status
      await writeBoolStorage(kStorageIsLoggedIn, true);
      
      LoggerUtils.logger.i('Login response data saved successfully for $userType (organization excluded)');
    } catch (ex) {
      LoggerUtils.logException('saveLoginResponseData', ex);
    }
  }

  /// get current user type
  Future<String> getCurrentUserType() async {
    try {
      if (await getBoolFromStorage(kStorageIsAdmin) == true) {
        return 'admin';
      } else if (await getBoolFromStorage(kStorageIsEmployee) == true) {
        return 'employee';
      } else if (await getBoolFromStorage(kStorageIsClient) == true) {
        return 'client';
      }
      return '';
    } catch (ex) {
      LoggerUtils.logException('getCurrentUserType', ex);
      return '';
    }
  }

  /// Save cached organization-user list (GET /organization-user). Call once after login; cleared on logout.
  Future<void> saveCachedOrganizationUserList(Map<String, dynamic> data) async {
    try {
      await writeJsonStorage(kStorageCachedOrganizationUserList, data);
      LoggerUtils.logger.i('Cached organization user list saved');
    } catch (ex) {
      LoggerUtils.logException('saveCachedOrganizationUserList', ex);
    }
  }

  /// Get cached organization-user list. Returns null if not found or on logout.
  Future<Map<String, dynamic>?> getCachedOrganizationUserList() async {
    try {
      return await getJsonFromStorage(kStorageCachedOrganizationUserList);
    } catch (ex) {
      LoggerUtils.logException('getCachedOrganizationUserList', ex);
      return null;
    }
  }

  /// Clear cached organization-user list (also cleared automatically in clearAllData on logout).
  Future<void> clearCachedOrganizationUserList() async {
    try {
      await _mEncryptedStorage.delete(key: kStorageCachedOrganizationUserList);
    } catch (ex) {
      LoggerUtils.logException('clearCachedOrganizationUserList', ex);
    }
  }

  /// clear all locally stored data
  Future clearAllData() async {
    try {
      _mEncryptedStorage.deleteAll();
    } catch (ex) {
      LoggerUtils.logException('clearAllData', ex);
    }
  }
}
