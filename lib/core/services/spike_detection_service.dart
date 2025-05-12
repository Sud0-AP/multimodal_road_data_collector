/// Interface for detecting and handling spikes in sensor data readings
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart';

abstract class SpikeDetectionService {
  /// Initialize the spike detection service with the provided bump threshold
  /// and refractory period.
  ///
  /// [bumpThreshold] is the calculated threshold for spike detection
  /// [refractoryPeriodMs] is the minimum time (in milliseconds) that must pass
  /// between spike detections (defaults to 8000ms / 8s)
  void initialize({
    required double bumpThreshold,
    int refractoryPeriodMs = 8000,
  });

  /// Analyze a sensor data point to determine if it represents a spike/bump
  ///
  /// Returns true if the data point exceeds the threshold and the refractory
  /// period has elapsed since the last detected spike
  bool detectSpike(CorrectedSensorDataPoint dataPoint);

  /// Get the timestamp of the last detected spike in milliseconds
  /// Returns null if no spike has been detected yet
  int? getLastSpikeTimestamp();

  /// Reset the spike detection state
  /// This should be called when ending a recording session
  void reset();

  /// Dispose of any resources
  void dispose();
}
