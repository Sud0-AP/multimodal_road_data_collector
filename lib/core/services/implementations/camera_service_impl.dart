import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../camera_service.dart';

/// Implementation of CameraService using the camera plugin
class CameraServiceImpl implements CameraService {
  /// Camera controller
  CameraController? _controller;

  /// Available cameras
  List<CameraDescription>? _cameras;

  /// Index of the current camera in the cameras list
  int _cameraIndex = 0;

  /// Current device orientation
  DeviceOrientation _currentOrientation = DeviceOrientation.portraitUp;

  @override
  Future<void> initialize() async {
    try {
      // Get available cameras
      _cameras = await availableCameras();

      if (_cameras == null || _cameras!.isEmpty) {
        throw CameraException('No cameras', 'No cameras available on device');
      }

      // Always use the back camera
      // Find the back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse:
            () =>
                _cameras!
                    .first, // Fallback to the first camera if no back camera
      );

      // Set the camera index to the back camera
      _cameraIndex = _cameras!.indexOf(backCamera);

      // Set up orientation detection
      await _setupOrientationDetection();

      // Initialize with the back camera
      await _initializeCameraController();
    } on CameraException catch (e) {
      // Handle camera initialization errors
      _handleCameraError(e);
    }
  }

  /// Set up device orientation detection
  Future<void> _setupOrientationDetection() async {
    // Enable all orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Get the current device orientation
    _updateCurrentOrientation();

    // Listen for orientation changes
    WidgetsBinding.instance.addObserver(
      _OrientationObserver(
        onOrientationChange: (DeviceOrientation orientation) {
          final previousOrientation = _currentOrientation;
          _currentOrientation = orientation;
          debugPrint('📱 ORIENTATION: Changed to $_currentOrientation');

          // If orientation has actually changed, adjust the camera settings
          if (previousOrientation != _currentOrientation) {
            _handleOrientationChange();
          }
        },
      ),
    );
  }

  /// Update the current orientation based on system metrics
  void _updateCurrentOrientation() {
    // Get orientation from MediaQuery would be better but we don't have BuildContext here
    // Use system metrics as a fallback
    final size = WidgetsBinding.instance.window.physicalSize;
    final orientation =
        size.width > size.height
            ? DeviceOrientation.landscapeLeft
            : DeviceOrientation.portraitUp;

    _currentOrientation = orientation;
    debugPrint('📱 ORIENTATION: Updated to $_currentOrientation');
  }

  /// Handle orientation changes by updating the camera
  Future<void> _handleOrientationChange() async {
    if (!isInitialized) return;

    try {
      // Set the capture orientation to match the new device orientation
      await _setRecordingOrientation();

      // Force a camera settings update to reflect the new orientation
      debugPrint(
        '📱 CAMERA: Adjusting preview for orientation change to $_currentOrientation',
      );

      // This will trigger any listeners to rebuild the camera preview
      if (_controller != null) {
        // Apply auto-focus to trigger a controller refresh
        await _controller!.setFocusMode(FocusMode.auto);
      }
    } catch (e) {
      debugPrint('⚠️ CAMERA: Failed to adjust for orientation change: $e');
    }
  }

  /// Initialize or re-initialize the camera controller
  Future<void> _initializeCameraController() async {
    if (_cameras == null || _cameras!.isEmpty) {
      throw CameraException('No cameras', 'No cameras available on device');
    }

    // Release any previous controller
    await dispose();

    // Create a new controller with the selected camera
    _controller = CameraController(
      _cameras![_cameraIndex],
      ResolutionPreset
          .max, // Using highest resolution (1080p or better if available)
      enableAudio: false, // No audio recording for video
      imageFormatGroup: ImageFormatGroup.jpeg,
    );

    // Initialize the controller
    await _controller!.initialize();

    // Configure video settings for better quality
    // Note: Not all devices support these settings
    try {
      // Set higher video bitrate for better quality (30 Mbps)
      final bitrate = 30 * 1000 * 1000; // 30 Mbps
      await _controller!.setExposureMode(ExposureMode.auto);
      await _controller!.setFocusMode(FocusMode.auto);
    } catch (e) {
      debugPrint('Warning: Could not set advanced camera settings: $e');
    }

    // Do NOT lock orientation here - we want the camera to adapt to the device orientation
    // Instead, handle orientation when starting recording
  }

  /// Set the recording orientation based on the current device orientation
  Future<void> _setRecordingOrientation() async {
    DeviceOrientation recordingOrientation;

    // Determine which orientation to use for recording
    if (_currentOrientation == DeviceOrientation.landscapeLeft ||
        _currentOrientation == DeviceOrientation.landscapeRight) {
      // Use the current landscape orientation
      recordingOrientation = _currentOrientation;
    } else {
      // Default to portrait if not in landscape
      recordingOrientation = DeviceOrientation.portraitUp;
    }

    // Set the capture orientation
    try {
      await _controller!.lockCaptureOrientation(recordingOrientation);
      debugPrint(
        '📱 CAMERA: Set recording orientation to $recordingOrientation',
      );
    } catch (e) {
      debugPrint('⚠️ CAMERA: Failed to set recording orientation: $e');
    }
  }

  @override
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }

  @override
  bool get isInitialized => _controller?.value.isInitialized ?? false;

  @override
  Future<void> startVideoRecording() async {
    if (!isInitialized) {
      debugPrint(
        '❌ CAMERA ERROR: Camera not initialized when attempting to start recording',
      );
      throw CameraException(
        'Camera not initialized',
        'Call initialize() first',
      );
    }

    if (_controller!.value.isRecordingVideo) {
      // Already recording, do nothing
      debugPrint('⚠️ CAMERA: Already recording video, ignoring start request');
      return;
    }

    try {
      // Update orientation detection before recording
      _updateCurrentOrientation();

      // Set the recording orientation based on current device orientation
      await _setRecordingOrientation();

      debugPrint(
        '🎥 CAMERA: Starting video recording at ${DateTime.now().toIso8601String()} in orientation: $_currentOrientation',
      );
      await _controller!.startVideoRecording();
      debugPrint('✅ CAMERA: Video recording started successfully');
    } on CameraException catch (e) {
      debugPrint(
        '❌ CAMERA ERROR: Failed to start video recording: ${e.code} - ${e.description}',
      );
      _handleCameraError(e);
    }
  }

  @override
  Future<String> stopVideoRecording() async {
    if (!isInitialized) {
      debugPrint(
        '❌ CAMERA ERROR: Camera not initialized when attempting to stop recording',
      );
      throw CameraException(
        'Camera not initialized',
        'Call initialize() first',
      );
    }

    if (!_controller!.value.isRecordingVideo) {
      debugPrint('❌ CAMERA ERROR: Not recording video when stop was requested');
      throw CameraException('Not recording', 'No active recording to stop');
    }

    try {
      debugPrint(
        '🎥 CAMERA: Stopping video recording at ${DateTime.now().toIso8601String()}',
      );
      final XFile videoFile = await _controller!.stopVideoRecording();

      // Get file size
      final file = File(videoFile.path);
      if (await file.exists()) {
        final size = await file.length();
        debugPrint(
          '✅ CAMERA: Video recording stopped successfully. File: ${videoFile.path}',
        );
        debugPrint(
          '📊 CAMERA: Recorded video file size: ${(size / 1024 / 1024).toStringAsFixed(2)} MB',
        );
      } else {
        debugPrint(
          '⚠️ CAMERA: Video file does not exist after recording: ${videoFile.path}',
        );
      }

      // Unlock orientation after recording
      try {
        // We don't actually unlock - just recompute the current orientation
        _updateCurrentOrientation();

        // Set the current orientation to match the device
        await _setRecordingOrientation();
      } catch (e) {
        debugPrint(
          '⚠️ CAMERA: Failed to reset orientation after recording: $e',
        );
      }

      return videoFile.path;
    } on CameraException catch (e) {
      debugPrint(
        '❌ CAMERA ERROR: Failed to stop video recording: ${e.code} - ${e.description}',
      );
      _handleCameraError(e);
      return '';
    }
  }

  @override
  Widget get previewWidget {
    if (!isInitialized) {
      // Return a placeholder when camera isn't initialized
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Text(
            'Camera initializing...',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Return the camera preview with a transform to handle orientation
    // Using a key based on orientation to force recreation when orientation changes
    return _buildCameraPreview(key: ValueKey(_currentOrientation));
  }

  /// Build camera preview with appropriate orientation handling
  Widget _buildCameraPreview({Key? key}) {
    // Determine if we are in landscape mode
    final isLandscape =
        _currentOrientation == DeviceOrientation.landscapeLeft ||
        _currentOrientation == DeviceOrientation.landscapeRight;

    debugPrint(
      '📱 CAMERA: Building preview for orientation: $_currentOrientation (isLandscape: $isLandscape)',
    );

    // Use SizedBox.expand to fill the entire available space
    return SizedBox.expand(
      key: key,
      child: FittedBox(
        // Fill the space while maintaining aspect ratio
        fit: BoxFit.cover,
        child: SizedBox(
          width: _controller!.value.previewSize!.height,
          height: _controller!.value.previewSize!.width,
          child: Center(
            child: AspectRatio(
              aspectRatio:
                  isLandscape
                      ? _controller!.value.aspectRatio
                      : 1 / _controller!.value.aspectRatio,
              child: CameraPreview(_controller!),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Future<String> takePicture() async {
    if (!isInitialized) {
      throw CameraException(
        'Camera not initialized',
        'Call initialize() first',
      );
    }

    try {
      // Update orientation detection before taking picture
      _updateCurrentOrientation();

      // Set the capture orientation based on current device orientation
      await _setRecordingOrientation();

      final XFile image = await _controller!.takePicture();
      return image.path;
    } on CameraException catch (e) {
      _handleCameraError(e);
      return '';
    }
  }

  @override
  Future<void> toggleCamera() async {
    if (_cameras == null || _cameras!.length <= 1) {
      // Only one camera available, cannot toggle
      return;
    }

    // Switch to the next camera
    _cameraIndex = (_cameraIndex + 1) % _cameras!.length;

    // Re-initialize with the new camera
    await _initializeCameraController();
  }

  @override
  int get currentCameraLensDirection {
    if (_cameras == null || _cameras!.isEmpty || _controller == null) {
      return CameraLensDirection.back.index;
    }

    return _cameras![_cameraIndex].lensDirection.index;
  }

  /// Handle camera exceptions
  void _handleCameraError(CameraException e) {
    // Log the error
    debugPrint('Camera error: ${e.code} - ${e.description}');

    // Rethrow the exception
    throw e;
  }

  // Methods for testing purposes

  /// Set the camera controller (for testing)
  @visibleForTesting
  void testSetController(CameraController? controller) {
    _controller = controller;
  }

  /// Get the camera controller (for testing)
  @visibleForTesting
  CameraController? testGetController() {
    return _controller;
  }
}

/// Observer for device orientation changes
class _OrientationObserver with WidgetsBindingObserver {
  /// Callback for orientation changes
  final Function(DeviceOrientation) onOrientationChange;

  /// Constructor
  _OrientationObserver({required this.onOrientationChange});

  @override
  void didChangeMetrics() {
    // Get current orientation
    final size = WidgetsBinding.instance.window.physicalSize;
    final orientation =
        size.width > size.height
            ? DeviceOrientation.landscapeLeft
            : DeviceOrientation.portraitUp;

    // Notify the callback
    onOrientationChange(orientation);
  }
}
