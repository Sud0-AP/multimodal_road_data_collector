import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'file_storage_service.dart';
import 'implementations/permission_service_impl.dart';
import 'implementations/preferences_service_impl.dart';
import 'implementations/sensor_service_impl.dart';
import 'permission_service.dart';
import 'preferences_service.dart';
import 'sensor_service.dart';

/// Provider for PermissionService
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionServiceImpl();
});

/// Provider for PreferencesService
final preferencesServiceProvider = FutureProvider<PreferencesService>((
  ref,
) async {
  return await PreferencesServiceImpl.create();
});

/// Provider for FileStorageService
final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  // Implementation will be added in a future task
  throw UnimplementedError(
    'FileStorageService implementation is not yet available',
  );
});

/// Provider for SensorService
final sensorServiceProvider = Provider<SensorService>((ref) {
  final service = SensorServiceImpl();

  // Initialize the service
  service.initialize();

  // Add dispose callback
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});
