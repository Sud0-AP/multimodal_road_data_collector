import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/sensor_service.dart';
import '../../../../core/services/providers.dart';

/// Processed sensor data for recording and calibration
class ProcessedSensorData {
  /// Original raw sensor data
  final SensorData rawData;

  /// Corrected Z-axis acceleration (with initial calibration applied)
  final double correctedAccelZ;

  /// Corrected Z-axis gyroscope reading (with initial calibration applied)
  final double correctedGyroZ;

  /// Acceleration magnitude (calculated from X, Y, Z components)
  final double accelMagnitude;

  /// Whether this data point represents a bump/pothole detection
  final bool isBumpDetected;

  /// Constructor
  ProcessedSensorData({
    required this.rawData,
    required this.correctedAccelZ,
    required this.correctedGyroZ,
    required this.accelMagnitude,
    this.isBumpDetected = false,
  });
}

/// Manager responsible for handling sensor data during recording sessions
class RecordingSessionManager {
  /// Instance of SensorService for raw data access
  final SensorService _sensorService;

  /// StreamController for processed sensor data
  final _processedDataController =
      StreamController<ProcessedSensorData>.broadcast();

  /// Subscription to the sensor data stream
  StreamSubscription<SensorData>? _sensorDataSubscription;

  /// Flag indicating if data collection is active
  bool _isDataCollectionActive = false;

  /// Initial calibration values for sensor corrections
  /// These should be set from initial calibration (Task 2)
  double _accelZOffset = 0.0;
  double _gyroZOffset = 0.0;
  bool _swapXY = false;

  /// Session-specific calibration values (from pre-recording calibration)
  double _sessionAccelOffsetZ = 0.0;
  double _gyroZDrift = 0.0;
  double _bumpThreshold = 0.0;
  bool _useSessionParameters = false;

  /// Constructor
  RecordingSessionManager(this._sensorService);

  /// Initialize the manager
  Future<void> initialize() async {
    await _sensorService.initialize();
  }

  /// Get stream of processed sensor data
  Stream<ProcessedSensorData> getProcessedSensorStream() {
    return _processedDataController.stream;
  }

  /// Start collecting sensor data
  Future<void> startSensorDataCollection() async {
    if (_isDataCollectionActive) {
      return;
    }

    // Initialize sensor service if needed
    if (!_sensorService.isSensorDataCollectionActive()) {
      await _sensorService.startSensorDataCollection();
    }

    // Subscribe to sensor data stream
    _sensorDataSubscription = _sensorService.getSensorDataStream().listen(
      _processSensorData,
      onError: (error) {
        _processedDataController.addError(error);
      },
    );

    _isDataCollectionActive = true;
  }

  /// Stop collecting sensor data
  Future<void> stopSensorDataCollection() async {
    if (!_isDataCollectionActive) {
      return;
    }

    // Cancel subscription
    await _sensorDataSubscription?.cancel();
    _sensorDataSubscription = null;

    // Stop sensor service if needed
    if (_sensorService.isSensorDataCollectionActive()) {
      await _sensorService.stopSensorDataCollection();
    }

    _isDataCollectionActive = false;
  }

  /// Set calibration values for sensor corrections
  void setCalibrationParameters({
    double accelZOffset = 0.0,
    double gyroZOffset = 0.0,
    bool swapXY = false,
  }) {
    _accelZOffset = accelZOffset;
    _gyroZOffset = gyroZOffset;
    _swapXY = swapXY;
  }

  /// Set session-specific calibration parameters from pre-recording calibration
  void setSessionCalibrationParameters({
    required double sessionAccelOffsetZ,
    required double gyroZDrift,
    required double bumpThreshold,
    bool useSessionParameters = true,
  }) {
    _sessionAccelOffsetZ = sessionAccelOffsetZ;
    _gyroZDrift = gyroZDrift;
    _bumpThreshold = bumpThreshold;
    _useSessionParameters = useSessionParameters;
  }

  /// Clear session-specific calibration parameters
  void clearSessionCalibrationParameters() {
    _sessionAccelOffsetZ = 0.0;
    _gyroZDrift = 0.0;
    _bumpThreshold = 0.0;
    _useSessionParameters = false;
  }

  /// Process raw sensor data and apply corrections
  void _processSensorData(SensorData data) {
    // Apply sensor corrections based on initial calibration
    double accelX = data.accelerometerX;
    double accelY = data.accelerometerY;

    // Swap X and Y if required by calibration
    if (_swapXY) {
      final temp = accelX;
      accelX = accelY;
      accelY = temp;
    }

    // Apply initial Z-offset correction
    double correctedAccelZ = data.accelerometerZ - _accelZOffset;

    // Apply session-specific Z-offset if available
    if (_useSessionParameters) {
      correctedAccelZ -= _sessionAccelOffsetZ;
    }

    // Apply initial gyro Z-offset correction
    double correctedGyroZ = data.gyroscopeZ - _gyroZOffset;

    // Apply session-specific gyro drift correction if available
    if (_useSessionParameters) {
      correctedGyroZ -= _gyroZDrift;
    }

    // Calculate acceleration magnitude (for bump detection)
    final accelMagnitude = sqrt(
      accelX * accelX + accelY * accelY + correctedAccelZ * correctedAccelZ,
    );

    // Detect bumps if threshold is set
    bool isBumpDetected = false;
    if (_useSessionParameters && _bumpThreshold > 0) {
      isBumpDetected = accelMagnitude > _bumpThreshold;
    }

    // Create processed data
    final processedData = ProcessedSensorData(
      rawData: data,
      correctedAccelZ: correctedAccelZ,
      correctedGyroZ: correctedGyroZ,
      accelMagnitude: accelMagnitude,
      isBumpDetected: isBumpDetected,
    );

    // Add to stream
    _processedDataController.add(processedData);
  }

  /// Check if data collection is active
  bool isDataCollectionActive() {
    return _isDataCollectionActive;
  }

  /// Check if initial calibration has been completed
  /// Returns true if calibration parameters have been set
  bool isInitialCalibrationDone() {
    // Check if any calibration values have been set
    // This is a simple check - you may want to enhance this with persistent storage
    // to properly track calibration status across app restarts
    return _accelZOffset != 0.0 || _gyroZOffset != 0.0 || _swapXY;
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await stopSensorDataCollection();
    await _processedDataController.close();
  }
}

/// Provider for RecordingSessionManager
final recordingSessionManagerProvider = Provider<RecordingSessionManager>((
  ref,
) {
  final sensorService = ref.watch(sensorServiceProvider);
  return RecordingSessionManager(sensorService);
});
