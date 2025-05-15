import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_road_data_collector/constants/app_constants.dart';
import 'package:multimodal_road_data_collector/core/utils/isolate_logger.dart';

void main() {
  // Save original debugPrint to restore after tests
  final originalDebugPrint = debugPrint;

  setUp(() {
    // No setup needed for debugPrint
  });

  tearDown(() {
    // Restore original values
    debugPrint = originalDebugPrint;
  });

  test('IsolateLogger formats messages correctly', () {
    List<String> loggedMessages = [];

    // Override debugPrint to capture messages
    debugPrint = (String? message, {int? wrapWidth}) {
      loggedMessages.add(message ?? '');
    };

    // Test each log level
    IsolateLogger.info('TAG', 'Info message');
    IsolateLogger.debug('TAG', 'Debug message');
    IsolateLogger.warning('TAG', 'Warning message');
    IsolateLogger.error('TAG', 'Error message');
    IsolateLogger.critical('TAG', 'Critical message');

    // Verify the format of the messages
    expect(loggedMessages[0], contains('[ISOLATE]'));
    expect(loggedMessages[0], contains('INFO'));
    expect(loggedMessages[0], contains('[TAG]'));
    expect(loggedMessages[0], contains('Info message'));

    expect(loggedMessages[1], contains('[ISOLATE]'));
    expect(loggedMessages[1], contains('DEBUG'));
    expect(loggedMessages[1], contains('[TAG]'));
    expect(loggedMessages[1], contains('Debug message'));

    expect(loggedMessages[2], contains('[ISOLATE]'));
    expect(loggedMessages[2], contains('WARN'));
    expect(loggedMessages[2], contains('[TAG]'));
    expect(loggedMessages[2], contains('Warning message'));

    expect(loggedMessages[3], contains('[ISOLATE]'));
    expect(loggedMessages[3], contains('ERROR'));
    expect(loggedMessages[3], contains('[TAG]'));
    expect(loggedMessages[3], contains('Error message'));

    expect(loggedMessages[4], contains('[ISOLATE]'));
    expect(loggedMessages[4], contains('CRITICAL'));
    expect(loggedMessages[4], contains('[TAG]'));
    expect(loggedMessages[4], contains('Critical message'));
  });

  test('IsolateLogger handles exceptions and stack traces', () {
    List<String> loggedMessages = [];

    // Override debugPrint to capture messages
    debugPrint = (String? message, {int? wrapWidth}) {
      loggedMessages.add(message ?? '');
    };

    // Create an exception and stack trace
    final exception = Exception('Test exception');
    final stackTrace = StackTrace.current;

    // Test error and critical with exception and stack trace
    IsolateLogger.error('TAG', 'Error message', exception, stackTrace);
    IsolateLogger.critical('TAG', 'Critical message', exception, stackTrace);

    // Verify the exception and stack trace are included
    expect(loggedMessages[0], contains('Error message'));
    expect(loggedMessages[0], contains('Exception: $exception'));
    expect(loggedMessages[0], contains('StackTrace:'));

    expect(loggedMessages[1], contains('Critical message'));
    expect(loggedMessages[1], contains('Exception: $exception'));
    expect(loggedMessages[1], contains('StackTrace:'));
  });

  test('IsolateLogger specialty methods work correctly', () {
    List<String> loggedMessages = [];

    // Override debugPrint to capture messages
    debugPrint = (String? message, {int? wrapWidth}) {
      loggedMessages.add(message ?? '');
    };

    // Test specialty methods
    IsolateLogger.sensor('Sensor message');
    IsolateLogger.camera('Camera message');
    IsolateLogger.recording('Recording message');
    IsolateLogger.calibration('Calibration message');
    IsolateLogger.file('File message');

    // Verify the messages
    expect(loggedMessages[0], contains('[SENSOR]'));
    expect(loggedMessages[0], contains('Sensor message'));

    expect(loggedMessages[1], contains('[CAMERA]'));
    expect(loggedMessages[1], contains('Camera message'));

    expect(loggedMessages[2], contains('[RECORDING]'));
    expect(loggedMessages[2], contains('Recording message'));

    expect(loggedMessages[3], contains('[CALIBRATION]'));
    expect(loggedMessages[3], contains('Calibration message'));

    expect(loggedMessages[4], contains('[FILE]'));
    expect(loggedMessages[4], contains('File message'));
  });

  // Skip this test if debug logs are always enabled in the constants
  test('IsolateLogger debug method depends on enableDebugLogs constant', () {
    List<String> loggedMessages = [];

    // Override debugPrint to capture messages
    debugPrint = (String? message, {int? wrapWidth}) {
      loggedMessages.add(message ?? '');
    };

    // Test debug method with current enableDebugLogs setting
    IsolateLogger.debug('TAG', 'Debug message');

    // If debug logs are enabled (the constant value), verify the message
    if (AppConstants.enableDebugLogs) {
      expect(loggedMessages.length, 1);
      expect(loggedMessages[0], contains('Debug message'));
    } else {
      // If debug logs are disabled, verify no message
      expect(loggedMessages.length, 0);
    }
  });
}
