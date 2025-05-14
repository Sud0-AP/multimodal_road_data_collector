import 'package:multimodal_road_data_collector/core/services/sensor_service.dart';

/// Represents a fully processed sensor data point with corrected values
/// ready for CSV logging
class CorrectedSensorDataPoint {
  /// Relative timestamp in milliseconds from the start of the sensor stream
  final int timestampMs;

  /// Corrected accelerometer X value in m/s²
  final double accelX;

  /// Corrected accelerometer Y value in m/s²
  final double accelY;

  /// Corrected accelerometer Z value in m/s²
  final double accelZ;

  /// Acceleration magnitude (calculated from X, Y, Z components)
  final double accelMagnitude;

  /// Corrected gyroscope X value in rad/s
  final double gyroX;

  /// Corrected gyroscope Y value in rad/s
  final double gyroY;

  /// Corrected gyroscope Z value in rad/s
  final double gyroZ;

  /// Whether this data point represents a pothole/bump detection
  final bool isBump;

  /// User feedback for this data point (if any)
  final String userFeedback;

  /// Constructor
  CorrectedSensorDataPoint({
    required this.timestampMs,
    required this.accelX,
    required this.accelY,
    required this.accelZ,
    required this.accelMagnitude,
    required this.gyroX,
    required this.gyroY,
    required this.gyroZ,
    this.isBump = false,
    this.userFeedback = '',
  });

  /// Create a copy with modified values
  CorrectedSensorDataPoint copyWith({
    int? timestampMs,
    double? accelX,
    double? accelY,
    double? accelZ,
    double? accelMagnitude,
    double? gyroX,
    double? gyroY,
    double? gyroZ,
    bool? isBump,
    String? userFeedback,
  }) {
    return CorrectedSensorDataPoint(
      timestampMs: timestampMs ?? this.timestampMs,
      accelX: accelX ?? this.accelX,
      accelY: accelY ?? this.accelY,
      accelZ: accelZ ?? this.accelZ,
      accelMagnitude: accelMagnitude ?? this.accelMagnitude,
      gyroX: gyroX ?? this.gyroX,
      gyroY: gyroY ?? this.gyroY,
      gyroZ: gyroZ ?? this.gyroZ,
      isBump: isBump ?? this.isBump,
      userFeedback: userFeedback ?? this.userFeedback,
    );
  }

  /// Factory method to create a CorrectedSensorDataPoint from ProcessedSensorData
  factory CorrectedSensorDataPoint.fromProcessedData({
    required int relativeTimestampMs,
    required double accelX,
    required double accelY,
    required double correctedAccelZ,
    required double accelMagnitude,
    required double gyroX,
    required double gyroY,
    required double correctedGyroZ,
    bool isBump = false,
    String userFeedback = '',
  }) {
    return CorrectedSensorDataPoint(
      timestampMs: relativeTimestampMs,
      accelX: accelX,
      accelY: accelY,
      accelZ: correctedAccelZ,
      accelMagnitude: accelMagnitude,
      gyroX: gyroX,
      gyroY: gyroY,
      gyroZ: correctedGyroZ,
      isBump: isBump,
      userFeedback: userFeedback,
    );
  }

  /// Convert to a CSV row string
  String toCsvRow() {
    // Properly escape fields with commas or quotes by wrapping in quotes and escaping quotes
    final escapedUserFeedback =
        userFeedback.contains(',') || userFeedback.contains('"')
            ? '"${userFeedback.replaceAll('"', '""')}"' // Double quotes are escaped with double quotes in CSV
            : userFeedback;

    // CHANGED: Handle the isBump field - always output '1' when true
    // This ensures isBump column is independent of user feedback
    String isBumpValue = isBump ? '1' : '';

    return [
      timestampMs.toString(),
      accelX.toString(),
      accelY.toString(),
      accelZ.toString(),
      accelMagnitude.toString(),
      gyroX.toString(),
      gyroY.toString(),
      gyroZ.toString(),
      isBumpValue,
      escapedUserFeedback,
    ].join(',');
  }

  @override
  String toString() {
    return 'CorrectedSensorDataPoint(timestampMs: $timestampMs, '
        'accelX: $accelX, accelY: $accelY, accelZ: $accelZ, '
        'accelMagnitude: $accelMagnitude, '
        'gyroX: $gyroX, gyroY: $gyroY, gyroZ: $gyroZ, '
        'isBump: $isBump, userFeedback: "$userFeedback")';
  }
}
