import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/services/file_storage_service.dart';
import '../core/services/implementations/file_storage_service_impl.dart';
import '../core/services/implementations/logger_service_impl.dart';
import '../core/services/implementations/preferences_service_impl.dart';
import '../core/services/logger_service.dart';
import '../core/services/preferences_service.dart';

/// Provider for the PreferencesService
final preferencesServiceProvider = Provider<Future<PreferencesService>>((
  ref,
) async {
  return PreferencesServiceImpl.create();
});

/// Provider for the FileStorageService
final fileStorageServiceProvider = Provider<FileStorageService>((ref) {
  return FileStorageServiceImpl();
});

/// Provider for the LoggerService
final loggerServiceProvider = Provider<Future<LoggerService>>((ref) async {
  final fileStorageService = ref.watch(fileStorageServiceProvider);
  final preferencesService = await ref.watch(preferencesServiceProvider);

  return LoggerServiceImpl(
    fileStorageService: fileStorageService,
    preferencesService: preferencesService,
  );
});
