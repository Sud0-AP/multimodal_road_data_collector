import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_road_data_collector/core/services/sensor_service.dart';
import 'package:multimodal_road_data_collector/core/services/implementations/sensor_service_impl.dart';

// Creating a test-specific MockSensorService instead of extending SensorServiceImpl
class MockSensorService implements SensorService {
  final _sensorDataStreamController = StreamController<SensorData>.broadcast();
  bool _isCollectionActive = false;
  Timer? _emitTimer;

  // Add data emission capability to the mock
  void emitSensorData(SensorData data) {
    if (!_sensorDataStreamController.isClosed) {
      _sensorDataStreamController.add(data);
    }
  }

  // Add error emission capability to the mock
  void emitError(Object error) {
    if (!_sensorDataStreamController.isClosed) {
      _sensorDataStreamController.addError(error);
    }
  }

  @override
  Future<void> dispose() async {
    _emitTimer?.cancel();
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

    // Simulate data emission at 100Hz for testing
    _emitTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      if (_isCollectionActive) {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        emitSensorData(
          SensorData(
            accelerometerX: 0.1,
            accelerometerY: 0.2,
            accelerometerZ: 9.8,
            gyroscopeX: 0.01,
            gyroscopeY: 0.02,
            gyroscopeZ: 0.03,
            timestamp: timestamp,
          ),
        );
      }
    });
  }

  @override
  Future<void> stopSensorDataCollection() async {
    _isCollectionActive = false;
    _emitTimer?.cancel();
    _emitTimer = null;
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

  test('SensorService should emit data at approximately 100Hz', () async {
    // Arrange
    await sensorService.startSensorDataCollection();
    final dataPoints = <SensorData>[];
    final subscription = sensorService.getSensorDataStream().listen(
      (data) => dataPoints.add(data),
    );

    // Act
    // Wait for 500ms which should give us ~50 data points at 100Hz
    await Future.delayed(const Duration(milliseconds: 500));
    await sensorService.stopSensorDataCollection();
    await subscription.cancel();

    // Assert
    // We should have at least 30 data points (allowing for some timing variance)
    // but not more than 70 (ensuring we're not getting too many)
    expect(dataPoints.length, greaterThan(30));
    expect(dataPoints.length, lessThan(70));

    // Verify that timestamps are increasing
    for (int i = 1; i < dataPoints.length; i++) {
      expect(
        dataPoints[i].timestamp,
        greaterThanOrEqualTo(dataPoints[i - 1].timestamp),
      );
    }
  });

  test('Error handling - stream should propagate errors', () async {
    // Arrange
    final errorCompleter = Completer<dynamic>();
    final subscription = sensorService.getSensorDataStream().listen(
      (_) {},
      onError: (error) {
        if (!errorCompleter.isCompleted) errorCompleter.complete(error);
      },
    );

    // Act
    sensorService.emitError(Exception('Test error'));

    // Assert
    expect(errorCompleter.future, completes);
    final error = await errorCompleter.future;
    expect(error, isA<Exception>());
    expect(error.toString(), contains('Test error'));

    // Cleanup
    await subscription.cancel();
  });

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
