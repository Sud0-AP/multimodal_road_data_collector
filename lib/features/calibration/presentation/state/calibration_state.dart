import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multimodal_road_data_collector/core/services/providers.dart';
import 'package:multimodal_road_data_collector/core/services/sensor_service.dart';
import 'package:multimodal_road_data_collector/features/calibration/data/repositories/providers.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/models/initial_calibration_data.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/repositories/calibration_repository.dart';

/// Helper class to store the result of offset calibration
class _CalibrationResult {
  final bool success;
  final InitialCalibrationData data;
  final bool movementDetected;

  _CalibrationResult({
    required this.success,
    required this.data,
    this.movementDetected = false,
  });

  /// Factory method for successful calibration
  factory _CalibrationResult.success(InitialCalibrationData data) {
    return _CalibrationResult(success: true, data: data);
  }

  /// Factory method for failed calibration due to movement
  factory _CalibrationResult.movementDetected() {
    return _CalibrationResult(
      success: false,
      movementDetected: true,
      data: InitialCalibrationData.initial(),
    );
  }

  /// Factory method for failed calibration due to other reasons
  factory _CalibrationResult.failure() {
    return _CalibrationResult(
      success: false,
      data: InitialCalibrationData.initial(),
    );
  }
}

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

  /// Stream subscription for sensor data
  StreamSubscription<SensorData>? _sensorSubscription;

  /// Buffer to store accelerometer data for orientation detection
  final List<SensorData> _accelerometerBuffer = [];

  /// Duration for orientation detection in milliseconds (1 second)
  static const int _orientationDetectionDurationMs = 1000;

  /// Standard gravity value in m/s²
  static const double _standardGravity = 9.81;

  /// Threshold for detecting movement during calibration (in m/s²)
  static const double _movementThreshold = 0.2;

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
    // Cancel any existing calibration and clean up resources first
    await _cleanupSensorResources();

    // Reset the state completely
    state = CalibrationState.initial().copyWith(
      isCalibrating: true,
      calibrationProgress: 0.0,
      movementDetected: false,
      deviceOrientation: DeviceOrientation.unknown,
      statusMessage: 'Starting calibration...',
    );

    try {
      // Initialize sensor service if needed
      await _sensorService.initialize();

      // Start the sensor data collection
      await _sensorService.startSensorDataCollection();

      // Update status to reflect we're detecting orientation
      state = state.copyWith(
        statusMessage: 'Detecting device orientation...',
        calibrationProgress: 0.1, // 10% progress
      );

      // Detect orientation first
      final detectedOrientation = await _detectOrientation();

      // Update state with detected orientation
      state = state.copyWith(
        deviceOrientation: detectedOrientation,
        statusMessage:
            'Orientation detected: ${_orientationToString(detectedOrientation)}',
        calibrationProgress: 0.3, // 30% progress
      );

      // New implementation for subtask 2.9: offset calibration and movement detection
      state = state.copyWith(
        statusMessage:
            'Keep device still for 15 seconds to calculate sensor offsets...',
        calibrationProgress: 0.4, // 40% progress
      );

      // Perform offset calibration
      final calibrationResult = await _performOffsetCalibration(
        detectedOrientation,
      );

      // Explicitly set progress to 0.95 before saving data to indicate almost done
      state = state.copyWith(
        statusMessage: 'Processing calibration data...',
        calibrationProgress: 0.95, // 95% progress to show we're almost done
      );

      // Check if calibration was successful
      if (calibrationResult.success) {
        // Save the calibration data
        final success = await _calibrationRepository.saveInitialCalibrationData(
          calibrationResult.data,
        );

        if (success) {
          // First update the calibration data
          state = state.copyWith(calibrationData: calibrationResult.data);

          // Then set progress to 100% and all other completion flags
          // Using a slight delay to ensure UI updates properly
          await Future.delayed(const Duration(milliseconds: 300));

          state = state.copyWith(
            isCalibrating: false,
            calibrationProgress: 1.0,
            isCalibrationComplete: true,
            statusMessage: 'Calibration completed successfully',
          );
        } else {
          state = state.copyWith(
            isCalibrating: false,
            calibrationProgress: 0.0,
            statusMessage: 'Failed to save calibration data',
          );
        }
      } else {
        // Movement was detected, calibration failed
        state = state.copyWith(
          isCalibrating: false,
          calibrationProgress: 0.0,
          movementDetected: calibrationResult.movementDetected,
          statusMessage:
              calibrationResult.movementDetected
                  ? 'Excessive movement detected. Please try again and keep the device still.'
                  : 'Calibration failed. Please try again.',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isCalibrating: false,
        calibrationProgress: 0.0,
        statusMessage: 'Calibration error: ${e.toString()}',
      );
    } finally {
      // Always clean up sensor resources
      await _cleanupSensorResources();
    }
  }

  /// Detect the device orientation using accelerometer data
  ///
  /// This method collects accelerometer data for 1 second and analyzes
  /// the gravity components to determine the device's orientation.
  ///
  /// Returns the detected [DeviceOrientation]
  Future<DeviceOrientation> _detectOrientation() async {
    // Clear any previous data
    _accelerometerBuffer.clear();

    // Update status message
    state = state.copyWith(
      statusMessage: 'Detecting device orientation...',
      calibrationProgress: 0.1, // Start at 10% progress
    );

    // The orientation detection time in milliseconds (1 second)
    const int orientationDetectionTimeMs = 1000;

    // For tests, we use a completer to handle the sensor data
    final completer = Completer<DeviceOrientation>();

    // Start timestamp when we begin collecting samples
    final startTime = DateTime.now().millisecondsSinceEpoch;

    // Subscribe to sensor data stream
    _sensorSubscription = _sensorService.getSensorDataStream().listen(
      (SensorData data) {
        // Add data to buffer
        _accelerometerBuffer.add(data);

        // Calculate elapsed time and progress
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final elapsedMs = currentTime - startTime;
        final progress = elapsedMs / orientationDetectionTimeMs;

        // Update calibration progress (0.1 to 0.3 for orientation detection)
        state = state.copyWith(
          calibrationProgress: 0.1 + (progress * 0.2).clamp(0.0, 0.2),
        );

        // Complete after collecting 1 second of data
        if (elapsedMs >= orientationDetectionTimeMs && !completer.isCompleted) {
          final orientation = _calculateOrientation(_accelerometerBuffer);
          completer.complete(orientation);
        }
      },
      onError: (error) {
        if (!completer.isCompleted) {
          completer.completeError('Failed to collect sensor data: $error');
        }
      },
    );

    // Timeout in case we don't get enough data
    Future.delayed(const Duration(seconds: 3), () {
      if (!completer.isCompleted) {
        // If we have at least some data, try to calculate orientation
        if (_accelerometerBuffer.isNotEmpty) {
          final orientation = _calculateOrientation(_accelerometerBuffer);
          completer.complete(orientation);
        } else {
          // No data received
          completer.complete(DeviceOrientation.unknown);
        }
      }
    });

    return completer.future;
  }

  /// Calculate the device orientation from the collected accelerometer data
  ///
  /// Analyzes the average gravity components from the accelerometer data
  /// to determine the device orientation.
  DeviceOrientation _calculateOrientation(List<SensorData> dataPoints) {
    if (dataPoints.isEmpty) {
      return DeviceOrientation.unknown;
    }

    // Calculate average accelerometer values with gravity component
    double sumX = 0, sumY = 0, sumZ = 0;
    for (final data in dataPoints) {
      sumX += data.accelerometerX;
      sumY += data.accelerometerY;
      sumZ += data.accelerometerZ;
    }

    final avgX = sumX / dataPoints.length;
    final avgY = sumY / dataPoints.length;
    final avgZ = sumZ / dataPoints.length;

    // Debug print to help diagnose orientation issues
    print('Accelerometer Raw Avg X: $avgX, Y: $avgY, Z: $avgZ');

    // Calculate the magnitude of the acceleration vector
    final magnitude = sqrt(avgX * avgX + avgY * avgY + avgZ * avgZ);

    print('Magnitude: $magnitude (Expected ~9.81)');

    // Check if the magnitude is reasonable (close to standard gravity)
    // Allow more flexibility for real devices
    if ((magnitude - _standardGravity).abs() > 2.5) {
      print('Magnitude too far from standard gravity');
      return DeviceOrientation.unknown;
    }

    // Normalized values for better comparison (dividing by magnitude gives unit vector)
    final normalizedX = avgX / magnitude;
    final normalizedY = avgY / magnitude;
    final normalizedZ = avgZ / magnitude;

    // Absolute values for comparison
    final absX = normalizedX.abs();
    final absY = normalizedY.abs();
    final absZ = normalizedZ.abs();

    // Debug print values to help diagnose orientation
    print('Normalized X: $normalizedX, Y: $normalizedY, Z: $normalizedZ');
    print('Absolute X: $absX, Y: $absY, Z: $absZ');

    // On Android, typical orientations are:
    // Device lying flat on table, screen up: Z around -1.0
    // Portrait: Y around -1.0
    // Landscape right: X around +1.0
    // Landscape left: X around -1.0

    // Lower threshold for more reliable detection on actual devices
    const threshold = 0.65;

    // Device flat (screen facing up)
    if (absZ > threshold && normalizedZ < 0) {
      print('Detected flat orientation');
      return DeviceOrientation.flat;
    }

    // Portrait orientation (phone standing upright)
    if (absY > threshold && normalizedY < 0) {
      print('Detected portrait orientation');
      return DeviceOrientation.portrait;
    }

    // Landscape orientations
    if (absX > threshold) {
      print('Detected landscape orientation');
      // Check the sign of X to determine which landscape orientation
      return (normalizedX > 0)
          ? DeviceOrientation.landscapeRight
          : DeviceOrientation.landscapeLeft;
    }

    // If no clear orientation detected, use looser thresholds
    const looseThreshold = 0.5;

    if (absZ > looseThreshold && normalizedZ < 0) {
      print('Detected flat orientation (loose threshold)');
      return DeviceOrientation.flat;
    } else if (absY > looseThreshold && normalizedY < 0) {
      print('Detected portrait orientation (loose threshold)');
      return DeviceOrientation.portrait;
    } else if (absX > looseThreshold) {
      print('Detected landscape orientation (loose threshold)');
      return (normalizedX > 0)
          ? DeviceOrientation.landscapeRight
          : DeviceOrientation.landscapeLeft;
    }

    // If we can't definitively determine orientation, use simple majority rule
    if (absX > absY && absX > absZ) {
      print('Detected landscape using majority rule');
      return normalizedX > 0
          ? DeviceOrientation.landscapeRight
          : DeviceOrientation.landscapeLeft;
    } else if (absY > absX && absY > absZ) {
      print('Detected portrait using majority rule');
      return DeviceOrientation.portrait;
    } else if (absZ > absX && absZ > absY) {
      print('Detected flat using majority rule');
      return DeviceOrientation.flat;
    }

    print('Could not detect orientation, defaulting to unknown');
    return DeviceOrientation.unknown;
  }

  /// Perform the offset calibration by collecting sensor data
  ///
  /// This method collects accelerometer and gyroscope data,
  /// checks for excessive movement, and calculates the average offsets.
  ///
  /// Returns a [_CalibrationResult] containing the calibration data and success status.
  Future<_CalibrationResult> _performOffsetCalibration(
    DeviceOrientation orientation,
  ) async {
    // Create a completer to wait for offset calibration
    final completer = Completer<_CalibrationResult>();

    // Buffer to store sensor data during offset calibration
    final List<SensorData> sensorBuffer = [];

    // The total calibration time in milliseconds (15 seconds)
    const int calibrationTimeMs = 15000;

    // The expected number of samples at 100Hz over 15 seconds
    const int expectedSamples = 15 * 100; // 100Hz * 15 seconds = 1500 samples

    // Start timestamp when we begin collecting samples
    final startTime = DateTime.now().millisecondsSinceEpoch;

    // Flag to track if excessive movement was detected
    bool movementDetected = false;
    int consecutiveMovementFrames = 0;

    // Increased sensitivity to detect movement
    const int movementThresholdFrames =
        10; // Lower threshold to detect movement sooner

    // Stricter thresholds for movement detection
    const accelerationThreshold = 0.3; // m/s² (lowered from 0.4)
    const gyroscopeThreshold = 0.2; // rad/s (lowered from 0.25)

    // Set initial state before starting data collection
    state = state.copyWith(
      statusMessage:
          'Starting offset calibration. Keep device still for 15 seconds...',
      calibrationProgress: 0.4, // Start at 40% progress for this phase
    );

    // Subscribe to sensor data stream
    _sensorSubscription = _sensorService.getSensorDataStream().listen(
      (sensorData) {
        // Calculate elapsed time
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        final elapsedMs = currentTime - startTime;

        // Add data to buffer
        sensorBuffer.add(sensorData);

        // Check for excessive movement
        if (sensorBuffer.length >= 2) {
          final previousData = sensorBuffer[sensorBuffer.length - 2];
          final currentData = sensorBuffer[sensorBuffer.length - 1];

          // Calculate magnitude of acceleration change
          final deltaAccX =
              (currentData.accelerometerX - previousData.accelerometerX).abs();
          final deltaAccY =
              (currentData.accelerometerY - previousData.accelerometerY).abs();
          final deltaAccZ =
              (currentData.accelerometerZ - previousData.accelerometerZ).abs();

          // Calculate magnitude of gyroscope change
          final deltaGyroX =
              (currentData.gyroscopeX - previousData.gyroscopeX).abs();
          final deltaGyroY =
              (currentData.gyroscopeY - previousData.gyroscopeY).abs();
          final deltaGyroZ =
              (currentData.gyroscopeZ - previousData.gyroscopeZ).abs();

          // Check if movement is excessive using stricter thresholds
          bool currentFrameHasMovement = false;
          if (deltaAccX > accelerationThreshold ||
              deltaAccY > accelerationThreshold ||
              deltaAccZ > accelerationThreshold ||
              deltaGyroX > gyroscopeThreshold ||
              deltaGyroY > gyroscopeThreshold ||
              deltaGyroZ > gyroscopeThreshold) {
            currentFrameHasMovement = true;
            consecutiveMovementFrames++;

            // Print debug info for movement detection
            print('Movement detected: Frame $consecutiveMovementFrames');
            print('AccX: $deltaAccX, AccY: $deltaAccY, AccZ: $deltaAccZ');
            print('GyroX: $deltaGyroX, GyroY: $deltaGyroY, GyroZ: $deltaGyroZ');
          } else {
            // Only reset the counter if we've had several consecutive good frames
            // This prevents a single good frame from resetting the counter
            if (consecutiveMovementFrames > 0) {
              consecutiveMovementFrames = max(0, consecutiveMovementFrames - 1);
            }
          }

          // Update movement detection flag immediately for UI feedback
          if (currentFrameHasMovement) {
            // Update UI to show movement detection immediately
            state = state.copyWith(
              movementDetected: true,
              statusMessage: 'Movement detected! Please keep the device still.',
            );
          }

          // If too much consecutive movement detected, pause calibration and clear data
          if (consecutiveMovementFrames >= movementThresholdFrames) {
            // Stop sensor data collection immediately
            _sensorService.stopSensorDataCollection();
            if (_sensorSubscription != null) {
              _sensorSubscription!.cancel();
              _sensorSubscription = null;
            }

            // Clear the sensor buffer to delete previously recorded data
            sensorBuffer.clear();

            // Update state to indicate movement detection and paused calibration
            state = state.copyWith(
              isCalibrating: false,
              calibrationProgress: 0.0,
              movementDetected: true,
              statusMessage:
                  'Calibration paused due to excessive movement. Please keep the device still and try again.',
            );

            if (!completer.isCompleted) {
              completer.complete(_CalibrationResult.movementDetected());
            }
            return;
          }
        }

        // Only update progress if movement is not detected
        if (!movementDetected) {
          // Calculate calibration progress (scale from 0.4 to 0.9 for UI)
          // Make sure we don't exceed 15 seconds in the calculation
          final progress = (elapsedMs / calibrationTimeMs).clamp(0.0, 1.0);
          final scaledProgress = 0.4 + (progress * 0.5);

          // Update status message with remaining time
          final remainingSeconds = ((calibrationTimeMs - elapsedMs) / 1000)
              .ceil()
              .clamp(0, 15);
          final statusMessage =
              'Keep device still for offset calibration: $remainingSeconds seconds remaining...';

          // Set state to update UI
          state = state.copyWith(
            deviceOrientation: orientation,
            statusMessage: statusMessage,
            calibrationProgress: scaledProgress,
            movementDetected: false,
          );
        }

        // Check if we've collected enough data or reached the time limit
        // Only complete once we reach the full 15 seconds
        if (elapsedMs >= calibrationTimeMs) {
          // Stop sensor data collection after the full time has elapsed
          _sensorService.stopSensorDataCollection();
          if (_sensorSubscription != null) {
            _sensorSubscription!.cancel();
            _sensorSubscription = null;
          }

          // Only use the data if we have a reasonable number of samples
          // We expect ~1500 samples at 100Hz over 15 seconds
          // Allow some flexibility (70% of expected samples)
          if (sensorBuffer.length >= expectedSamples * 0.7) {
            // Calculate average offsets
            double sumAccX = 0, sumAccY = 0, sumAccZ = 0;
            double sumGyroX = 0, sumGyroY = 0, sumGyroZ = 0;

            for (final data in sensorBuffer) {
              sumAccX += data.accelerometerX;
              sumAccY += data.accelerometerY;
              sumAccZ += data.accelerometerZ;
              sumGyroX += data.gyroscopeX;
              sumGyroY += data.gyroscopeY;
              sumGyroZ += data.gyroscopeZ;
            }

            // Compute averages
            final sampleCount = sensorBuffer.length;
            final offsetAccX = sumAccX / sampleCount;
            final offsetAccY = sumAccY / sampleCount;
            final offsetAccZ = sumAccZ / sampleCount;
            final offsetGyroX = sumGyroX / sampleCount;
            final offsetGyroY = sumGyroY / sampleCount;
            final offsetGyroZ = sumGyroZ / sampleCount;

            // Create calibration result
            final calibrationData = InitialCalibrationData(
              deviceOrientation: orientation,
              accelerometerXOffset: offsetAccX,
              accelerometerYOffset: offsetAccY,
              accelerometerZOffset: offsetAccZ,
              gyroscopeXOffset: offsetGyroX,
              gyroscopeYOffset: offsetGyroY,
              gyroscopeZOffset: offsetGyroZ,
              calibrationTimestamp: DateTime.now().millisecondsSinceEpoch,
            );

            // Update UI with final status
            state = state.copyWith(
              statusMessage:
                  'Offset calibration complete! '
                  '${sensorBuffer.length} samples collected over ${elapsedMs / 1000} seconds.',
              calibrationProgress: 0.9, // 90% progress
            );

            // Small delay to ensure the UI updates with 90% before moving to completion
            Future.delayed(const Duration(milliseconds: 200), () {
              if (!completer.isCompleted) {
                completer.complete(_CalibrationResult.success(calibrationData));
              }
            });
          } else {
            // Not enough samples collected
            state = state.copyWith(
              statusMessage:
                  'Not enough sensor samples collected. Please try again.',
              calibrationProgress: 0.0,
              isCalibrating: false,
            );

            if (!completer.isCompleted) {
              completer.complete(_CalibrationResult.failure());
            }
          }
        }
      },
      onError: (error) {
        // Clean up resources on error
        _sensorService.stopSensorDataCollection();
        if (_sensorSubscription != null) {
          _sensorSubscription!.cancel();
          _sensorSubscription = null;
        }

        state = state.copyWith(
          statusMessage: 'Sensor error: $error',
          calibrationProgress: 0.0,
          isCalibrating: false,
        );

        if (!completer.isCompleted) {
          completer.completeError('Sensor error: $error');
        }
      },
    );

    // Safety timeout to ensure we don't hang indefinitely
    // This should only trigger if something went wrong with the sensor data collection
    Future.delayed(const Duration(seconds: 20), () {
      if (!completer.isCompleted) {
        // Clean up resources
        _sensorService.stopSensorDataCollection();
        if (_sensorSubscription != null) {
          _sensorSubscription!.cancel();
          _sensorSubscription = null;
        }

        if (sensorBuffer.isNotEmpty) {
          // Try to calculate with what we have
          state = state.copyWith(
            statusMessage: 'Calibration timeout, using partial data',
            calibrationProgress: 0.9,
          );

          // Process what data we have
          double sumAccX = 0, sumAccY = 0, sumAccZ = 0;
          double sumGyroX = 0, sumGyroY = 0, sumGyroZ = 0;

          for (final data in sensorBuffer) {
            sumAccX += data.accelerometerX;
            sumAccY += data.accelerometerY;
            sumAccZ += data.accelerometerZ;
            sumGyroX += data.gyroscopeX;
            sumGyroY += data.gyroscopeY;
            sumGyroZ += data.gyroscopeZ;
          }

          final sampleCount = sensorBuffer.length;
          final calibrationData = InitialCalibrationData(
            deviceOrientation: orientation,
            accelerometerXOffset: sumAccX / sampleCount,
            accelerometerYOffset: sumAccY / sampleCount,
            accelerometerZOffset: sumAccZ / sampleCount,
            gyroscopeXOffset: sumGyroX / sampleCount,
            gyroscopeYOffset: sumGyroY / sampleCount,
            gyroscopeZOffset: sumGyroZ / sampleCount,
            calibrationTimestamp: DateTime.now().millisecondsSinceEpoch,
          );

          completer.complete(_CalibrationResult.success(calibrationData));
        } else {
          state = state.copyWith(
            statusMessage:
                'Calibration timeout with no data. Please try again.',
            calibrationProgress: 0.0,
            isCalibrating: false,
          );

          completer.complete(_CalibrationResult.failure());
        }
      }
    });

    return completer.future;
  }

  /// Convert DeviceOrientation enum to user-friendly string
  String _orientationToString(DeviceOrientation orientation) {
    switch (orientation) {
      case DeviceOrientation.portrait:
        return 'Portrait';
      case DeviceOrientation.landscapeRight:
        return 'Landscape Right';
      case DeviceOrientation.landscapeLeft:
        return 'Landscape Left';
      case DeviceOrientation.flat:
        return 'Flat (screen up)';
      case DeviceOrientation.unknown:
      default:
        return 'Unknown';
    }
  }

  /// Clean up sensor resources
  Future<void> _cleanupSensorResources() async {
    // Cancel sensor subscription
    if (_sensorSubscription != null) {
      await _sensorSubscription!.cancel();
      _sensorSubscription = null;
    }

    // Stop sensor data collection
    if (_sensorService.isSensorDataCollectionActive()) {
      await _sensorService.stopSensorDataCollection();
    }
  }

  /// Cancel the calibration process
  void cancelCalibration() async {
    // Clean up sensor resources
    await _cleanupSensorResources();

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

  @override
  void dispose() {
    _cleanupSensorResources();
    super.dispose();
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
