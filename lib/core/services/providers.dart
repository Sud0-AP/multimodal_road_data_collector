import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'camera_service.dart';
import 'file_storage_service.dart';
import 'logger_service.dart';
import 'implementations/camera_service_impl.dart';
import 'implementations/file_storage_service_impl.dart';
import 'implementations/logger_service_impl.dart';
import 'implementations/permission_service_impl.dart';
import 'implementations/preferences_service_impl.dart';
import 'implementations/sensor_service_impl.dart';
import 'implementations/ntp_service_impl.dart';
import 'implementations/spike_detection_service_impl.dart';
import 'permission_service.dart';
import 'preferences_service.dart';
import 'sensor_service.dart';
import 'ntp_service.dart';
import 'spike_detection_service.dart';

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
  return FileStorageServiceImpl();
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

/// Provider for CameraService
final cameraServiceProvider = Provider<CameraService>((ref) {
  final service = CameraServiceImpl();

  // Add dispose callback
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for NtpService
final ntpServiceProvider = Provider<NtpService>((ref) {
  final service = NtpServiceImpl();

  // Initialize the service
  service.initialize();

  // Add dispose callback
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for SpikeDetectionService
final spikeDetectionServiceProvider = Provider<SpikeDetectionService>((ref) {
  final service = SpikeDetectionServiceImpl();

  // Add dispose callback
  ref.onDispose(() {
    service.dispose();
  });

  return service;
});

/// Provider for LoggerService
final loggerServiceProvider = Provider<LoggerService>((ref) {
  // Wait for preferences service to resolve before creating the logger
  final fileStorage = ref.watch(fileStorageServiceProvider);
  final preferencesAsync = ref.watch(preferencesServiceProvider);

  // Handle async preference service
  return preferencesAsync.when(
    data: (preferences) {
      final service = LoggerServiceImpl(
        fileStorageService: fileStorage,
        preferencesService: preferences,
      );

      // Initialize the service
      service.initialize();

      return service;
    },
    loading: () {
      // Return a dummy implementation that does nothing until preferences are loaded
      return DummyLoggerService();
    },
    error: (_, __) {
      // Return a dummy implementation that does nothing if there's an error
      return DummyLoggerService();
    },
  );
});

/// A dummy implementation of LoggerService that does nothing
/// Used while preferences are loading or if there's an error
class DummyLoggerService implements LoggerService {
  @override
  Future<void> initialize() async {}

  @override
  Future<String> startDebugSession() async => 'dummy_session';

  @override
  Future<void> endDebugSession() async {}

  @override
  bool isDebugSessionActive() => false;

  @override
  Future<void> info(String tag, String message) async {}

  @override
  Future<void> debug(String tag, String message) async {}

  @override
  Future<void> warning(String tag, String message) async {}

  @override
  Future<void> error(
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) async {}

  @override
  Future<void> critical(
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) async {}

  @override
  Future<String?> getCurrentLogFilePath() async => null;

  @override
  Future<List<String>> getLogFilePaths([String? sessionId]) async => [];
}
