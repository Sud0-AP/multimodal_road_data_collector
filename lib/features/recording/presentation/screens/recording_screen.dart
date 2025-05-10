import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/camera_service.dart';
import '../../../../core/services/file_storage_service.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/providers.dart';
import '../state/recording_state.dart';

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

  @override
  void initState() {
    super.initState();
    // Just initialize the service references in initState
    _cameraService = ref.read(cameraServiceProvider);
    _fileStorageService = ref.read(fileStorageServiceProvider);
    _permissionService = ref.read(permissionServiceProvider);

    // Schedule the actual initialization after the build is complete
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServices();
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
      notifier.setReady();
    } catch (e) {
      notifier.setError('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _cameraService.dispose();
    super.dispose();
  }

  // Start recording
  Future<void> _startRecording() async {
    try {
      final notifier = ref.read(recordingStateProvider.notifier);

      // Start video recording
      await _cameraService.startVideoRecording();
      notifier.startRecording();

      // Start a timer to update recording duration
      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        notifier.updateDuration(timer.tick);
      });
    } catch (e) {
      ref
          .read(recordingStateProvider.notifier)
          .setError('Error starting recording: $e');
    }
  }

  // Stop recording
  Future<void> _stopRecording() async {
    try {
      // Cancel the duration timer
      _recordingTimer?.cancel();
      _recordingTimer = null;

      // Stop video recording
      final videoPath = await _cameraService.stopVideoRecording();
      ref.read(recordingStateProvider.notifier).stopRecording(videoPath);

      // Create a session directory and save the video
      final sessionDir = await _fileStorageService.createSessionDirectory();
      final savedPath = await _fileStorageService.saveVideoToSession(
        videoPath,
        sessionDir,
      );

      ref.read(recordingStateProvider.notifier).saveRecording(sessionDir);

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Recording saved to $savedPath'),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      ref
          .read(recordingStateProvider.notifier)
          .setError('Error stopping recording: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final recordingState = ref.watch(recordingStateProvider);

    return Scaffold(
      // Using a transparent AppBar to get full screen camera view
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('Record Road Data'),
        backgroundColor: Colors.black.withOpacity(0.5),
        elevation: 0,
      ),
      body: _buildBody(recordingState),
    );
  }

  Widget _buildBody(RecordingState state) {
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
              const SizedBox(height: 24),
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

            // Controls at the bottom
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: _buildControls(state),
            ),
          ],
        );
    }
  }

  Widget _buildControls(RecordingState state) {
    return Container(
      color: Colors.black.withOpacity(0.5),
      padding: const EdgeInsets.symmetric(vertical: 20.0),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Record button
            if (state.status == RecordingStatus.ready)
              _buildControlButton(
                icon: Icons.circle,
                color: Colors.red,
                onPressed: _startRecording,
                label: 'Record',
              ),

            // Stop button
            if (state.status == RecordingStatus.recording)
              _buildControlButton(
                icon: Icons.stop,
                color: Colors.white,
                onPressed: _stopRecording,
                label: 'Stop',
              ),

            // Reset button after recording
            if (state.status == RecordingStatus.saved ||
                state.status == RecordingStatus.stopped)
              _buildControlButton(
                icon: Icons.refresh,
                color: Colors.blue,
                onPressed:
                    () => ref.read(recordingStateProvider.notifier).reset(),
                label: 'New',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
    required String label,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: onPressed,
          icon: Icon(icon, size: 40, color: color),
          padding: const EdgeInsets.all(12),
        ),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
