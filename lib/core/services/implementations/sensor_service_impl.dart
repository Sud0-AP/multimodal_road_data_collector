import 'dart:async';

import 'package:sensors_plus/sensors_plus.dart';

import '../../../core/utils/logger.dart';
import '../sensor_service.dart';

/// Implementation of SensorService using the sensors_plus package
class SensorServiceImpl implements SensorService {
  /// Stream controller for combined sensor data
  final _sensorDataStreamController = StreamController<SensorData>.broadcast();

  /// Flag indicating if sensor data collection is active
  bool _isCollectionActive = false;

  /// Subscription for accelerometer events
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  /// Subscription for gyroscope events
  StreamSubscription<GyroscopeEvent>? _gyroscopeSubscription;

  /// Latest accelerometer data
  AccelerometerEvent? _latestAccelerometerEvent;

  /// Latest gyroscope data
  GyroscopeEvent? _latestGyroscopeEvent;

  /// Timer for emitting sensor data at 100Hz
  Timer? _sensorDataEmitTimer;

  /// Last emission timestamp to monitor actual frequency
  int? _lastEmissionTimestamp;

  /// Count of emissions for frequency monitoring
  int _emissionCount = 0;

  /// Target interval between emissions in milliseconds (10ms = 100Hz)
  static const _targetIntervalMs = 10;

  @override
  Future<void> initialize() async {
    // Check if sensors are available
    try {
      // Quick check by requesting a single reading from each sensor
      await accelerometerEvents.first.timeout(
        const Duration(seconds: 1),
        onTimeout: () => throw TimeoutException('Accelerometer not responding'),
      );
      await gyroscopeEvents.first.timeout(
        const Duration(seconds: 1),
        onTimeout: () => throw TimeoutException('Gyroscope not responding'),
      );
      Logger.info('SENSOR', 'Sensors initialized successfully');
    } catch (e) {
      Logger.error('SENSOR', 'Sensor initialization failed', e);
      _sensorDataStreamController.addError(
        Exception('Sensor initialization failed: $e'),
      );
      // We don't throw here to allow the app to continue,
      // but the error will be available in the stream
    }

    if (_sensorDataStreamController.isClosed) {
      final error = StateError(
        'SensorService has been disposed and cannot be reinitialized',
      );
      Logger.critical(
        'SENSOR',
        'Cannot reinitialize disposed SensorService',
        error,
      );
      throw error;
    }
  }

  @override
  Stream<SensorData> getSensorDataStream() {
    return _sensorDataStreamController.stream;
  }

  @override
  Future<void> startSensorDataCollection() async {
    if (_isCollectionActive) {
      Logger.debug(
        'SENSOR',
        'Sensor data collection already active, ignoring start request',
      );
      return;
    }

    // Reset monitoring variables
    _lastEmissionTimestamp = null;
    _emissionCount = 0;

    // Set collection as active
    _isCollectionActive = true;
    Logger.info('SENSOR', 'Starting sensor data collection');

    // Subscribe to accelerometer events
    _accelerometerSubscription = accelerometerEvents.listen(
      (AccelerometerEvent event) {
        _latestAccelerometerEvent = event;
      },
      onError: (error) {
        // Handle errors
        Logger.error('SENSOR', 'Accelerometer error', error);
        _sensorDataStreamController.addError(
          Exception('Accelerometer error: $error'),
        );
      },
    );

    // Subscribe to gyroscope events
    _gyroscopeSubscription = gyroscopeEvents.listen(
      (GyroscopeEvent event) {
        _latestGyroscopeEvent = event;
      },
      onError: (error) {
        // Handle errors
        Logger.error('SENSOR', 'Gyroscope error', error);
        _sensorDataStreamController.addError(
          Exception('Gyroscope error: $error'),
        );
      },
    );

    // Start timer to emit sensor data at 100Hz (10ms interval)
    _sensorDataEmitTimer = Timer.periodic(
      const Duration(milliseconds: _targetIntervalMs),
      (_) => _emitCombinedSensorData(),
    );
  }

  /// Combine the latest accelerometer and gyroscope data and emit it
  void _emitCombinedSensorData() {
    // Only emit if both accelerometer and gyroscope data are available
    if (_latestAccelerometerEvent != null && _latestGyroscopeEvent != null) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Monitor actual emission frequency
      if (_lastEmissionTimestamp != null) {
        final interval = timestamp - _lastEmissionTimestamp!;
        _emissionCount++;

        // Log if we're significantly deviating from target frequency
        // (only log every 100 emissions to avoid flooding)
        if (_emissionCount % 100 == 0 &&
            (interval < _targetIntervalMs * 0.5 ||
                interval > _targetIntervalMs * 1.5)) {
          Logger.warning(
            'SENSOR',
            'Sensor emission interval ($interval ms) is deviating from target ($_targetIntervalMs ms)',
          );
        }
      }
      _lastEmissionTimestamp = timestamp;

      final sensorData = SensorData(
        accelerometerX: _latestAccelerometerEvent!.x,
        accelerometerY: _latestAccelerometerEvent!.y,
        accelerometerZ: _latestAccelerometerEvent!.z,
        gyroscopeX: _latestGyroscopeEvent!.x,
        gyroscopeY: _latestGyroscopeEvent!.y,
        gyroscopeZ: _latestGyroscopeEvent!.z,
        timestamp: timestamp,
      );

      _sensorDataStreamController.add(sensorData);
    }
  }

  @override
  Future<void> stopSensorDataCollection() async {
    if (!_isCollectionActive) {
      Logger.debug(
        'SENSOR',
        'Sensor data collection not active, ignoring stop request',
      );
      return;
    }

    Logger.info('SENSOR', 'Stopping sensor data collection');

    // Cancel accelerometer subscription
    await _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;

    // Cancel gyroscope subscription
    await _gyroscopeSubscription?.cancel();
    _gyroscopeSubscription = null;

    // Cancel timer
    _sensorDataEmitTimer?.cancel();
    _sensorDataEmitTimer = null;

    // Reset latest events
    _latestAccelerometerEvent = null;
    _latestGyroscopeEvent = null;

    // Mark collection as inactive
    _isCollectionActive = false;
  }

  @override
  bool isSensorDataCollectionActive() {
    return _isCollectionActive;
  }

  @override
  Future<void> dispose() async {
    Logger.debug('SENSOR', 'Disposing SensorService');

    // Stop data collection if active
    await stopSensorDataCollection();

    // Close stream controller
    await _sensorDataStreamController.close();
  }
}
