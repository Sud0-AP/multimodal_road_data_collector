import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as path;

import '../../../../app/router.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/file_storage_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/providers.dart';
import '../../../../features/calibration/presentation/state/calibration_provider.dart';
import '../../../../features/calibration/data/repositories/providers.dart';
import '../../domain/managers/recording_session_manager.dart';
import '../../domain/models/corrected_sensor_data_point.dart';
import '../providers/recording_lifecycle_provider.dart';
import '../state/recording_state.dart';
import '../state/pre_recording_calibration_state.dart';
import '../state/spike_detection_notifier.dart';
import '../state/providers.dart';
import '../widgets/pre_recording_calibration_overlay.dart';
import '../widgets/annotation_prompt_overlay.dart';
import '../../../recordings/presentation/providers/recordings_providers.dart';

// Enum to define the position of buttons for different layout adjustments
enum ButtonPosition { left, center, right }

/// Recording screen with camera preview and recording controls
class RecordingScreen extends ConsumerStatefulWidget {
  /// Constructor
  const RecordingScreen({super.key});

  @override
  ConsumerState<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends ConsumerState<RecordingScreen> {
  // Timer for tracking recording duration
  Timer? _recordingTimer;

  // Services
  late final CameraService _cameraService;
  late final FileStorageService _fileStorageService;
  late final PermissionService _permissionService;
  late final RecordingSessionManager _recordingSessionManager;

  // Flag for sensor initialization status
  bool _isSensorInitialized = false;

  // Subscription to sensor data
  StreamSubscription? _sensorDataSubscription;

  @override
  void initState() {
    super.initState();
    // Just initialize the service references in initState
    _cameraService = ref.read(cameraServiceProvider);
    _fileStorageService = ref.read(fileStorageServiceProvider);
    _permissionService = ref.read(permissionServiceProvider);
    _recordingSessionManager = ref.read(recordingSessionManagerProvider);

    // Schedule the actual initialization after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
      _checkCalibrationStatus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // Ensure spike detection is initialized if recording is in progress
    // This handles cases like device rotation or app resume
    final recordingState = ref.read(recordingStateProvider);
    if (recordingState.status == RecordingStatus.recording &&
        recordingState.bumpThreshold != null) {
      // Re-initialize spike detection if needed
      final spikeDetectionNotifier = ref.read(spikeDetectionProvider.notifier);
      if (!ref.read(spikeDetectionProvider).isDetectionActive) {
        debugPrint('🔄 Re-initializing spike detection after state change');
        spikeDetectionNotifier.initialize(
          bumpThreshold: recordingState.bumpThreshold!,
          refractoryPeriodMs: 8000,
        );
      }
    }
  }

  // Initialize all required services
  Future<void> _initializeServices() async {
    // Get the state notifier
    final notifier = ref.read(recordingStateProvider.notifier);

    // Set state to initializing
    notifier.initialize();

    try {
      final hasCameraPermission =
          await _permissionService.requestCameraPermission();

      // We need storage permission to save to Downloads folder
      final hasStoragePermission =
          await _permissionService.requestStoragePermission();

      if (!hasCameraPermission) {
        notifier.setError('Camera permission denied');
        return;
      }

      if (!hasStoragePermission) {
        notifier.setError('Storage permission is required to save recordings');
        return;
      }

      await _cameraService.initialize();

      // Initialize the sensor service
      await _recordingSessionManager.initialize();
      _isSensorInitialized = true;

      notifier.setReady();
    } catch (e) {
      notifier.setError('Error initializing services: $e');
    }
  }

  // Check if calibration is completed
  void _checkCalibrationStatus() {
    final calibrationNeeded = ref.read(calibrationNeededProvider);
    final calibrationCompleted = ref.read(calibrationCompletedProvider);

    if (calibrationNeeded && !calibrationCompleted && mounted) {
      // Show dialog prompting for calibration
      showDialog(
        context: context,
        barrierDismissible: false,
        builder:
            (context) => AlertDialog(
              title: const Text('Calibration Required'),
              content: const Text(
                'You need to complete the initial calibration before recording. '
                'Please keep your device still during calibration.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(AppRoutes.calibrationPath);
                  },
                  child: const Text('Go to Calibration'),
                ),
              ],
            ),
      );
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _sensorDataSubscription?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  // Initiate pre-recording calibration before starting recording
  Future<void> _startPreRecordingCalibration() async {
    try {
      // First check if initial calibration is completed
      final calibrationNeeded = ref.read(calibrationNeededProvider);
      final calibrationCompleted = ref.read(calibrationCompletedProvider);

      if (calibrationNeeded && !calibrationCompleted) {
        // Show dialog prompting for calibration
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder:
                (context) => AlertDialog(
                  title: const Text('Calibration Required'),
                  content: const Text(
                    'You need to complete the initial calibration before recording. '
                    'Please keep your device still during calibration.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.go(AppRoutes.calibrationPath);
                      },
                      child: const Text('Go to Calibration'),
                    ),
                  ],
                ),
          );
        }
        return; // Don't proceed with pre-recording calibration
      }

      // Reset pre-recording calibration state
      ref.read(preRecordingCalibrationProvider.notifier).reset();

      // Update recording state
      ref.read(recordingStateProvider.notifier).startCalibration();
    } catch (e) {
      ref
          .read(recordingStateProvider.notifier)
          .setError('Error starting calibration: $e');
    }
  }

  // Handle successful calibration completion
  void _handleCalibrationComplete(
    double sessionAccelOffsetZ,
    double gyroZDrift,
    double bumpThreshold,
  ) {
    // Update recording state
    ref
        .read(recordingStateProvider.notifier)
        .completeCalibration(
          sessionAccelOffsetZ: sessionAccelOffsetZ,
          gyroZDrift: gyroZDrift,
          bumpThreshold: bumpThreshold,
        );

    // Apply session calibration parameters to the recording session manager
    _recordingSessionManager.setSessionCalibrationParameters(
      sessionAccelOffsetZ: sessionAccelOffsetZ,
      gyroZDrift: gyroZDrift,
      bumpThreshold: bumpThreshold,
    );

    // Start the actual recording
    _startRecording();
  }

  // Handle calibration failure
  void _handleCalibrationFailed() {
    // Update recording state
    ref.read(recordingStateProvider.notifier).failCalibration();

    // Show error message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Calibration failed. Please try again.'),
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  // Start recording
  Future<void> _startRecording() async {
    try {
      final notifier = ref.read(recordingStateProvider.notifier);
      final lifecycleNotifier = ref.read(recordingLifecycleProvider.notifier);

      // Create a session directory for this recording
      final sessionDir = await _fileStorageService.createSessionDirectory();
      debugPrint('📁 RECORDING: Created session directory: $sessionDir');

      // Update recording state with session path
      notifier.setSessionPath(sessionDir);

      debugPrint(
        '🎬 VIDEO: Starting recording session at ${DateTime.now().toIso8601String()}',
      );

      // Start the recording session using the lifecycle-aware provider
      // This ensures proper handling of app lifecycle events
      await lifecycleNotifier.startRecording(sessionDir);

      // Set up a subscription to process sensor data if needed
      // This might be used later for UI feedback during recording
      if (_isSensorInitialized) {
        _sensorDataSubscription = _recordingSessionManager
            .getProcessedSensorStream()
            .listen(_handleSensorData);
      }

      // Start video recording
      await _cameraService.startVideoRecording();
      debugPrint(
        '🎥 VIDEO: Recording started at ${DateTime.now().toIso8601String()}',
      );

      notifier.startRecording();

      // Start a timer to update recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        notifier.updateDuration(timer.tick);
      });
    } catch (e) {
      debugPrint('❌ ERROR starting recording: $e');
      ref
          .read(recordingStateProvider.notifier)
          .setError('Error starting recording: $e');
    }
  }

  void _handleSensorData(ProcessedSensorData data) {
    // Skip if we're not recording or don't have a session directory
    if (ref.read(recordingStateProvider).status != RecordingStatus.recording ||
        ref.read(recordingStateProvider).sessionPath == null) {
      return;
    }

    final sessionPath = ref.read(recordingStateProvider).sessionPath!;
    final bumpThreshold = ref.read(recordingStateProvider).bumpThreshold;

    // Initialize spike detection if not already done
    final spikeDetectionNotifier = ref.read(spikeDetectionProvider.notifier);
    if (!ref.read(spikeDetectionProvider).isDetectionActive &&
        bumpThreshold != null) {
      spikeDetectionNotifier.initialize(
        bumpThreshold: bumpThreshold,
        refractoryPeriodMs:
            8000, // Updated to 8 seconds refractory period to match implementation
      );
    }

    // Process the corrected sensor data point
    final correctedDataPoint = CorrectedSensorDataPoint.fromProcessedData(
      relativeTimestampMs:
          data.rawData.timestamp -
          _recordingSessionManager.getMonotonicStartTimeMs()!,
      accelX: data.rawData.accelerometerX,
      accelY: data.rawData.accelerometerY,
      correctedAccelZ: data.correctedAccelZ,
      accelMagnitude: data.accelMagnitude,
      gyroX: data.rawData.gyroscopeX,
      gyroY: data.rawData.gyroscopeY,
      correctedGyroZ: data.correctedGyroZ,
      isPothole:
          false, // Initialize to false, will be updated below if detected
    );

    // Process the data point and check if a spike was detected
    final spikeDetected = spikeDetectionNotifier.processSensorDataPoint(
      correctedDataPoint,
    );

    // Update the isPothole flag in the data point if a spike was detected
    // This ensures CSV data correctly reflects actual detected potholes (not false positives)
    final correctedDataPointWithPotholeFlag =
        spikeDetected
            ? correctedDataPoint.copyWith(isPothole: true)
            : correctedDataPoint;

    // Try to update the buffer with the corrected data point (with proper isPothole flag)
    // This might fail if the data has already been flushed to disk
    final updated = _recordingSessionManager.updateDataPoint(
      correctedDataPointWithPotholeFlag,
    );

    // If it's a pothole detection and we couldn't update it in the buffer (already written)
    // we should log this special case (as the CSV will have incorrect isPothole flags)
    if (spikeDetected && !updated) {
      // Consider logging this special case for debugging
      debugPrint(
        '⚠️ Pothole was detected but data point was already written to CSV',
      );
    }

    // If a spike is detected, show the annotation prompt
    if (spikeDetected && mounted) {
      // Get or create an AnnotationPromptOverlay
      final annotationOverlay = AnnotationPromptOverlay(context);

      // Show the overlay with callback to log the annotation
      annotationOverlay.show(
        onResponse: (String response) {
          // Get the last spike timestamp
          final spikeTimestamp =
              ref.read(spikeDetectionProvider).lastSpikeTimestampMs;
          if (spikeTimestamp != null) {
            // Log the annotation
            _fileStorageService.logAnnotation(
              sessionPath,
              spikeTimestamp,
              response,
            );

            // Update the isPothole flag and user feedback for ALL data points in the
            // window (5 seconds before and 5 seconds after the spike)
            // Calculate window boundaries (5 seconds = ~500 data points at 100Hz)
            final windowStartMs = spikeTimestamp - 5000; // 5 seconds before
            final windowEndMs = spikeTimestamp + 5000; // 5 seconds after

            // Set isPothole based on user response
            // Yes = true, No = false, Uncategorized = -1 (special case)
            bool isPothole = false;
            if (response == 'Yes') {
              isPothole = true;
            } else if (response == 'Uncategorized') {
              // For Uncategorized, we'll still mark it in the CSV
              // but with a special flag indicating timeout/uncategorized
              isPothole = false; // In CSV we'll use 0 for Uncategorized as well
            }

            // Update all data points in the time window using the more efficient method
            _recordingSessionManager
                .updateDataPointsInWindow(
                  windowStartMs,
                  windowEndMs,
                  isPothole,
                  response,
                )
                .then((updatedCount) {
                  debugPrint(
                    'Updated $updatedCount data points for annotation window',
                  );
                });

            debugPrint(
              'Annotation logged: $spikeTimestamp,$response with window [$windowStartMs-$windowEndMs]ms',
            );
          }
        },
      );
    }
  }

  // Stop recording
  Future<void> _stopRecording() async {
    try {
      // Cancel recording timer
      _recordingTimer?.cancel();
      _recordingTimer = null;

      // Stop spike detection
      ref.read(spikeDetectionProvider.notifier).stopDetection();

      debugPrint(
        '🎬 VIDEO: Stopping recording at ${DateTime.now().toIso8601String()}',
      );

      // Get the current session directory before stopping the recording
      // This will prevent the "No session directory available" error
      final recordingState = ref.read(recordingStateProvider);
      final sessionDir = recordingState.sessionPath;
      if (sessionDir == null) {
        debugPrint('⚠️ Warning: No session directory in state, creating one');
        // If session directory is null, get it from the recording manager
        // or create one as a fallback
        final sessionDirectory =
            await _fileStorageService.createSessionDirectory();
        ref
            .read(recordingStateProvider.notifier)
            .setSessionPath(sessionDirectory);
        debugPrint(
          '📁 RECORDING: Created fallback session directory: $sessionDirectory',
        );
      }

      // Stop the recording using the lifecycle-aware provider
      final lifecycleNotifier = ref.read(recordingLifecycleProvider.notifier);
      await lifecycleNotifier.stopRecording();

      // Cancel sensor data subscription
      await _sensorDataSubscription?.cancel();
      _sensorDataSubscription = null;

      // Stop video recording
      debugPrint('🎥 VIDEO: Stopping video recording...');
      final videoPath = await _cameraService.stopVideoRecording();
      debugPrint(
        '🎥 VIDEO: Recording stopped at ${DateTime.now().toIso8601String()}',
      );
      debugPrint('🎥 VIDEO: Temporary video path: $videoPath');

      ref.read(recordingStateProvider.notifier).stopRecording(videoPath);

      // Get the session directory again in case it was updated
      final updatedSessionDir = ref.read(recordingStateProvider).sessionPath;
      if (updatedSessionDir == null) {
        throw Exception(
          'No session directory available after stopping recording',
        );
      }

      // Save the video to the session directory
      debugPrint(
        '🎥 VIDEO: Saving video from $videoPath to $updatedSessionDir',
      );
      final savedPath = await _fileStorageService.saveVideoToSession(
        videoPath,
        updatedSessionDir,
      );

      // Verify the saved video exists
      final savedFile = File(savedPath);
      final exists = await savedFile.exists();
      if (!exists) {
        debugPrint(
          '❌ ERROR: Saved video file does not exist at path: $savedPath',
        );
      } else {
        final size = await savedFile.length();
        debugPrint(
          '✅ VIDEO: Saved successfully at: $savedPath (${(size / 1024 / 1024).toStringAsFixed(2)} MB)',
        );
      }

      ref
          .read(recordingStateProvider.notifier)
          .saveRecording(updatedSessionDir);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording saved to $savedPath'),
            duration: const Duration(seconds: 4),
          ),
        );
      }

      // Verify that both video and CSV files are in the same directory
      final videoFile = File(savedPath);
      final videoDir = videoFile.parent.path;

      // Get the CSV file path
      final csvPath = await _fileStorageService.getSensorDataCsvPath(
        updatedSessionDir,
      );
      final csvFile = File(csvPath);
      final csvExists = await csvFile.exists();

      debugPrint('📊 VERIFICATION: Video directory: $videoDir');
      debugPrint('📊 VERIFICATION: CSV path: $csvPath');
      debugPrint('📊 VERIFICATION: CSV exists: $csvExists');

      if (csvExists) {
        final csvSize = await csvFile.length();
        debugPrint(
          '📊 VERIFICATION: CSV file size: ${(csvSize / 1024).toStringAsFixed(2)} KB',
        );
        debugPrint(
          '📊 VERIFICATION: CSV contains approximately ${csvSize ~/ 100} data points',
        );
      }

      // Generate metadata.txt file
      final recState = ref.read(recordingStateProvider);

      // Load the actual calibration data from repository
      final calibrationRepository = ref.read(calibrationRepositoryProvider);
      final initialCalibrationData =
          await calibrationRepository.loadInitialCalibrationData();

      // Get actual sampling rate using multiple methods for reliability
      double actualSamplingRate;

      // Primary method: Use the recording session manager's calculation
      final calculatedRate =
          _recordingSessionManager.calculateActualSamplingRateHz();

      if (calculatedRate != null && calculatedRate > 0) {
        // Use the calculated rate from session manager if available
        actualSamplingRate = calculatedRate;
        debugPrint(
          '📊 SENSOR RATE: Using calculated rate: ${actualSamplingRate.toStringAsFixed(2)} Hz',
        );
      } else {
        // Fallback method 1: Calculate based on the number of data points and recording duration
        try {
          final csvPath = await _fileStorageService.getSensorDataCsvPath(
            updatedSessionDir,
          );
          final csvFile = File(csvPath);
          if (await csvFile.exists()) {
            final csvSize = await csvFile.length();
            final approximateDataPoints =
                csvSize ~/ 100; // Rough estimate based on file size

            // Calculate using the recording duration and approximate data points
            actualSamplingRate =
                approximateDataPoints / recState.recordingDurationSeconds;
            debugPrint(
              '📊 SENSOR RATE: Calculated from CSV size: ${actualSamplingRate.toStringAsFixed(2)} Hz',
            );
          } else {
            // Fallback method 2: Use a more reasonable default based on device capabilities
            actualSamplingRate =
                100.0; // More realistic default than 50Hz for modern devices
            debugPrint(
              '📊 SENSOR RATE: Using default rate (100 Hz) as CSV file not found',
            );
          }
        } catch (e) {
          // Final fallback: Use a reasonable default
          actualSamplingRate = 100.0;
          debugPrint(
            '📊 SENSOR RATE: Using default rate (100 Hz) due to error: $e',
          );
        }
      }

      // Create recording completion data with all necessary information
      final Map<String, dynamic> recordingData = {
        'sessionId': path.basename(updatedSessionDir),
        'durationSeconds': recState.recordingDurationSeconds,
        'orientationMode':
            initialCalibrationData?.deviceOrientation.toString() ?? 'portrait',
        'accelOffsetX': initialCalibrationData?.accelerometerXOffset ?? 0.0,
        'accelOffsetY': initialCalibrationData?.accelerometerYOffset ?? 0.0,
        'accelOffsetZ': initialCalibrationData?.accelerometerZOffset ?? 0.0,
        'gyroOffsetX': initialCalibrationData?.gyroscopeXOffset ?? 0.0,
        'gyroOffsetY': initialCalibrationData?.gyroscopeYOffset ?? 0.0,
        'gyroOffsetZ': initialCalibrationData?.gyroscopeZOffset ?? 0.0,
        'sessionAdjustedAccelZ': recState.sessionAccelOffsetZ ?? 0.0,
        'bumpThreshold': recState.bumpThreshold ?? 0.0,
        'gyroZDrift': recState.gyroZDrift ?? 0.0,
        'calibrationTimestamp':
            initialCalibrationData?.calibrationTimestamp ??
            recState.calibrationTimestamp ??
            DateTime.now().millisecondsSinceEpoch,
        'calibrationSamplesCount':
            initialCalibrationData?.calibrationSamplesCount ??
            recState.calibrationSamplesCount ??
            0,
        'videoStartNtp': DateTime.now().subtract(
          Duration(seconds: recState.recordingDurationSeconds),
        ),
        'videoEndNtp': DateTime.now(),
        'sensorStartNtp': DateTime.now().subtract(
          Duration(seconds: recState.recordingDurationSeconds),
        ),
        'sensorEndNtp': DateTime.now(),
        'sensorStartMonotonicMs': 0,
        'sensorEndMonotonicMs': recState.recordingDurationSeconds * 1000,
        'actualSamplingRateHz': actualSamplingRate,
        'videoResolution': '1920x1080', // Default resolution
        'warnings': <String>[], // Empty list of strings for warnings
      };

      // Add the import for the recordings notifier provider
      try {
        // Call generateAndSaveMetadata on the DataManagementService directly
        final dataManagementService = ref.read(dataManagementServiceProvider);
        final metadataSuccess = await dataManagementService
            .generateAndSaveMetadata(updatedSessionDir, recordingData);

        if (metadataSuccess) {
          debugPrint('✅ METADATA: Generated and saved successfully');
        } else {
          // If the service-level save fails, try a direct file write as a fallback
          debugPrint(
            '⚠️ METADATA: Primary method failed, trying fallback method',
          );

          // Create basic metadata content
          final basicMetadata = StringBuffer();
          basicMetadata.writeln('--- Recording Session Metadata ---');
          basicMetadata.writeln('Session ID: ${recordingData['sessionId']}');
          basicMetadata.writeln(
            'Recording Duration (s): ${recordingData['durationSeconds']}',
          );
          basicMetadata.writeln(
            'Actual Sampling Rate (Hz): ${recordingData['actualSamplingRateHz']}',
          );
          basicMetadata.writeln(
            'Calibration Timestamp: ${DateTime.fromMillisecondsSinceEpoch(recordingData['calibrationTimestamp'] as int).toIso8601String()}',
          );
          basicMetadata.writeln(
            'Calibration Samples Count: ${recordingData['calibrationSamplesCount']}',
          );

          // Try to write directly
          final fileStorageService = ref.read(fileStorageServiceProvider);
          final fallbackSuccess = await fileStorageService.writeMetadata(
            basicMetadata.toString(),
            updatedSessionDir,
          );

          if (fallbackSuccess) {
            debugPrint('✅ METADATA: Fallback method successful');
          } else {
            debugPrint('❌ METADATA: All metadata generation methods failed');
            // Even if metadata fails, we don't throw an exception here
            // The recording is still valid and usable without metadata
          }
        }
      } catch (e) {
        // Log the error but continue - metadata is helpful but not critical
        debugPrint('❌ METADATA ERROR: $e');
        debugPrint('⚠️ Continuing without metadata - recording is still saved');
      }
    } catch (e) {
      debugPrint('❌ ERROR stopping recording: $e');
      ref
          .read(recordingStateProvider.notifier)
          .setError('Error stopping recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingStateProvider);
    final calibrationNeeded = ref.watch(calibrationNeededProvider);
    final calibrationCompleted = ref.watch(calibrationCompletedProvider);
    // Watch the recording lifecycle state to ensure the UI stays in sync
    final isRecording = ref.watch(recordingLifecycleProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;

    return Scaffold(
      // Using a transparent AppBar to get full screen camera view
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(''), // Removed title text
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _buildBody(
        recordingState,
        calibrationNeeded && !calibrationCompleted,
        isLandscape,
        colorScheme,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildBody(
    RecordingState state,
    bool calibrationNeeded,
    bool isLandscape,
    ColorScheme colorScheme,
  ) {
    switch (state.status) {
      case RecordingStatus.initial:
      case RecordingStatus.initializing:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Initializing camera...'),
              const SizedBox(height: 8),
              Text(
                'Please wait',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        );

      case RecordingStatus.error:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 48),
                const SizedBox(height: 16),
                Text(
                  state.errorMessage ?? 'An error occurred',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: colorScheme.error),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _initializeServices,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );

      case RecordingStatus.ready:
      case RecordingStatus.recording:
      case RecordingStatus.stopped:
      case RecordingStatus.saved:
        return Stack(
          children: [
            // Camera preview takes full screen
            SizedBox.expand(
              child:
                  _cameraService.isInitialized
                      ? _cameraService.previewWidget
                      : const ColoredBox(
                        color: Colors.black,
                        child: Center(
                          child: Text(
                            'Camera not initialized',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
            ),

            // Recording duration display and indicators
            if (state.status == RecordingStatus.recording)
              Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.7),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Colors.red, size: 14),
                        const SizedBox(width: 8),
                        Text(
                          'REC ${_formatDuration(state.recordingDurationSeconds)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Calibration required warning banner
            if (calibrationNeeded)
              Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.warning_amber_rounded,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        const Flexible(
                          child: Text(
                            'Calibration required before recording',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Controls - positioned based on orientation
            isLandscape
                ? Positioned(
                  right: 24,
                  top: 0,
                  bottom: 0,
                  child: _buildLandscapeControls(
                    state,
                    calibrationNeeded,
                    colorScheme,
                  ),
                )
                : Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: _buildPortraitControls(
                    state,
                    calibrationNeeded,
                    colorScheme,
                  ),
                ),

            // Calibration overlay
            if (state.status == RecordingStatus.calibrating)
              PreRecordingCalibrationOverlay(
                onCalibrationComplete: _handleCalibrationComplete,
                onCalibrationFailed: _handleCalibrationFailed,
              ),
          ],
        );

      case RecordingStatus.calibrating:
        return Stack(
          children: [
            // Camera preview in background
            SizedBox.expand(
              child:
                  _cameraService.isInitialized
                      ? _cameraService.previewWidget
                      : const ColoredBox(
                        color: Colors.black,
                        child: Center(
                          child: Text(
                            'Camera not initialized',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
            ),

            // Calibration overlay
            PreRecordingCalibrationOverlay(
              onCalibrationComplete: _handleCalibrationComplete,
              onCalibrationFailed: _handleCalibrationFailed,
            ),
          ],
        );
    }
  }

  Widget _buildLandscapeControls(
    RecordingState state,
    bool calibrationNeeded,
    ColorScheme colorScheme,
  ) {
    // Use primary color for all non-record buttons
    final buttonColor = colorScheme.primary;

    return Center(
      child: Container(
        width: 100,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Settings button (top)
            _buildControlButton(
              onPressed: () => context.pushNamed(AppRoutes.settings),
              icon: Icons.settings,
              label: 'Settings',
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              isLandscape: true,
              buttonSize: 60,
            ),

            const SizedBox(height: 32),

            // Record/Stop button (middle)
            state.status == RecordingStatus.recording
                ? _buildControlButton(
                  onPressed: _stopRecording,
                  icon: Icons.stop,
                  label: 'Stop',
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  isMain: true,
                  isLandscape: true,
                  buttonSize: 70,
                )
                : _buildControlButton(
                  onPressed:
                      calibrationNeeded
                          ? _checkCalibrationStatus
                          : _startPreRecordingCalibration,
                  icon: Icons.fiber_manual_record,
                  label: 'Record',
                  backgroundColor: calibrationNeeded ? Colors.grey : Colors.red,
                  foregroundColor: Colors.white,
                  isMain: true,
                  isLandscape: true,
                  buttonSize: 70,
                ),

            const SizedBox(height: 32),

            // Recordings button (bottom)
            _buildControlButton(
              onPressed: () => context.pushNamed(AppRoutes.recordings),
              icon: Icons.folder,
              label: 'Recordings',
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              isLandscape: true,
              buttonSize: 60,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortraitControls(
    RecordingState state,
    bool calibrationNeeded,
    ColorScheme colorScheme,
  ) {
    // Use primary color for all non-record buttons
    final buttonColor = colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Settings button (left side)
            _buildControlButton(
              onPressed: () => context.pushNamed(AppRoutes.settings),
              icon: Icons.settings,
              label: 'Settings',
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              isLandscape: false,
              buttonSize: 60,
            ),

            // Record/Stop button (center)
            state.status == RecordingStatus.recording
                ? _buildControlButton(
                  onPressed: _stopRecording,
                  icon: Icons.stop,
                  label: 'Stop',
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  isMain: true,
                  isLandscape: false,
                  buttonSize: 70,
                )
                : _buildControlButton(
                  onPressed:
                      calibrationNeeded
                          ? _checkCalibrationStatus
                          : _startPreRecordingCalibration,
                  icon: Icons.fiber_manual_record,
                  label: 'Record',
                  backgroundColor: calibrationNeeded ? Colors.grey : Colors.red,
                  foregroundColor: Colors.white,
                  isMain: true,
                  isLandscape: false,
                  buttonSize: 70,
                ),

            // Recordings button (right side)
            _buildControlButton(
              onPressed: () => context.pushNamed(AppRoutes.recordings),
              icon: Icons.folder,
              label: 'Recordings',
              backgroundColor: buttonColor,
              foregroundColor: Colors.white,
              isLandscape: false,
              buttonSize: 60,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required VoidCallback onPressed,
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required Color foregroundColor,
    bool isMain = false,
    required bool isLandscape,
    double buttonSize = 50,
  }) {
    if (isLandscape) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: onPressed,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 4,
            heroTag: null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(isMain ? 16 : 12),
            ),
            child: Icon(icon, size: isMain ? 32 : 24),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }

    // For portrait mode
    if (isMain) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        backgroundColor: backgroundColor,
        foregroundColor: foregroundColor,
        elevation: 6,
        heroTag: null,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: Icon(icon, size: 28),
        label: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
            fontSize: 16,
          ),
        ),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            onPressed: onPressed,
            backgroundColor: backgroundColor,
            foregroundColor: foregroundColor,
            elevation: 4,
            heroTag: null,
            mini: true,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.7),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      );
    }
  }
}
