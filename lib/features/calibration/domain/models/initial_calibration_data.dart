import 'dart:convert';

/// Enum representing device orientations that can be detected during calibration
enum DeviceOrientation {
  /// Device is in portrait orientation
  portrait,

  /// Device is in landscape orientation (rotated right)
  landscapeRight,

  /// Device is in landscape orientation (rotated left)
  landscapeLeft,

  /// Device is laying flat on a surface, screen facing up
  flat,

  /// Device orientation is unknown or not yet determined
  unknown,
}

/// Data class representing the calibration data collected during initial calibration
class InitialCalibrationData {
  /// The orientation of the device during calibration
  final DeviceOrientation deviceOrientation;

  /// X-axis accelerometer offset/bias in m/s²
  final double accelerometerXOffset;

  /// Y-axis accelerometer offset/bias in m/s²
  final double accelerometerYOffset;

  /// Z-axis accelerometer offset/bias in m/s²
  final double accelerometerZOffset;

  /// X-axis gyroscope offset/bias in rad/s
  final double gyroscopeXOffset;

  /// Y-axis gyroscope offset/bias in rad/s
  final double gyroscopeYOffset;

  /// Z-axis gyroscope offset/bias in rad/s
  final double gyroscopeZOffset;

  /// Timestamp when the calibration was performed
  final int calibrationTimestamp;

  /// Creates an instance of [InitialCalibrationData]
  InitialCalibrationData({
    required this.deviceOrientation,
    required this.accelerometerXOffset,
    required this.accelerometerYOffset,
    required this.accelerometerZOffset,
    required this.gyroscopeXOffset,
    required this.gyroscopeYOffset,
    required this.gyroscopeZOffset,
    required this.calibrationTimestamp,
  });

  /// Default constructor with zero values for offsets
  factory InitialCalibrationData.initial() {
    return InitialCalibrationData(
      deviceOrientation: DeviceOrientation.unknown,
      accelerometerXOffset: 0.0,
      accelerometerYOffset: 0.0,
      accelerometerZOffset: 0.0,
      gyroscopeXOffset: 0.0,
      gyroscopeYOffset: 0.0,
      gyroscopeZOffset: 0.0,
      calibrationTimestamp: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// Create a copy of this [InitialCalibrationData] with optional parameter changes
  InitialCalibrationData copyWith({
    DeviceOrientation? deviceOrientation,
    double? accelerometerXOffset,
    double? accelerometerYOffset,
    double? accelerometerZOffset,
    double? gyroscopeXOffset,
    double? gyroscopeYOffset,
    double? gyroscopeZOffset,
    int? calibrationTimestamp,
  }) {
    return InitialCalibrationData(
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      accelerometerXOffset: accelerometerXOffset ?? this.accelerometerXOffset,
      accelerometerYOffset: accelerometerYOffset ?? this.accelerometerYOffset,
      accelerometerZOffset: accelerometerZOffset ?? this.accelerometerZOffset,
      gyroscopeXOffset: gyroscopeXOffset ?? this.gyroscopeXOffset,
      gyroscopeYOffset: gyroscopeYOffset ?? this.gyroscopeYOffset,
      gyroscopeZOffset: gyroscopeZOffset ?? this.gyroscopeZOffset,
      calibrationTimestamp: calibrationTimestamp ?? this.calibrationTimestamp,
    );
  }

  /// Convert the model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'deviceOrientation': deviceOrientation.toString().split('.').last,
      'accelerometerXOffset': accelerometerXOffset,
      'accelerometerYOffset': accelerometerYOffset,
      'accelerometerZOffset': accelerometerZOffset,
      'gyroscopeXOffset': gyroscopeXOffset,
      'gyroscopeYOffset': gyroscopeYOffset,
      'gyroscopeZOffset': gyroscopeZOffset,
      'calibrationTimestamp': calibrationTimestamp,
    };
  }

  /// Create an [InitialCalibrationData] from a JSON map
  factory InitialCalibrationData.fromJson(Map<String, dynamic> json) {
    return InitialCalibrationData(
      deviceOrientation: _parseDeviceOrientation(json['deviceOrientation']),
      accelerometerXOffset: json['accelerometerXOffset'],
      accelerometerYOffset: json['accelerometerYOffset'],
      accelerometerZOffset: json['accelerometerZOffset'],
      gyroscopeXOffset: json['gyroscopeXOffset'],
      gyroscopeYOffset: json['gyroscopeYOffset'],
      gyroscopeZOffset: json['gyroscopeZOffset'],
      calibrationTimestamp: json['calibrationTimestamp'],
    );
  }

  /// Helper method to parse device orientation from string
  static DeviceOrientation _parseDeviceOrientation(String value) {
    switch (value) {
      case 'portrait':
        return DeviceOrientation.portrait;
      case 'landscapeRight':
        return DeviceOrientation.landscapeRight;
      case 'landscapeLeft':
        return DeviceOrientation.landscapeLeft;
      case 'flat':
        return DeviceOrientation.flat;
      default:
        return DeviceOrientation.unknown;
    }
  }

  /// Serialize the calibration data to a JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Create an [InitialCalibrationData] from a JSON string
  factory InitialCalibrationData.fromJsonString(String jsonString) {
    final json = jsonDecode(jsonString) as Map<String, dynamic>;
    return InitialCalibrationData.fromJson(json);
  }

  @override
  String toString() {
    return 'InitialCalibrationData('
        'deviceOrientation: $deviceOrientation, '
        'accelerometerXOffset: $accelerometerXOffset, '
        'accelerometerYOffset: $accelerometerYOffset, '
        'accelerometerZOffset: $accelerometerZOffset, '
        'gyroscopeXOffset: $gyroscopeXOffset, '
        'gyroscopeYOffset: $gyroscopeYOffset, '
        'gyroscopeZOffset: $gyroscopeZOffset, '
        'calibrationTimestamp: $calibrationTimestamp)';
  }
}
