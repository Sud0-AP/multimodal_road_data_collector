import 'dart:convert';

/// Data class representing pre-recording calibration results used during a recording session
class PreRecordingCalibrationResult {
  /// Adjusted Z-axis acceleration offset for the current recording session (in m/s²)
  final double sessionAccelOffsetZ;

  /// Z-axis gyroscope drift value measured during pre-recording calibration (in rad/s)
  final double gyroZDrift;

  /// Calculated bump threshold based on acceleration magnitude during smooth driving (in m/s²)
  final double bumpThreshold;

  /// Standard deviation of acceleration magnitude used in threshold calculation (for diagnostics)
  final double accelMagnitudeStdDev;

  /// Timestamp when the calibration was performed
  final int timestamp;

  /// Whether the pre-recording calibration completed successfully
  final bool isCalibrationSuccessful;

  /// Creates a new [PreRecordingCalibrationResult]
  PreRecordingCalibrationResult({
    required this.sessionAccelOffsetZ,
    required this.gyroZDrift,
    required this.bumpThreshold,
    required this.accelMagnitudeStdDev,
    required this.timestamp,
    required this.isCalibrationSuccessful,
  });

  /// Default constructor with zero values
  factory PreRecordingCalibrationResult.initial() {
    return PreRecordingCalibrationResult(
      sessionAccelOffsetZ: 0.0,
      gyroZDrift: 0.0,
      bumpThreshold: 0.0,
      accelMagnitudeStdDev: 0.0,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isCalibrationSuccessful: false,
    );
  }

  /// Create a copy of this [PreRecordingCalibrationResult] with optional parameter changes
  PreRecordingCalibrationResult copyWith({
    double? sessionAccelOffsetZ,
    double? gyroZDrift,
    double? bumpThreshold,
    double? accelMagnitudeStdDev,
    int? timestamp,
    bool? isCalibrationSuccessful,
  }) {
    return PreRecordingCalibrationResult(
      sessionAccelOffsetZ: sessionAccelOffsetZ ?? this.sessionAccelOffsetZ,
      gyroZDrift: gyroZDrift ?? this.gyroZDrift,
      bumpThreshold: bumpThreshold ?? this.bumpThreshold,
      accelMagnitudeStdDev: accelMagnitudeStdDev ?? this.accelMagnitudeStdDev,
      timestamp: timestamp ?? this.timestamp,
      isCalibrationSuccessful:
          isCalibrationSuccessful ?? this.isCalibrationSuccessful,
    );
  }

  /// Convert the model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'sessionAccelOffsetZ': sessionAccelOffsetZ,
      'gyroZDrift': gyroZDrift,
      'bumpThreshold': bumpThreshold,
      'accelMagnitudeStdDev': accelMagnitudeStdDev,
      'timestamp': timestamp,
      'isCalibrationSuccessful': isCalibrationSuccessful,
    };
  }

  /// Create an [PreRecordingCalibrationResult] from a JSON map
  factory PreRecordingCalibrationResult.fromJson(Map<String, dynamic> json) {
    return PreRecordingCalibrationResult(
      sessionAccelOffsetZ: json['sessionAccelOffsetZ'],
      gyroZDrift: json['gyroZDrift'],
      bumpThreshold: json['bumpThreshold'],
      accelMagnitudeStdDev: json['accelMagnitudeStdDev'],
      timestamp: json['timestamp'],
      isCalibrationSuccessful: json['isCalibrationSuccessful'],
    );
  }

  /// Serialize to a JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create from a JSON string
  factory PreRecordingCalibrationResult.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return PreRecordingCalibrationResult.fromJson(json);
  }

  @override
  String toString() {
    return 'PreRecordingCalibrationResult('
        'sessionAccelOffsetZ: $sessionAccelOffsetZ, '
        'gyroZDrift: $gyroZDrift, '
        'bumpThreshold: $bumpThreshold, '
        'accelMagnitudeStdDev: $accelMagnitudeStdDev, '
        'timestamp: $timestamp, '
        'isCalibrationSuccessful: $isCalibrationSuccessful)';
  }
}
