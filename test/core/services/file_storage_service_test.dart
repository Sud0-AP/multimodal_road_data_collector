import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart';
import 'package:multimodal_road_data_collector/core/services/implementations/file_storage_service_impl.dart';

import 'file_storage_service_test.mocks.dart';

// Generate mocks
@GenerateMocks([Directory])
void main() {
  group('FileStorageServiceImpl - Session Management', () {
    late FileStorageServiceImpl fileStorageService;
    late String testBasePath;
    late Directory testDirectory;

    setUp(() {
      fileStorageService = FileStorageServiceImpl();
      testBasePath = '/test/path';
      testDirectory = Directory(testBasePath);

      // Override getApplicationDocumentsDirectory for testing
      getApplicationDocumentsDirectoryOverride = () async {
        return testDirectory;
      };
    });

    tearDown(() {
      getApplicationDocumentsDirectoryOverride = null;
    });

    test(
      'getSessionsBaseDirectory creates the sessions directory if needed',
      () async {
        // Mock method for testing
        fileStorageService.createDirectory = (_) async => true;
        fileStorageService.getDocumentsDirectoryPath = () async => testBasePath;

        final sessionsDir = await fileStorageService.getSessionsBaseDirectory();

        // Verify path structure
        expect(sessionsDir, path.join(testBasePath, 'sessions'));
      },
    );

    test('createSessionDirectory generates timestamped session folder', () async {
      // Mock methods for testing
      fileStorageService.getSessionsBaseDirectory =
          () async => path.join(testBasePath, 'sessions');
      fileStorageService.createDirectory = (_) async => true;

      final sessionDir = await fileStorageService.createSessionDirectory();

      // Check that the path is correct (prefix and structure)
      expect(
        sessionDir,
        startsWith(path.join(testBasePath, 'sessions', 'session_')),
      );

      // Check that the path contains a timestamp pattern (e.g., YYYYMMDD_HHMMSS)
      final folderName = path.basename(sessionDir);
      expect(folderName, matches(r'session_\d{8}_\d{6}'));
    });

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
}
