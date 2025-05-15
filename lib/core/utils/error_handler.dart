import 'dart:io';
import 'dart:async' show TimeoutException;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'logger.dart';

/// A utility class for standardized error handling throughout the app
///
/// Provides common error handling patterns and categorizes errors by severity
/// to ensure consistent error reporting and logging.
class ErrorHandler {
  /// Handle exceptions that occur during file operations
  ///
  /// Logs appropriate error messages and returns a boolean indicating success/failure
  static bool handleFileException(
    String operation,
    String filePath,
    dynamic error,
    StackTrace stackTrace, {
    bool isCritical = false,
  }) {
    String errorType = 'Unknown';
    String errorDetails = '';

    if (error is FileSystemException) {
      errorType = 'FileSystemException';
      errorDetails = 'Path: ${error.path}, OS Error: ${error.osError}';
    } else if (error is PathNotFoundException) {
      errorType = 'PathNotFoundException';
    } else if (error is IOException) {
      errorType = 'IOException';
    }

    final errorMessage =
        '$operation failed for $filePath: $errorType. $errorDetails';

    if (isCritical) {
      Logger.critical('FILE', errorMessage, error, stackTrace);
    } else {
      Logger.error('FILE', errorMessage, error, stackTrace);
    }

    return false;
  }

  /// Handle exceptions that occur during platform interactions
  ///
  /// Logs appropriate error messages for platform channel errors
  static void handlePlatformException(
    String operation,
    dynamic error,
    StackTrace stackTrace, {
    bool isCritical = false,
  }) {
    String errorType = 'Unknown';
    String errorDetails = '';

    if (error is PlatformException) {
      errorType = 'PlatformException';
      errorDetails = 'Code: ${error.code}, Message: ${error.message}';
    } else if (error is MissingPluginException) {
      errorType = 'MissingPluginException';
    }

    final errorMessage = '$operation failed: $errorType. $errorDetails';

    if (isCritical) {
      Logger.critical('PLATFORM', errorMessage, error, stackTrace);
    } else {
      Logger.error('PLATFORM', errorMessage, error, stackTrace);
    }
  }

  /// Handle camera-related exceptions
  ///
  /// Logs appropriate error messages for camera errors
  static void handleCameraException(
    String operation,
    dynamic error,
    StackTrace stackTrace, {
    bool isCritical = false,
  }) {
    final errorMessage = 'Camera $operation failed: ${error.toString()}';

    if (isCritical) {
      Logger.critical('CAMERA', errorMessage, error, stackTrace);
    } else {
      Logger.error('CAMERA', errorMessage, error, stackTrace);
    }
  }

  /// Handle sensor-related exceptions
  ///
  /// Logs appropriate error messages for sensor errors
  static void handleSensorException(
    String operation,
    dynamic error,
    StackTrace stackTrace, {
    bool isCritical = false,
  }) {
    final errorMessage = 'Sensor $operation failed: ${error.toString()}';

    if (isCritical) {
      Logger.critical('SENSOR', errorMessage, error, stackTrace);
    } else {
      Logger.error('SENSOR', errorMessage, error, stackTrace);
    }
  }

  /// Handle network-related exceptions
  ///
  /// Logs appropriate error messages for network errors
  static void handleNetworkException(
    String operation,
    dynamic error,
    StackTrace stackTrace, {
    bool isCritical = false,
  }) {
    String errorType = 'Unknown';
    String errorDetails = '';

    if (error is SocketException) {
      errorType = 'SocketException';
      errorDetails =
          'Address: ${error.address}, Port: ${error.port}, OS Error: ${error.osError}';
    } else if (error is HttpException) {
      errorType = 'HttpException';
    } else if (error is TimeoutException) {
      errorType = 'TimeoutException';
    }

    final errorMessage = 'Network $operation failed: $errorType. $errorDetails';

    if (isCritical) {
      Logger.critical('NETWORK', errorMessage, error, stackTrace);
    } else {
      Logger.error('NETWORK', errorMessage, error, stackTrace);
    }
  }

  /// Handle general exceptions
  ///
  /// Logs appropriate error messages for any unhandled errors
  static void handleGeneralException(
    String tag,
    String operation,
    dynamic error,
    StackTrace stackTrace, {
    bool isCritical = false,
  }) {
    final errorMessage = '$operation failed: ${error.toString()}';

    if (isCritical) {
      Logger.critical(tag, errorMessage, error, stackTrace);
    } else {
      Logger.error(tag, errorMessage, error, stackTrace);
    }
  }

  /// Determine if an error is critical based on the type of exception and context
  ///
  /// Returns true if the error should be treated as critical
  static bool isCriticalError(dynamic error) {
    // File errors are critical if they affect the app's ability to function
    if (error is FileSystemException) {
      // Check if it's a permission denied error
      if (error.osError?.errorCode == 13) {
        // Permission denied
        return true;
      }
      // Check if it's a storage full error
      if (error.osError?.errorCode == 28) {
        // No space left on device
        return true;
      }
    }

    // Platform errors are critical if they're missing plugin or unsupported version
    if (error is PlatformException) {
      if (error.code == 'PERMISSION_DENIED') {
        return true;
      }
    }

    if (error is MissingPluginException) {
      return true;
    }

    return false;
  }
}
