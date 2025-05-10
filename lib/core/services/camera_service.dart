/// Interface for handling camera operations
abstract class CameraService {
  /// Initialize the camera
  Future<void> initialize();

  /// Dispose of camera resources
  Future<void> dispose();

  /// Check if camera is initialized
  bool get isInitialized;

  /// Start video recording
  Future<void> startVideoRecording();

  /// Stop video recording and return the file path
  Future<String> stopVideoRecording();

  /// Get the camera preview widget
  dynamic get previewWidget;

  /// Take a picture and return the file path
  Future<String> takePicture();

  /// Toggle between front and back camera
  Future<void> toggleCamera();

  /// Get the current camera lens direction (front or back)
  int get currentCameraLensDirection;
}
