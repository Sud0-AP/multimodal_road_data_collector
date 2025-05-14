/// Data class representing all information from a completed recording session
/// needed to generate the metadata.txt file
class RecordingCompletionData {
  /// Unique session ID (typically YYYYMMDD_HHMMSS format)
  final String sessionId;

  /// Duration of recording in seconds
  final int durationSeconds;

  /// NTP-synchronized timestamp when recording started
  final DateTime? videoStartNtp;

  /// NTP-synchronized timestamp when recording ended
  final DateTime? videoEndNtp;

  /// NTP-synchronized timestamp when sensor stream started
  final DateTime? sensorStartNtp;

  /// NTP-synchronized timestamp when sensor stream ended
  final DateTime? sensorEndNtp;

  /// Monotonic clock timestamp in milliseconds when sensor stream started
  final int? sensorStartMonotonicMs;

  /// Monotonic clock timestamp in milliseconds when sensor stream ended
  final int? sensorEndMonotonicMs;

  /// Actual measured sensor sampling rate in Hz
  final double? actualSamplingRateHz;

  /// Video resolution in "width x height" format
  final String? videoResolution;

  /// Orientation mode detected during calibration
  final String orientationMode;

  /// Initial accelerometer X-axis offset from calibration
  final double accelOffsetX;

  /// Initial accelerometer Y-axis offset from calibration
  final double accelOffsetY;

  /// Initial accelerometer Z-axis offset from calibration
  final double accelOffsetZ;

  /// Initial gyroscope X-axis offset from calibration
  final double gyroOffsetX;

  /// Initial gyroscope Y-axis offset from calibration
  final double gyroOffsetY;

  /// Initial gyroscope Z-axis offset from calibration
  final double gyroOffsetZ;

  /// Final adjusted Z-axis offset used for this session
  final double sessionAdjustedAccelZ;

  /// Bump detection threshold calculated during pre-recording calibration
  final double bumpThreshold;

  /// Gyroscope drift in degrees measured during pre-recording calibration
  final double gyroZDrift;

  /// Timestamp when the calibration was performed (in milliseconds since epoch)
  final int? calibrationTimestamp;

  /// Number of samples used during calibration
  final int calibrationSamplesCount;

  /// Any significant warnings or issues encountered during recording
  final List<String> warnings;

  /// Constructor
  RecordingCompletionData({
    required this.sessionId,
    required this.durationSeconds,
    required this.orientationMode,
    required this.accelOffsetX,
    required this.accelOffsetY,
    required this.accelOffsetZ,
    required this.gyroOffsetX,
    required this.gyroOffsetY,
    required this.gyroOffsetZ,
    required this.sessionAdjustedAccelZ,
    required this.bumpThreshold,
    required this.gyroZDrift,
    this.calibrationTimestamp,
    this.calibrationSamplesCount = 0,
    this.videoStartNtp,
    this.videoEndNtp,
    this.sensorStartNtp,
    this.sensorEndNtp,
    this.sensorStartMonotonicMs,
    this.sensorEndMonotonicMs,
    this.actualSamplingRateHz,
    this.videoResolution,
    this.warnings = const [],
  });

  /// Create a copy of this RecordingCompletionData with optional parameter changes
  RecordingCompletionData copyWith({
    String? sessionId,
    int? durationSeconds,
    DateTime? videoStartNtp,
    DateTime? videoEndNtp,
    DateTime? sensorStartNtp,
    DateTime? sensorEndNtp,
    int? sensorStartMonotonicMs,
    int? sensorEndMonotonicMs,
    double? actualSamplingRateHz,
    String? videoResolution,
    String? orientationMode,
    double? accelOffsetX,
    double? accelOffsetY,
    double? accelOffsetZ,
    double? gyroOffsetX,
    double? gyroOffsetY,
    double? gyroOffsetZ,
    double? sessionAdjustedAccelZ,
    double? bumpThreshold,
    double? gyroZDrift,
    int? calibrationTimestamp,
    int? calibrationSamplesCount,
    List<String>? warnings,
  }) {
    return RecordingCompletionData(
      sessionId: sessionId ?? this.sessionId,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      videoStartNtp: videoStartNtp ?? this.videoStartNtp,
      videoEndNtp: videoEndNtp ?? this.videoEndNtp,
      sensorStartNtp: sensorStartNtp ?? this.sensorStartNtp,
      sensorEndNtp: sensorEndNtp ?? this.sensorEndNtp,
      sensorStartMonotonicMs:
          sensorStartMonotonicMs ?? this.sensorStartMonotonicMs,
      sensorEndMonotonicMs: sensorEndMonotonicMs ?? this.sensorEndMonotonicMs,
      actualSamplingRateHz: actualSamplingRateHz ?? this.actualSamplingRateHz,
      videoResolution: videoResolution ?? this.videoResolution,
      orientationMode: orientationMode ?? this.orientationMode,
      accelOffsetX: accelOffsetX ?? this.accelOffsetX,
      accelOffsetY: accelOffsetY ?? this.accelOffsetY,
      accelOffsetZ: accelOffsetZ ?? this.accelOffsetZ,
      gyroOffsetX: gyroOffsetX ?? this.gyroOffsetX,
      gyroOffsetY: gyroOffsetY ?? this.gyroOffsetY,
      gyroOffsetZ: gyroOffsetZ ?? this.gyroOffsetZ,
      sessionAdjustedAccelZ:
          sessionAdjustedAccelZ ?? this.sessionAdjustedAccelZ,
      bumpThreshold: bumpThreshold ?? this.bumpThreshold,
      gyroZDrift: gyroZDrift ?? this.gyroZDrift,
      calibrationTimestamp: calibrationTimestamp ?? this.calibrationTimestamp,
      calibrationSamplesCount:
          calibrationSamplesCount ?? this.calibrationSamplesCount,
      warnings: warnings ?? this.warnings,
    );
  }

  /// Convert this RecordingCompletionData to a map
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'durationSeconds': durationSeconds,
      'videoStartNtp': videoStartNtp?.toIso8601String(),
      'videoEndNtp': videoEndNtp?.toIso8601String(),
      'sensorStartNtp': sensorStartNtp?.toIso8601String(),
      'sensorEndNtp': sensorEndNtp?.toIso8601String(),
      'sensorStartMonotonicMs': sensorStartMonotonicMs,
      'sensorEndMonotonicMs': sensorEndMonotonicMs,
      'actualSamplingRateHz': actualSamplingRateHz,
      'videoResolution': videoResolution,
      'orientationMode': orientationMode,
      'accelOffsetX': accelOffsetX,
      'accelOffsetY': accelOffsetY,
      'accelOffsetZ': accelOffsetZ,
      'gyroOffsetX': gyroOffsetX,
      'gyroOffsetY': gyroOffsetY,
      'gyroOffsetZ': gyroOffsetZ,
      'sessionAdjustedAccelZ': sessionAdjustedAccelZ,
      'bumpThreshold': bumpThreshold,
      'gyroZDrift': gyroZDrift,
      'calibrationTimestamp': calibrationTimestamp,
      'calibrationSamplesCount': calibrationSamplesCount,
      'warnings': warnings,
    };
  }

  @override
  String toString() {
    return 'RecordingCompletionData('
        'sessionId: $sessionId, '
        'durationSeconds: $durationSeconds, '
        'videoResolution: $videoResolution, '
        'orientationMode: $orientationMode, '
        'bumpThreshold: $bumpThreshold)';
  }
}
