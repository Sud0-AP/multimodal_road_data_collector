import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_road_data_collector/core/services/sensor_service.dart';
import 'package:multimodal_road_data_collector/core/services/implementations/sensor_service_impl.dart';

// Creating a test-specific MockSensorService instead of extending SensorServiceImpl
class MockSensorService implements SensorService {
  final _sensorDataStreamController = StreamController<SensorData>.broadcast();
  bool _isCollectionActive = false;

  @override
  Future<void> dispose() async {
    if (!_sensorDataStreamController.isClosed) {
      await _sensorDataStreamController.close();
    }
  }

  @override
  Stream<SensorData> getSensorDataStream() {
    return _sensorDataStreamController.stream;
  }

  @override
  Future<void> initialize() async {
    // No-op for testing
  }

  @override
  bool isSensorDataCollectionActive() {
    return _isCollectionActive;
  }

  @override
  Future<void> startSensorDataCollection() async {
    _isCollectionActive = true;
  }

  @override
  Future<void> stopSensorDataCollection() async {
    _isCollectionActive = false;
  }
}

void main() {
  // Initialize Flutter binding
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSensorService sensorService;

  setUp(() {
    sensorService = MockSensorService();
  });

  tearDown(() async {
    await sensorService.dispose();
  });

  test('initialize should not throw', () async {
    // Act & Assert
    expect(sensorService.initialize(), completes);
  });

  test('getSensorDataStream should return a non-null stream', () {
    // Act
    final stream = sensorService.getSensorDataStream();

    // Assert
    expect(stream, isNotNull);
  });

  test('isSensorDataCollectionActive should return false initially', () {
    // Assert
    expect(sensorService.isSensorDataCollectionActive(), isFalse);
  });

  test(
    'startSensorDataCollection should set isCollectionActive to true',
    () async {
      // Act
      await sensorService.startSensorDataCollection();

      // Assert
      expect(sensorService.isSensorDataCollectionActive(), isTrue);

      // Cleanup
      await sensorService.stopSensorDataCollection();
    },
  );

  test(
    'stopSensorDataCollection should set isCollectionActive to false',
    () async {
      // Arrange
      await sensorService.startSensorDataCollection();
      expect(sensorService.isSensorDataCollectionActive(), isTrue);

      // Act
      await sensorService.stopSensorDataCollection();

      // Assert
      expect(sensorService.isSensorDataCollectionActive(), isFalse);
    },
  );

  test('SensorData copyWith works correctly', () {
    // Arrange
    final originalData = SensorData(
      accelerometerX: 1.0,
      accelerometerY: 2.0,
      accelerometerZ: 3.0,
      gyroscopeX: 4.0,
      gyroscopeY: 5.0,
      gyroscopeZ: 6.0,
      timestamp: 123456789,
    );

    // Act
    final modifiedData = originalData.copyWith(
      accelerometerX: 10.0,
      gyroscopeY: 50.0,
    );

    // Assert
    expect(modifiedData.accelerometerX, 10.0);
    expect(modifiedData.accelerometerY, 2.0);
    expect(modifiedData.accelerometerZ, 3.0);
    expect(modifiedData.gyroscopeX, 4.0);
    expect(modifiedData.gyroscopeY, 50.0);
    expect(modifiedData.gyroscopeZ, 6.0);
    expect(modifiedData.timestamp, 123456789);
  });

  test('SensorData toString returns the expected format', () {
    // Arrange
    final sensorData = SensorData(
      accelerometerX: 1.0,
      accelerometerY: 2.0,
      accelerometerZ: 3.0,
      gyroscopeX: 4.0,
      gyroscopeY: 5.0,
      gyroscopeZ: 6.0,
      timestamp: 123456789,
    );

    // Act
    final stringRepresentation = sensorData.toString();

    // Assert
    expect(
      stringRepresentation,
      'SensorData(accelerometerX: 1.0, accelerometerY: 2.0, accelerometerZ: 3.0, gyroscopeX: 4.0, gyroscopeY: 5.0, gyroscopeZ: 6.0, timestamp: 123456789)',
    );
  });
}
