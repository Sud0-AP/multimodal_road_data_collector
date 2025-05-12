/// Data class representing display information for a recording session
class RecordingDisplayInfo {
  /// Unique identifier for the session (folder name, YYYYMMDD_HHMMSS format)
  final String sessionId;

  /// Full path to the session directory
  final String sessionPath;

  /// When the recording was created
  final DateTime timestamp;

  /// Duration of the recording in seconds
  final int durationSeconds;

  /// Name of the video file, typically "video.mp4"
  final String? videoFileName;

  /// Name of the sensor data file, typically "sensors.csv"
  final String? sensorDataFileName;

  /// Constructor
  RecordingDisplayInfo({
    required this.sessionId,
    required this.sessionPath,
    required this.timestamp,
    required this.durationSeconds,
    this.videoFileName,
    this.sensorDataFileName,
  });

  /// Create a RecordingDisplayInfo from a map of values
  factory RecordingDisplayInfo.fromMap(Map<String, dynamic> map) {
    return RecordingDisplayInfo(
      sessionId: map['sessionId'] as String,
      sessionPath: map['sessionPath'] as String,
      timestamp: map['timestamp'] as DateTime,
      durationSeconds: map['durationSeconds'] as int,
      videoFileName: map['videoFileName'] as String?,
      sensorDataFileName: map['sensorDataFileName'] as String?,
    );
  }

  /// Convert this RecordingDisplayInfo to a map
  Map<String, dynamic> toMap() {
    return {
      'sessionId': sessionId,
      'sessionPath': sessionPath,
      'timestamp': timestamp,
      'durationSeconds': durationSeconds,
      'videoFileName': videoFileName,
      'sensorDataFileName': sensorDataFileName,
    };
  }

  @override
  String toString() {
    return 'RecordingDisplayInfo(sessionId: $sessionId, sessionPath: $sessionPath, timestamp: $timestamp, durationSeconds: $durationSeconds, videoFileName: $videoFileName, sensorDataFileName: $sensorDataFileName)';
  }
}
