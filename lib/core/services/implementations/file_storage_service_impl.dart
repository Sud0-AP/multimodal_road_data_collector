import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../file_storage_service.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart';

/// Implementation of FileStorageService using dart:io and path_provider
class FileStorageServiceImpl implements FileStorageService {
  @override
  Future<String> getDocumentsDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Future<String> getTemporaryDirectoryPath() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  @override
  Future<String?> getExternalStorageDirectoryPath() async {
    try {
      final directory = await getExternalStorageDirectory();
      return directory?.path;
    } catch (e) {
      // External storage might not be available on all platforms
      return null;
    }
  }

  @override
  Future<bool> writeStringToFile(String content, String filePath) async {
    try {
      final file = File(filePath);

      // Create the parent directory if it doesn't exist
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await file.writeAsString(content);
      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<String?> readStringFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      // Log error in a real application
      return null;
    }
  }

  @override
  Future<bool> writeBytesToFile(List<int> bytes, String filePath) async {
    try {
      final file = File(filePath);

      // Create the parent directory if it doesn't exist
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<List<int>?> readBytesFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      // Log error in a real application
      return null;
    }
  }

  @override
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      // Return true even if file doesn't exist, as the goal (file not existing) is achieved
      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<bool> createDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<List<String>> listFiles(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return [];
      }

      final List<String> fileList = [];
      await for (final entity in directory.list()) {
        if (entity is File) {
          fileList.add(entity.path);
        }
      }
      return fileList;
    } catch (e) {
      // Log error in a real application
      return [];
    }
  }

  @override
  Future<List<String>> listFilesWithExtension(
    String directoryPath,
    String extension,
  ) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return [];
      }

      final List<String> fileList = [];
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith(extension)) {
          fileList.add(entity.path);
        }
      }
      return fileList;
    } catch (e) {
      // Log error in a real application
      return [];
    }
  }

  @override
  Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return false;
      }

      // Create the directory for the destination file if it doesn't exist
      final destFile = File(destinationPath);
      final destDir = destFile.parent;
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      await sourceFile.copy(destinationPath);
      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<bool> moveFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return false;
      }

      // Create the directory for the destination file if it doesn't exist
      final destFile = File(destinationPath);
      final destDir = destFile.parent;
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      await sourceFile.rename(destinationPath);
      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<int?> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return null;
    } catch (e) {
      // Log error in a real application
      return null;
    }
  }

  @override
  Future<int?> getAvailableStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stat = await directory.stat();

      // Note: This is a simplistic approximation as Flutter doesn't provide
      // a direct way to get available storage space
      return stat.size;
    } catch (e) {
      // Log error in a real application
      return null;
    }
  }

  @override
  Future<String?> exportFile(String sourcePath, String fileName) async {
    try {
      // Currently just copies to external storage if available
      final externalPath = await getExternalStorageDirectoryPath();
      if (externalPath == null) {
        return null;
      }

      final destinationPath = '$externalPath/$fileName';
      final success = await copyFile(sourcePath, destinationPath);

      if (success) {
        return destinationPath;
      }
      return null;
    } catch (e) {
      // Log error in a real application
      return null;
    }
  }

  // Constants for session management
  static const String _sessionsDirectoryName = 'RoadDataCollector';
  static const String _sessionDateTimeFormat = 'yyyyMMdd_HHmmss';
  static const String _videoFileName = 'video.mp4';

  @override
  Future<String> getSessionsBaseDirectory() async {
    Directory? directory;
    try {
      // On Android, use the Downloads directory
      if (Platform.isAndroid) {
        // Get the Downloads directory
        directory = Directory(
          '/storage/emulated/0/Download/$_sessionsDirectoryName',
        );
      } else if (Platform.isIOS) {
        // On iOS, use the Documents directory which is accessible via Files app
        // This will be accessible through the Files app under On My iPhone/AppName
        final docsDir = await getApplicationDocumentsDirectory();
        directory = Directory('${docsDir.path}/$_sessionsDirectoryName');
      } else {
        // Fallback to app's external storage directory or documents directory
        final appDir =
            await getExternalStorageDirectoryPath() ??
            await getDocumentsDirectoryPath();
        directory = Directory('$appDir/$_sessionsDirectoryName');
      }

      // Ensure the directory exists
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }

      return directory.path;
    } catch (e) {
      // If there's an error, fallback to app's documents directory
      final appDir = await getDocumentsDirectoryPath();
      final sessionsDir = path.join(appDir, _sessionsDirectoryName);

      // Ensure the directory exists
      await createDirectory(sessionsDir);

      return sessionsDir;
    }
  }

  @override
  Future<String> createSessionDirectory() async {
    // Generate a timestamp-based session name (YYYYMMDD_HHMMSS)
    final sessionId = DateFormat(_sessionDateTimeFormat).format(DateTime.now());
    final sessionsBaseDir = await getSessionsBaseDirectory();
    final sessionDir = path.join(sessionsBaseDir, 'session_$sessionId');

    // Create the directory
    await createDirectory(sessionDir);

    return sessionDir;
  }

  @override
  Future<String> saveVideoToSession(
    String videoPath,
    String sessionDirectory,
  ) async {
    // Destination path for the video file
    final videoDestinationPath = path.join(sessionDirectory, _videoFileName);

    print('🎥 VIDEO SAVE: Source path: $videoPath');
    print('🎥 VIDEO SAVE: Destination directory: $sessionDirectory');
    print('🎥 VIDEO SAVE: Full destination path: $videoDestinationPath');

    // Make sure the destination directory exists
    await createDirectory(sessionDirectory);

    // Copy the video file to the session directory
    final success = await copyFile(videoPath, videoDestinationPath);

    if (success) {
      print('✅ VIDEO SAVE: Successfully saved video to $videoDestinationPath');
      // Check file size to verify the video was copied correctly
      final videoFile = File(videoDestinationPath);
      if (await videoFile.exists()) {
        final size = await videoFile.length();
        print(
          '✅ VIDEO SAVE: Video file size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB',
        );
      } else {
        print('❌ VIDEO SAVE: Destination file does not exist after copy!');
      }
    } else {
      print('❌ VIDEO SAVE: Failed to copy video to session directory');
    }

    if (Platform.isIOS) {
      // For iOS, we might need additional steps to make the video accessible
      // in the Photos app, but this would require additional packages
      // or native code integration, which is beyond the current scope

      // The video will still be accessible via the Files app
      // under "On My iPhone > App Name > RoadDataCollector > session_XXX"
    }

    return videoDestinationPath;
  }

  @override
  Future<List<String>> listSessions() async {
    final sessionsBaseDir = await getSessionsBaseDirectory();

    try {
      final directory = Directory(sessionsBaseDir);
      if (!await directory.exists()) {
        return [];
      }

      final List<String> sessionDirs = [];
      await for (final entity in directory.list()) {
        if (entity is Directory) {
          // Only include directory names that match our session pattern
          final dirName = path.basename(entity.path);
          if (dirName.startsWith('session_')) {
            sessionDirs.add(entity.path);
          }
        }
      }

      // Sort in descending order by creation time for convenience
      sessionDirs.sort((a, b) => b.compareTo(a));

      return sessionDirs;
    } catch (e) {
      // Log error in a real application
      return [];
    }
  }

  /// Constants for sensor data CSV
  static const String _sensorDataFileName = 'sensors.csv';

  /// List of column headers for the sensor data CSV file
  static const List<String> _sensorDataCsvColumns = [
    'timestamp_ms',
    'accel_x',
    'accel_y',
    'accel_z',
    'accel_magnitude',
    'gyro_x',
    'gyro_y',
    'gyro_z',
    'is_pothole',
    'user_feedback',
  ];

  @override
  Future<bool> createCsvWithHeader(
    String filePath,
    List<String> headerColumns,
  ) async {
    try {
      final file = File(filePath);

      // Create the parent directory if it doesn't exist
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      // Create the CSV header row
      final headerRow = headerColumns.join(',');

      // Write the header to the file
      await file.writeAsString('$headerRow\n');
      return true;
    } catch (e) {
      // Log error in a real application
      print('Error creating CSV with header: $e');
      return false;
    }
  }

  @override
  Future<bool> appendToCsv(String filePath, List<String> rows) async {
    try {
      final file = File(filePath);

      // Check if file exists
      if (!await file.exists()) {
        return false;
      }

      // Join rows with newlines and append to file
      final content = rows.join('\n') + '\n';
      await file.writeAsString(content, mode: FileMode.append);
      return true;
    } catch (e) {
      // Log error in a real application
      print('Error appending to CSV: $e');
      return false;
    }
  }

  @override
  Future<String> getSensorDataCsvPath(
    String sessionDirectory, {
    bool createIfNotExists = false,
  }) async {
    // Ensure sessionDirectory exists
    await createDirectory(sessionDirectory);

    // Define the path to sensors.csv in the session directory
    final csvPath = path.join(sessionDirectory, 'sensors.csv');

    // Create the file with headers if needed
    if (createIfNotExists && !await fileExists(csvPath)) {
      final headers = [
        'timestamp_ms',
        'accel_x',
        'accel_y',
        'accel_z',
        'accel_magnitude',
        'gyro_x',
        'gyro_y',
        'gyro_z',
        'is_pothole',
        'user_feedback',
      ];
      await createCsvWithHeader(csvPath, headers);
    }

    return csvPath;
  }

  @override
  Future<bool> appendToSensorDataCsv(
    String sessionDirectory,
    List<CorrectedSensorDataPoint> dataPoints,
  ) async {
    try {
      // Get the path to sensors.csv (create if it doesn't exist)
      final csvPath = await getSensorDataCsvPath(
        sessionDirectory,
        createIfNotExists: true,
      );

      // Convert data points to CSV rows
      final rows = dataPoints.map((point) => point.toCsvRow()).toList();

      // Append to CSV
      return await appendToCsv(csvPath, rows);
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<String> getAnnotationsLogPath(
    String sessionDirectory, {
    bool createIfNotExists = false,
  }) async {
    // Ensure sessionDirectory exists
    await createDirectory(sessionDirectory);

    // Define the path to annotations.log in the session directory
    final logPath = path.join(sessionDirectory, 'annotations.log');

    // Create an empty file if needed and it doesn't already exist
    if (createIfNotExists && !await fileExists(logPath)) {
      await writeStringToFile('', logPath);
    }

    return logPath;
  }

  @override
  Future<bool> logAnnotation(
    String sessionDirectory,
    int spikeTimestampMs,
    String feedbackType,
  ) async {
    try {
      // Get the path to annotations.log (create if it doesn't exist)
      final logPath = await getAnnotationsLogPath(
        sessionDirectory,
        createIfNotExists: true,
      );

      // Format the annotation line
      final annotationLine = '$spikeTimestampMs,$feedbackType\n';

      // Append the line to the log file
      final file = File(logPath);
      await file.writeAsString(annotationLine, mode: FileMode.append);

      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }
}
