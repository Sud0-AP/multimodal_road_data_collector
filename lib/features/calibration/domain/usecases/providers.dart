import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/providers.dart';
import '../../data/repositories/providers.dart';
import 'calibration_usecase.dart';

/// Provider for the CalibrationUseCase
final calibrationUseCaseProvider = Provider((ref) {
  // Get the repository from the provider
  final repositoryAsyncValue = ref.watch(calibrationRepositoryAsyncProvider);

  return repositoryAsyncValue.when(
    data:
        (repository) => CalibrationUseCase(
          sensorService: ref.watch(sensorServiceProvider),
          calibrationRepository: repository,
        ),
    loading:
        () =>
            throw UnimplementedError('CalibrationRepository is still loading'),
    error:
        (error, stackTrace) =>
            throw UnimplementedError(
              'Error loading CalibrationRepository: $error',
            ),
  );
});
