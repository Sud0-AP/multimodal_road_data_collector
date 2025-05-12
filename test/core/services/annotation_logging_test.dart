import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as path;
import 'package:multimodal_road_data_collector/core/services/implementations/file_storage_service_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FileStorageServiceImpl fileStorageService;
  late Directory tempDir;

  setUp(() async {
    fileStorageService = FileStorageServiceImpl();

    // Create a real temporary directory for testing
    tempDir = await Directory.systemTemp.createTemp('annotation_test_');
  });

  tearDown(() async {
    // Clean up the temporary directory after each test
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Annotation Logging', () {
    test(
      'logAnnotation creates annotations.log file and writes entry',
      () async {
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
      },
    );

    test('logAnnotation appends multiple entries to annotations.log', () async {
      // Arrange
      final sessionDir = path.join(tempDir.path, 'test_session');
      await Directory(sessionDir).create(recursive: true);

      final firstTimestamp = 12345;
      final firstFeedback = 'Yes';
      final secondTimestamp = 67890;
      final secondFeedback = 'No';
      final thirdTimestamp = 98765;
      final thirdFeedback = 'Uncategorized';

      // Act
      // Log all annotations
      await fileStorageService.logAnnotation(
        sessionDir,
        firstTimestamp,
        firstFeedback,
      );

      await fileStorageService.logAnnotation(
        sessionDir,
        secondTimestamp,
        secondFeedback,
      );

      await fileStorageService.logAnnotation(
        sessionDir,
        thirdTimestamp,
        thirdFeedback,
      );

      // Assert
      final logPath = path.join(sessionDir, 'annotations.log');
      final logFile = File(logPath);
      final content = await logFile.readAsString();

      final expectedContent =
          '$firstTimestamp,$firstFeedback\n'
          '$secondTimestamp,$secondFeedback\n'
          '$thirdTimestamp,$thirdFeedback\n';

      expect(content, expectedContent);
    });
  });
}
