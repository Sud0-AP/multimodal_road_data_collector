import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data_management_service.dart';
import '../file_storage_service.dart';
import '../device_info_service.dart';
import '../app_info_service.dart';
import '../../../features/recording/domain/models/recording_completion_data.dart';

/// Implementation of DataManagementService
class DataManagementServiceImpl implements DataManagementService {
  final FileStorageService _fileStorageService;
  final DeviceInfoService _deviceInfoService;
  final AppInfoService _appInfoService;

  /// Constructor
  DataManagementServiceImpl({
    required FileStorageService fileStorageService,
    required DeviceInfoService deviceInfoService,
    required AppInfoService appInfoService,
  }) : _fileStorageService = fileStorageService,
       _deviceInfoService = deviceInfoService,
       _appInfoService = appInfoService;

  @override
  Future<bool> generateAndSaveMetadata(
    String sessionPath,
    Map<String, dynamic> recordingData,
  ) async {
    try {
      final data = RecordingCompletionData(
        sessionId: recordingData['sessionId'] as String,
        durationSeconds: recordingData['durationSeconds'] as int,
        orientationMode: recordingData['orientationMode'] as String,
        accelOffsetX: (recordingData['accelOffsetX'] as num).toDouble(),
        accelOffsetY: (recordingData['accelOffsetY'] as num).toDouble(),
        accelOffsetZ: (recordingData['accelOffsetZ'] as num).toDouble(),
        gyroOffsetX: (recordingData['gyroOffsetX'] as num).toDouble(),
        gyroOffsetY: (recordingData['gyroOffsetY'] as num).toDouble(),
        gyroOffsetZ: (recordingData['gyroOffsetZ'] as num).toDouble(),
        sessionAdjustedAccelZ:
            (recordingData['sessionAdjustedAccelZ'] as num).toDouble(),
        bumpThreshold: (recordingData['bumpThreshold'] as num).toDouble(),
        gyroZDrift: (recordingData['gyroZDrift'] as num).toDouble(),
        calibrationTimestamp: recordingData['calibrationTimestamp'] as int?,
        calibrationSamplesCount:
            recordingData['calibrationSamplesCount'] as int? ?? 0,
        videoStartNtp: recordingData['videoStartNtp'] as DateTime?,
        videoEndNtp: recordingData['videoEndNtp'] as DateTime?,
        sensorStartNtp: recordingData['sensorStartNtp'] as DateTime?,
        sensorEndNtp: recordingData['sensorEndNtp'] as DateTime?,
        sensorStartMonotonicMs: recordingData['sensorStartMonotonicMs'] as int?,
        sensorEndMonotonicMs: recordingData['sensorEndMonotonicMs'] as int?,
        actualSamplingRateHz:
            recordingData['actualSamplingRateHz'] != null
                ? (recordingData['actualSamplingRateHz'] as num).toDouble()
                : null,
        videoResolution: recordingData['videoResolution'] as String?,
        // Handle warnings safely - it may come as List<dynamic> rather than List<String>
        warnings: _safelyGetWarnings(recordingData['warnings']),
      );

      // Format metadata in a structured plain text format
      final metadataContent = StringBuffer();
      metadataContent.writeln('--- Recording Session Metadata ---');
      metadataContent.writeln('Session ID: ${data.sessionId}');
      metadataContent.writeln(
        'Recording Duration (s): ${data.durationSeconds}',
      );
      metadataContent.writeln('');

      // Device Info Section
      metadataContent.writeln('--- Device Information ---');
      final deviceInfo = await _deviceInfoService.getDeviceInfo();

      // Handle Android vs iOS keys properly
      final bool isAndroid = Platform.isAndroid;
      metadataContent.writeln(
        'Device Model: ${deviceInfo['model'] ?? 'Unknown'}',
      );
      metadataContent.writeln(
        'Device Manufacturer: ${deviceInfo['manufacturer'] ?? deviceInfo['brand'] ?? 'Unknown'}',
      );

      // Handle different OS version key formats
      if (isAndroid) {
        final androidVersion = deviceInfo['androidVersion'] ?? 'Unknown';
        final sdkInt = deviceInfo['sdkInt']?.toString() ?? 'Unknown';
        metadataContent.writeln(
          'OS Version: Android $androidVersion (SDK $sdkInt)',
        );
        metadataContent.writeln(
          'Android ID: ${deviceInfo['androidId'] ?? 'Unknown'}',
        );
      } else {
        metadataContent.writeln(
          'OS Version: ${deviceInfo['systemName'] ?? 'iOS'} ${deviceInfo['systemVersion'] ?? 'Unknown'}',
        );
        metadataContent.writeln(
          'Device Name: ${deviceInfo['name'] ?? 'Unknown'}',
        );
      }

      // Get app info
      final appInfo = await _appInfoService.getAppInfo();
      metadataContent.writeln(
        'App Version: ${appInfo['version'] ?? 'Unknown'}',
      );
      metadataContent.writeln(
        'App Build Number: ${appInfo['buildNumber'] ?? 'Unknown'}',
      );
      metadataContent.writeln(
        'Package Name: ${appInfo['packageName'] ?? 'Unknown'}',
      );
      metadataContent.writeln('');

      // Timing Info Section
      metadataContent.writeln('--- Timing Info ---');
      if (data.videoStartNtp != null) {
        metadataContent.writeln(
          'Video Start: ${data.videoStartNtp!.toIso8601String()}',
        );
      }

      if (data.videoEndNtp != null) {
        metadataContent.writeln(
          'Video End: ${data.videoEndNtp!.toIso8601String()}',
        );
      }

      if (data.sensorStartNtp != null) {
        metadataContent.writeln(
          'Sensor Stream Start: ${data.sensorStartNtp!.toIso8601String()}',
        );
      }

      if (data.sensorEndNtp != null) {
        metadataContent.writeln(
          'Sensor Stream End: ${data.sensorEndNtp!.toIso8601String()}',
        );
      }

      if (data.sensorStartMonotonicMs != null) {
        metadataContent.writeln(
          'Sensor Stream Start Monotonic Epoch ms: ${data.sensorStartMonotonicMs}',
        );
      }

      if (data.sensorEndMonotonicMs != null) {
        metadataContent.writeln(
          'Sensor Stream End Monotonic Epoch ms: ${data.sensorEndMonotonicMs}',
        );
      }

      if (data.actualSamplingRateHz != null) {
        metadataContent.writeln(
          'Calculated Actual Sensor Sampling Rate (Hz): ${data.actualSamplingRateHz}',
        );
      }
      metadataContent.writeln('');

      // Camera Info Section
      metadataContent.writeln('--- Camera Info ---');
      metadataContent.writeln(
        'Video Resolution: ${data.videoResolution ?? 'Unknown'}',
      );
      metadataContent.writeln('');

      // Calibration Data Section
      metadataContent.writeln('--- Calibration Data ---');
      metadataContent.writeln('Orientation Mode: ${data.orientationMode}');
      metadataContent.writeln('Initial Accel Offset X: ${data.accelOffsetX}');
      metadataContent.writeln('Initial Accel Offset Y: ${data.accelOffsetY}');
      metadataContent.writeln('Initial Accel Offset Z: ${data.accelOffsetZ}');
      metadataContent.writeln('Initial Gyro Offset X: ${data.gyroOffsetX}');
      metadataContent.writeln('Initial Gyro Offset Y: ${data.gyroOffsetY}');
      metadataContent.writeln('Initial Gyro Offset Z: ${data.gyroOffsetZ}');
      metadataContent.writeln(
        'Session Adjusted Accel Z Offset (Final): ${data.sessionAdjustedAccelZ}',
      );
      metadataContent.writeln(
        'Pre-Recording Bump Detection Threshold: ${data.bumpThreshold}',
      );

      final gyroZDriftStr =
          data.gyroZDrift > 0.1
              ? data.gyroZDrift.toString()
              : 'Not significant';
      metadataContent.writeln(
        'Pre-Recording Gyro Drift (degrees): $gyroZDriftStr',
      );

      // Add calibration timestamp in human-readable format
      final calibrationDateTime = DateTime.fromMillisecondsSinceEpoch(
        data.calibrationTimestamp ?? DateTime.now().millisecondsSinceEpoch,
      );
      metadataContent.writeln(
        'Calibration Timestamp: ${calibrationDateTime.toIso8601String()}',
      );

      // Add calibration samples count
      metadataContent.writeln(
        'Calibration Samples Count: ${data.calibrationSamplesCount}',
      );
      metadataContent.writeln('');

      // Warnings/Log Section
      metadataContent.writeln('--- Warnings/Log ---');
      final ntpSyncStatus =
          data.videoStartNtp != null ? 'OK' : 'Failed - Using device time';
      metadataContent.writeln('NTP Sync Status: $ntpSyncStatus');

      // Add any additional warnings from recording
      if (data.warnings.isNotEmpty) {
        for (final warning in data.warnings) {
          metadataContent.writeln(warning);
        }
      }

      // Write metadata to file
      return await _fileStorageService.writeMetadata(
        metadataContent.toString(),
        sessionPath,
      );
    } catch (e) {
      // Log error
      print('Error generating metadata: $e');
      return false;
    }
  }

  /// Safely convert warnings from any type to List<String>
  List<String> _safelyGetWarnings(dynamic warningsValue) {
    if (warningsValue == null) {
      return [];
    }

    // If it's already a List<String>, return it
    if (warningsValue is List<String>) {
      return warningsValue;
    }

    // If it's a List<dynamic>, convert each item to string
    if (warningsValue is List) {
      return warningsValue.map((item) => item.toString()).toList();
    }

    // If it's some other type, return an empty list
    return [];
  }

  @override
  Future<List<String>> loadSessionList() async {
    try {
      return await _fileStorageService.listRecordingSessionPaths();
    } catch (e) {
      // Log error
      print('Error loading session list: $e');
      return [];
    }
  }

  /// Parses a duration string safely from metadata into seconds
  /// Handles various formats that might be in the metadata file
  int _parseDurationSafely(String? durationStr) {
    if (durationStr == null || durationStr.isEmpty) {
      return 0;
    }

    try {
      // Try parsing as a simple integer first (most common case)
      return int.parse(durationStr);
    } catch (e) {
      // Not a simple integer, try other formats
      try {
        // Remove any non-numeric characters except colons, periods, and commas
        final cleaned = durationStr.replaceAll(RegExp(r'[^0-9:.,]'), '');

        // Check if it might be in MM:SS format
        if (cleaned.contains(':')) {
          final parts = cleaned.split(':');
          if (parts.length == 2) {
            // MM:SS format
            final minutes = int.tryParse(parts[0]) ?? 0;
            final seconds = int.tryParse(parts[1]) ?? 0;
            return (minutes * 60) + seconds;
          } else if (parts.length == 3) {
            // HH:MM:SS format
            final hours = int.tryParse(parts[0]) ?? 0;
            final minutes = int.tryParse(parts[1]) ?? 0;
            final seconds = int.tryParse(parts[2]) ?? 0;
            return (hours * 3600) + (minutes * 60) + seconds;
          }
        }

        // Try parsing as a double (in case it has decimal points)
        final doubleValue = double.tryParse(cleaned);
        if (doubleValue != null) {
          return doubleValue.round();
        }

        // If all else fails, return 0
        return 0;
      } catch (e) {
        print('Error parsing duration "$durationStr": $e');
        return 0;
      }
    }
  }

  @override
  Future<Map<String, dynamic>?> getSessionDisplayInfo(
    String sessionPath,
  ) async {
    try {
      final Directory sessionDir = Directory(sessionPath);
      if (!await sessionDir.exists()) {
        print('Session directory does not exist: $sessionPath');
        return null;
      }

      // Try to read metadata file
      final File metadataFile = File('$sessionPath/metadata.txt');
      final DateTime timestamp = await _getSessionTimestamp(sessionPath);
      final String sessionId = path.basename(sessionPath);

      int durationSeconds = 0;
      if (await metadataFile.exists()) {
        try {
          final metadata = await _readMetadataSummary(metadataFile);
          // Look for the correct key - "Recording Duration (s)" in the metadata file
          if (metadata.containsKey('Recording Duration (s)')) {
            print(
              'Found duration in metadata: ${metadata['Recording Duration (s)']}',
            );
            durationSeconds = _parseDurationSafely(
              metadata['Recording Duration (s)'],
            );
          } else if (metadata.containsKey('duration')) {
            // Fallback to alternate key
            durationSeconds = _parseDurationSafely(metadata['duration']);
          }
        } catch (e) {
          print('Error reading metadata file: $e');
        }
      }

      // Check for video file and estimate duration ONLY if we couldn't read from metadata
      final File videoFile = File('$sessionPath/video.mp4');
      String? videoFileName;
      if (await videoFile.exists()) {
        videoFileName = 'video.mp4';

        // Only estimate if we couldn't get a valid duration from metadata
        if (durationSeconds <= 0) {
          try {
            final videoFileSize = await videoFile.length();
            final videoSizeKB = videoFileSize ~/ 1024;
            print('Video file size for estimation: $videoSizeKB KB');

            if (videoSizeKB > 100) {
              // Estimate duration based on video size (very rough estimate)
              // Using higher KB/sec ratio for more realistic values
              final estimatedDurationSeconds =
                  videoSizeKB ~/ 1500; // More conservative estimate
              if (estimatedDurationSeconds > 0) {
                print(
                  'Estimated duration from file size: $estimatedDurationSeconds seconds (fallback)',
                );
                durationSeconds = estimatedDurationSeconds;
              }
            }
          } catch (e) {
            print('Error estimating duration from file size: $e');
          }
        }
      }

      // Check for sensor data file
      final File sensorFile = File('$sessionPath/sensors.csv');
      String? sensorDataFileName;
      if (await sensorFile.exists()) {
        sensorDataFileName = 'sensors.csv';
      }

      return {
        'sessionId': sessionId,
        'sessionPath': sessionPath,
        'timestamp': timestamp,
        'durationSeconds': durationSeconds,
        'videoFileName': videoFileName,
        'sensorDataFileName': sensorDataFileName,
      };
    } catch (e) {
      print('Error getting session display info: $e');
      return null;
    }
  }

  @override
  Future<bool> deleteSession(String sessionPath) async {
    try {
      return await _fileStorageService.deleteDirectoryRecursive(sessionPath);
    } catch (e) {
      // Log error
      print('Error deleting session: $e');
      return false;
    }
  }

  @override
  Future<bool> shareSession(String sessionPath) async {
    try {
      final filePaths = await _fileStorageService.getSessionFilePathsForSharing(
        sessionPath,
      );

      if (filePaths.isEmpty) {
        return false;
      }

      // Convert to XFiles for share_plus
      final files = filePaths.map((path) => XFile(path)).toList();

      // Share files
      await Share.shareXFiles(
        files,
        subject: 'Road Data Recording ${path.basename(sessionPath)}',
        text: null, // Set to null to avoid type casting issues
      );

      return true;
    } catch (e) {
      // Log error
      print('Error sharing session: $e');
      return false;
    }
  }

  @override
  Future<bool> openSessionInFileExplorer(String sessionPath) async {
    try {
      // Don't even try on iOS
      if (Platform.isIOS) {
        print('Opening file explorer is not supported on iOS');
        return false;
      }

      if (Platform.isAndroid) {
        // For Android, we should use the proper FileProvider approach
        final Directory sessionDir = Directory(sessionPath);
        if (!await sessionDir.exists()) {
          print('Directory does not exist: $sessionPath');
          return false;
        }

        print('Trying to open directory: $sessionPath');

        // Extract the folder name from the path
        final folderName = path.basename(sessionPath);

        // Use the content URI approach which works in the previous version
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
            try {
              final bool baseLaunched = await launchUrl(
                baseUri,
                mode: LaunchMode.externalApplication,
              );
              if (!baseLaunched) {
                print("Base fallback also failed");
                return false;
              }
              return true;
            } catch (baseE) {
              print("Error launching base URL $baseUriString: $baseE");
              return false;
            }
          }
          return true;
        } catch (e) {
          print("Error launching URL $uriString: $e");

          // Try fallback methods from the original implementation
          // Create a dummy index.html file
          final File indexFile = File('${sessionPath}/index.html');
          if (!await indexFile.exists()) {
            await indexFile.writeAsString(
              '<html><body><h1>Road Data Recording</h1><p>This file was created to help navigate to this folder.</p></body></html>',
            );
          }

          // Try to use the default file manager with a proper MIME type
          final uri = Uri.file(indexFile.path);
          if (await canLaunchUrl(uri)) {
            print('Opening folder via index.html file: $uri');
            return await launchUrl(
              uri,
              mode: LaunchMode.externalNonBrowserApplication,
            );
          }
          return false;
        }
      }

      return false;
    } catch (e) {
      // Log the error
      print('Error opening file explorer: $e');
      return false;
    }
  }

  // Helper method to read metadata summary from file
  Future<Map<String, String>> _readMetadataSummary(File metadataFile) async {
    final Map<String, String> result = {};

    try {
      if (await metadataFile.exists()) {
        final String content = await metadataFile.readAsString();
        final List<String> lines = content.split('\n');

        for (final line in lines) {
          if (line.contains(':')) {
            final parts = line.split(':');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              final value = parts.sublist(1).join(':').trim();
              result[key] = value;
            }
          }
        }
      }
    } catch (e) {
      print('Error reading metadata file: $e');
    }

    return result;
  }

  // Helper method to get session timestamp from directory name or metadata
  Future<DateTime> _getSessionTimestamp(String sessionPath) async {
    try {
      final String sessionId = path.basename(sessionPath);

      // Try to parse timestamp from sessionId (expected format: session_YYYYMMDD_HHMMSS)
      if (sessionId.startsWith('session_') && sessionId.length >= 21) {
        try {
          // Parse date part and time part separately to avoid format issues
          final datePart = sessionId.substring(8, 16); // YYYYMMDD
          final timePart = sessionId.substring(17, 23); // HHMMSS

          final year = int.parse(datePart.substring(0, 4));
          final month = int.parse(datePart.substring(4, 6));
          final day = int.parse(datePart.substring(6, 8));

          final hour = int.parse(timePart.substring(0, 2));
          final minute = int.parse(timePart.substring(2, 4));
          final second = int.parse(timePart.substring(4, 6));

          return DateTime(year, month, day, hour, minute, second);
        } catch (e) {
          print('Error parsing datetime from sessionId: $e');
        }
      }

      // Try to read timestamp from metadata.txt
      final File metadataFile = File('$sessionPath/metadata.txt');
      if (await metadataFile.exists()) {
        try {
          final metadata = await _readMetadataSummary(metadataFile);
          if (metadata.containsKey('timestamp')) {
            return DateTime.parse(metadata['timestamp']!);
          }
          if (metadata.containsKey('recording_time')) {
            return DateTime.parse(metadata['recording_time']!);
          }
        } catch (e) {
          print('Error parsing timestamp from metadata: $e');
        }
      }

      // Fallback: use directory stats
      try {
        final dirStat = await Directory(sessionPath).stat();
        return dirStat.changed;
      } catch (e) {
        print('Error getting directory stats: $e');
      }

      // Last resort: current time
      return DateTime.now();
    } catch (e) {
      print('Error getting session timestamp: $e');
      return DateTime.now();
    }
  }
}
