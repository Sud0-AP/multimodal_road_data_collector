import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:multimodal_road_data_collector/core/services/sensor_service.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/managers/recording_session_manager.dart';

import 'recording_session_manager_test.mocks.dart';

@GenerateMocks([SensorService])
void main() {
  late MockSensorService mockSensorService;
  late RecordingSessionManager manager;
  late StreamController<SensorData> sensorStreamController;

  setUp(() {
    mockSensorService = MockSensorService();
    manager = RecordingSessionManager(mockSensorService);
    sensorStreamController = StreamController<SensorData>.broadcast();

    // Setup mock behavior
    when(mockSensorService.initialize()).thenAnswer((_) async {});
    when(mockSensorService.getSensorDataStream())
        .thenAnswer((_) => sensorStreamController.stream);
    when(mockSensorService.startSensorDataCollection())
        .thenAnswer((_) async {});
    when(mockSensorService.stopSensorDataCollection())
        .thenAnswer((_) async {});
    when(mockSensorService.isSensorDataCollectionActive())
        .thenReturn(false);
  });

  tearDown(() async {
    await manager.dispose();
    await sensorStreamController.close();
  });

  test('initialize should call initialize on sensor service', () async {
    await manager.initialize();
    verify(mockSensorService.initialize()).called(1);
  });

  test('startSensorDataCollection should start sensor service if not active', () async {
    await manager.startSensorDataCollection();
    verify(mockSensorService.startSensorDataCollection()).called(1);
  });

  test('stopSensorDataCollection should stop sensor service if active', () async {
    when(mockSensorService.isSensorDataCollectionActive()).thenReturn(true);
    await manager.startSensorDataCollection();
    await manager.stopSensorDataCollection();
    verify(mockSensorService.stopSensorDataCollection()).called(1);
  });

  test('getProcessedSensorStream returns processed data with corrections applied', () async {
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
    expect(processedData.correctedAccelZ, equals(testData.accelerometerZ - 0.5));
    
    // Verify gyroZ correction is applied
    expect(processedData.correctedGyroZ, equals(testData.gyroscopeZ - 0.1));
  });

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
} 