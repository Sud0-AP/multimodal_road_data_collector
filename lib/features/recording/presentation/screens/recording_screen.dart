import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/services/camera_service.dart';
import '../../../../core/services/file_storage_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/providers.dart';
import '../../../../features/calibration/presentation/state/calibration_provider.dart';
import '../../domain/managers/recording_session_manager.dart';
import '../providers/recording_lifecycle_provider.dart';
import '../state/recording_state.dart';
import '../state/pre_recording_calibration_state.dart';
import '../widgets/pre_recording_calibration_overlay.dart';

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
    // We can use this to update UI based on sensor data
    // Pothole detection is currently disabled as per user request

    // Debug info about accelerometer data
    // Use this for debug purposes only
    // if (data.accelMagnitude > 15.0) {  // Higher threshold just for extreme values
    //   debugPrint('High acceleration detected: ${data.accelMagnitude}');
    // }
  }

  // Stop recording
  Future<void> _stopRecording() async {
    try {
      // Cancel recording timer
      _recordingTimer?.cancel();
      _recordingTimer = null;

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

    return Scaffold(
      // Using a transparent AppBar to get full screen camera view
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Record Road Data'),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
      ),
      body: _buildBody(
        recordingState,
        calibrationNeeded && !calibrationCompleted,
      ),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Widget _buildBody(RecordingState state, bool calibrationNeeded) {
    switch (state.status) {
      case RecordingStatus.initial:
      case RecordingStatus.initializing:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing camera...'),
            ],
          ),
        );

      case RecordingStatus.error:
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(state.errorMessage ?? 'An error occurred'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeServices,
                child: const Text('Retry'),
              ),
            ],
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

            // Recording duration display when recording
            if (state.status == RecordingStatus.recording)
              Positioned(
                top: kToolbarHeight + MediaQuery.of(context).padding.top + 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Recording: ${_formatDuration(state.recordingDurationSeconds)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
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
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Initial calibration required before recording',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

            // Controls at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildControls(state, calibrationNeeded),
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

  Widget _buildControls(RecordingState state, bool calibrationNeeded) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (state.status == RecordingStatus.recording)
            FloatingActionButton(
              onPressed: _stopRecording,
              backgroundColor: Colors.red,
              child: const Icon(Icons.stop, color: Colors.white),
            )
          else
            FloatingActionButton(
              onPressed:
                  calibrationNeeded
                      ? _checkCalibrationStatus
                      : _startPreRecordingCalibration,
              backgroundColor: calibrationNeeded ? Colors.grey : Colors.red,
              child: const Icon(Icons.fiber_manual_record, color: Colors.white),
            ),
        ],
      ),
    );
  }
}
