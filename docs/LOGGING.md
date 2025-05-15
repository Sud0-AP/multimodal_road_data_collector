# Multimodal Road Data Collector - Logging Guidelines

This document outlines the logging approach for the Multimodal Road Data Collector app to ensure consistent, useful logs for debugging and monitoring.

## Overview

The app uses a centralized `Logger` utility class that wraps the `LoggerService` to provide structured logging. This ensures logs are:

1. Consistently formatted
2. Properly categorized by severity and component
3. Easily filterable and searchable
4. Available in debug logs for development and file logs for production issues

## Logger Utility

The `Logger` utility (`lib/core/utils/logger.dart`) provides static methods for different logging levels:

```dart
import 'package:multimodal_road_data_collector/core/utils/logger.dart';

// Basic logging by level
Logger.info('TAG', 'Information message');
Logger.debug('TAG', 'Detailed debug information');
Logger.warning('TAG', 'Warning message');
Logger.error('TAG', 'Error message', exception, stackTrace);
Logger.critical('TAG', 'Critical error message', exception, stackTrace);

// Domain-specific logging methods
Logger.sensor('Sensor data received: x=$x, y=$y, z=$z');
Logger.camera('Camera initialized with resolution $width x $height');
Logger.recording('Recording started, session ID: $sessionId');
Logger.calibration('Calibrating with threshold: $threshold');
Logger.file('File saved to: $path');
```

## Log Levels

Choose the appropriate log level based on the nature of the message:

- **INFO**: General operational information (user actions, state transitions)
- **DEBUG**: Detailed information useful during development
- **WARNING**: Unexpected behaviors that aren't errors (fallbacks, retries)
- **ERROR**: Recoverable errors (failed operations that can be retried)
- **CRITICAL**: Severe errors (crashes, unrecoverable states)

## Tags

Use tags to identify the component or feature generating the log. Tags should be:

- Short but descriptive (3-10 characters)
- All caps for visibility
- Consistent within the same file/feature

Common tag examples:
- `UI` - User interface events
- `SENSOR` - Sensor-related operations
- `CAMERA` - Camera operations
- `FILE` - File operations
- `NET` - Network operations

## Best Practices

1. **Be concise**: Keep log messages short but informative
   ```dart
   // Good
   Logger.info('FILE', 'Saved recording to: $path');
   // Avoid
   Logger.info('FILE', 'The recording has been successfully saved to the following path on the device: $path');
   ```

2. **Include context**: Add relevant parameters to understand the situation
   ```dart
   // Good
   Logger.sensor('Processing ${buffer.length} samples at $rateHz Hz');
   // Avoid
   Logger.sensor('Processing samples');
   ```

3. **Use domain-specific methods** for common subsystems
   ```dart
   // Good
   Logger.sensor('Starting accelerometer at $rateHz Hz');
   // Avoid
   Logger.debug('ACCEL', 'Starting accelerometer at $rateHz Hz');
   ```

4. **Log exceptions properly** with both error message and stack trace
   ```dart
   // Good
   try {
     // Operation
   } catch (e, stackTrace) {
     Logger.error('TAG', 'Failed to complete operation', e, stackTrace);
   }
   // Avoid
   try {
     // Operation
   } catch (e) {
     Logger.debug('TAG', 'Error: $e');
   }
   ```

5. **Enable debug logging** only when needed to avoid performance impact
   - Debug logs are controlled by `AppConstants.enableDebugLogs`

## Isolate Compatibility

When working with code running in background isolates (e.g., processing sensor data), use `debugPrint` as a fallback since the main logger might not be initialized:

```dart
void backgroundProcessing() {
  // In isolates, use debugPrint as logging
  debugPrint('Processing data in background');
}
```

## Migration

When migrating existing code that uses `print()` or `debugPrint()`:

1. Use the patterns from `scripts/logger_migration.dart`
2. Ensure you add the proper import
3. Categorize by appropriate log level
4. Add meaningful context to the log message

## Log Storage

Logs are stored:
- In development: Console output
- In production: Session-specific log files stored in the app's private directory

To access logs in production builds use:
```dart
final logs = await loggerService.getCurrentLogFilePath();
// Share logs with developers
```

## Roadmap

Future improvements to the logging system:
- Remote logging for crash reports
- Log rotation to manage storage
- Better integration with Flutter's built-in logging 