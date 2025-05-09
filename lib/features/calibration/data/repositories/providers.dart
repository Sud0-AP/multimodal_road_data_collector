import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multimodal_road_data_collector/core/services/providers.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/repositories/calibration_repository.dart';

import 'calibration_repository_impl.dart';

/// Provider for the CalibrationRepository
///
/// Uses the PreferencesService for persistence
final calibrationRepositoryProvider = Provider<CalibrationRepository>((ref) {
  // Get the preferences service from the provider
  final preferencesServiceAsync = ref.watch(preferencesServiceProvider);

  // Return the repository asynchronously
  return preferencesServiceAsync.when(
    data: (preferencesService) => CalibrationRepositoryImpl(preferencesService),
    loading:
        () =>
            throw UnimplementedError(
              'PreferencesService is still loading, CalibrationRepository is not yet available',
            ),
    error:
        (error, stackTrace) =>
            throw UnimplementedError(
              'Error loading PreferencesService: $error',
            ),
  );
});

/// Provider that exposes a CalibrationRepository through an AsyncValue
///
/// This is useful when you need to handle loading states properly in the UI
final calibrationRepositoryAsyncProvider =
    FutureProvider<CalibrationRepository>((ref) async {
      // Get the preferences service from the provider
      final preferencesService = await ref.watch(
        preferencesServiceProvider.future,
      );

      // Return the repository with the preferences service
      return CalibrationRepositoryImpl(preferencesService);
    });
