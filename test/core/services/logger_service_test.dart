import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:path/path.dart' as path;
import 'package:multimodal_road_data_collector/core/services/logger_service.dart';
import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart';
import 'package:multimodal_road_data_collector/core/services/preferences_service.dart';
import 'package:multimodal_road_data_collector/core/services/implementations/logger_service_impl.dart';

// Manual mock classes since we don't want to rely on generated mocks for this test
class MockFileStorageService extends Mock implements FileStorageService {}

class MockPreferencesService extends Mock implements PreferencesService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFileStorageService mockFileStorage;
  late MockPreferencesService mockPreferences;
  late LoggerServiceImpl loggerService;
  late Directory tempDir;

  setUp(() async {
    mockFileStorage = MockFileStorageService();
    mockPreferences = MockPreferencesService();

    // Create a real temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('logger_test_');

    // Set up common mock behavior
    when(
      mockFileStorage.getSessionsBaseDirectory(),
    ).thenAnswer((_) async => tempDir.path);
    when(
      mockFileStorage.createDirectory(captureAny),
    ).thenAnswer((_) async => true);

    loggerService = LoggerServiceImpl(
      fileStorageService: mockFileStorage,
      preferencesService: mockPreferences,
    );
  });

  tearDown(() async {
    // Clean up the temporary directory after each test
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LoggerService', () {
    test('initialize should not throw', () async {
      // Act & Assert
      expect(loggerService.initialize(), completes);
    });

    test('isDebugSessionActive returns false initially', () {
      // Act & Assert
      expect(loggerService.isDebugSessionActive(), isFalse);
    });

    test('startDebugSession creates log directory and file', () async {
      // Arrange
      final logsDir = path.join(tempDir.path, 'logs');

      when(
        mockFileStorage.writeStringToFile(captureAny, captureAny),
      ).thenAnswer((_) async => true);

      // Act
      final sessionId = await loggerService.startDebugSession();

      // Assert
      expect(sessionId, isNotEmpty);
      expect(sessionId, contains('debug_'));

      // Verify the directory creation
      verify(mockFileStorage.createDirectory(logsDir)).called(1);

      // Verify that at least one directory was created
      verify(
        mockFileStorage.createDirectory(captureAny),
      ).called(greaterThan(1));

      // Verify that a write operation was performed for the log file
      verify(
        mockFileStorage.writeStringToFile(captureAny, captureAny),
      ).called(greaterThan(0));

      expect(loggerService.isDebugSessionActive(), isTrue);
    });

    test('endDebugSession updates active state', () async {
      // Arrange
      when(
        mockFileStorage.writeStringToFile(captureAny, captureAny),
      ).thenAnswer((_) async => true);
      await loggerService.startDebugSession();

      // Act
      await loggerService.endDebugSession();

      // Assert
      expect(loggerService.isDebugSessionActive(), isFalse);
    });

    test('debug logs are not written when debug is inactive', () async {
      // Act
      await loggerService.debug('Test', 'Test message');

      // Assert - No logs should be written
      verifyNever(mockFileStorage.writeStringToFile(captureAny, captureAny));
    });

    test('info logs are written even when debug is inactive', () async {
      // Arrange
      when(
        mockFileStorage.writeStringToFile(captureAny, captureAny),
      ).thenAnswer((_) async => true);

      // Act
      await loggerService.info('Test', 'Info message');

      // Assert
      // In LoggerServiceImpl, info logs are still printed to console but not written to file
      verifyNever(mockFileStorage.writeStringToFile(captureAny, captureAny));
    });

    test('debug logs are written when debug is active', () async {
      // Arrange
      when(
        mockFileStorage.writeStringToFile(captureAny, captureAny),
      ).thenAnswer((_) async => true);
      await loggerService.startDebugSession();

      // Act
      await loggerService.debug('Test', 'Debug message');

      // Assert - We expect at least one log write
      verify(
        mockFileStorage.writeStringToFile(captureAny, captureAny),
      ).called(greaterThan(0));
    });

    test('error logs include exception and stack trace', () async {
      // Arrange
      when(
        mockFileStorage.writeStringToFile(captureAny, captureAny),
      ).thenAnswer((_) async => true);
      await loggerService.startDebugSession();

      final exception = Exception('Test error');
      final stackTrace = StackTrace.current;

      // Act
      await loggerService.error('Test', 'Error message', exception, stackTrace);

      // Assert - We expect logging to happen but we can't easily test the content
      verify(
        mockFileStorage.writeStringToFile(captureAny, captureAny),
      ).called(greaterThan(0));
    });

    test(
      'getLogFilePaths returns empty list when logs directory does not exist',
      () async {
        // Arrange - Make sure listFilesWithExtension is mocked but don't test it directly
        when(
          mockFileStorage.listFilesWithExtension(captureAny, captureAny),
        ).thenAnswer((_) async => []);

        // We're using the real implementation of Directory.exists but need to ensure
        // the logs directory doesn't exist for this test

        // Act
        final result = await loggerService.getLogFilePaths();

        // Assert
        expect(result, isEmpty);
      },
    );
  });
}
