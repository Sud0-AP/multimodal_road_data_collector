/// Data class representing a single sensor reading with timestamp
class SensorData {
  /// X-axis acceleration in m/s²
  final double accelerometerX;

  /// Y-axis acceleration in m/s²
  final double accelerometerY;

  /// Z-axis acceleration in m/s²
  final double accelerometerZ;

  /// X-axis gyroscope reading in rad/s
  final double gyroscopeX;

  /// Y-axis gyroscope reading in rad/s
  final double gyroscopeY;

  /// Z-axis gyroscope reading in rad/s
  final double gyroscopeZ;

  /// Timestamp in milliseconds since epoch
  final int timestamp;

  /// Constructor for SensorData
  SensorData({
    required this.accelerometerX,
    required this.accelerometerY,
    required this.accelerometerZ,
    required this.gyroscopeX,
    required this.gyroscopeY,
    required this.gyroscopeZ,
    required this.timestamp,
  });

  /// Create a copy of this SensorData with optional parameter changes
  SensorData copyWith({
    double? accelerometerX,
    double? accelerometerY,
    double? accelerometerZ,
    double? gyroscopeX,
    double? gyroscopeY,
    double? gyroscopeZ,
    int? timestamp,
  }) {
    return SensorData(
      accelerometerX: accelerometerX ?? this.accelerometerX,
      accelerometerY: accelerometerY ?? this.accelerometerY,
      accelerometerZ: accelerometerZ ?? this.accelerometerZ,
      gyroscopeX: gyroscopeX ?? this.gyroscopeX,
      gyroscopeY: gyroscopeY ?? this.gyroscopeY,
      gyroscopeZ: gyroscopeZ ?? this.gyroscopeZ,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  @override
  String toString() {
    return 'SensorData(accelerometerX: $accelerometerX, accelerometerY: $accelerometerY, accelerometerZ: $accelerometerZ, gyroscopeX: $gyroscopeX, gyroscopeY: $gyroscopeY, gyroscopeZ: $gyroscopeZ, timestamp: $timestamp)';
  }
}

/// Interface for accessing and processing sensor data
abstract class SensorService {
  /// Initialize the sensor service
  Future<void> initialize();

  /// Get a stream of sensor data at 100Hz frequency
  ///
  /// Returns a stream of [SensorData] objects containing accelerometer
  /// and gyroscope readings with timestamps
  Stream<SensorData> getSensorDataStream();

  /// Start collecting sensor data
  ///
  /// This method should be called before accessing the sensor data stream
  Future<void> startSensorDataCollection();

  /// Stop collecting sensor data
  ///
  /// This method should be called when sensor data is no longer needed
  /// to free up resources and save battery
  Future<void> stopSensorDataCollection();

  /// Check if sensor data collection is currently active
  bool isSensorDataCollectionActive();

  /// Dispose of resources
  ///
  /// This method should be called when the service is no longer needed
  Future<void> dispose();
}
