import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multimodal_road_data_collector/core/services/providers.dart';
import 'package:multimodal_road_data_collector/core/services/sensor_service.dart';
import 'package:multimodal_road_data_collector/features/calibration/data/repositories/providers.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/models/initial_calibration_data.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/repositories/calibration_repository.dart';

/// CalibrationState represents the current state of the calibration process
class CalibrationState {
  /// The current orientation of the device
  final DeviceOrientation deviceOrientation;

  /// Whether calibration is currently in progress
  final bool isCalibrating;

  /// The progress of the calibration (0.0 to 1.0)
  final double calibrationProgress;

  /// Whether excessive movement was detected during calibration
  final bool movementDetected;

  /// The calibration data from the repository
  final InitialCalibrationData? calibrationData;

  /// Whether the calibration is complete
  final bool isCalibrationComplete;

  /// Status message to display to the user
  final String statusMessage;

  /// Creates a new [CalibrationState]
  const CalibrationState({
    this.deviceOrientation = DeviceOrientation.unknown,
    this.isCalibrating = false,
    this.calibrationProgress = 0.0,
    this.movementDetected = false,
    this.calibrationData,
    this.isCalibrationComplete = false,
    this.statusMessage = '',
  });

  /// Create a copy of this [CalibrationState] with optional parameter changes
  CalibrationState copyWith({
    DeviceOrientation? deviceOrientation,
    bool? isCalibrating,
    double? calibrationProgress,
    bool? movementDetected,
    InitialCalibrationData? calibrationData,
    bool? isCalibrationComplete,
    String? statusMessage,
  }) {
    return CalibrationState(
      deviceOrientation: deviceOrientation ?? this.deviceOrientation,
      isCalibrating: isCalibrating ?? this.isCalibrating,
      calibrationProgress: calibrationProgress ?? this.calibrationProgress,
      movementDetected: movementDetected ?? this.movementDetected,
      calibrationData: calibrationData ?? this.calibrationData,
      isCalibrationComplete:
          isCalibrationComplete ?? this.isCalibrationComplete,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }

  /// Initial state for calibration
  factory CalibrationState.initial() {
    return const CalibrationState(
      statusMessage: 'Place your device on a flat surface to begin calibration',
    );
  }
}

/// CalibrationNotifier manages the state of the calibration process
class CalibrationNotifier extends StateNotifier<CalibrationState> {
  final CalibrationRepository _calibrationRepository;
  final SensorService _sensorService;

  /// Creates a new [CalibrationNotifier]
  CalibrationNotifier({
    required CalibrationRepository calibrationRepository,
    required SensorService sensorService,
  }) : _calibrationRepository = calibrationRepository,
       _sensorService = sensorService,
       super(CalibrationState.initial()) {
    // Check if calibration data exists
    _loadCalibrationData();
  }

  /// Load existing calibration data from repository
  Future<void> _loadCalibrationData() async {
    final hasCalibrationData =
        await _calibrationRepository.hasInitialCalibrationData();

    if (hasCalibrationData) {
      final calibrationData =
          await _calibrationRepository.loadInitialCalibrationData();
      if (calibrationData != null) {
        state = state.copyWith(
          calibrationData: calibrationData,
          isCalibrationComplete: true,
          statusMessage: 'Device calibration data loaded successfully',
        );
      }
    }
  }

  /// Start the calibration process
  Future<void> startCalibration() async {
    // Reset the state
    state = state.copyWith(
      isCalibrating: true,
      calibrationProgress: 0.0,
      movementDetected: false,
      statusMessage: 'Starting calibration...',
    );

    // This would be replaced with actual calibration logic
    // For now, we'll just simulate the process

    // In a real implementation, we would:
    // 1. Start collecting sensor data using _sensorService
    // 2. Detect the orientation
    // 3. Collect sensor data for 15 seconds
    // 4. Check for movement during collection
    // 5. Calculate the offsets
    // 6. Save the calibration data

    // For now, we'll create a dummy calibration data object
    final dummyData = InitialCalibrationData(
      deviceOrientation: DeviceOrientation.flat,
      accelerometerXOffset: 0.01,
      accelerometerYOffset: 0.02,
      accelerometerZOffset: 0.03,
      gyroscopeXOffset: 0.001,
      gyroscopeYOffset: 0.002,
      gyroscopeZOffset: 0.003,
      calibrationTimestamp: DateTime.now().millisecondsSinceEpoch,
    );

    // Save the calibration data
    final success = await _calibrationRepository.saveInitialCalibrationData(
      dummyData,
    );

    if (success) {
      state = state.copyWith(
        isCalibrating: false,
        calibrationProgress: 1.0,
        calibrationData: dummyData,
        isCalibrationComplete: true,
        statusMessage: 'Calibration completed successfully',
      );
    } else {
      state = state.copyWith(
        isCalibrating: false,
        statusMessage: 'Failed to save calibration data',
      );
    }
  }

  /// Cancel the calibration process
  void cancelCalibration() {
    state = state.copyWith(
      isCalibrating: false,
      calibrationProgress: 0.0,
      statusMessage: 'Calibration cancelled',
    );
  }

  /// Clear existing calibration data
  Future<void> clearCalibrationData() async {
    final success = await _calibrationRepository.clearCalibrationData();

    if (success) {
      state = state.copyWith(
        calibrationData: null,
        isCalibrationComplete: false,
        statusMessage: 'Calibration data cleared',
      );
    } else {
      state = state.copyWith(statusMessage: 'Failed to clear calibration data');
    }
  }
}

/// Provider for the CalibrationNotifier
final calibrationProvider = StateNotifierProvider<
  CalibrationNotifier,
  CalibrationState
>((ref) {
  // Use the async value unwrapping approach for the repository
  final repositoryAsyncValue = ref.watch(calibrationRepositoryAsyncProvider);

  return repositoryAsyncValue.when(
    data:
        (repository) => CalibrationNotifier(
          calibrationRepository: repository,
          sensorService: ref.watch(sensorServiceProvider),
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
