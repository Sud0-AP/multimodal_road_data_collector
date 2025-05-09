import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart';
import 'package:multimodal_road_data_collector/features/calibration/data/repositories/calibration_repository_file_impl.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/models/initial_calibration_data.dart';

import 'calibration_repository_file_impl_test.mocks.dart';

// Generate mocks for the FileStorageService
@GenerateMocks([FileStorageService])
void main() {
  late MockFileStorageService mockFileStorageService;
  late CalibrationRepositoryFileImpl repository;

  setUp(() {
    mockFileStorageService = MockFileStorageService();
    repository = CalibrationRepositoryFileImpl(mockFileStorageService);

    // Setup mock to return a standard path for documents directory
    when(
      mockFileStorageService.getDocumentsDirectoryPath(),
    ).thenAnswer((_) async => '/test/documents');
  });

  group('CalibrationRepositoryFileImpl', () {
    final testData = InitialCalibrationData(
      deviceOrientation: DeviceOrientation.portrait,
      accelerometerXOffset: 0.1,
      accelerometerYOffset: 0.2,
      accelerometerZOffset: 0.3,
      gyroscopeXOffset: 0.01,
      gyroscopeYOffset: 0.02,
      gyroscopeZOffset: 0.03,
      calibrationTimestamp: 1000,
    );

    final testJsonString = testData.toJsonString();

    test(
      'saveInitialCalibrationData calls fileStorageService with correct data',
      () async {
        // Setup mock to return success
        when(
          mockFileStorageService.writeStringToFile(
            testJsonString,
            '/test/documents/$kInitialCalibrationDataFilename',
          ),
        ).thenAnswer((_) async => true);

        // Call the method under test
        final result = await repository.saveInitialCalibrationData(testData);

        // Verify the interaction
        verify(mockFileStorageService.getDocumentsDirectoryPath()).called(1);
        verify(
          mockFileStorageService.writeStringToFile(
            testJsonString,
            '/test/documents/$kInitialCalibrationDataFilename',
          ),
        ).called(1);

        // Verify the result
        expect(result, true);
      },
    );

    test(
      'loadInitialCalibrationData returns data from fileStorageService',
      () async {
        // Setup mock behavior for file existence check and content reading
        when(
          mockFileStorageService.fileExists(
            '/test/documents/$kInitialCalibrationDataFilename',
          ),
        ).thenAnswer((_) async => true);

        when(
          mockFileStorageService.readStringFromFile(
            '/test/documents/$kInitialCalibrationDataFilename',
          ),
        ).thenAnswer((_) async => testJsonString);

        // Call the method under test
        final result = await repository.loadInitialCalibrationData();

        // Verify interactions
        verify(mockFileStorageService.getDocumentsDirectoryPath()).called(1);
        verify(
          mockFileStorageService.fileExists(
            '/test/documents/$kInitialCalibrationDataFilename',
          ),
        ).called(1);
        verify(
          mockFileStorageService.readStringFromFile(
            '/test/documents/$kInitialCalibrationDataFilename',
          ),
        ).called(1);

        // Verify the result
        expect(result, isNotNull);
        expect(result?.deviceOrientation, testData.deviceOrientation);
        expect(result?.accelerometerXOffset, testData.accelerometerXOffset);
        expect(result?.accelerometerYOffset, testData.accelerometerYOffset);
        expect(result?.accelerometerZOffset, testData.accelerometerZOffset);
        expect(result?.gyroscopeXOffset, testData.gyroscopeXOffset);
        expect(result?.gyroscopeYOffset, testData.gyroscopeYOffset);
        expect(result?.gyroscopeZOffset, testData.gyroscopeZOffset);
        expect(result?.calibrationTimestamp, testData.calibrationTimestamp);
      },
    );

    test(
      'loadInitialCalibrationData returns null when file does not exist',
      () async {
        // Setup mock behavior
        when(
          mockFileStorageService.fileExists(
            '/test/documents/$kInitialCalibrationDataFilename',
          ),
        ).thenAnswer((_) async => false);

        // Call the method under test
        final result = await repository.loadInitialCalibrationData();

        // Verify interactions
        verify(mockFileStorageService.getDocumentsDirectoryPath()).called(1);
        verify(
          mockFileStorageService.fileExists(
            '/test/documents/$kInitialCalibrationDataFilename',
          ),
        ).called(1);
        // Should not try to read a file that doesn't exist
        verifyNever(mockFileStorageService.readStringFromFile(any));

        // Verify the result
        expect(result, isNull);
      },
    );

    test('hasInitialCalibrationData checks if file exists', () async {
      // Setup mock behavior
      when(
        mockFileStorageService.fileExists(
          '/test/documents/$kInitialCalibrationDataFilename',
        ),
      ).thenAnswer((_) async => true);

      // Call the method under test
      final result = await repository.hasInitialCalibrationData();

      // Verify interactions
      verify(mockFileStorageService.getDocumentsDirectoryPath()).called(1);
      verify(
        mockFileStorageService.fileExists(
          '/test/documents/$kInitialCalibrationDataFilename',
        ),
      ).called(1);

      // Verify the result
      expect(result, true);
    });

    test('clearCalibrationData deletes file', () async {
      // Setup mock behavior
      when(
        mockFileStorageService.fileExists(
          '/test/documents/$kInitialCalibrationDataFilename',
        ),
      ).thenAnswer((_) async => true);

      when(
        mockFileStorageService.deleteFile(
          '/test/documents/$kInitialCalibrationDataFilename',
        ),
      ).thenAnswer((_) async => true);

      // Call the method under test
      final result = await repository.clearCalibrationData();

      // Verify interactions
      verify(mockFileStorageService.getDocumentsDirectoryPath()).called(1);
      verify(
        mockFileStorageService.fileExists(
          '/test/documents/$kInitialCalibrationDataFilename',
        ),
      ).called(1);
      verify(
        mockFileStorageService.deleteFile(
          '/test/documents/$kInitialCalibrationDataFilename',
        ),
      ).called(1);

      // Verify the result
      expect(result, true);
    });

    test(
      'clearCalibrationData returns true when file does not exist',
      () async {
        // Setup mock behavior
        when(
          mockFileStorageService.fileExists(
            '/test/documents/$kInitialCalibrationDataFilename',
          ),
        ).thenAnswer((_) async => false);

        // Call the method under test
        final result = await repository.clearCalibrationData();

        // Verify interactions
        verify(mockFileStorageService.getDocumentsDirectoryPath()).called(1);
        verify(
          mockFileStorageService.fileExists(
            '/test/documents/$kInitialCalibrationDataFilename',
          ),
        ).called(1);
        // Should not try to delete a file that doesn't exist
        verifyNever(mockFileStorageService.deleteFile(any));

        // Verify the result
        expect(result, true);
      },
    );

    test('handles errors gracefully in saveInitialCalibrationData', () async {
      // Setup mock to throw exception
      when(
        mockFileStorageService.getDocumentsDirectoryPath(),
      ).thenThrow(Exception('Test exception'));

      // Call the method under test
      final result = await repository.saveInitialCalibrationData(testData);

      // Verify the result
      expect(result, false);
    });

    test('handles errors gracefully in loadInitialCalibrationData', () async {
      // Setup mock to throw exception
      when(
        mockFileStorageService.getDocumentsDirectoryPath(),
      ).thenThrow(Exception('Test exception'));

      // Call the method under test
      final result = await repository.loadInitialCalibrationData();

      // Verify the result
      expect(result, isNull);
    });

    test('handles errors gracefully in hasInitialCalibrationData', () async {
      // Setup mock to throw exception
      when(
        mockFileStorageService.getDocumentsDirectoryPath(),
      ).thenThrow(Exception('Test exception'));

      // Call the method under test
      final result = await repository.hasInitialCalibrationData();

      // Verify the result
      expect(result, false);
    });

    test('handles errors gracefully in clearCalibrationData', () async {
      // Setup mock to throw exception
      when(
        mockFileStorageService.getDocumentsDirectoryPath(),
      ).thenThrow(Exception('Test exception'));

      // Call the method under test
      final result = await repository.clearCalibrationData();

      // Verify the result
      expect(result, false);
    });
  });
}
