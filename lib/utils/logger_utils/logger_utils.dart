import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Custom logger printer that provides clean, readable output without ANSI codes
class CleanPrinter extends LogPrinter {
  @override
  List<String> log(LogEvent event) {
    final emoji = _getLevelEmoji(event.level);
    final levelName = _getLevelName(event.level);
    final time = DateTime.now().toString().substring(11, 19); // HH:mm:ss
    
    final buffer = StringBuffer();
    buffer.write('[$time] $emoji [$levelName] ${event.message}');
    
    // Add error if present
    if (event.error != null) {
      buffer.write('\n  └─ Error: ${event.error}');
    }
    
    // Add stack trace if present (only for errors)
    if (event.stackTrace != null && event.level.index >= Level.error.index) {
      final lines = event.stackTrace.toString().split('\n');
      if (lines.isNotEmpty) {
        buffer.write('\n  └─ ${lines.first}');
      }
    }
    
    return [buffer.toString()];
  }

  String _getLevelName(Level level) {
    switch (level) {
      case Level.trace:
        return 'TRACE';
      case Level.debug:
        return 'DEBUG';
      case Level.info:
        return 'INFO ';
      case Level.warning:
        return 'WARN ';
      case Level.error:
        return 'ERROR';
      case Level.fatal:
        return 'FATAL';
      case Level.off:
        return 'OFF  ';
      case Level.all:
        return 'ALL  ';
      case Level.verbose:
        return 'VERBOSE';
      case Level.wtf:
        return 'WTF  ';
      case Level.nothing:
        return 'NONE ';
    }
  }

  String _getLevelEmoji(Level level) {
    switch (level) {
      case Level.trace:
        return '🔍';
      case Level.debug:
        return '🐛';
      case Level.info:
        return 'ℹ️';
      case Level.warning:
        return '⚠️';
      case Level.error:
        return '❌';
      case Level.fatal:
        return '💀';
      case Level.off:
        return '🚫';
      case Level.all:
        return '📋';
      case Level.verbose:
        return '📝';
      case Level.wtf:
        return '🤯';
      case Level.nothing:
        return '🙈';
    }
  }
}

class LoggerUtils {
  static var logger = Logger(
    printer: kDebugMode 
        ? CleanPrinter() 
        : SimplePrinter(colors: false), // Disable colors in release mode
    level: kDebugMode ? Level.trace : Level.warning, // Only show warnings+ in release
    output: ConsoleOutput(), // Use console output
  );

  /// Log exception with clear formatting
  static void logException(String title, dynamic object) {
    if (kDebugMode) {
      logger.e('EXCEPTION: $title');
      logger.e('Error Details: $object');
    }
  }

  /// Log success message with clear formatting
  static void logSuccess(String message) {
    if (kDebugMode) {
      logger.i('✅ SUCCESS: $message');
    }
  }

  /// Log failure message with clear formatting
  static void logFailure(String message) {
    if (kDebugMode) {
      logger.w('❌ FAILURE: $message');
    }
  }

  /// Log API success
  static void logApiSuccess(String endpoint, int statusCode) {
    if (kDebugMode) {
      logger.i('✅ API SUCCESS: $endpoint | Status: $statusCode');
    }
  }

  /// Log API failure
  static void logApiFailure(String endpoint, int? statusCode, [String? error]) {
    if (kDebugMode) {
      final errorMsg = error != null ? ' | Error: $error' : '';
      logger.w('❌ API FAILURE: $endpoint | Status: ${statusCode ?? "N/A"}$errorMsg');
    }
  }

  /// Log API error
  static void logApiError(String endpoint, dynamic error) {
    if (kDebugMode) {
      logger.e('💥 API ERROR: $endpoint');
      logger.e('Error: $error');
    }
  }

  /// Log info message
  static void logInfo(String message) {
    if (kDebugMode) {
      logger.i('ℹ️ INFO: $message');
    }
  }

  /// Log warning message
  static void logWarning(String message) {
    if (kDebugMode) {
      logger.w('⚠️ WARNING: $message');
    }
  }
}
