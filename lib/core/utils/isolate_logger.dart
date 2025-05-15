import 'package:flutter/foundation.dart';
import '../../constants/app_constants.dart';

/// A utility for logging in background isolates where the main Logger might not be initialized.
///
/// This utility provides similar formatting and functionality to the main Logger class
/// but doesn't require LoggerService which might not be available in isolates.
/// It uses debugPrint for all logging to ensure logs appear in the console.
class IsolateLogger {
  /// Format and log an info message
  ///
  /// Use this for general information about normal operation
  static void info(String tag, String message) {
    _formatAndPrint('INFO', tag, message);
  }

  /// Format and log a debug message
  ///
  /// Use this for detailed information useful during development
  static void debug(String tag, String message) {
    if (AppConstants.enableDebugLogs) {
      _formatAndPrint('DEBUG', tag, message);
    }
  }

  /// Format and log a warning message
  ///
  /// Use this for unexpected behaviors that aren't errors
  static void warning(String tag, String message) {
    _formatAndPrint('WARN', tag, message);
  }

  /// Format and log an error message
  ///
  /// Use this for recoverable errors
  static void error(
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) {
    _formatAndPrint('ERROR', tag, message, exception, stackTrace);
  }

  /// Format and log a critical message
  ///
  /// Use this for severe errors
  static void critical(
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) {
    _formatAndPrint('CRITICAL', tag, message, exception, stackTrace);
  }

  /// Log a message related to sensor operations
  static void sensor(String message) {
    debug('SENSOR', message);
  }

  /// Log a message related to camera operations
  static void camera(String message) {
    debug('CAMERA', message);
  }

  /// Log a message related to recording operations
  static void recording(String message) {
    debug('RECORDING', message);
  }

  /// Log a message related to calibration operations
  static void calibration(String message) {
    debug('CALIBRATION', message);
  }

  /// Log a message related to file system operations
  static void file(String message) {
    debug('FILE', message);
  }

  /// Format the log message with consistent formatting and print it
  static void _formatAndPrint(
    String level,
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) {
    String output = '${level.padRight(8)} [$tag] $message';

    // Add emoji indicators for visual filtering + isolate marker
    switch (level) {
      case 'INFO':
        output = '📝 [ISOLATE] $output';
        break;
      case 'DEBUG':
        output = '🔍 [ISOLATE] $output';
        break;
      case 'WARN':
        output = '⚠️ [ISOLATE] $output';
        break;
      case 'ERROR':
        output = '❌ [ISOLATE] $output';
        break;
      case 'CRITICAL':
        output = '🔥 [ISOLATE] $output';
        break;
    }

    if (exception != null) {
      output += '\nException: $exception';

      if (stackTrace != null) {
        output += '\nStackTrace: $stackTrace';
      }
    }

    // Use debugPrint to avoid log truncation
    debugPrint(output);
  }
}
