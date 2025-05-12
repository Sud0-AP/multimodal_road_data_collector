import 'package:multimodal_road_data_collector/core/services/spike_detection_service.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart';

/// Implementation of SpikeDetectionService that analyzes corrected accelerometer
/// data to detect spikes based on a threshold value
class SpikeDetectionServiceImpl implements SpikeDetectionService {
  /// The calculated threshold for spike detection
  double _bumpThreshold = 0.0;

  /// Refractory period in milliseconds to prevent multiple detections
  /// for the same event
  int _refractoryPeriodMs = 8000;

  /// Timestamp of the last detected spike (null if no spike has been detected)
  int? _lastSpikeTimestampMs;

  /// Last spike magnitude value
  double? _lastSpikeMagnitude;

  /// Minimum difference in magnitude required for a new detection during refractory period
  static const double _minMagnitudeDifference = 4.0;

  /// The number of consecutive readings that must exceed threshold to detect a spike
  static const int _requiredConsecutiveReadings = 2;

  /// Count of current consecutive readings above threshold
  int _consecutiveReadingsAboveThreshold = 0;

  /// Previous magnitude value for consecutive checks
  double? _previousMagnitude;

  /// Flag to track if the service has been initialized
  bool _isInitialized = false;

  @override
  void initialize({
    required double bumpThreshold,
    int refractoryPeriodMs = 8000,
  }) {
    _bumpThreshold = bumpThreshold;
    _refractoryPeriodMs = refractoryPeriodMs;
    _lastSpikeTimestampMs = null;
    _lastSpikeMagnitude = null;
    _consecutiveReadingsAboveThreshold = 0;
    _previousMagnitude = null;
    _isInitialized = true;
  }

  @override
  bool detectSpike(CorrectedSensorDataPoint dataPoint) {
    if (!_isInitialized) {
      throw StateError('SpikeDetectionService must be initialized before use');
    }

    final currentTimestamp = dataPoint.timestampMs;
    final magnitude = dataPoint.accelMagnitude;

    // Reset consecutive count if magnitude doesn't exceed threshold
    // or if it's too similar to the previous reading
    if (magnitude <= _bumpThreshold ||
        (_previousMagnitude != null &&
            (magnitude - _previousMagnitude!).abs() < 0.05)) {
      _consecutiveReadingsAboveThreshold = 0;
      _previousMagnitude = magnitude;
      return false;
    }

    // Increment consecutive readings counter
    _consecutiveReadingsAboveThreshold++;
    _previousMagnitude = magnitude;

    // Only proceed with spike detection if we have enough consecutive readings
    if (_consecutiveReadingsAboveThreshold < _requiredConsecutiveReadings) {
      return false;
    }

    // Check if the magnitude exceeds the threshold
    if (magnitude > _bumpThreshold) {
      // First case: This is the first spike or we're outside the refractory period
      if (_lastSpikeTimestampMs == null ||
          (currentTimestamp - _lastSpikeTimestampMs!) >= _refractoryPeriodMs) {
        // Update the last spike information
        _lastSpikeTimestampMs = currentTimestamp;
        _lastSpikeMagnitude = magnitude;
        return true;
      }
      // Second case: Within refractory period but significantly stronger spike
      // Only detect if the new spike is substantially stronger than the previous one
      else if (_lastSpikeMagnitude != null &&
          magnitude > (_lastSpikeMagnitude! + _minMagnitudeDifference)) {
        // Update the last spike information
        _lastSpikeTimestampMs = currentTimestamp;
        _lastSpikeMagnitude = magnitude;
        return true;
      }
    }

    return false;
  }

  @override
  int? getLastSpikeTimestamp() {
    return _lastSpikeTimestampMs;
  }

  @override
  void reset() {
    _lastSpikeTimestampMs = null;
    _lastSpikeMagnitude = null;
    _consecutiveReadingsAboveThreshold = 0;
    _previousMagnitude = null;
  }

  @override
  void dispose() {
    // No resources to dispose in this implementation
  }
}
