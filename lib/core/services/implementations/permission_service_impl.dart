import 'dart:io';
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
    if (Platform.isAndroid) {
      // On Android, we need more specific permissions for media storage
      // For Android 13+ (SDK 33+), we need photos and videos permission
      // For older Android, we need storage permission

      // First try with the photos permission (for Android 13+)
      final photosStatus = await ph.Permission.photos.status;
      if (photosStatus.isGranted) {
        return true;
      }

      // Request photos permission
      final photosResult = await ph.Permission.photos.request();
      if (photosResult.isGranted) {
        return true;
      }

      // If photos permission failed or not available (older Android), try with storage
      final storageStatus = await ph.Permission.storage.status;
      if (storageStatus.isGranted) {
        return true;
      }

      // Request storage permission
      final storageResult = await ph.Permission.storage.request();
      return storageResult.isGranted;
    } else if (Platform.isIOS) {
      // On iOS, we need photos permission for saving videos
      final status = await ph.Permission.photos.status;

      if (status.isGranted) {
        return true;
      }

      // Request the permission
      final result = await ph.Permission.photos.request();
      return result.isGranted;
    } else {
      // For other platforms, fallback to storage permission
      final status = await ph.Permission.storage.status;

      if (status.isGranted) {
        return true;
      }

      // Request the permission
      final result = await ph.Permission.storage.request();
      return result.isGranted;
    }
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
    if (Platform.isAndroid) {
      // Check both storage and photos permissions for Android
      return await ph.Permission.storage.isGranted ||
          await ph.Permission.photos.isGranted;
    } else if (Platform.isIOS) {
      // For iOS, check photos permission
      return await ph.Permission.photos.isGranted;
    } else {
      // For other platforms, check storage permission
      return await ph.Permission.storage.isGranted;
    }
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
