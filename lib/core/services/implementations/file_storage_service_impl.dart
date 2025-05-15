import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../file_storage_service.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart';
import 'package:url_launcher/url_launcher.dart';

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
    'is_bump',
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
        'is_bump',
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

  @override
  Future<bool> writeMetadata(String metadataContent, String sessionPath) async {
    try {
      final metadataFilePath = path.join(sessionPath, 'metadata.txt');
      print('📄 METADATA: Writing metadata to $metadataFilePath');

      // Ensure the session directory exists
      final dir = Directory(sessionPath);
      if (!await dir.exists()) {
        print('📁 METADATA: Creating directory $sessionPath');
        await dir.create(recursive: true);
      }

      // Write the file
      final result = await writeStringToFile(metadataContent, metadataFilePath);

      // Verify file was written
      final metadataFile = File(metadataFilePath);
      final exists = await metadataFile.exists();

      if (exists) {
        final size = await metadataFile.length();
        print(
          '✅ METADATA: Successfully wrote ${size} bytes to $metadataFilePath',
        );
      } else {
        print(
          '❌ METADATA: Failed to write metadata file - file does not exist after write',
        );
      }

      return result && exists;
    } catch (e) {
      print('❌ METADATA ERROR: $e');
      return false;
    }
  }

  @override
  Future<Map<String, String>?> readMetadataSummary(
    String sessionPath, [
    List<String>? keysToRead,
  ]) async {
    try {
      final metadataFilePath = path.join(sessionPath, 'metadata.txt');
      final content = await readStringFromFile(metadataFilePath);

      if (content == null) {
        return null;
      }

      // Parse content line by line
      final Map<String, String> result = {};
      final lines = content.split('\n');

      for (final line in lines) {
        // Skip section headers and empty lines
        if (line.isEmpty || line.startsWith('---')) {
          continue;
        }

        // Extract key-value pairs
        final separatorIndex = line.indexOf(':');
        if (separatorIndex > 0) {
          final key = line.substring(0, separatorIndex).trim();
          final value = line.substring(separatorIndex + 1).trim();

          // If keysToRead is specified, only include those keys
          if (keysToRead == null || keysToRead.contains(key)) {
            result[key] = value;
          }

          // If we've found all the keys we need, break early
          if (keysToRead != null && result.length == keysToRead.length) {
            break;
          }
        }
      }

      return result;
    } catch (e) {
      // Log error in a real application
      return null;
    }
  }

  @override
  Future<List<String>> listRecordingSessionPaths() async {
    try {
      final documentsDir = await getDocumentsDirectoryPath();
      final recordingsDir = path.join(documentsDir, 'recordings');

      print('📂 RECORDINGS: Looking for recordings in $recordingsDir');

      // Create the recordings directory if it doesn't exist
      if (!await Directory(recordingsDir).exists()) {
        print('📁 RECORDINGS: Creating directory $recordingsDir');
        await Directory(recordingsDir).create(recursive: true);
        return [];
      }

      // List all subdirectories in the recordings directory
      final dir = Directory(recordingsDir);
      final List<String> sessionPaths = [];

      final entities = await dir.list().toList();
      print(
        '📂 RECORDINGS: Found ${entities.length} items in recordings directory',
      );

      // First check for Android Download folder sessions
      final downloadPath = '/storage/emulated/0/Download/RoadDataCollector';
      if (Platform.isAndroid && await Directory(downloadPath).exists()) {
        print(
          '📂 RECORDINGS: Checking Android Download folder at $downloadPath',
        );
        final downloadEntities = await Directory(downloadPath).list().toList();
        print(
          '📂 RECORDINGS: Found ${downloadEntities.length} items in Download/RoadDataCollector',
        );

        for (final entity in downloadEntities) {
          if (entity is Directory) {
            final dirName = path.basename(entity.path);

            // Skip the 'logs' directory - it's not a recording
            if (dirName == 'logs') {
              print('📂 RECORDINGS: Skipping logs directory: ${entity.path}');
              continue;
            }

            print(
              '📂 RECORDINGS: Found directory in Downloads: ${entity.path}',
            );

            // Check files in this directory
            final dirFiles = await Directory(entity.path).list().toList();
            print(
              '📂 RECORDINGS: Directory contains ${dirFiles.length} files/folders',
            );

            // Add this path to our sessions list
            sessionPaths.add(entity.path);
          }
        }
      }

      for (final entity in entities) {
        if (entity is Directory) {
          final dirName = path.basename(entity.path);

          // Skip the 'logs' directory - it's not a recording
          if (dirName == 'logs') {
            print('📂 RECORDINGS: Skipping logs directory: ${entity.path}');
            continue;
          }

          print(
            '📂 RECORDINGS: Found potential session directory: ${entity.path}',
          );

          // Try to list files in this directory to see what's available
          try {
            final dirFiles = await Directory(entity.path).list().toList();
            print(
              '📂 RECORDINGS: Directory contains ${dirFiles.length} files/folders',
            );

            // Add this to session paths regardless, we'll filter in the UI if needed
            sessionPaths.add(entity.path);

            // Continue with detailed file checking for debugging
            final metadataFile = File(path.join(entity.path, 'metadata.txt'));
            final metadataExists = await metadataFile.exists();

            final videoFile = File(path.join(entity.path, 'video.mp4'));
            final videoExists = await videoFile.exists();

            final sensorsFile = File(path.join(entity.path, 'sensors.csv'));
            final sensorsExists = await sensorsFile.exists();

            print(
              '📂 RECORDINGS: Files in ${path.basename(entity.path)}: ' +
                  'metadata.txt: $metadataExists, ' +
                  'video.mp4: $videoExists, ' +
                  'sensors.csv: $sensorsExists',
            );
          } catch (e) {
            print(
              '❌ RECORDINGS: Error checking files in directory ${entity.path}: $e',
            );
          }
        }
      }

      // Sort by directory name (which should be a timestamp) in descending order
      sessionPaths.sort((a, b) {
        final aName = path.basename(a);
        final bName = path.basename(b);
        return bName.compareTo(aName); // Descending order (newest first)
      });

      print('📂 RECORDINGS: Returning ${sessionPaths.length} session paths');
      return sessionPaths;
    } catch (e) {
      // Log error in a real application
      print('❌ RECORDINGS ERROR: $e');
      return [];
    }
  }

  @override
  Future<List<String>> getSessionFilePathsForSharing(String sessionPath) async {
    try {
      print('👨‍💻 SHARING: Getting files from $sessionPath');
      final List<String> filePaths = [];

      // Add standard files if they exist
      final videoFile = File(path.join(sessionPath, 'video.mp4'));
      if (await videoFile.exists()) {
        filePaths.add(videoFile.path);
        print('👨‍💻 SHARING: Added video file: ${videoFile.path}');
      }

      final sensorsFile = File(path.join(sessionPath, 'sensors.csv'));
      if (await sensorsFile.exists()) {
        filePaths.add(sensorsFile.path);
        print('👨‍💻 SHARING: Added sensors file: ${sensorsFile.path}');
      }

      final metadataFile = File(path.join(sessionPath, 'metadata.txt'));
      if (await metadataFile.exists()) {
        filePaths.add(metadataFile.path);
        print('👨‍💻 SHARING: Added metadata file: ${metadataFile.path}');
      }

      // Check for different possible log files - be very explicit with naming
      final annotationsLogFile = File(
        path.join(sessionPath, 'annotations.log'),
      );
      if (await annotationsLogFile.exists()) {
        filePaths.add(annotationsLogFile.path);
        print(
          '👨‍💻 SHARING: Added annotations.log file: ${annotationsLogFile.path}',
        );
      }

      // Specifically look for annotation.log (singular form without 's')
      final annotationLogFile = File(path.join(sessionPath, 'annotation.log'));
      if (await annotationLogFile.exists()) {
        filePaths.add(annotationLogFile.path);
        print(
          '👨‍💻 SHARING: Added annotation.log file: ${annotationLogFile.path}',
        );
      }

      // Also check for session.log if it exists
      final sessionLogFile = File(path.join(sessionPath, 'session.log'));
      if (await sessionLogFile.exists()) {
        filePaths.add(sessionLogFile.path);
        print('👨‍💻 SHARING: Added session.log file: ${sessionLogFile.path}');
      }

      // Recursive function to find all log files in a directory
      Future<void> findLogFilesRecursively(String dirPath) async {
        try {
          final dir = Directory(dirPath);
          if (!await dir.exists()) return;

          await for (final entity in dir.list()) {
            if (entity is File && entity.path.toLowerCase().endsWith('.log')) {
              if (!filePaths.contains(entity.path)) {
                filePaths.add(entity.path);
                print(
                  '👨‍💻 SHARING: Added log file from recursive scan: ${entity.path}',
                );
              }
            } else if (entity is Directory) {
              // Check subdirectories too (within reason - don't go too deep)
              await findLogFilesRecursively(entity.path);
            }
          }
        } catch (e) {
          print('❌ SHARING: Error searching for log files: $e');
        }
      }

      // Do a thorough search for log files
      await findLogFilesRecursively(sessionPath);

      print('👨‍💻 SHARING: Total files to share: ${filePaths.length}');
      for (int i = 0; i < filePaths.length; i++) {
        print('👨‍💻 SHARING: File ${i + 1}: ${filePaths[i]}');
      }

      return filePaths;
    } catch (e) {
      // Log error in a real application
      print('❌ SHARING ERROR: $e');
      return [];
    }
  }

  @override
  Future<bool> deleteDirectoryRecursive(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (await directory.exists()) {
        await directory.delete(recursive: true);
        return true;
      }
      return true; // Directory already doesn't exist
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<bool> openDirectoryInFileExplorer(String directoryPath) async {
    try {
      if (Platform.isAndroid) {
        final directory = Directory(directoryPath);
        if (!await directory.exists()) {
          print('Directory does not exist: $directoryPath');
          return false;
        }

        // Extract the folder name from the path
        final folderName = path.basename(directoryPath);

        // Format path for Android using content URI
        final String basePath = 'RoadDataCollector';
        final uriString =
            'content://com.android.externalstorage.documents/document/primary%3ADownload%2F${basePath}%2F${Uri.encodeComponent(folderName)}';
        final Uri uri = Uri.parse(uriString);

        print("Attempting to launch URI: $uriString");
        try {
          final bool launched = await launchUrl(
            uri,
            mode: LaunchMode.externalApplication,
          );
          if (!launched) {
            print("launchUrl returned false for $uriString");

            // Try fallback to base folder
            print("Trying fallback to base folder...");
            const baseUriString =
                'content://com.android.externalstorage.documents/document/primary%3ADownload%2FRoadDataCollector';
            final baseUri = Uri.parse(baseUriString);
            print("Fallback: Attempting to launch base URI: $baseUriString");

            final bool baseLaunched = await launchUrl(
              baseUri,
              mode: LaunchMode.externalApplication,
            );

            if (!baseLaunched) {
              print("Base fallback also failed");
              // Last resort: try using more generic storage URI
              final storageUri = Uri.parse(
                'content://com.android.externalstorage.documents/document/primary',
              );
              print(
                'Last resort: Attempting to launch storage URI: $storageUri',
              );

              if (await canLaunchUrl(storageUri)) {
                return await launchUrl(
                  storageUri,
                  mode: LaunchMode.externalApplication,
                );
              }
              return false;
            }
            return true;
          }
          return true;
        } catch (e) {
          print("Error launching URL $uriString: $e");

          // Try fallback to generic storage browser
          final storageUri = Uri.parse(
            'content://com.android.externalstorage.documents/document/primary',
          );
          print('Fallback: Attempting to launch storage URI: $storageUri');

          if (await canLaunchUrl(storageUri)) {
            return await launchUrl(
              storageUri,
              mode: LaunchMode.externalApplication,
            );
          }
          return false;
        }
      } else if (Platform.isIOS) {
        // iOS doesn't support direct folder opening
        print('Opening folder in file explorer is not supported on iOS');
        return false;
      }

      return false;
    } catch (e) {
      print('Error opening directory in file explorer: $e');
      return false;
    }
  }

  @override
  Future<String> createNewSessionDirectory() async {
    try {
      // Get the documents directory
      final documentsDir = await getDocumentsDirectoryPath();

      // Create a recordings subdirectory if it doesn't exist
      final recordingsDir = path.join(documentsDir, 'recordings');
      final recordingsDirObj = Directory(recordingsDir);
      if (!await recordingsDirObj.exists()) {
        await recordingsDirObj.create(recursive: true);
      }

      // Generate a timestamp for the session folder name (YYYYMMDD_HHMMSS)
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final sessionDir = path.join(recordingsDir, timestamp);

      // Create the session directory
      await Directory(sessionDir).create(recursive: true);

      return sessionDir;
    } catch (e) {
      // Log error in a real application
      // For now, return a fallback directory name
      final documentsDir = await getDocumentsDirectoryPath();
      final fallbackDir = path.join(
        documentsDir,
        'recordings',
        'fallback_${DateTime.now().millisecondsSinceEpoch}',
      );
      await Directory(fallbackDir).create(recursive: true);
      return fallbackDir;
    }
  }
}
