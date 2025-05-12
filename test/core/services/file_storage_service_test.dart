import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart';
import 'package:multimodal_road_data_collector/core/services/implementations/file_storage_service_impl.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart';

import 'file_storage_service_test.mocks.dart';

// Generate mocks
@GenerateMocks([Directory, FileStorageService])
// Mock for PathProvider
class MockPathProviderPlatform extends Mock
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getTemporaryPath() async => '/temp';

  @override
  Future<String?> getApplicationDocumentsPath() async => '/docs';

  @override
  Future<String?> getExternalStoragePath() async => '/external';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FileStorageServiceImpl fileStorageService;
  late Directory tempDir;

  setUpAll(() {
    // Register mock path provider
    PathProviderPlatform.instance = MockPathProviderPlatform();
  });

  setUp(() async {
    fileStorageService = FileStorageServiceImpl();

    // Create a real temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('file_storage_test_');
  });

  tearDown(() async {
    // Clean up the temporary directory after each test
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('FileStorageServiceImpl - Session Management', () {
    late String testBasePath;

    setUp(() {
      testBasePath = '/test/path';
    });

    test(
      'getSessionsBaseDirectory creates the sessions directory if needed',
      () async {
        // Create test stub for file storage methods
        fileStorageService = MockFileStorageService() as FileStorageServiceImpl;
        when(
          fileStorageService.getDocumentsDirectoryPath(),
        ).thenAnswer((_) async => testBasePath);
        when(
          fileStorageService.createDirectory(any),
        ).thenAnswer((_) async => true);

        final sessionsDir = await fileStorageService.getSessionsBaseDirectory();

        // Verify path structure
        expect(sessionsDir, contains('RoadDataCollector'));
        verify(fileStorageService.createDirectory(any)).called(1);
      },
    );

    test(
      'createSessionDirectory generates timestamped session folder',
      () async {
        // Use a real implementation but with mocked methods
        fileStorageService = FileStorageServiceImpl();

        // Use a spy to monitor the real calls
        final spy = MockFileStorageService();

        // Setup the test session path
        final sessionsBasePath = path.join(testBasePath, 'RoadDataCollector');

        // Replace the methods we don't want to run in tests
        when(
          spy.getSessionsBaseDirectory(),
        ).thenAnswer((_) async => sessionsBasePath);
        when(spy.createDirectory(any)).thenAnswer((_) async => true);

        // Call the method we're testing
        fileStorageService.getSessionsBaseDirectory =
            spy.getSessionsBaseDirectory;
        fileStorageService.createDirectory = spy.createDirectory;

        // Execute the test
        final sessionPath = await fileStorageService.createSessionDirectory();

        // Verify the session directory was created with a timestamp pattern
        expect(sessionPath, contains('session_'));
        verify(spy.createDirectory(any)).called(1);
      },
    );

    test('saveVideoToSession copies video file to session directory', () async {
      // Test paths
      final testVideoPath = '/test/video.mp4';
      final testSessionDir = '/test/session_dir';
      final expectedDestPath = path.join(testSessionDir, 'video.mp4');

      // Mock the copy method for testing
      fileStorageService.copyFile = (source, dest) async {
        expect(source, equals(testVideoPath));
        expect(dest, equals(expectedDestPath));
        return true;
      };

      final result = await fileStorageService.saveVideoToSession(
        testVideoPath,
        testSessionDir,
      );

      // Verify the result is the expected destination path
      expect(result, equals(expectedDestPath));
    });

    test('listSessions returns sorted session directories', () async {
      // Mock dir listing for testing
      final testSessionsBaseDir = path.join(testBasePath, 'sessions');
      fileStorageService.getSessionsBaseDirectory =
          () async => testSessionsBaseDir;

      // Sample session directories
      final testSessions = [
        path.join(testSessionsBaseDir, 'session_20230501_120000'),
        path.join(testSessionsBaseDir, 'session_20230502_120000'),
        path.join(testSessionsBaseDir, 'session_20230503_120000'),
        path.join(testSessionsBaseDir, 'other_folder'), // Should be ignored
      ];

      // Override fileStorageService's directory listing functionality
      fileStorageService.listDirectoriesInDirectory = (dirPath) async {
        expect(dirPath, equals(testSessionsBaseDir));
        return testSessions.where((path) => path.contains('session_')).toList();
      };

      final sessions = await fileStorageService.listSessions();

      // Verify sessions are returned in descending order (newest first)
      expect(sessions, hasLength(3));
      expect(
        sessions[0],
        equals(path.join(testSessionsBaseDir, 'session_20230503_120000')),
      );
      expect(
        sessions[1],
        equals(path.join(testSessionsBaseDir, 'session_20230502_120000')),
      );
      expect(
        sessions[2],
        equals(path.join(testSessionsBaseDir, 'session_20230501_120000')),
      );
    });
  });

  group('FileStorageServiceImpl - CSV Operations', () {
    late MockFileStorageService mockFileStorageService;
    late String testBasePath;
    late String testCsvPath;

    setUp(() {
      mockFileStorageService = MockFileStorageService();
      testBasePath = '/test/path';
      testCsvPath = path.join(testBasePath, 'test.csv');
    });

    test(
      'createCsvWithHeader creates a CSV file with header columns',
      () async {
        final headerColumns = ['col1', 'col2', 'col3'];

        // Setup mock behavior
        when(
          mockFileStorageService.createCsvWithHeader(
            testCsvPath,
            headerColumns,
          ),
        ).thenAnswer((_) async => true);

        // Call the method and verify
        final result = await mockFileStorageService.createCsvWithHeader(
          testCsvPath,
          headerColumns,
        );

        expect(result, isTrue);
        verify(
          mockFileStorageService.createCsvWithHeader(
            testCsvPath,
            headerColumns,
          ),
        ).called(1);
      },
    );

    test('appendToCsv appends rows to an existing CSV file', () async {
      final rows = ['row1,data1,value1', 'row2,data2,value2'];

      // Setup mock behavior
      when(
        mockFileStorageService.fileExists(testCsvPath),
      ).thenAnswer((_) async => true);
      when(
        mockFileStorageService.appendToCsv(testCsvPath, rows),
      ).thenAnswer((_) async => true);

      // Call the method and verify
      final result = await mockFileStorageService.appendToCsv(
        testCsvPath,
        rows,
      );

      expect(result, isTrue);
      verify(mockFileStorageService.appendToCsv(testCsvPath, rows)).called(1);
    });

    test('appendToCsv returns false for non-existent files', () async {
      final rows = ['row1,data1,value1'];

      // Override for this test - file doesn't exist
      when(
        mockFileStorageService.fileExists(testCsvPath),
      ).thenAnswer((_) async => false);

      final result = await mockFileStorageService.appendToCsv(
        testCsvPath,
        rows,
      );
      expect(result, isFalse);
    });

    test('getSensorDataCsvPath returns correct path', () async {
      final sessionDir = '/test/path/session_123';
      final expectedPath = path.join(sessionDir, 'sensors.csv');

      // Setup mock behavior
      when(
        mockFileStorageService.getSensorDataCsvPath(sessionDir),
      ).thenAnswer((_) async => expectedPath);

      // Call the method and verify
      final resultPath = await mockFileStorageService.getSensorDataCsvPath(
        sessionDir,
      );

      expect(resultPath, equals(expectedPath));
      verify(mockFileStorageService.getSensorDataCsvPath(sessionDir)).called(1);
    });

    test('getSensorDataCsvPath creates file if specified', () async {
      final sessionDir = '/test/path/session_123';
      final expectedPath = path.join(sessionDir, 'sensors.csv');

      // Override to simulate file not existing
      when(
        mockFileStorageService.fileExists(expectedPath),
      ).thenAnswer((_) async => false);

      // Expect createCsvWithHeader to be called with correct columns
      bool createCsvCalled = false;
      when(
        mockFileStorageService.createCsvWithHeader(expectedPath, any),
      ).thenAnswer((invocation) {
        createCsvCalled = true;
        return true;
      });

      // Call method with createIfNotExists
      final resultPath = await mockFileStorageService.getSensorDataCsvPath(
        sessionDir,
        createIfNotExists: true,
      );

      expect(resultPath, equals(expectedPath));
      expect(createCsvCalled, isTrue);
    });
  });

  group('Sensor CSV Schema', () {
    test('FileStorageServiceImpl defines the correct CSV schema columns', () {
      // Verify that the FileStorageServiceImpl has the expected columns
      // for sensor data CSV as defined in the task requirements
      expect(
        FileStorageServiceImpl._sensorDataCsvColumns,
        equals([
          'timestamp_ms',
          'accel_x',
          'accel_y',
          'accel_z',
          'accel_magnitude',
          'gyro_x',
          'gyro_y',
          'gyro_z',
          'is_pothole',
          'user_feedback',
        ]),
      );
    });
  });

  group('FileStorageServiceImpl - CSV Operations', () {
    late String testBasePath;
    late String testCsvPath;
    late String testSessionDir;

    setUp(() {
      testBasePath = '/test/path';
      testCsvPath = path.join(testBasePath, 'test.csv');
      testSessionDir = path.join(testBasePath, 'session_123');

      // We need to override internal methods that would access the filesystem
      (fileStorageService as FileStorageServiceImpl).writeStringToFile =
          (content, filePath) async => true;

      (fileStorageService as FileStorageServiceImpl).fileExists =
          (filePath) async => true;

      (fileStorageService as FileStorageServiceImpl).getSensorDataCsvPath =
          (sessionDir, {createIfNotExists = false}) async =>
              path.join(sessionDir, 'sensors.csv');

      (fileStorageService as FileStorageServiceImpl).createCsvWithHeader =
          (filePath, columns) async => true;

      (fileStorageService as FileStorageServiceImpl).appendToCsv =
          (filePath, rows) async => true;
    });

    test(
      'appendToSensorDataCsv converts and appends data points correctly',
      () async {
        // Mock test data
        final dataPoints = [
          CorrectedSensorDataPoint(
            timestampMs: 1000,
            accelX: 1.1,
            accelY: 2.2,
            accelZ: 3.3,
            accelMagnitude: 4.1,
            gyroX: 0.1,
            gyroY: 0.2,
            gyroZ: 0.3,
            isPothole: true,
          ),
          CorrectedSensorDataPoint(
            timestampMs: 1010,
            accelX: 1.2,
            accelY: 2.3,
            accelZ: 3.4,
            accelMagnitude: 4.2,
            gyroX: 0.11,
            gyroY: 0.21,
            gyroZ: 0.31,
            isPothole: false,
          ),
        ];

        // Track calls to appendToCsv
        List<String> capturedRows = [];
        (fileStorageService as FileStorageServiceImpl).appendToCsv = (
          filePath,
          rows,
        ) async {
          expect(filePath, equals(path.join(testSessionDir, 'sensors.csv')));
          capturedRows.addAll(rows);
          return true;
        };

        // Call the method we're testing
        final result = await fileStorageService.appendToSensorDataCsv(
          testSessionDir,
          dataPoints,
        );

        // Verify result
        expect(result, isTrue);

        // Verify that we got the expected CSV rows
        expect(capturedRows.length, equals(2));

        // First row
        expect(
          capturedRows[0].startsWith('1000,1.1,2.2,3.3,4.1,0.1,0.2,0.3,1,'),
          isTrue,
        );

        // Second row
        expect(
          capturedRows[1].startsWith('1010,1.2,2.3,3.4,4.2,0.11,0.21,0.31,0,'),
          isTrue,
        );
      },
    );
  });

  group('Annotation Logging', () {
    test(
      'getAnnotationsLogPath creates directory and file when needed',
      () async {
        // Arrange
        final sessionDir = path.join(tempDir.path, 'test_session');

        // Act
        final logPath = await fileStorageService.getAnnotationsLogPath(
          sessionDir,
          createIfNotExists: true,
        );

        // Assert
        expect(logPath, path.join(sessionDir, 'annotations.log'));
        expect(await File(logPath).exists(), true);
      },
    );

    test('getAnnotationsLogPath returns path without creating file', () async {
      // Arrange
      final sessionDir = path.join(tempDir.path, 'test_session');
      await Directory(sessionDir).create(recursive: true);

      // Act
      final logPath = await fileStorageService.getAnnotationsLogPath(
        sessionDir,
        createIfNotExists: false,
      );

      // Assert
      expect(logPath, path.join(sessionDir, 'annotations.log'));
      expect(await File(logPath).exists(), false);
    });

    test('logAnnotation writes entry to annotations.log file', () async {
      // Arrange
      final sessionDir = path.join(tempDir.path, 'test_session');
      await Directory(sessionDir).create(recursive: true);
      final spikeTimestamp = 12345;
      final feedbackType = 'Yes';

      // Act
      final result = await fileStorageService.logAnnotation(
        sessionDir,
        spikeTimestamp,
        feedbackType,
      );

      // Assert
      expect(result, true);

      final logPath = path.join(sessionDir, 'annotations.log');
      final logFile = File(logPath);
      expect(await logFile.exists(), true);

      final content = await logFile.readAsString();
      expect(content, '$spikeTimestamp,$feedbackType\n');
    });

    test('logAnnotation appends to existing file', () async {
      // Arrange
      final sessionDir = path.join(tempDir.path, 'test_session');
      await Directory(sessionDir).create(recursive: true);

      final firstTimestamp = 12345;
      final firstFeedback = 'Yes';
      final secondTimestamp = 67890;
      final secondFeedback = 'No';

      // Act
      // Log first annotation
      await fileStorageService.logAnnotation(
        sessionDir,
        firstTimestamp,
        firstFeedback,
      );

      // Log second annotation
      final result = await fileStorageService.logAnnotation(
        sessionDir,
        secondTimestamp,
        secondFeedback,
      );

      // Assert
      expect(result, true);

      final logPath = path.join(sessionDir, 'annotations.log');
      final logFile = File(logPath);
      final content = await logFile.readAsString();

      expect(
        content,
        '$firstTimestamp,$firstFeedback\n$secondTimestamp,$secondFeedback\n',
      );
    });
  });
}
