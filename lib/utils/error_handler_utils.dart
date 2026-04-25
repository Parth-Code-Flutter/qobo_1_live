import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:qobo_one_live/routes/app_pages.dart';
import 'package:qobo_one_live/utils/local_storage/controllers/local_storage_controller.dart';
import 'package:qobo_one_live/utils/alert_message_utils/alert_message_utils.dart';
import 'package:qobo_one_live/utils/logger_utils/logger_utils.dart';

/// Global Error Handler Utility
/// Handles common API errors and provides centralized logout functionality
class ErrorHandlerUtils {
  static final ErrorHandlerUtils _instance = ErrorHandlerUtils._internal();
  factory ErrorHandlerUtils() => _instance;
  ErrorHandlerUtils._internal();

  // Static flag to prevent multiple logout attempts
  static bool _isLoggingOut = false;
  static bool _hasShownLogoutMessage = false;

  // Global session state management
  static bool _isSessionExpired = false;
  static bool _isNavigatingToLogin = false;
  static DateTime? _lastSessionExpiryTime;
  
  /// Check if session is currently expired
  static bool get isSessionExpired => _isSessionExpired;
  
  /// Check if currently navigating to login
  static bool get isNavigatingToLogin => _isNavigatingToLogin;
  
  /// Get the last session expiry time
  static DateTime? get lastSessionExpiryTime => _lastSessionExpiryTime;
  
  /// Reset session state (call this after successful login)
  static void resetSessionState() {
    _isSessionExpired = false;
    _isNavigatingToLogin = false;
    _lastSessionExpiryTime = null;
    LoggerUtils.logger.i('🔄 Session state reset');
  }
  
  /// Check if we should handle session expiry (prevents multiple calls)
  /// Returns true if we should proceed, false if already handled recently
  static bool _shouldHandleSessionExpiry() {
    // If we recently handled session expiry (within 2 seconds), don't handle again
    // This prevents multiple simultaneous 401s from causing multiple navigations
    if (_lastSessionExpiryTime != null) {
      final timeSinceLastExpiry = DateTime.now().difference(_lastSessionExpiryTime!);
      if (timeSinceLastExpiry.inSeconds < 2) {
        LoggerUtils.logger.w('⚠️ Session expiry handled recently (${timeSinceLastExpiry.inSeconds}s ago), skipping duplicate');
        return false;
      }
    }
    
    return true;
  }

  /// Handle 401 Unauthorized Error
  /// Logs out user and navigates to login screen
  static void handleUnauthorizedError() {
    // Check if we should handle session expiry (prevent duplicate calls within 2 seconds)
    if (!_shouldHandleSessionExpiry()) {
      return;
    }
    
    // Set flags immediately to prevent duplicate calls
    _isSessionExpired = true;
    _isNavigatingToLogin = true;
    _lastSessionExpiryTime = DateTime.now();
    
    LoggerUtils.logger.w('🔄 Handling 401 Unauthorized Error - Logging out user and navigating to login');
    
    try {
      // Clear all local storage first
      LocalStorage().clearAllData();
      LoggerUtils.logger.i('✅ Local storage cleared');
    } catch (e) {
      LoggerUtils.logException('Error clearing local storage', e);
    }
    
    // Perform navigation immediately
    // Use WidgetsBinding to ensure we're on the UI thread
    if (Get.context != null) {
      // Navigate immediately if context is available
      _performNavigation();
    } else {
      // If context is not available, wait for next frame
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _performNavigation();
      });
    }
  }

  /// Perform the actual navigation to login screen
  /// This is a helper method to avoid code duplication
  static void _performNavigation() {
    try {
      LoggerUtils.logger.i('🚀 Attempting navigation to login screen...');
      LoggerUtils.logger.i('Current route: ${Get.currentRoute}');
      
      // Use Get.offAll with direct widget - most reliable method
      // This clears all previous routes and navigates to login
      try {
        // Get.offAll(() => const LoginOptionsView());
        LoggerUtils.logger.i('✅ Successfully navigated to login screen using Get.offAll');
        
        // Show snackbar after navigation completes
        Future.delayed(const Duration(milliseconds: 1000), () {
          try {
            if (Get.context != null) {
              Get.find<AlertMessageUtils>().showSuccessSnackBar("Session expired. Please login again.");
            }
          } catch (e) {
            LoggerUtils.logger.w('Could not show snackbar after navigation: $e');
          }
        });
      } catch (navError) {
        LoggerUtils.logException('Navigation error with Get.offAll', navError);
        
        // Fallback: Try Get.offAllNamed
        try {
          LoggerUtils.logger.w('⚠️ Trying fallback navigation: Get.offAllNamed');
          // Get.offAllNamed(Routes.LOGIN_OPTIONS);
          LoggerUtils.logger.i('✅ Fallback navigation successful (Get.offAllNamed)');
          
          Future.delayed(const Duration(milliseconds: 1000), () {
            try {
              if (Get.context != null) {
                Get.find<AlertMessageUtils>().showSuccessSnackBar("Session expired. Please login again.");
              }
            } catch (e) {
              LoggerUtils.logger.w('Could not show snackbar after fallback navigation: $e');
            }
          });
        } catch (e2) {
          LoggerUtils.logException('Fallback navigation also failed', e2);
          
          // Last resort: Try Get.offNamed
          try {
            LoggerUtils.logger.w('⚠️ Trying last resort navigation: Get.offNamed');
            // Get.offNamed(Routes.LOGIN_OPTIONS);
            LoggerUtils.logger.i('✅ Last resort navigation successful (Get.offNamed)');
          } catch (e3) {
            LoggerUtils.logException('All navigation methods failed', e3);
            LoggerUtils.logger.e('❌ CRITICAL: Unable to navigate to login screen');
          }
        }
      }
    } catch (e) {
      LoggerUtils.logException('_performNavigation error', e);
    } finally {
      // Reset navigation flag after a delay to allow navigation to complete
      Future.delayed(const Duration(milliseconds: 3000), () {
        _isNavigatingToLogin = false;
      });
    }
  }

  /// Check if response status code indicates unauthorized access
  /// Returns true if status code is 401
  static bool isUnauthorizedError(int? statusCode) {
    return statusCode == 401;
  }

  /// Check if response data indicates unauthorized access
  /// Returns true if statusCode in response data is 401
  static bool isUnauthorizedErrorFromData(Map<String, dynamic>? responseData) {
    if (responseData == null) return false;
    
    int? statusCode = responseData['statusCode'];
    return statusCode == 401;
  }

  /// Check if API calls should be made (prevents multiple calls when session expired)
  /// Returns false if currently logging out
  static bool shouldMakeApiCall() {
    return !_isLoggingOut;
  }

  /// Handle API response and check for 401 errors
  /// Returns true if 401 error was handled, false otherwise
  static bool handleApiResponse(int? statusCode, Map<String, dynamic>? responseData) {
    // Check for 401 in status code
    if (isUnauthorizedError(statusCode)) {
      handleUnauthorizedError();
      return true;
    }
    
    // Check for 401 in response data
    if (isUnauthorizedErrorFromData(responseData)) {
      handleUnauthorizedError();
      return true;
    }
    
    return false;
  }

  /// Logout user manually (for logout button)
  static void logoutUser() {
    try {
      LoggerUtils.logger.i('🔄 Manual logout initiated by user');
      
      // Clear all local storage
      LocalStorage().clearAllData();
      
      // Check if context is still valid before showing snackbar
      if (Get.context != null && Get.overlayContext != null) {
        try {
          // Show logout message
          Get.find<AlertMessageUtils>().showSuccessSnackBar("Logged out successfully");
        } catch (e) {
          LoggerUtils.logger.w('Could not show snackbar: $e');
        }
      }
      
      // Navigate to login options screen
      // Get.offAllNamed(Routes.LOGIN_OPTIONS);
      
      LoggerUtils.logger.i('✅ User logged out successfully');
    } catch (e) {
      LoggerUtils.logException('logoutUser', e);
      // Fallback navigation
      // Get.offAllNamed(Routes.LOGIN_OPTIONS);
    }
  }
}
