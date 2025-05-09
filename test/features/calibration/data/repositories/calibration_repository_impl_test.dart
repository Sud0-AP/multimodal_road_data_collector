import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:multimodal_road_data_collector/core/services/preferences_service.dart';
import 'package:multimodal_road_data_collector/features/calibration/data/repositories/calibration_repository_impl.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/models/initial_calibration_data.dart';

import 'calibration_repository_impl_test.mocks.dart';

// Generate mocks
@GenerateMocks([PreferencesService])
void main() {
  late MockPreferencesService mockPreferencesService;
  late CalibrationRepositoryImpl repository;

  setUp(() {
    mockPreferencesService = MockPreferencesService();
    repository = CalibrationRepositoryImpl(mockPreferencesService);
  });

  group('CalibrationRepositoryImpl', () {
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
      'saveInitialCalibrationData calls preferences service with correct data',
      () async {
        // Setup mock to return success
        when(
          mockPreferencesService.setString(
            kInitialCalibrationData,
            testJsonString,
          ),
        ).thenAnswer((_) async => true);

        // Call the method
        final result = await repository.saveInitialCalibrationData(testData);

        // Verify interactions
        verify(
          mockPreferencesService.setString(
            kInitialCalibrationData,
            testJsonString,
          ),
        ).called(1);

        // Verify result
        expect(result, isTrue);
      },
    );

    test('saveInitialCalibrationData handles errors', () async {
      // Setup mock to throw exception
      when(
        mockPreferencesService.setString(
          kInitialCalibrationData,
          testJsonString,
        ),
      ).thenThrow(Exception('Test error'));

      // Call the method
      final result = await repository.saveInitialCalibrationData(testData);

      // Verify result
      expect(result, isFalse);
    });

    test(
      'loadInitialCalibrationData returns null when no data exists',
      () async {
        // Setup mock to return null
        when(
          mockPreferencesService.getString(kInitialCalibrationData),
        ).thenAnswer((_) async => null);

        // Call the method
        final result = await repository.loadInitialCalibrationData();

        // Verify interactions
        verify(
          mockPreferencesService.getString(kInitialCalibrationData),
        ).called(1);

        // Verify result
        expect(result, isNull);
      },
    );

    test(
      'loadInitialCalibrationData returns correct data when exists',
      () async {
        // Setup mock to return data
        when(
          mockPreferencesService.getString(kInitialCalibrationData),
        ).thenAnswer((_) async => testJsonString);

        // Call the method
        final result = await repository.loadInitialCalibrationData();

        // Verify interactions
        verify(
          mockPreferencesService.getString(kInitialCalibrationData),
        ).called(1);

        // Verify result
        expect(result, isNotNull);
        expect(result!.deviceOrientation, equals(testData.deviceOrientation));
        expect(
          result.accelerometerXOffset,
          equals(testData.accelerometerXOffset),
        );
        expect(
          result.accelerometerYOffset,
          equals(testData.accelerometerYOffset),
        );
        expect(
          result.accelerometerZOffset,
          equals(testData.accelerometerZOffset),
        );
        expect(result.gyroscopeXOffset, equals(testData.gyroscopeXOffset));
        expect(result.gyroscopeYOffset, equals(testData.gyroscopeYOffset));
        expect(result.gyroscopeZOffset, equals(testData.gyroscopeZOffset));
        expect(
          result.calibrationTimestamp,
          equals(testData.calibrationTimestamp),
        );
      },
    );

    test('loadInitialCalibrationData handles errors', () async {
      // Setup mock to throw exception
      when(
        mockPreferencesService.getString(kInitialCalibrationData),
      ).thenThrow(Exception('Test error'));

      // Call the method
      final result = await repository.loadInitialCalibrationData();

      // Verify result
      expect(result, isNull);
    });

    test('hasInitialCalibrationData returns true when data exists', () async {
      // Setup mock to return true
      when(
        mockPreferencesService.containsKey(kInitialCalibrationData),
      ).thenAnswer((_) async => true);

      // Call the method
      final result = await repository.hasInitialCalibrationData();

      // Verify interactions
      verify(
        mockPreferencesService.containsKey(kInitialCalibrationData),
      ).called(1);

      // Verify result
      expect(result, isTrue);
    });

    test(
      'hasInitialCalibrationData returns false when data does not exist',
      () async {
        // Setup mock to return false
        when(
          mockPreferencesService.containsKey(kInitialCalibrationData),
        ).thenAnswer((_) async => false);

        // Call the method
        final result = await repository.hasInitialCalibrationData();

        // Verify interactions
        verify(
          mockPreferencesService.containsKey(kInitialCalibrationData),
        ).called(1);

        // Verify result
        expect(result, isFalse);
      },
    );

    test('hasInitialCalibrationData handles errors', () async {
      // Setup mock to throw exception
      when(
        mockPreferencesService.containsKey(kInitialCalibrationData),
      ).thenThrow(Exception('Test error'));

      // Call the method
      final result = await repository.hasInitialCalibrationData();

      // Verify result
      expect(result, isFalse);
    });

    test('clearCalibrationData returns true on success', () async {
      // Setup mock to return true
      when(
        mockPreferencesService.remove(kInitialCalibrationData),
      ).thenAnswer((_) async => true);

      // Call the method
      final result = await repository.clearCalibrationData();

      // Verify interactions
      verify(mockPreferencesService.remove(kInitialCalibrationData)).called(1);

      // Verify result
      expect(result, isTrue);
    });

    test('clearCalibrationData handles errors', () async {
      // Setup mock to throw exception
      when(
        mockPreferencesService.remove(kInitialCalibrationData),
      ).thenThrow(Exception('Test error'));

      // Call the method
      final result = await repository.clearCalibrationData();

      // Verify result
      expect(result, isFalse);
    });
  });
}
