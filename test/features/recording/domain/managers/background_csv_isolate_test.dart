import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:multimodal_road_data_collector/core/services/sensor_service.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/managers/recording_session_manager.dart';
import 'package:multimodal_road_data_collector/core/services/ntp_service.dart';
import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart';

import 'recording_session_manager_test.mocks.dart';

@GenerateMocks([SensorService, NtpService, FileStorageService])
void main() {
  late MockSensorService mockSensorService;
  late MockNtpService mockNtpService;
  late MockFileStorageService mockFileStorageService;
  late RecordingSessionManager manager;
  late StreamController<SensorData> sensorStreamController;

  // Mock current device time and NTP time
  final testStartTime = DateTime.now();
  final testNtpTime = testStartTime.add(
    const Duration(seconds: 1),
  ); // Simulate 1 second offset

  setUp(() {
    mockSensorService = MockSensorService();
    mockNtpService = MockNtpService();
    mockFileStorageService = MockFileStorageService();
    manager = RecordingSessionManager(
      mockSensorService,
      mockNtpService,
      mockFileStorageService,
    );
    sensorStreamController = StreamController<SensorData>.broadcast();

    when(mockSensorService.initialize()).thenAnswer((_) async {});
    when(
      mockSensorService.getSensorDataStream(),
    ).thenAnswer((_) => sensorStreamController.stream);
    when(
      mockSensorService.startSensorDataCollection(),
    ).thenAnswer((_) async {});
    when(mockSensorService.stopSensorDataCollection()).thenAnswer((_) async {});
    when(mockSensorService.isSensorDataCollectionActive()).thenReturn(false);

    // Set up NTP service mock
    when(mockNtpService.initialize()).thenAnswer((_) async {});
    when(
      mockNtpService.getCurrentNtpTime(),
    ).thenAnswer((_) async => testNtpTime);
    when(
      mockNtpService.getOffset(),
    ).thenAnswer((_) async => 1000); // 1 second offset
  });

  tearDown(() async {
    await sensorStreamController.close();
    await manager.dispose();
  });

  // Test group for Background CSV Writing
  group('Background CSV Writing Tests', () {
    const sessionDir = 'test/session/dir';

    setUp(() {
      // Setup mocks specifically for CSV writing tests
      manager.setSessionDirectory(sessionDir);

      // Mock getSensorDataCsvPath to return a valid path
      when(
        mockFileStorageService.getSensorDataCsvPath(
          any,
          createIfNotExists: anyNamed('createIfNotExists'),
        ),
      ).thenAnswer((_) async => '$sessionDir/sensors.csv');

      // Default mock for appendToSensorDataCsv to succeed
      when(
        mockFileStorageService.appendToSensorDataCsv(any, any),
      ).thenAnswer((_) async => true);
    });

    test('flushBuffer should write data to CSV in background', () async {
      // Manually trigger a data collection start to initialize the manager
      await manager.startSensorDataCollection();

      // Create a callback to count buffer flushes
      int callbackCount = 0;
      manager.setBufferFullCallback((dataPoints) {
        callbackCount++;
      });

      // Add data points through the sensor stream
      for (var i = 0; i < 10; i++) {
        sensorStreamController.add(
          SensorData(
            accelerometerX: 1.0 + i * 0.1,
            accelerometerY: 2.0 + i * 0.1,
            accelerometerZ: 3.0 + i * 0.1,
            gyroscopeX: 0.1 + i * 0.01,
            gyroscopeY: 0.2 + i * 0.01,
            gyroscopeZ: 0.3 + i * 0.01,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }

      // Give time for the stream to process
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify data is in buffer before flushing
      expect(manager.getBufferedDataPoints().isNotEmpty, isTrue);

      // Flush the buffer and await the result
      final dataPoints = await manager.flushBuffer();

      // Verify some data was flushed
      expect(dataPoints.isNotEmpty, isTrue);

      // Verify the appendToSensorDataCsv method was called
      verify(
        mockFileStorageService.appendToSensorDataCsv(any, any),
      ).called(greaterThan(0));

      // Verify buffer is empty after flush
      expect(manager.getBufferedDataPoints().isEmpty, isTrue);
    });

    test('should handle failed CSV write attempts', () async {
      // Mock appendToSensorDataCsv to fail
      when(
        mockFileStorageService.appendToSensorDataCsv(any, any),
      ).thenAnswer((_) async => false);

      // Setup an error callback to catch the error
      bool errorCallbackCalled = false;
      manager.setCsvWriteErrorCallback((errorMsg) {
        errorCallbackCalled = true;
      });

      // Start data collection
      await manager.startSensorDataCollection();

      // Add enough data points to trigger multiple flushes
      for (var i = 0; i < 200; i++) {
        sensorStreamController.add(
          SensorData(
            accelerometerX: 1.0,
            accelerometerY: 2.0,
            accelerometerZ: 3.0,
            gyroscopeX: 0.1,
            gyroscopeY: 0.2,
            gyroscopeZ: 0.3,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }

      // Allow time for processing
      await Future.delayed(const Duration(milliseconds: 200));

      // Force one more flush
      await manager.flushBuffer();

      // Verify error callback was eventually called
      expect(errorCallbackCalled, isTrue);
    });

    test('startSensorDataCollection should reset counters', () async {
      // First, start collection and generate some data
      await manager.startSensorDataCollection();

      // Add sample data
      for (var i = 0; i < 10; i++) {
        sensorStreamController.add(
          SensorData(
            accelerometerX: 1.0,
            accelerometerY: 2.0,
            accelerometerZ: 3.0,
            gyroscopeX: 0.1,
            gyroscopeY: 0.2,
            gyroscopeZ: 0.3,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }

      // Wait for processing then flush
      await Future.delayed(const Duration(milliseconds: 50));
      await manager.flushBuffer();

      // Stop and check the count
      await manager.stopSensorDataCollection();
      final firstCount = manager.getTotalRowsWritten();
      expect(firstCount, greaterThan(0));

      // Start again and verify count is reset
      await manager.startSensorDataCollection();
      expect(manager.getTotalRowsWritten(), equals(0));
    });

    test('stopSensorDataCollection should flush remaining buffer', () async {
      // Start data collection
      await manager.startSensorDataCollection();

      // Add some data
      for (var i = 0; i < 5; i++) {
        sensorStreamController.add(
          SensorData(
            accelerometerX: 1.0,
            accelerometerY: 2.0,
            accelerometerZ: 3.0,
            gyroscopeX: 0.1,
            gyroscopeY: 0.2,
            gyroscopeZ: 0.3,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }

      // Wait for data processing
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify there's data in the buffer
      expect(manager.getBufferedDataPoints().isNotEmpty, isTrue);

      // Reset verification counter
      clearInteractions(mockFileStorageService);

      // Stop data collection - should flush buffer
      await manager.stopSensorDataCollection();

      // Verify appendToSensorDataCsv was called
      verify(mockFileStorageService.appendToSensorDataCsv(any, any)).called(1);

      // Verify buffer is empty after stopping
      expect(manager.getBufferedDataPoints().isEmpty, isTrue);
    });

    test(
      'multiple concurrent write operations should be handled properly',
      () async {
        // Mock a delay for appendToSensorDataCsv
        bool firstCallCompleted = false;
        when(mockFileStorageService.appendToSensorDataCsv(any, any)).thenAnswer(
          (invocation) async {
            if (!firstCallCompleted) {
              firstCallCompleted = true;
              await Future.delayed(const Duration(milliseconds: 200));
            }
            return true;
          },
        );

        // Start collection
        await manager.startSensorDataCollection();

        // Add first batch of data points
        for (var i = 0; i < 5; i++) {
          sensorStreamController.add(
            SensorData(
              accelerometerX: 1.0,
              accelerometerY: 2.0,
              accelerometerZ: 3.0,
              gyroscopeX: 0.1,
              gyroscopeY: 0.2,
              gyroscopeZ: 0.3,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }

        // Wait for processing
        await Future.delayed(const Duration(milliseconds: 50));

        // Start first flush (will be slow due to the delay)
        final firstFlushFuture = manager.flushBuffer();

        // Add second batch immediately
        for (var i = 0; i < 5; i++) {
          sensorStreamController.add(
            SensorData(
              accelerometerX: 2.0,
              accelerometerY: 3.0,
              accelerometerZ: 4.0,
              gyroscopeX: 0.2,
              gyroscopeY: 0.3,
              gyroscopeZ: 0.4,
              timestamp: DateTime.now().millisecondsSinceEpoch,
            ),
          );
        }

        // Wait for processing
        await Future.delayed(const Duration(milliseconds: 50));

        // Start second flush (should wait for first to complete)
        final secondFlushFuture = manager.flushBuffer();

        // Wait for both operations
        await Future.wait([firstFlushFuture, secondFlushFuture]);

        // Verify both flushes were processed
        verify(
          mockFileStorageService.appendToSensorDataCsv(any, any),
        ).called(2);
      },
    );
  });
}
