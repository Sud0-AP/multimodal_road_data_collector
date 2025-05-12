import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_road_data_collector/core/services/implementations/spike_detection_service_impl.dart';
import 'package:multimodal_road_data_collector/core/services/spike_detection_service.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart';

void main() {
  group('SpikeDetectionService', () {
    late SpikeDetectionService spikeDetectionService;
    const double testThreshold = 10.0;
    const int testRefractoryPeriod = 8000; // 8 seconds

    setUp(() {
      spikeDetectionService = SpikeDetectionServiceImpl();
      spikeDetectionService.initialize(
        bumpThreshold: testThreshold,
        refractoryPeriodMs: testRefractoryPeriod,
      );
    });

    test('should detect spike when magnitude exceeds threshold', () {
      // Arrange
      final dataPoint = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.0,
        accelY: 2.0,
        accelZ: 3.0,
        accelMagnitude: 15.0, // Greater than threshold
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
      );

      // Act
      final result = spikeDetectionService.detectSpike(dataPoint);

      // Assert
      expect(result, true);
      expect(spikeDetectionService.getLastSpikeTimestamp(), 1000);
    });

    test('should not detect spike when magnitude is below threshold', () {
      // Arrange
      final dataPoint = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.0,
        accelY: 2.0,
        accelZ: 3.0,
        accelMagnitude: 5.0, // Less than threshold
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
      );

      // Act
      final result = spikeDetectionService.detectSpike(dataPoint);

      // Assert
      expect(result, false);
      expect(spikeDetectionService.getLastSpikeTimestamp(), null);
    });

    test('should honor refractory period', () {
      // Arrange
      final firstDataPoint = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.0,
        accelY: 2.0,
        accelZ: 3.0,
        accelMagnitude: 15.0, // Greater than threshold
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
      );

      final secondDataPoint = CorrectedSensorDataPoint(
        timestampMs: 2000, // Within refractory period (8000ms)
        accelX: 1.0,
        accelY: 2.0,
        accelZ: 3.0,
        accelMagnitude: 15.0, // Greater than threshold but same magnitude
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
      );

      final thirdDataPoint = CorrectedSensorDataPoint(
        timestampMs: 9001, // Outside refractory period
        accelX: 1.0,
        accelY: 2.0,
        accelZ: 3.0,
        accelMagnitude: 15.0, // Greater than threshold
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
      );

      // Act & Assert
      expect(spikeDetectionService.detectSpike(firstDataPoint), true);
      expect(spikeDetectionService.getLastSpikeTimestamp(), 1000);

      expect(spikeDetectionService.detectSpike(secondDataPoint), false);
      expect(spikeDetectionService.getLastSpikeTimestamp(), 1000); // Unchanged

      expect(spikeDetectionService.detectSpike(thirdDataPoint), true);
      expect(spikeDetectionService.getLastSpikeTimestamp(), 9001);
    });

    test(
      'should detect significantly stronger spike within refractory period',
      () {
        // Arrange
        final firstDataPoint = CorrectedSensorDataPoint(
          timestampMs: 1000,
          accelX: 1.0,
          accelY: 2.0,
          accelZ: 3.0,
          accelMagnitude: 15.0, // Initial spike magnitude
          gyroX: 0.1,
          gyroY: 0.2,
          gyroZ: 0.3,
        );

        final strongerDataPoint = CorrectedSensorDataPoint(
          timestampMs: 2000, // Within refractory period
          accelX: 2.0,
          accelY: 3.0,
          accelZ: 4.0,
          accelMagnitude: 18.0, // More than 2.0 greater than previous (15.0)
          gyroX: 0.1,
          gyroY: 0.2,
          gyroZ: 0.3,
        );

        // Act & Assert
        expect(spikeDetectionService.detectSpike(firstDataPoint), true);
        expect(spikeDetectionService.getLastSpikeTimestamp(), 1000);

        expect(spikeDetectionService.detectSpike(strongerDataPoint), true);
        expect(spikeDetectionService.getLastSpikeTimestamp(), 2000); // Updated
      },
    );

    test(
      'should not detect minor magnitude increase within refractory period',
      () {
        // Arrange
        final firstDataPoint = CorrectedSensorDataPoint(
          timestampMs: 1000,
          accelX: 1.0,
          accelY: 2.0,
          accelZ: 3.0,
          accelMagnitude: 15.0, // Initial spike magnitude
          gyroX: 0.1,
          gyroY: 0.2,
          gyroZ: 0.3,
        );

        final similarDataPoint = CorrectedSensorDataPoint(
          timestampMs: 2000, // Within refractory period
          accelX: 1.2,
          accelY: 2.2,
          accelZ: 3.2,
          accelMagnitude:
              16.0, // Only 1.0 greater than previous (15.0), less than the required 2.0
          gyroX: 0.1,
          gyroY: 0.2,
          gyroZ: 0.3,
        );

        // Act & Assert
        expect(spikeDetectionService.detectSpike(firstDataPoint), true);
        expect(spikeDetectionService.getLastSpikeTimestamp(), 1000);

        expect(spikeDetectionService.detectSpike(similarDataPoint), false);
        expect(
          spikeDetectionService.getLastSpikeTimestamp(),
          1000,
        ); // Unchanged
      },
    );

    test('should reset properly', () {
      // Arrange
      final dataPoint = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.0,
        accelY: 2.0,
        accelZ: 3.0,
        accelMagnitude: 15.0, // Greater than threshold
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
      );

      // Act
      spikeDetectionService.detectSpike(dataPoint);
      spikeDetectionService.reset();

      // Assert
      expect(spikeDetectionService.getLastSpikeTimestamp(), null);
    });

    test('should throw error if not initialized', () {
      // Arrange
      spikeDetectionService =
          SpikeDetectionServiceImpl(); // New instance without initialization

      final dataPoint = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.0,
        accelY: 2.0,
        accelZ: 3.0,
        accelMagnitude: 15.0,
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
      );

      // Act & Assert
      expect(
        () => spikeDetectionService.detectSpike(dataPoint),
        throwsStateError,
      );
    });
  });
}
