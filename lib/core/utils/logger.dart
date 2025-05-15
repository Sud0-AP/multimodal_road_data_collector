import 'package:flutter/foundation.dart';
import 'dart:io' show FileSystemException;
import '../../constants/app_constants.dart';
import '../services/logger_service.dart';

/// A utility for consistent logging throughout the app
///
/// This utility wraps the [LoggerService] and provides easy-to-use static methods
/// for logging at different levels. It ensures consistent formatting and allows
/// for easy filtering of logs by category/tag.
class Logger {
  static LoggerService? _loggerService;

  /// Initialize the logger with a [LoggerService] instance
  static void init(LoggerService loggerService) {
    _loggerService = loggerService;
  }

  /// Log an info message for general, expected information
  ///
  /// Use this for general information that's useful for understanding
  /// the normal operation of the app
  static void info(String tag, String message) {
    _logToService('INFO', tag, message);
    _logToConsole('INFO', tag, message);
  }

  /// Log a debug message for detailed development information
  ///
  /// Use this for detailed information that's useful during development
  /// but not necessary for normal operation
  static void debug(String tag, String message) {
    _logToService('DEBUG', tag, message);
    if (AppConstants.enableDebugLogs) {
      _logToConsole('DEBUG', tag, message);
    }
  }

  /// Log a warning message for unexpected behaviors that aren't errors
  ///
  /// Use this for situations where something unexpected happened,
  /// but the app can continue to function normally
  static void warning(
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) {
    _logToService('WARN', tag, message, exception, stackTrace);
    _logToConsole('WARN', tag, message, exception, stackTrace);
  }

  /// Log an error message for recoverable errors
  ///
  /// Use this for errors that can be recovered from but indicate
  /// a problem that should be addressed
  static void error(
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) {
    // Capture stack trace automatically if not provided
    final trace = stackTrace ?? (exception != null ? StackTrace.current : null);
    _logToService('ERROR', tag, message, exception, trace);
    _logToConsole('ERROR', tag, message, exception, trace);
  }

  /// Log a critical message for severe errors
  ///
  /// Use this for severe errors that may prevent the app from functioning properly
  static void critical(
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) {
    // Always capture stack trace for critical errors if not provided
    final trace = stackTrace ?? StackTrace.current;
    _logToService('CRITICAL', tag, message, exception, trace);
    _logToConsole('CRITICAL', tag, message, exception, trace);
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

  /// Log a message related to permissions
  static void permission(
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) {
    if (exception != null) {
      error('PERMISSION', message, exception, stackTrace);
    } else {
      debug('PERMISSION', message);
    }
  }

  /// Log a message related to network operations
  static void network(
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) {
    if (exception != null) {
      error('NETWORK', message, exception, stackTrace);
    } else {
      debug('NETWORK', message);
    }
  }

  /// Log a message to the LoggerService
  static void _logToService(
    String level,
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) {
    if (_loggerService == null) {
      return;
    }

    switch (level) {
      case 'INFO':
        _loggerService!.info(tag, message);
        break;
      case 'DEBUG':
        _loggerService!.debug(tag, message);
        break;
      case 'WARN':
        _loggerService!.warning(tag, message);
        break;
      case 'ERROR':
        _loggerService!.error(tag, message, exception, stackTrace);
        break;
      case 'CRITICAL':
        _loggerService!.critical(tag, message, exception, stackTrace);
        break;
    }
  }

  /// Format an exception for clear logging
  ///
  /// Extracts useful information from common exception types
  static String formatException(dynamic exception) {
    if (exception == null) return 'No exception details';

    // Special handling for common exception types
    if (exception is FileSystemException) {
      return 'FileSystemException: ${exception.message}, path: ${exception.path}, osError: ${exception.osError}';
    }

    return exception.toString();
  }

  /// Log a message to the console
  static void _logToConsole(
    String level,
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) {
    String output = '${level.padRight(8)} [$tag] $message';

    // Add emoji indicators for better visual filtering in console
    switch (level) {
      case 'INFO':
        output = '📝 $output';
        break;
      case 'DEBUG':
        output = '🔍 $output';
        break;
      case 'WARN':
        output = '⚠️ $output';
        break;
      case 'ERROR':
        output = '❌ $output';
        break;
      case 'CRITICAL':
        output = '🔥 $output';
        break;
    }

    if (exception != null) {
      output += '\nException: ${formatException(exception)}';

      if (stackTrace != null) {
        // Format the stack trace for better readability by taking only the first 8 lines
        final stackTraceLines = stackTrace.toString().split('\n');
        final limitedStackTrace = stackTraceLines.take(8).join('\n');
        output +=
            '\nStackTrace: $limitedStackTrace${stackTraceLines.length > 8 ? '\n...(${stackTraceLines.length - 8} more lines)' : ''}';
      }
    }

    // Use debugPrint to avoid log truncation that can happen with print
    debugPrint(output);
  }
}
