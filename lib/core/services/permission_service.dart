/// Interface for handling device permissions
abstract class PermissionService {
  /// Request camera permission
  Future<bool> requestCameraPermission();

  /// Request storage permission
  Future<bool> requestStoragePermission();

  /// Request motion sensors permission
  Future<bool> requestSensorPermission();

  /// Request microphone permission
  Future<bool> requestMicrophonePermission();

  /// Check camera permission status
  Future<bool> isCameraPermissionGranted();

  /// Check storage permission status
  Future<bool> isStoragePermissionGranted();

  /// Check motion sensors permission status
  Future<bool> isSensorPermissionGranted();

  /// Check microphone permission status
  Future<bool> isMicrophonePermissionGranted();

  /// Open app settings
  Future<bool> openAppSettings();
}
