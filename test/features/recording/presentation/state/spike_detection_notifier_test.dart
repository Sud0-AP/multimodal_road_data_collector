import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:multimodal_road_data_collector/core/services/spike_detection_service.dart';
import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart';
import 'package:multimodal_road_data_collector/features/recording/presentation/state/spike_detection_notifier.dart';

import 'spike_detection_notifier_test.mocks.dart';

@GenerateMocks([SpikeDetectionService, FileStorageService])
void main() {
  group('SpikeDetectionNotifier', () {
    late MockSpikeDetectionService mockSpikeDetectionService;
    late SpikeDetectionNotifier notifier;

    setUp(() {
      mockSpikeDetectionService = MockSpikeDetectionService();
      notifier = SpikeDetectionNotifier(mockSpikeDetectionService);
    });

    test('initial state has detection inactive', () {
      expect(notifier.state.isDetectionActive, false);
      expect(notifier.state.lastSpikeTimestampMs, null);
    });

    test('initialize sets detection active state', () {
      // Arrange
      const bumpThreshold = 10.0;
      const refractoryPeriodMs = 2000;

      // Act
      notifier.initialize(
        bumpThreshold: bumpThreshold,
        refractoryPeriodMs: refractoryPeriodMs,
      );

      // Assert
      expect(notifier.state.isDetectionActive, true);
      expect(notifier.state.lastSpikeTimestampMs, null);
      verify(
        mockSpikeDetectionService.initialize(
          bumpThreshold: bumpThreshold,
          refractoryPeriodMs: refractoryPeriodMs,
        ),
      ).called(1);
    });

    test('processSensorDataPoint returns false when detection inactive', () {
      // Arrange
      final dataPoint = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.0,
        accelY: 1.0,
        accelZ: 1.0,
        accelMagnitude: 1.73,
        gyroX: 0.0,
        gyroY: 0.0,
        gyroZ: 0.0,
      );

      // Act
      final result = notifier.processSensorDataPoint(dataPoint);

      // Assert
      expect(result, false);
      verifyNever(mockSpikeDetectionService.detectSpike(any));
    });

    test(
      'processSensorDataPoint calls service and updates state when spike detected',
      () {
        // Arrange
        notifier = SpikeDetectionNotifier(mockSpikeDetectionService);
        notifier.initialize(bumpThreshold: 10.0, refractoryPeriodMs: 2000);

        final dataPoint = CorrectedSensorDataPoint(
          timestampMs: 1000,
          accelX: 5.0,
          accelY: 5.0,
          accelZ: 5.0,
          accelMagnitude: 8.66,
          gyroX: 0.0,
          gyroY: 0.0,
          gyroZ: 0.0,
        );

        when(mockSpikeDetectionService.detectSpike(any)).thenReturn(true);

        // Act
        final result = notifier.processSensorDataPoint(dataPoint);

        // Assert
        expect(result, true);
        expect(notifier.state.lastSpikeTimestampMs, 1000);
        verify(mockSpikeDetectionService.detectSpike(dataPoint)).called(1);
      },
    );

    test('stopDetection calls service reset and updates state', () {
      // Arrange
      notifier.initialize(bumpThreshold: 10.0);

      // Act
      notifier.stopDetection();

      // Assert
      expect(notifier.state.isDetectionActive, false);
      verify(mockSpikeDetectionService.reset()).called(1);
    });

    test('reset calls service reset and sets initial state', () {
      // Arrange
      notifier.initialize(bumpThreshold: 10.0);

      final dataPoint = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.0,
        accelY: 1.0,
        accelZ: 1.0,
        accelMagnitude: 1.73,
        gyroX: 0.0,
        gyroY: 0.0,
        gyroZ: 0.0,
      );

      when(mockSpikeDetectionService.detectSpike(any)).thenReturn(true);
      notifier.processSensorDataPoint(dataPoint);

      // Act
      notifier.reset();

      // Assert
      expect(notifier.state.isDetectionActive, false);
      expect(notifier.state.lastSpikeTimestampMs, null);
      verify(mockSpikeDetectionService.reset()).called(1);
    });

    test('integration with annotation logging workflow', () {
      // This test simulates the integration with the FileStorageService
      // for the annotation logging workflow

      // Setup
      final mockFileStorageService = MockFileStorageService();
      when(
        mockFileStorageService.logAnnotation(any, any, any),
      ).thenAnswer((_) async => true);

      // Initialize spike detection
      notifier.initialize(bumpThreshold: 10.0);

      // Simulate spike detection
      final dataPoint = CorrectedSensorDataPoint(
        timestampMs: 1500,
        accelX: 6.0,
        accelY: 6.0,
        accelZ: 6.0,
        accelMagnitude: 10.4, // Above threshold
        gyroX: 0.1,
        gyroY: 0.1,
        gyroZ: 0.1,
      );

      when(mockSpikeDetectionService.detectSpike(any)).thenReturn(true);

      // Process data point - should detect spike
      final spikeDetected = notifier.processSensorDataPoint(dataPoint);
      expect(spikeDetected, isTrue);
      expect(notifier.state.lastSpikeTimestampMs, 1500);

      // Simulate user responding "Yes" to annotation prompt
      final sessionDir = '/path/to/session';
      mockFileStorageService.logAnnotation(
        sessionDir,
        notifier.state.lastSpikeTimestampMs!,
        'Yes',
      );

      // Verify annotation was logged with correct parameters
      verify(
        mockFileStorageService.logAnnotation(sessionDir, 1500, 'Yes'),
      ).called(1);
    });
  });
}
