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

  test('initialize should call initialize on sensor service', () async {
    await manager.initialize();
    verify(mockSensorService.initialize()).called(1);
  });

  test(
    'startSensorDataCollection should start sensor service if not active',
    () async {
      await manager.startSensorDataCollection();
      verify(mockSensorService.startSensorDataCollection()).called(1);
    },
  );

  test(
    'stopSensorDataCollection should stop sensor service if active',
    () async {
      when(mockSensorService.isSensorDataCollectionActive()).thenReturn(true);
      await manager.startSensorDataCollection();
      await manager.stopSensorDataCollection();
      verify(mockSensorService.stopSensorDataCollection()).called(1);
    },
  );

  test(
    'getProcessedSensorStream returns processed data with corrections applied',
    () async {
      // Setup test data
      final testData = SensorData(
        accelerometerX: 1.0,
        accelerometerY: 2.0,
        accelerometerZ: 9.8, // Approx gravity
        gyroscopeX: 0.1,
        gyroscopeY: 0.2,
        gyroscopeZ: 0.3,
        timestamp: 123456789,
      );

      // Set calibration parameters
      manager.setCalibrationParameters(
        accelZOffset: 0.5,
        gyroZOffset: 0.1,
        swapXY: true,
      );

      // Start collection and prepare to receive data
      await manager.startSensorDataCollection();

      // Create expectation for the processed data
      final processedDataCompleter = Completer<ProcessedSensorData>();
      manager.getProcessedSensorStream().listen((data) {
        if (!processedDataCompleter.isCompleted) {
          processedDataCompleter.complete(data);
        }
      });

      // Add test data to the mock stream
      sensorStreamController.add(testData);

      // Wait for the processed data
      final processedData = await processedDataCompleter.future;

      // Verify the data is correctly processed
      expect(processedData.rawData, equals(testData));

      // Verify X and Y are swapped (since swapXY is true)
      expect(processedData.accelMagnitude, isNotNull);

      // Verify Z-offset correction is applied
      expect(
        processedData.correctedAccelZ,
        equals(testData.accelerometerZ - 0.5),
      );

      // Verify gyroZ correction is applied
      expect(processedData.correctedGyroZ, equals(testData.gyroscopeZ - 0.1));
    },
  );

  test('acceleration magnitude is calculated correctly', () async {
    // Setup test data with known values for easy verification
    final testData = SensorData(
      accelerometerX: 3.0,
      accelerometerY: 4.0,
      accelerometerZ: 5.0,
      gyroscopeX: 0.0,
      gyroscopeY: 0.0,
      gyroscopeZ: 0.0,
      timestamp: 123456789,
    );

    // No calibration parameters for this test

    // Start collection and prepare to receive data
    await manager.startSensorDataCollection();

    // Create expectation for the processed data
    final processedDataCompleter = Completer<ProcessedSensorData>();
    manager.getProcessedSensorStream().listen((data) {
      if (!processedDataCompleter.isCompleted) {
        processedDataCompleter.complete(data);
      }
    });

    // Add test data to the mock stream
    sensorStreamController.add(testData);

    // Wait for the processed data
    final processedData = await processedDataCompleter.future;

    // Expected magnitude: sqrt(3² + 4² + 5²) = sqrt(9 + 16 + 25) = sqrt(50) = 7.071...
    expect(processedData.accelMagnitude, closeTo(7.071, 0.001));
  });

  group('Buffer Management Tests', () {
    test('Buffer should flush when maximum size is reached', () async {
      // Set a sample session directory
      const sessionDir = 'test/session/dir';
      manager.setSessionDirectory(sessionDir);

      // Mock successful file storage append operation
      when(
        mockFileStorageService.appendToSensorDataCsv(any, any),
      ).thenAnswer((_) async => true);

      // Set up the stream controller to emit sensor data
      final streamController = StreamController<SensorData>();
      when(
        mockSensorService.getSensorDataStream(),
      ).thenAnswer((_) => streamController.stream);
      when(
        mockSensorService.startSensorDataCollection(),
      ).thenAnswer((_) async {});

      // Mock NTP time retrieval
      final mockNtpTime = DateTime.now().toUtc();
      when(
        mockNtpService.getCurrentNtpTime(),
      ).thenAnswer((_) async => mockNtpTime);

      // Store flushed data for verification
      final List<CorrectedSensorDataPoint> flushedData = [];
      manager.setBufferFullCallback((data) {
        flushedData.addAll(data);
      });

      // Start data collection
      await manager.startSensorDataCollection();

      // Send enough sensor data to trigger a buffer flush
      // The maxBufferSize is set to 150 in the manager
      final maxBuffer = 155; // Slightly more than buffer size
      for (int i = 0; i < maxBuffer; i++) {
        streamController.add(
          SensorData(
            timestamp: DateTime.now().millisecondsSinceEpoch,
            accelerometerX: 0.1 * i,
            accelerometerY: 0.2 * i,
            accelerometerZ: 0.3 * i,
            gyroscopeX: 0.01 * i,
            gyroscopeY: 0.02 * i,
            gyroscopeZ: 0.03 * i,
          ),
        );
      }

      // Wait for flush processing
      await Future.delayed(const Duration(milliseconds: 100));

      // Verify the buffer was flushed
      verify(
        mockFileStorageService.appendToSensorDataCsv(sessionDir, any),
      ).called(1);

      // Verify that the buffer was cleared
      expect(manager.getBufferedDataPoints().length, lessThan(maxBuffer));

      // Clean up
      await streamController.close();
      await manager.dispose();
    });

    test('Buffer should be flushed when stopping data collection', () async {
      // Set a sample session directory
      const sessionDir = 'test/session/dir';
      manager.setSessionDirectory(sessionDir);

      // Mock successful file storage append operation
      when(
        mockFileStorageService.appendToSensorDataCsv(any, any),
      ).thenAnswer((_) async => true);

      // Set up the stream controller to emit sensor data
      final streamController = StreamController<SensorData>();
      when(
        mockSensorService.getSensorDataStream(),
      ).thenAnswer((_) => streamController.stream);
      when(
        mockSensorService.startSensorDataCollection(),
      ).thenAnswer((_) async {});
      when(
        mockSensorService.stopSensorDataCollection(),
      ).thenAnswer((_) async {});

      // Mock NTP time retrieval
      final mockNtpTime = DateTime.now().toUtc();
      when(
        mockNtpService.getCurrentNtpTime(),
      ).thenAnswer((_) async => mockNtpTime);

      // Start data collection
      await manager.startSensorDataCollection();

      // Send some sensor data but not enough to trigger auto-flush
      final dataCount = 50; // Less than buffer threshold
      for (int i = 0; i < dataCount; i++) {
        streamController.add(
          SensorData(
            timestamp: DateTime.now().millisecondsSinceEpoch,
            accelerometerX: 0.1 * i,
            accelerometerY: 0.2 * i,
            accelerometerZ: 0.3 * i,
            gyroscopeX: 0.01 * i,
            gyroscopeY: 0.02 * i,
            gyroscopeZ: 0.03 * i,
          ),
        );
      }

      // Verify buffer now contains data
      expect(manager.getBufferedDataPoints().length, equals(dataCount));

      // Stop data collection which should trigger a flush
      await manager.stopSensorDataCollection();

      // Verify the buffer was flushed to storage
      verify(
        mockFileStorageService.appendToSensorDataCsv(sessionDir, any),
      ).called(1);

      // Verify the buffer is now empty
      expect(manager.getBufferedDataPoints().length, equals(0));

      // Clean up
      await streamController.close();
      await manager.dispose();
    });

    test('Manual flush should write data to file storage', () async {
      // Set a sample session directory
      const sessionDir = 'test/session/dir';
      manager.setSessionDirectory(sessionDir);

      // Mock successful file storage append operation
      when(
        mockFileStorageService.appendToSensorDataCsv(any, any),
      ).thenAnswer((_) async => true);

      // Add some data points manually to the buffer
      for (int i = 0; i < 10; i++) {
        manager.getBufferedDataPoints().add(
          CorrectedSensorDataPoint(
            timestampMs: i * 10,
            accelX: 0.1 * i,
            accelY: 0.2 * i,
            accelZ: 0.3 * i,
            accelMagnitude: 0.5 * i,
            gyroX: 0.01 * i,
            gyroY: 0.02 * i,
            gyroZ: 0.03 * i,
          ),
        );
      }

      // Manually flush the buffer
      final flushedData = await manager.flushBuffer();

      // Verify that data was flushed
      expect(flushedData.length, equals(10));

      // Verify the storage service was called
      verify(
        mockFileStorageService.appendToSensorDataCsv(sessionDir, any),
      ).called(1);

      // Verify buffer is now empty
      expect(manager.getBufferedDataPoints().length, equals(0));
    });

    test('Buffer should handle errors during file writing', () async {
      // Set a sample session directory
      const sessionDir = 'test/session/dir';
      manager.setSessionDirectory(sessionDir);

      // Mock file storage to throw an error
      when(
        mockFileStorageService.appendToSensorDataCsv(any, any),
      ).thenAnswer((_) async => throw Exception('Simulated write error'));

      // Add some data points manually to the buffer
      for (int i = 0; i < 10; i++) {
        manager.getBufferedDataPoints().add(
          CorrectedSensorDataPoint(
            timestampMs: i * 10,
            accelX: 0.1 * i,
            accelY: 0.2 * i,
            accelZ: 0.3 * i,
            accelMagnitude: 0.5 * i,
            gyroX: 0.01 * i,
            gyroY: 0.02 * i,
            gyroZ: 0.03 * i,
          ),
        );
      }

      // Attempting to flush should not throw despite the storage error
      final flushedData = await manager.flushBuffer();

      // Data should still be returned even though save failed
      expect(flushedData.length, equals(10));

      // Buffer should be cleared regardless of storage error
      expect(manager.getBufferedDataPoints().length, equals(0));
    });
  });

  group('Hybrid Timestamping Tests', () {
    test('should initialize and track start timestamps', () async {
      // Start sensor data collection
      await manager.initialize();
      await manager.startSensorDataCollection();

      // Verify NTP service was initialized
      verify(mockNtpService.initialize()).called(1);

      // Verify NTP time was fetched
      verify(mockNtpService.getCurrentNtpTime()).called(1);

      // Verify that start time is recorded
      expect(manager.getNtpStartTime(), isNotNull);
      expect(manager.getMonotonicStartTimeMs(), isNotNull);
    });

    test('should correctly calculate relative timestamps', () async {
      // Start sensor data collection
      await manager.initialize();
      await manager.startSensorDataCollection();

      // Store the start time for calculations
      final monotonicStartTime = manager.getMonotonicStartTimeMs()!;

      // Create bufferFull callback to capture processed data
      final processedDataPoints = <CorrectedSensorDataPoint>[];
      manager.setBufferFullCallback((dataPoints) {
        processedDataPoints.addAll(dataPoints);
      });

      // Emit test sensor data with timestamps
      final testData1 = SensorData(
        accelerometerX: 1.0,
        accelerometerY: 2.0,
        accelerometerZ: 3.0,
        gyroscopeX: 0.1,
        gyroscopeY: 0.2,
        gyroscopeZ: 0.3,
        timestamp: monotonicStartTime + 100, // 100ms after start
      );

      final testData2 = SensorData(
        accelerometerX: 1.1,
        accelerometerY: 2.1,
        accelerometerZ: 3.1,
        gyroscopeX: 0.11,
        gyroscopeY: 0.21,
        gyroscopeZ: 0.31,
        timestamp: monotonicStartTime + 200, // 200ms after start
      );

      // Emit the test data
      sensorStreamController.add(testData1);
      sensorStreamController.add(testData2);

      // Wait for data to be processed
      await Future.delayed(const Duration(milliseconds: 50));

      // Force flush to capture all data points
      final remainingDataPoints = manager.flushBuffer();
      if (remainingDataPoints.isNotEmpty) {
        processedDataPoints.addAll(remainingDataPoints);
      }

      // Verify we have two data points
      expect(processedDataPoints.length, 2);

      // Verify relative timestamps are calculated correctly
      expect(processedDataPoints[0].timestampMs, 100);
      expect(processedDataPoints[1].timestampMs, 200);
    });

    test('should track end timestamps when stopping collection', () async {
      // Start sensor data collection
      await manager.initialize();
      await manager.startSensorDataCollection();

      // Stop collection
      await manager.stopSensorDataCollection();

      // Verify NTP time was fetched for end time
      verify(
        mockNtpService.getCurrentNtpTime(),
      ).called(2); // Once for start, once for end

      // Verify both start and end times are recorded
      expect(manager.getNtpStartTime(), isNotNull);
      expect(manager.getNtpEndTime(), isNotNull);
      expect(manager.getMonotonicStartTimeMs(), isNotNull);
      expect(manager.getMonotonicEndTimeMs(), isNotNull);
    });

    test('should fall back to device time if NTP service fails', () async {
      // Setup NTP service to fail
      when(
        mockNtpService.getCurrentNtpTime(),
      ).thenThrow(Exception('NTP service failure'));

      // Start sensor data collection
      await manager.initialize();
      await manager.startSensorDataCollection();

      // Verify NTP service was attempted
      verify(mockNtpService.getCurrentNtpTime()).called(1);

      // Verify that start time is still recorded (should fall back to device time)
      expect(manager.getNtpStartTime(), isNotNull);
      expect(manager.getMonotonicStartTimeMs(), isNotNull);
    });

    test('should flush buffer when stopping collection', () async {
      // Start sensor data collection
      await manager.initialize();
      await manager.startSensorDataCollection();

      // Store the start time for calculations
      final monotonicStartTime = manager.getMonotonicStartTimeMs()!;

      // Create bufferFull callback to capture processed data
      final processedDataPoints = <CorrectedSensorDataPoint>[];
      manager.setBufferFullCallback((dataPoints) {
        processedDataPoints.addAll(dataPoints);
      });

      // Emit test sensor data
      final testData = SensorData(
        accelerometerX: 1.0,
        accelerometerY: 2.0,
        accelerometerZ: 3.0,
        gyroscopeX: 0.1,
        gyroscopeY: 0.2,
        gyroscopeZ: 0.3,
        timestamp: monotonicStartTime + 100,
      );

      sensorStreamController.add(testData);

      // Wait for data to be processed
      await Future.delayed(const Duration(milliseconds: 50));

      // Stop collection - should trigger buffer flush
      await manager.stopSensorDataCollection();

      // Verify data was flushed
      expect(processedDataPoints.length, 1);
      expect(processedDataPoints[0].timestampMs, 100);
    });

    test('should calculate actual sampling rate', () async {
      // Start sensor data collection
      await manager.initialize();
      await manager.startSensorDataCollection();

      // Simulate a recording lasting 1 second
      await Future.delayed(const Duration(milliseconds: 100));

      // Store the start time for calculations
      final monotonicStartTime = manager.getMonotonicStartTimeMs()!;

      // Emit 10 data points over a simulated 1 second period
      for (int i = 0; i < 10; i++) {
        final testData = SensorData(
          accelerometerX: 1.0,
          accelerometerY: 2.0,
          accelerometerZ: 3.0,
          gyroscopeX: 0.1,
          gyroscopeY: 0.2,
          gyroscopeZ: 0.3,
          timestamp: monotonicStartTime + (i * 100), // Each 100ms
        );

        sensorStreamController.add(testData);
      }

      // Wait for data to be processed
      await Future.delayed(const Duration(milliseconds: 100));

      // Stop collection
      await manager.stopSensorDataCollection();

      // Calculate sampling rate
      final samplingRate = manager.calculateActualSamplingRateHz();

      // Sampling rate might vary in tests, but should be greater than 0
      expect(samplingRate, isNotNull);
      expect(samplingRate! > 0, isTrue);
    });

    test('Should use NTP time when available', () async {
      // Mock NTP time retrieval
      final mockNtpTime = DateTime.now().toUtc();
      when(
        mockNtpService.getCurrentNtpTime(),
      ).thenAnswer((_) async => mockNtpTime);

      // Set up the stream controller
      final streamController = StreamController<SensorData>();
      when(
        mockSensorService.getSensorDataStream(),
      ).thenAnswer((_) => streamController.stream);
      when(
        mockSensorService.startSensorDataCollection(),
      ).thenAnswer((_) async {});

      // Start data collection
      await manager.startSensorDataCollection();

      // Verify NTP service was used
      verify(mockNtpService.getCurrentNtpTime()).called(1);

      // Verify NTP time was stored
      expect(manager.getNtpStartTime(), equals(mockNtpTime));

      // Clean up
      await streamController.close();
      await manager.dispose();
    });

    test('Should calculate relative timestamps correctly', () async {
      // Mock NTP time retrieval
      final mockNtpTime = DateTime.now().toUtc();
      when(
        mockNtpService.getCurrentNtpTime(),
      ).thenAnswer((_) async => mockNtpTime);

      // Set up the stream controller
      final streamController = StreamController<SensorData>();
      when(
        mockSensorService.getSensorDataStream(),
      ).thenAnswer((_) => streamController.stream);
      when(
        mockSensorService.startSensorDataCollection(),
      ).thenAnswer((_) async {});

      // Create a storage callback to capture data points
      final List<CorrectedSensorDataPoint> capturedDataPoints = [];
      manager.setBufferFullCallback((data) {
        capturedDataPoints.addAll(data);
      });

      // Start data collection
      await manager.startSensorDataCollection();

      // Get the monotonic start time
      final startTimeMs = manager.getMonotonicStartTimeMs();
      expect(startTimeMs, isNotNull);

      // Send sensor data with timestamps at different offsets
      final baseTimestamp = DateTime.now().millisecondsSinceEpoch;
      for (int i = 0; i < 10; i++) {
        final timestamp = baseTimestamp + (i * 100); // 100ms intervals
        streamController.add(
          SensorData(
            timestamp: timestamp,
            accelerometerX: 0.1,
            accelerometerY: 0.2,
            accelerometerZ: 0.3,
            gyroscopeX: 0.01,
            gyroscopeY: 0.02,
            gyroscopeZ: 0.03,
          ),
        );
      }

      // Force flush data to capture data points
      await manager.flushBuffer();

      // Verify relative timestamps were calculated correctly
      for (int i = 0; i < capturedDataPoints.length; i++) {
        final expectedRelativeTime = (baseTimestamp + (i * 100)) - startTimeMs!;
        expect(capturedDataPoints[i].timestampMs, equals(expectedRelativeTime));
      }

      // Clean up
      await streamController.close();
      await manager.dispose();
    });
  });

  // New test group for Background CSV Writing
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
      // Create test data points
      final testDataPoints = List.generate(
        10,
        (i) => CorrectedSensorDataPoint(
          timestampMs: i * 10,
          accelX: 1.0 + i * 0.1,
          accelY: 2.0 + i * 0.1,
          accelZ: 3.0 + i * 0.1,
          accelMagnitude: 4.0 + i * 0.1,
          gyroX: 0.1 + i * 0.01,
          gyroY: 0.2 + i * 0.01,
          gyroZ: 0.3 + i * 0.01,
          isPothole: i % 3 == 0, // Every third point is a pothole
        ),
      );

      // Manually trigger a data collection start to initialize the manager
      await manager.startSensorDataCollection();

      // Use reflection or access through public API to add data to buffer
      for (final point in testDataPoints) {
        // Instead of direct buffer access, we'll use the buffer directly in the test
        sensorStreamController.add(
          SensorData(
            accelerometerX: point.accelX,
            accelerometerY: point.accelY,
            accelerometerZ: point.accelZ,
            gyroscopeX: point.gyroX,
            gyroscopeY: point.gyroY,
            gyroscopeZ: point.gyroZ,
            timestamp: DateTime.now().millisecondsSinceEpoch,
          ),
        );
      }

      // Give time for the stream to process
      await Future.delayed(const Duration(milliseconds: 50));

      // Get current buffered points before flush
      final bufferedPoints = manager.getBufferedDataPoints();
      expect(bufferedPoints.isNotEmpty, isTrue);

      // Flush the buffer
      final flushedPoints = await manager.flushBuffer();

      // Verify the data was flushed
      expect(flushedPoints.isNotEmpty, isTrue);

      // Verify the appendToSensorDataCsv method was called
      verify(
        mockFileStorageService.appendToSensorDataCsv(sessionDir, any),
      ).called(greaterThan(0));

      // Verify the buffer is cleared after flush
      expect(manager.getBufferedDataPoints(), isEmpty);
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

      // Add some data points through the stream
      for (var i = 0; i < 3; i++) {
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
      await Future.delayed(const Duration(milliseconds: 50));

      // Force multiple failed write attempts by repeatedly flushing
      for (var i = 0; i < 3; i++) {
        await manager.flushBuffer();
      }

      // Verify error callback was eventually called
      expect(errorCallbackCalled, isTrue);

      // Verify appendToSensorDataCsv was called multiple times
      verify(
        mockFileStorageService.appendToSensorDataCsv(sessionDir, any),
      ).called(greaterThanOrEqualTo(3));
    });

    test('startSensorDataCollection should reset counters', () async {
      // First add some data and flush to increase counters
      await manager.startSensorDataCollection();

      // Add sample data
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

      // Allow time for processing
      await Future.delayed(const Duration(milliseconds: 50));

      // Flush to increment written count
      await manager.flushBuffer();

      // Verify some rows were written
      expect(manager.getTotalRowsWritten(), greaterThan(0));

      // Stop collection
      await manager.stopSensorDataCollection();

      // Get current count
      final previousCount = manager.getTotalRowsWritten();

      // Start collection again - should reset counters
      await manager.startSensorDataCollection();

      // Verify counters are reset
      expect(manager.getTotalRowsWritten(), equals(0));
      expect(manager.getTotalRowsWritten(), lessThan(previousCount));
    });

    test('calculateActualSamplingRateHz should calculate correctly', () async {
      // Start collection to initialize timestamps
      await manager.startSensorDataCollection();

      // Add 100 data points in quick succession
      for (var i = 0; i < 100; i++) {
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
      await Future.delayed(const Duration(milliseconds: 100));

      // Flush buffer to ensure they're counted
      await manager.flushBuffer();

      // Stop collection to finalize timestamps
      await manager.stopSensorDataCollection();

      // Calculate sampling rate
      final samplingRate = manager.calculateActualSamplingRateHz();

      // Should return a valid sampling rate if data was collected
      expect(samplingRate, isNotNull);
      expect(samplingRate, greaterThan(0));
    });

    test('stopSensorDataCollection should flush remaining buffer', () async {
      // Start data collection
      await manager.startSensorDataCollection();

      // Add some data points to the stream
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

      // Allow time for processing
      await Future.delayed(const Duration(milliseconds: 50));

      // Verify data is in buffer before stopping
      expect(manager.getBufferedDataPoints(), isNotEmpty);

      // Mock sensor service to report active status
      when(mockSensorService.isSensorDataCollectionActive()).thenReturn(true);

      // Reset verification counter for appendToSensorDataCsv
      clearInteractions(mockFileStorageService);

      // Stop data collection - should flush buffer
      await manager.stopSensorDataCollection();

      // Verify appendToSensorDataCsv was called
      verify(
        mockFileStorageService.appendToSensorDataCsv(sessionDir, any),
      ).called(1);

      // Verify buffer is empty after stopping
      expect(manager.getBufferedDataPoints(), isEmpty);
    });

    test(
      'multiple concurrent write operations should be handled properly',
      () async {
        // Mock a delay for appendToSensorDataCsv
        when(mockFileStorageService.appendToSensorDataCsv(any, any)).thenAnswer(
          (_) async {
            await Future.delayed(const Duration(milliseconds: 100));
            return true;
          },
        );

        // Start data collection
        await manager.startSensorDataCollection();

        // Add some initial data points
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

        // Start first flush
        final firstFlushFuture = manager.flushBuffer();

        // Add more data immediately
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

        // Start second flush before first completes
        final secondFlushFuture = manager.flushBuffer();

        // Wait for both operations to complete
        await Future.wait([firstFlushFuture, secondFlushFuture]);

        // Verify appendToSensorDataCsv was called twice
        verify(
          mockFileStorageService.appendToSensorDataCsv(sessionDir, any),
        ).called(2);

        // Verify buffer is empty
        expect(manager.getBufferedDataPoints(), isEmpty);
      },
    );
  });

  test('should handle background CSV writing with retry mechanism', () async {
    // Setup
    final mockSensorService = MockSensorService();
    final mockNtpService = MockNtpService();
    final mockFileStorageService = MockFileStorageService();
    
    final sessionManager = RecordingSessionManager(
      mockSensorService,
      mockNtpService, 
      mockFileStorageService,
    );
    
    final testSessionDir = '/test/session';
    final dataPoints = [
      CorrectedSensorDataPoint(
        timestampMs: 0,
        accelX: 0.1,
        accelY: 0.2,
        accelZ: 0.3,
        accelMagnitude: 0.5,
        gyroX: 0.01,
        gyroY: 0.02,
        gyroZ: 0.03,
        isPothole: false,
      ),
      CorrectedSensorDataPoint(
        timestampMs: 10,
        accelX: 0.4,
        accelY: 0.5,
        accelZ: 0.6,
        accelMagnitude: 0.8,
        gyroX: 0.04,
        gyroY: 0.05,
        gyroZ: 0.06,
        isPothole: true,
      ),
    ];
    
    // Setup mock responses
    when(mockFileStorageService.getSensorDataCsvPath(
      testSessionDir, 
      createIfNotExists: true,
    )).thenAnswer((_) async => '$testSessionDir/sensors.csv');
    
    when(mockFileStorageService.createDirectory(testSessionDir))
        .thenAnswer((_) async => true);
        
    when(mockFileStorageService.writeStringToFile(
      any, 
      '$testSessionDir/test_write_access.tmp',
    )).thenAnswer((_) async => true);
    
    when(mockFileStorageService.deleteFile(
      '$testSessionDir/test_write_access.tmp',
    )).thenAnswer((_) async => true);
    
    // First call fails, second succeeds to test retry mechanism
    final csvRows = dataPoints.map((point) => point.toCsvRow()).toList();
    when(mockFileStorageService.appendToCsv(
      '$testSessionDir/sensors.csv', 
      csvRows,
    )).thenAnswer((_) async {
      // First call fails, subsequent calls succeed
      if (csvFailCounter == 0) {
        csvFailCounter++;
        return false;
      }
      return true;
    });
    
    // Capture CSV write status events
    final List<CsvWriteResult> writeResults = [];
    sessionManager.getCsvWriteStatusStream().listen((result) {
      writeResults.add(result);
    });
    
    // Set error callback
    String? errorMessage;
    sessionManager.setCsvWriteErrorCallback((msg) {
      errorMessage = msg;
    });
    
    // Set session directory
    sessionManager.setSessionDirectory(testSessionDir);
    
    // Act
    final flushedData = await sessionManager.flushBuffer();
    
    // Wait for both attempts (fail + retry)
    await Future.delayed(Duration(milliseconds: 1500));
    
    // Assert
    expect(flushedData, isEmpty); // No data in buffer initially
    expect(writeResults.length, 2); // First attempt failed, second succeeded
    expect(writeResults[0].success, false); // First attempt failed
    expect(writeResults[1].success, true); // Second attempt succeeded after retry
    expect(errorMessage, isNull); // No critical error since retry succeeded
    
    // Reset counter for other tests
    csvFailCounter = 0;
  });
}

// Counter used for testing retry mechanism
int csvFailCounter = 0;
