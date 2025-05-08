import 'package:permission_handler/permission_handler.dart' as ph;
import '../permission_service.dart';

/// Implementation of PermissionService using the permission_handler package
class PermissionServiceImpl implements PermissionService {
  @override
  Future<bool> requestCameraPermission() async {
    // First check current status
    final status = await ph.Permission.camera.status;

    // Only request if not already granted
    if (status.isGranted) {
      return true;
    }

    // Request the permission
    final result = await ph.Permission.camera.request();
    return result.isGranted;
  }

  @override
  Future<bool> requestStoragePermission() async {
    // For Android, storage permission differs based on SDK version
    // Check current status first
    final status = await ph.Permission.storage.status;

    // Only request if not already granted
    if (status.isGranted) {
      return true;
    }

    // Request the permission
    final result = await ph.Permission.storage.request();
    return result.isGranted;
  }

  @override
  Future<bool> requestSensorPermission() async {
    // Accelerometer and gyroscope don't require runtime permissions
    // Return true immediately as these sensors are always accessible
    return true;
  }

  @override
  Future<bool> isCameraPermissionGranted() async {
    return await ph.Permission.camera.isGranted;
  }

  @override
  Future<bool> isStoragePermissionGranted() async {
    return await ph.Permission.storage.isGranted;
  }

  @override
  Future<bool> isSensorPermissionGranted() async {
    // Accelerometer and gyroscope don't require runtime permissions
    // Return true immediately as these sensors are always accessible
    return true;
  }

  @override
  Future<bool> openAppSettings() async {
    return await ph.openAppSettings();
  }
}
