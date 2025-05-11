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

      // Initialize with the back camera
      await _initializeCameraController();
    } on CameraException catch (e) {
      // Handle camera initialization errors
      _handleCameraError(e);
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

    // Lock orientation to portrait mode
    await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);
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
      debugPrint(
        '🎥 CAMERA: Starting video recording at ${DateTime.now().toIso8601String()}',
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

    // Return the camera preview
    return CameraPreview(_controller!);
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
