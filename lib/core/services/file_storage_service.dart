/// Interface for managing files on the device
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart';

abstract class FileStorageService {
  /// Get the application documents directory path
  Future<String> getDocumentsDirectoryPath();

  /// Get the application temporary directory path
  Future<String> getTemporaryDirectoryPath();

  /// Get the application external storage directory path (if available)
  Future<String?> getExternalStorageDirectoryPath();

  /// Write a string to a file
  Future<bool> writeStringToFile(String content, String filePath);

  /// Read a string from a file
  Future<String?> readStringFromFile(String filePath);

  /// Write bytes to a file
  Future<bool> writeBytesToFile(List<int> bytes, String filePath);

  /// Read bytes from a file
  Future<List<int>?> readBytesFromFile(String filePath);

  /// Check if a file exists
  Future<bool> fileExists(String filePath);

  /// Delete a file
  Future<bool> deleteFile(String filePath);

  /// Create a directory
  Future<bool> createDirectory(String directoryPath);

  /// List files in a directory
  Future<List<String>> listFiles(String directoryPath);

  /// List files in a directory with a specific extension
  Future<List<String>> listFilesWithExtension(
    String directoryPath,
    String extension,
  );

  /// Copy a file from source to destination
  Future<bool> copyFile(String sourcePath, String destinationPath);

  /// Move a file from source to destination
  Future<bool> moveFile(String sourcePath, String destinationPath);

  /// Get file size
  Future<int?> getFileSize(String filePath);

  /// Get available storage space
  Future<int?> getAvailableStorage();

  /// Export file to a shareable location
  Future<String?> exportFile(String sourcePath, String fileName);

  /// Create a new uniquely named session directory with timestamp (YYYYMMDD_HHMMSS format)
  /// Returns the path to the created session directory
  Future<String> createSessionDirectory();

  /// Get the base directory where all sessions are stored
  Future<String> getSessionsBaseDirectory();

  /// Save a video file to a specific session directory
  /// Returns the path to the saved video file
  Future<String> saveVideoToSession(String videoPath, String sessionDirectory);

  /// List all available sessions
  Future<List<String>> listSessions();

  /// Create a new CSV file with header row
  /// If the file already exists, it will be overwritten
  /// Returns true if file was created successfully
  Future<bool> createCsvWithHeader(String filePath, List<String> headerColumns);

  /// Append data rows to an existing CSV file
  /// Returns true if data was written successfully
  Future<bool> appendToCsv(String filePath, List<String> rows);

  /// Get the path to the sensor data CSV file for a specific session
  /// If createIfNotExists is true, it will create the csv file with the appropriate header
  /// Returns the full path to the sensors.csv file
  Future<String> getSensorDataCsvPath(
    String sessionDirectory, {
    bool createIfNotExists = false,
  });

  /// Appends a list of CorrectedSensorDataPoint objects to the sensors.csv file for a specific session
  /// If the file doesn't exist, it will be created with the appropriate header
  /// Returns true if data was successfully written to the file
  Future<bool> appendToSensorDataCsv(
    String sessionDirectory,
    List<CorrectedSensorDataPoint> dataPoints,
  );

  /// Get the path to the annotations log file for a specific session
  /// If createIfNotExists is true, it will create an empty file
  /// Returns the full path to the annotations.log file
  Future<String> getAnnotationsLogPath(
    String sessionDirectory, {
    bool createIfNotExists = false,
  });

  /// Logs an annotation event to the annotations.log file for a specific session
  /// The annotation includes the spike timestamp and user feedback type
  /// Returns true if the annotation was successfully logged
  Future<bool> logAnnotation(
    String sessionDirectory,
    int spikeTimestampMs,
    String feedbackType,
  );
}
