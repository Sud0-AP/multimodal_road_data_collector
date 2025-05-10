import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:multimodal_road_data_collector/core/services/sensor_service.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/models/initial_calibration_data.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/repositories/calibration_repository.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/usecases/calibration_usecase.dart';

// Generate mocks
@GenerateMocks([SensorService, CalibrationRepository])
import 'calibration_usecase_test.mocks.dart';

void main() {
  late MockSensorService mockSensorService;
  late MockCalibrationRepository mockCalibrationRepository;
  late CalibrationUseCase calibrationUseCase;

  setUp(() {
    mockSensorService = MockSensorService();
    mockCalibrationRepository = MockCalibrationRepository();
    calibrationUseCase = CalibrationUseCase(
      sensorService: mockSensorService,
      calibrationRepository: mockCalibrationRepository,
    );
  });

  group('Pre-recording calibration', () {
    test(
      'performPreRecordingCalibration returns failure when no initial calibration exists',
      () async {
        // Mock repository to return no calibration data
        when(
          mockCalibrationRepository.loadInitialCalibrationData(),
        ).thenAnswer((_) async => null);

        // Call the method
        final result =
            await calibrationUseCase.performPreRecordingCalibration();

        // Verify the result
        expect(result.isCalibrationSuccessful, isFalse);
      },
    );

    test(
      'performPreRecordingCalibration handles sensor errors gracefully',
      () async {
        // Set up test data and mocks
        final initialCalibrationData = InitialCalibrationData.initial();

        // Mock repository to return test calibration data
        when(
          mockCalibrationRepository.loadInitialCalibrationData(),
        ).thenAnswer((_) async => initialCalibrationData);

        // Mock sensor service to throw an error
        when(
          mockSensorService.isSensorDataCollectionActive(),
        ).thenReturn(false);
        when(
          mockSensorService.startSensorDataCollection(),
        ).thenThrow(Exception('Sensor error'));

        // Call the method
        final result =
            await calibrationUseCase.performPreRecordingCalibration();

        // Verify the result
        expect(result.isCalibrationSuccessful, isFalse);
      },
    );

    test(
      'performPreRecordingCalibration handles empty data gracefully',
      () async {
        // Set up test data and mocks
        final initialCalibrationData = InitialCalibrationData.initial();

        // Mock repository to return test calibration data
        when(
          mockCalibrationRepository.loadInitialCalibrationData(),
        ).thenAnswer((_) async => initialCalibrationData);

        // Create an empty stream
        final sensorDataController = StreamController<SensorData>();

        // Mock sensor service
        when(
          mockSensorService.isSensorDataCollectionActive(),
        ).thenReturn(false);
        when(
          mockSensorService.getSensorDataStream(),
        ).thenAnswer((_) => sensorDataController.stream);
        when(
          mockSensorService.startSensorDataCollection(),
        ).thenAnswer((_) async {});

        // Start the calibration
        final calibrationFuture =
            calibrationUseCase.performPreRecordingCalibration();

        // Close the controller immediately with no data
        await sensorDataController.close();

        // Get the result
        final result = await calibrationFuture;

        // Verify the result
        expect(result.isCalibrationSuccessful, isFalse);
      },
    );
  });
}
