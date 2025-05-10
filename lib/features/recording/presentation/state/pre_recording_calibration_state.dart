import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../features/calibration/domain/models/pre_recording_calibration_result.dart';
import '../../../../features/calibration/domain/usecases/calibration_usecase.dart';
import '../../../../features/calibration/domain/usecases/providers.dart';

/// The different states of pre-recording calibration
enum PreRecordingCalibrationStatus {
  /// Initial state before calibration starts
  initial,

  /// Calibration in progress collecting 20s of data
  inProgress,

  /// Calibration completed successfully
  complete,

  /// Calibration failed
  failed,
}

/// State class for pre-recording calibration
class PreRecordingCalibrationState {
  /// Current status of calibration
  final PreRecordingCalibrationStatus status;

  /// Progress of calibration (0.0 to 1.0)
  final double progress;

  /// Results of calibration (null if not complete)
  final PreRecordingCalibrationResult? result;

  /// Status message to display to the user
  final String statusMessage;

  /// Constructor for PreRecordingCalibrationState
  const PreRecordingCalibrationState({
    this.status = PreRecordingCalibrationStatus.initial,
    this.progress = 0.0,
    this.result,
    this.statusMessage = '',
  });

  /// Create a copy with optional changes
  PreRecordingCalibrationState copyWith({
    PreRecordingCalibrationStatus? status,
    double? progress,
    PreRecordingCalibrationResult? result,
    String? statusMessage,
  }) {
    return PreRecordingCalibrationState(
      status: status ?? this.status,
      progress: progress ?? this.progress,
      result: result ?? this.result,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  /// Initial state
  factory PreRecordingCalibrationState.initial() {
    return const PreRecordingCalibrationState(
      statusMessage: 'Ready to start pre-recording calibration',
    );
  }
}

/// Notifier for pre-recording calibration state
class PreRecordingCalibrationNotifier
    extends StateNotifier<PreRecordingCalibrationState> {
  final CalibrationUseCase _calibrationUseCase;

  /// Duration of calibration in milliseconds (20 seconds)
  static const _calibrationDurationMs = 20000;

  /// Constructor
  PreRecordingCalibrationNotifier({
    required CalibrationUseCase calibrationUseCase,
  }) : _calibrationUseCase = calibrationUseCase,
       super(PreRecordingCalibrationState.initial());

  /// Start the pre-recording calibration process
  Future<void> startCalibration() async {
    // Set state to in progress
    state = state.copyWith(
      status: PreRecordingCalibrationStatus.inProgress,
      progress: 0.0,
      statusMessage: 'Drive smoothly on a level surface',
    );

    // Start a timer to update progress
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final endTime = startTime + _calibrationDurationMs;

    // Update progress periodically
    void updateProgress() {
      if (state.status != PreRecordingCalibrationStatus.inProgress) {
        return;
      }

      final currentTime = DateTime.now().millisecondsSinceEpoch;
      if (currentTime >= endTime) {
        return;
      }

      final elapsed = currentTime - startTime;
      final progress = elapsed / _calibrationDurationMs;

      // Update message with seconds remaining
      final secondsRemaining =
          ((_calibrationDurationMs - elapsed) / 1000).ceil();

      state = state.copyWith(
        progress: progress,
        statusMessage: 'Drive smoothly for $secondsRemaining more seconds',
      );

      // Schedule next update
      Future.delayed(const Duration(milliseconds: 100), updateProgress);
    }

    // Start progress updates
    updateProgress();

    try {
      // Perform calibration
      final result = await _calibrationUseCase.performPreRecordingCalibration();

      if (result.isCalibrationSuccessful) {
        state = state.copyWith(
          status: PreRecordingCalibrationStatus.complete,
          progress: 1.0,
          result: result,
          statusMessage: 'Calibration complete! Ready to record.',
        );
      } else {
        state = state.copyWith(
          status: PreRecordingCalibrationStatus.failed,
          progress: 1.0,
          statusMessage: 'Calibration failed. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: PreRecordingCalibrationStatus.failed,
        progress: 1.0,
        statusMessage: 'Error during calibration: $e',
      );
    }
  }

  /// Reset calibration state
  void reset() {
    state = PreRecordingCalibrationState.initial();
  }
}

/// Provider for pre-recording calibration state
final preRecordingCalibrationProvider = StateNotifierProvider<
  PreRecordingCalibrationNotifier,
  PreRecordingCalibrationState
>((ref) {
  return PreRecordingCalibrationNotifier(
    calibrationUseCase: ref.watch(calibrationUseCaseProvider),
  );
});
