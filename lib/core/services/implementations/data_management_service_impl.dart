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

  @override
  Future<Map<String, dynamic>?> getSessionDisplayInfo(
    String sessionPath,
  ) async {
    try {
      // Read essential metadata
      final metadataKeys = [
        'Recording Duration (s)',
        'Session ID',
        'Video Resolution',
      ];

      final metadata = await _fileStorageService.readMetadataSummary(
        sessionPath,
        metadataKeys,
      );

      if (metadata == null) {
        // If metadata is missing, try to extract basic info from the path
        final sessionId = path.basename(sessionPath);
        DateTime? timestamp;

        // Try to parse timestamp from sessionId
        try {
          // Expecting format: YYYYMMDD_HHMMSS
          if (sessionId.contains('_')) {
            timestamp = DateFormat('yyyyMMdd_HHmmss').parse(sessionId);
          }
        } catch (e) {
          // If parsing fails, use directory's creation time
          try {
            final dirStat = await Directory(sessionPath).stat();
            timestamp = dirStat.changed;
          } catch (e) {
            // If all fails, use current time
            timestamp = DateTime.now();
          }
        }

        return {
          'sessionId': sessionId,
          'sessionPath': sessionPath,
          'timestamp': timestamp ?? DateTime.now(),
          'durationSeconds': 0, // Unknown duration
          'videoFileName': 'video.mp4', // Assumed default
          'sensorDataFileName': 'sensors.csv', // Assumed default
        };
      }

      // Try to parse timestamp from the Session ID
      final sessionId = metadata['Session ID'] ?? path.basename(sessionPath);
      DateTime timestamp;

      try {
        // Try to parse from the session ID (expected format: YYYYMMDD_HHMMSS)
        timestamp = DateFormat('yyyyMMdd_HHmmss').parse(sessionId);
      } catch (e) {
        // Fallback: use current time
        timestamp = DateTime.now();
      }

      // Parse duration - default to 0 if parsing fails
      int durationSeconds = 0;
      try {
        final durationStr = metadata['Recording Duration (s)'];
        if (durationStr != null) {
          durationSeconds = int.parse(durationStr);
        }
      } catch (e) {
        // Keep default duration
      }

      // Check for video and sensor files
      final videoFile = File(path.join(sessionPath, 'video.mp4'));
      final sensorFile = File(path.join(sessionPath, 'sensors.csv'));

      final videoFileName = await videoFile.exists() ? 'video.mp4' : null;
      final sensorDataFileName =
          await sensorFile.exists() ? 'sensors.csv' : null;

      return {
        'sessionId': sessionId,
        'sessionPath': sessionPath,
        'timestamp': timestamp,
        'durationSeconds': durationSeconds,
        'videoFileName': videoFileName,
        'sensorDataFileName': sensorDataFileName,
      };
    } catch (e) {
      // Log error
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
      // Note: For text parameter, we need to check if this is Android or iOS
      // On Android, text must be a String not CharSequence
      // Use null for the text parameter to avoid issues with type casting
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
}
