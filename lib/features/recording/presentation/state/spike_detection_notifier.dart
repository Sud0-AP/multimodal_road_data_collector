import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multimodal_road_data_collector/core/services/spike_detection_service.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart';

/// State for the SpikeDetectionNotifier
class SpikeDetectionState {
  /// Indicates whether a detection is currently active
  final bool isDetectionActive;

  /// The timestamp of the most recently detected spike (if any)
  final int? lastSpikeTimestampMs;

  /// Constructor
  SpikeDetectionState({
    this.isDetectionActive = false,
    this.lastSpikeTimestampMs,
  });

  /// Create a copy with modified values
  SpikeDetectionState copyWith({
    bool? isDetectionActive,
    int? lastSpikeTimestampMs,
    bool clearLastSpikeTimestamp = false,
  }) {
    return SpikeDetectionState(
      isDetectionActive: isDetectionActive ?? this.isDetectionActive,
      lastSpikeTimestampMs:
          clearLastSpikeTimestamp
              ? null
              : lastSpikeTimestampMs ?? this.lastSpikeTimestampMs,
    );
  }
}

/// Notifier for managing spike detection state
class SpikeDetectionNotifier extends StateNotifier<SpikeDetectionState> {
  /// The spike detection service
  final SpikeDetectionService _spikeDetectionService;

  /// Constructor
  SpikeDetectionNotifier(this._spikeDetectionService)
    : super(SpikeDetectionState());

  /// Initialize the spike detection with the provided threshold
  void initialize({
    required double bumpThreshold,
    int refractoryPeriodMs = 8000,
  }) {
    _spikeDetectionService.initialize(
      bumpThreshold: bumpThreshold,
      refractoryPeriodMs: refractoryPeriodMs,
    );
    state = state.copyWith(
      isDetectionActive: true,
      clearLastSpikeTimestamp: true,
    );
  }

  /// Process a sensor data point to detect spikes
  /// Returns true if a spike was detected
  bool processSensorDataPoint(CorrectedSensorDataPoint dataPoint) {
    if (!state.isDetectionActive) return false;

    final isSpike = _spikeDetectionService.detectSpike(dataPoint);

    if (isSpike) {
      // Save the timestamp of the spike for future reference
      state = state.copyWith(lastSpikeTimestampMs: dataPoint.timestampMs);
    }

    return isSpike;
  }

  /// Stop the spike detection
  void stopDetection() {
    _spikeDetectionService.reset();
    state = state.copyWith(isDetectionActive: false);
  }

  /// Reset the spike detection state
  void reset() {
    _spikeDetectionService.reset();
    state = SpikeDetectionState();
  }
}
