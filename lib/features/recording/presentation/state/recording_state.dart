import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The different states of recording
enum RecordingStatus {
  /// Initial state, camera not initialized
  initial,

  /// Camera is initializing
  initializing,

  /// Ready to record
  ready,

  /// Pre-recording calibration phase
  calibrating,

  /// Currently recording
  recording,

  /// Recording has been stopped, but not yet saved
  stopped,

  /// Recording has been saved to a session
  saved,

  /// Error occurred during recording
  error,
}

/// State class for the recording screen
class RecordingState {
  /// Current status of the recording
  final RecordingStatus status;

  /// Path to the recorded video file (if any)
  final String? videoPath;

  /// Path to the session directory (if any)
  final String? sessionPath;

  /// Error message (if any)
  final String? errorMessage;

  /// Duration of the recording in seconds
  final int recordingDurationSeconds;

  /// Whether pre-recording calibration is complete
  final bool isPreRecordingCalibrationComplete;

  /// Session-specific Z-axis accelerometer offset (after pre-recording calibration)
  final double? sessionAccelOffsetZ;

  /// Session-specific gyroscope drift value
  final double? gyroZDrift;

  /// Session-specific bump threshold
  final double? bumpThreshold;

  /// Timestamp when the calibration was performed
  final int? calibrationTimestamp;

  /// Number of samples used during calibration
  final int? calibrationSamplesCount;

  /// Constructor
  const RecordingState({
    this.status = RecordingStatus.initial,
    this.videoPath,
    this.sessionPath,
    this.errorMessage,
    this.recordingDurationSeconds = 0,
    this.isPreRecordingCalibrationComplete = false,
    this.sessionAccelOffsetZ,
    this.gyroZDrift,
    this.bumpThreshold,
    this.calibrationTimestamp,
    this.calibrationSamplesCount,
  });

  /// Create a copy of this state with the given fields replaced
  RecordingState copyWith({
    RecordingStatus? status,
    String? videoPath,
    String? sessionPath,
    String? errorMessage,
    int? recordingDurationSeconds,
    bool? isPreRecordingCalibrationComplete,
    double? sessionAccelOffsetZ,
    double? gyroZDrift,
    double? bumpThreshold,
    int? calibrationTimestamp,
    int? calibrationSamplesCount,
  }) {
    return RecordingState(
      status: status ?? this.status,
      videoPath: videoPath ?? this.videoPath,
      sessionPath: sessionPath ?? this.sessionPath,
      errorMessage: errorMessage ?? this.errorMessage,
      recordingDurationSeconds:
          recordingDurationSeconds ?? this.recordingDurationSeconds,
      isPreRecordingCalibrationComplete:
          isPreRecordingCalibrationComplete ??
          this.isPreRecordingCalibrationComplete,
      sessionAccelOffsetZ: sessionAccelOffsetZ ?? this.sessionAccelOffsetZ,
      gyroZDrift: gyroZDrift ?? this.gyroZDrift,
      bumpThreshold: bumpThreshold ?? this.bumpThreshold,
      calibrationTimestamp: calibrationTimestamp ?? this.calibrationTimestamp,
      calibrationSamplesCount:
          calibrationSamplesCount ?? this.calibrationSamplesCount,
    );
  }
}

/// State notifier for the recording screen
class RecordingStateNotifier extends StateNotifier<RecordingState> {
  /// Constructor
  RecordingStateNotifier() : super(const RecordingState());

  /// Initialize the camera
  void initialize() {
    state = state.copyWith(status: RecordingStatus.initializing);
    // Actual initialization will be handled in the recording screen
  }

  /// Set the state to ready after camera initialization
  void setReady() {
    state = state.copyWith(status: RecordingStatus.ready);
  }

  /// Start pre-recording calibration phase
  void startCalibration() {
    state = state.copyWith(
      status: RecordingStatus.calibrating,
      isPreRecordingCalibrationComplete: false,
    );
  }

  /// Complete pre-recording calibration with results
  void completeCalibration({
    required double sessionAccelOffsetZ,
    required double gyroZDrift,
    required double bumpThreshold,
    int? calibrationTimestamp,
    int? calibrationSamplesCount,
  }) {
    state = state.copyWith(
      status: RecordingStatus.recording,
      isPreRecordingCalibrationComplete: true,
      sessionAccelOffsetZ: sessionAccelOffsetZ,
      gyroZDrift: gyroZDrift,
      bumpThreshold: bumpThreshold,
      recordingDurationSeconds: 0,
      calibrationTimestamp: calibrationTimestamp,
      calibrationSamplesCount: calibrationSamplesCount,
    );
  }

  /// Fail pre-recording calibration
  void failCalibration() {
    state = state.copyWith(
      status: RecordingStatus.ready,
      isPreRecordingCalibrationComplete: false,
    );
  }

  /// Start recording
  void startRecording() {
    state = state.copyWith(
      status: RecordingStatus.recording,
      recordingDurationSeconds: 0,
    );
  }

  /// Update recording duration
  void updateDuration(int seconds) {
    state = state.copyWith(recordingDurationSeconds: seconds);
  }

  /// Stop recording
  void stopRecording(String videoPath) {
    state = state.copyWith(
      status: RecordingStatus.stopped,
      videoPath: videoPath,
    );
  }

  /// Save recording to session
  void saveRecording(String sessionPath) {
    state = state.copyWith(
      status: RecordingStatus.saved,
      sessionPath: sessionPath,
    );
  }

  /// Set session path directly
  void setSessionPath(String sessionPath) {
    state = state.copyWith(sessionPath: sessionPath);
  }

  /// Set error state
  void setError(String message) {
    state = state.copyWith(
      status: RecordingStatus.error,
      errorMessage: message,
    );
  }

  /// Reset to ready state
  void reset() {
    state = const RecordingState(status: RecordingStatus.ready);
  }
}

/// Provider for the recording state
final recordingStateProvider =
    StateNotifierProvider<RecordingStateNotifier, RecordingState>((ref) {
      return RecordingStateNotifier();
    });
