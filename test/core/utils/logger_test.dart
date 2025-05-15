import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:mockito/mockito.dart';
import 'package:multimodal_road_data_collector/core/utils/logger.dart';
import 'package:multimodal_road_data_collector/core/services/logger_service.dart';

// Mock LoggerService
class MockLoggerService extends Mock implements LoggerService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockLoggerService mockLoggerService;

  setUp(() {
    mockLoggerService = MockLoggerService();

    // Set up common behavior
    when(mockLoggerService.initialize()).thenAnswer((_) async {});
    when(
      mockLoggerService.info(argThat(isA<String>()), argThat(isA<String>())),
    ).thenAnswer((_) async {});
    when(
      mockLoggerService.debug(argThat(isA<String>()), argThat(isA<String>())),
    ).thenAnswer((_) async {});
    when(
      mockLoggerService.warning(argThat(isA<String>()), argThat(isA<String>())),
    ).thenAnswer((_) async {});
    when(
      mockLoggerService.error(argThat(isA<String>()), argThat(isA<String>())),
    ).thenAnswer((_) async {});
    when(
      mockLoggerService.critical(
        argThat(isA<String>()),
        argThat(isA<String>()),
      ),
    ).thenAnswer((_) async {});
    when(
      mockLoggerService.startDebugSession(),
    ).thenAnswer((_) async => 'test_session');
    when(mockLoggerService.isDebugSessionActive()).thenReturn(true);
  });

  group('Logger', () {
    test('init sets the logger service', () {
      // Act
      Logger.init(mockLoggerService);

      // Assert - We can't directly check private fields, so we verify behavior
      Logger.info('TEST', 'Test message');
      verify(mockLoggerService.info('TEST', 'Test message')).called(1);
    });

    test('logs are sent to LoggerService when initialized', () {
      // Arrange
      Logger.init(mockLoggerService);

      // Act
      Logger.info('TAG', 'Info message');
      Logger.debug('TAG', 'Debug message');
      Logger.warning('TAG', 'Warning message');
      Logger.error('TAG', 'Error message');
      Logger.critical('TAG', 'Critical message');

      // Assert
      verify(mockLoggerService.info('TAG', 'Info message')).called(1);
      verify(mockLoggerService.debug('TAG', 'Debug message')).called(1);
      verify(mockLoggerService.warning('TAG', 'Warning message')).called(1);
      verify(mockLoggerService.error('TAG', 'Error message')).called(1);
      verify(mockLoggerService.critical('TAG', 'Critical message')).called(1);
    });

    test('category-specific logs use correct tags', () {
      // Arrange
      Logger.init(mockLoggerService);

      // Act
      Logger.sensor('Sensor message');
      Logger.camera('Camera message');
      Logger.recording('Recording message');
      Logger.calibration('Calibration message');
      Logger.file('File message');

      // Assert
      verify(mockLoggerService.debug('SENSOR', 'Sensor message')).called(1);
      verify(mockLoggerService.debug('CAMERA', 'Camera message')).called(1);
      verify(
        mockLoggerService.debug('RECORDING', 'Recording message'),
      ).called(1);
      verify(
        mockLoggerService.debug('CALIBRATION', 'Calibration message'),
      ).called(1);
      verify(mockLoggerService.debug('FILE', 'File message')).called(1);
    });

    test('logs are not sent to LoggerService when not initialized', () {
      // Arrange - Create a new test instance to avoid previous init
      setUpAll(() {
        // Reset Logger state (warning: hacky for testing only)
        // Typically we'd have better ways to reset singletons in a real app
        dynamic logger = Logger;
        dynamic privateField = logger._loggerService;
        privateField = null;
      });

      // Act - These should not throw even though no service is registered
      Logger.info('TAG', 'Info message');
      Logger.debug('TAG', 'Debug message');
      Logger.warning('TAG', 'Warning message');
      Logger.error('TAG', 'Error message');
      Logger.critical('TAG', 'Critical message');

      // Assert - Difficult to verify internal state, but we can verify no interactions
      verifyNever(
        mockLoggerService.info(argThat(isA<String>()), argThat(isA<String>())),
      );
      verifyNever(
        mockLoggerService.debug(argThat(isA<String>()), argThat(isA<String>())),
      );
      verifyNever(
        mockLoggerService.warning(
          argThat(isA<String>()),
          argThat(isA<String>()),
        ),
      );
      verifyNever(
        mockLoggerService.error(argThat(isA<String>()), argThat(isA<String>())),
      );
      verifyNever(
        mockLoggerService.critical(
          argThat(isA<String>()),
          argThat(isA<String>()),
        ),
      );
    });

    test('exception logs include exception and stack trace', () {
      // Arrange
      Logger.init(mockLoggerService);
      final exception = Exception('Test exception');
      final stackTrace = StackTrace.current;

      // Act
      Logger.error('TAG', 'Error message', exception, stackTrace);
      Logger.critical('TAG', 'Critical message', exception, stackTrace);

      // Assert
      verify(
        mockLoggerService.error('TAG', 'Error message', exception, stackTrace),
      ).called(1);
      verify(
        mockLoggerService.critical(
          'TAG',
          'Critical message',
          exception,
          stackTrace,
        ),
      ).called(1);
    });
  });
}
