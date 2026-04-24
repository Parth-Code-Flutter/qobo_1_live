import 'dart:convert';
import 'dart:io';
import 'package:aligned_rewards/constants/status_code_constants.dart';
import 'package:aligned_rewards/services/api_constants.dart';
import 'package:aligned_rewards/services/header_data.dart';
import 'package:aligned_rewards/utils/alert_message_utils/alert_message_utils.dart';
import 'package:aligned_rewards/utils/api_response_utils.dart';
import 'package:aligned_rewards/utils/logger_utils/logger_utils.dart';
import 'package:aligned_rewards/utils/error_handler_utils.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class ApiService {
  /// Check for 401 unauthorized error in both HTTP statusCode and body statusCode
  /// Returns true if 401 was detected and handled, false otherwise
  bool _checkAndHandle401(http.Response response, {bool isLoginCall = false}) {
    // Skip 401 check for login calls
    if (isLoginCall) {
      return false;
    }

    // Check HTTP statusCode
    if (response.statusCode == StatusCodeConstants.unauthorized) {
      LoggerUtils.logWarning('401 Unauthorized (HTTP) - Session expired');
      ErrorHandlerUtils.handleUnauthorizedError();
      return true;
    }

    // Check body statusCode
    final jsonMap = ApiResponseUtils.tryDecodeMap(response.body);
    final bodyStatusCode = ApiResponseUtils.tryGetBodyStatusCode(jsonMap);
    
    if (bodyStatusCode == StatusCodeConstants.unauthorized) {
      LoggerUtils.logWarning('401 Unauthorized (Body) - Session expired');
      ErrorHandlerUtils.handleUnauthorizedError();
      return true;
    }

    return false;
  }

  void _logApiResult(String label, http.Response response) {
    final jsonMap = ApiResponseUtils.tryDecodeMap(response.body);
    final bodyStatusCode = ApiResponseUtils.tryGetBodyStatusCode(jsonMap);
    final message = ApiResponseUtils.tryGetMessage(jsonMap);

    // If body is not JSON, fall back to HTTP 2xx.
    final isOk = jsonMap == null
        ? (response.statusCode >= 200 && response.statusCode < 300)
        : (StatusCodeConstants.isHttpSuccess(response.statusCode) &&
            StatusCodeConstants.isApiSuccess(bodyStatusCode));

    if (isOk) {
      LoggerUtils.logApiSuccess(label, response.statusCode);
    } else {
      final extra = <String>[
        if (bodyStatusCode != null) 'bodyStatusCode=$bodyStatusCode',
        if (message != null && message.isNotEmpty) 'message=$message',
      ].join(' | ');
      LoggerUtils.logApiFailure(label, response.statusCode, extra.isEmpty ? null : extra);
    }
  }

  Future<http.Response?> postRequest({
    required String endPoint,
    dynamic requestModel,
    bool isShowLoader = true,
    bool isLoginCall = false,
    // Map<String, String>? headers,
  }) async {
    // Check if session is expired (skip for login calls)
    if (!isLoginCall && !ErrorHandlerUtils.shouldMakeApiCall()) {
      LoggerUtils.logWarning('POST request blocked - session expired');
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
      return null;
    }
    
    // if (await checkUserConnection()) {
    LoggerUtils.logInfo('POST Request: $endPoint');

    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (isShowLoader) {
      Get.find<AlertMessageUtils>().showProgressDialog();
    }

    // headers ??= {'Content-Type': 'application/json'};
    if (!isLoginCall) {
      var authHeaders = await HeaderData().headers();
      headers.addAll(authHeaders);
    }
    var domainUrl = ApiConstants.baseUrl;

    // Fix URL duplication - ensure endpoint doesn't already contain base URL
    String finalEndpoint = endPoint;
    if (endPoint.startsWith('http')) {
      // If endpoint already contains full URL, use it as is
      finalEndpoint = endPoint;
    } else {
      // If endpoint is relative, combine with base URL
      finalEndpoint = '$domainUrl$endPoint';
    }

    var url = Uri.parse(finalEndpoint);

    try {
      // Convert requestModel to JSON string if it's a Map
      String body;
      if (requestModel is Map<String, dynamic>) {
        body = json.encode(requestModel);
      } else if (requestModel is String) {
        body = requestModel;
      } else {
        body = json.encode(requestModel);
      }
      
      var response = await http.post(url, body: body, headers: headers);
      
      // Check for 401 error globally (both HTTP and body statusCode)
      if (_checkAndHandle401(response, isLoginCall: isLoginCall)) {
        return null;
      }
      
      _logApiResult('POST $endPoint', response);
      
      return response;
    } catch (e) {
      LoggerUtils.logApiError('POST $endPoint', e);
    } finally {
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
    }
    // }
    // else {
    //   showInternetConnectivityDialog();
    //   return null;
    // }
    return null;
  }

  Future<http.Response?> getRequest({
    required String endPoint,
    Map<String, dynamic>? params,
    Map<String, String>? queryParams,
    bool isShowLoader = true,
    String? baseUrl,
    // Map<String, String>? headers,
  }) async {
    // Check if session is expired
    if (!ErrorHandlerUtils.shouldMakeApiCall()) {
      LoggerUtils.logWarning('GET request blocked - session expired');
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
      return null;
    }
    
    // if (await checkUserConnection()) {
    LoggerUtils.logInfo('GET Request: $endPoint');

    // Map<String, String>? headers = {};
    if (isShowLoader) {
      Get.find<AlertMessageUtils>().showProgressDialog();
    }

    // headers ??= {'Content-Type': 'application/json'};
    var headers = await HeaderData().headers();

    var domainUrl = baseUrl ?? ApiConstants.baseUrl;

    // Build URL with query parameters
    var uri = Uri.parse('$domainUrl$endPoint');
    if (queryParams != null && queryParams.isNotEmpty) {
      uri = uri.replace(queryParameters: queryParams);
    }

    try {
      var response = await http.get(uri, headers: headers);
      
      // Check for 401 error globally (both HTTP and body statusCode)
      if (_checkAndHandle401(response)) {
        return null;
      }
      
      _logApiResult('GET $endPoint', response);
      
      return response;
    } catch (e) {
      LoggerUtils.logApiError('GET $endPoint', e);
    } finally {
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
    }
    // } else {
    //   showInternetConnectivityDialog();
    //   return null;
    // }
    return null;
  }

  // Future<http.Response?> deleteRequest({
  Future<http.Response?> deleteRequest({
    required String endPoint,
    dynamic requestModel,
    Map<String, dynamic>? params,
    bool isShowLoader = true,
    // Map<String, String>? headers,
  }) async {
    // Check if session is expired
    if (!ErrorHandlerUtils.shouldMakeApiCall()) {
      LoggerUtils.logWarning('DELETE request blocked - session expired');
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
      return null;
    }
    
    // if (await checkUserConnection()) {
    debugPrint("REQUEST MODEL :: $requestModel");

    // Map<String, String>? headers = {};
    if (isShowLoader) {
      Get.find<AlertMessageUtils>().showProgressDialog();
    }

    var headers = await HeaderData().headers();
    var domainUrl = ApiConstants.baseUrl;

    var url = Uri.parse('$domainUrl$endPoint');

    debugPrint('deleteRequest : $url');
    try {
      var response =
          await http.delete(url, headers: headers, body: requestModel);
      debugPrint('response :  ${response.body}');
      
      // Check for 401 error globally (both HTTP and body statusCode)
      if (_checkAndHandle401(response)) {
        return null;
      }
      
      _logApiResult('DELETE $endPoint', response);
      
      return response;
    } catch (e) {
      LoggerUtils.logException('deleteRequest', e);
    } finally {
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
      // }}else {
      // showInternetConnectivityDialog();
      // return null;
      // }
    }
    return null;
  }

  Future<http.Response?> putRequest({
    required String endPoint,
    dynamic requestModel,
    bool isShowLoader = true,
    bool isLoginCall = false,
  }) async {
    // Check if session is expired (skip for login calls)
    if (!isLoginCall && !ErrorHandlerUtils.shouldMakeApiCall()) {
      LoggerUtils.logWarning('PUT request blocked - session expired');
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
      return null;
    }
    
    debugPrint("PUT REQUEST MODEL :: $requestModel");

    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (isShowLoader) {
      Get.find<AlertMessageUtils>().showProgressDialog();
    }

    if (!isLoginCall) {
      var authHeaders = await HeaderData().headers();
      headers.addAll(authHeaders);
    }
    var domainUrl = ApiConstants.baseUrl;

    var url = Uri.parse('$domainUrl$endPoint');

    debugPrint('PUT url : $url');
    try {
      // Convert requestModel to JSON string if it's a Map
      String body;
      if (requestModel is Map<String, dynamic>) {
        body = json.encode(requestModel);
      } else if (requestModel is String) {
        body = requestModel;
      } else {
        body = json.encode(requestModel);
      }
      
      var response = await http.put(url, body: body, headers: headers);
      debugPrint('PUT response :  ${response.body}');
      
      // Check for 401 error globally (both HTTP and body statusCode)
      if (_checkAndHandle401(response, isLoginCall: isLoginCall)) {
        return null;
      }
      
      _logApiResult('PUT $endPoint', response);
      
      return response;
    } catch (e) {
      LoggerUtils.logException('putRequest', e);
    } finally {
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
    }
    return null;
  }

  /// Upload file using multipart/form-data
  /// Used for uploading images, documents, and other files
  Future<http.Response?> uploadFile({
    required String endPoint,
    required File file,
    String? fileName,
    Map<String, String>? additionalFields,
    bool isShowLoader = true,
  }) async {
    // Check if session is expired
    if (!ErrorHandlerUtils.shouldMakeApiCall()) {
      LoggerUtils.logWarning('File upload blocked - session expired');
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
      return null;
    }

    LoggerUtils.logInfo('File Upload: $endPoint');

    if (isShowLoader) {
      Get.find<AlertMessageUtils>().showProgressDialog();
    }

    try {
      // Get authentication headers
      var authHeaders = await HeaderData().headers();
      
      // Build URL
      var domainUrl = ApiConstants.baseUrl;
      String finalEndpoint = endPoint;
      if (endPoint.startsWith('http')) {
        finalEndpoint = endPoint;
      } else {
        finalEndpoint = '$domainUrl$endPoint';
      }
      var url = Uri.parse(finalEndpoint);


      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add authentication headers
      request.headers.addAll(authHeaders);
      
      // Add file to request
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();
      final multipartFile = http.MultipartFile(
        'file', // Field name - adjust based on your API requirements
        fileStream,
        fileLength,
        filename: fileName ?? file.path.split('/').last,
      );
      request.files.add(multipartFile);
      
      // Add additional fields if provided
      if (additionalFields != null) {
        request.fields.addAll(additionalFields);
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Check for 401 error globally (both HTTP and body statusCode)
      if (_checkAndHandle401(response)) {
        return null;
      }
      
      _logApiResult('File Upload $endPoint', response);
      
      return response;
    } catch (e) {
      LoggerUtils.logApiError('File Upload $endPoint', e);
      return null;
    } finally {
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
    }
  }

  /// Upload multipart form data with multiple fields and optional files
  /// Used for creating todos and other form submissions with file uploads
  Future<http.Response?> multipartFormRequest({
    required String endPoint,
    required Map<String, String> fields,
    List<File>? files,
    String fileFieldName = 'image',
    bool isShowLoader = true,
  }) async {
    // Check if session is expired
    if (!ErrorHandlerUtils.shouldMakeApiCall()) {
      LoggerUtils.logWarning('Multipart form request blocked - session expired');
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
      return null;
    }

    LoggerUtils.logInfo('Multipart Form: $endPoint');

    if (isShowLoader) {
      Get.find<AlertMessageUtils>().showProgressDialog();
    }

    try {
      // Get authentication headers
      var authHeaders = await HeaderData().headers();
      
      // Build URL
      var domainUrl = ApiConstants.baseUrl;
      String finalEndpoint = endPoint;
      if (endPoint.startsWith('http')) {
        finalEndpoint = endPoint;
      } else {
        finalEndpoint = '$domainUrl$endPoint';
      }
      var url = Uri.parse(finalEndpoint);


      // Create multipart request
      var request = http.MultipartRequest('POST', url);
      
      // Add authentication headers
      request.headers.addAll(authHeaders);
      
      // Add form fields
      request.fields.addAll(fields);
      
      // Add files if provided
      if (files != null && files.isNotEmpty) {
        for (var file in files) {
          final fileStream = http.ByteStream(file.openRead());
          final fileLength = await file.length();
          final multipartFile = http.MultipartFile(
            fileFieldName,
            fileStream,
            fileLength,
            filename: file.path.split('/').last,
          );
          request.files.add(multipartFile);
        }
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      // Check for 401 error globally (both HTTP and body statusCode)
      if (_checkAndHandle401(response)) {
        return null;
      }
      
      _logApiResult('Multipart Form $endPoint', response);
      
      return response;
    } catch (e) {
      LoggerUtils.logApiError('Multipart Form $endPoint', e);
      LoggerUtils.logException('multipartFormRequest', e);
      return null;
    } finally {
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
    }
  }

  /// PATCH Request
  /// Used for partial updates to resources
  Future<http.Response?> patchRequest({
    required String endPoint,
    dynamic requestModel,
    bool isShowLoader = true,
    bool isLoginCall = false,
  }) async {
    // Check if session is expired (skip for login calls)
    if (!isLoginCall && !ErrorHandlerUtils.shouldMakeApiCall()) {
      LoggerUtils.logWarning('PATCH request blocked - session expired');
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
      return null;
    }
    
    LoggerUtils.logInfo('PATCH Request: $endPoint');

    Map<String, String> headers = {'Content-Type': 'application/json'};
    if (isShowLoader) {
      Get.find<AlertMessageUtils>().showProgressDialog();
    }

    if (!isLoginCall) {
      var authHeaders = await HeaderData().headers();
      headers.addAll(authHeaders);
    }
    var domainUrl = ApiConstants.baseUrl;

    // Fix URL duplication - ensure endpoint doesn't already contain base URL
    String finalEndpoint = endPoint;
    if (endPoint.startsWith('http')) {
      // If endpoint already contains full URL, use it as is
      finalEndpoint = endPoint;
    } else {
      // If endpoint is relative, combine with base URL
      finalEndpoint = '$domainUrl$endPoint';
    }

    var url = Uri.parse(finalEndpoint);

    try {
      // Convert requestModel to JSON string if it's a Map
      String body;
      if (requestModel is Map<String, dynamic>) {
        body = json.encode(requestModel);
      } else if (requestModel is String) {
        body = requestModel;
      } else {
        body = json.encode(requestModel);
      }
      
      var response = await http.patch(url, body: body, headers: headers);
      
      // Check for 401 error globally (both HTTP and body statusCode)
      if (_checkAndHandle401(response, isLoginCall: isLoginCall)) {
        return null;
      }
      
      _logApiResult('PATCH $endPoint', response);
      
      return response;
    } catch (e) {
      LoggerUtils.logApiError('PATCH $endPoint', e);
      LoggerUtils.logException('patchRequest', e);
    } finally {
      if (isShowLoader) {
        Get.find<AlertMessageUtils>().hideProgressDialog();
      }
    }
    return null;
  }
}
