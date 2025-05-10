import 'dart:async';
import 'dart:math';

import '../../../../core/services/sensor_service.dart';
import '../models/pre_recording_calibration_result.dart';
import '../repositories/calibration_repository.dart';
import '../../domain/models/initial_calibration_data.dart';

/// Number of standard deviations to use for bump threshold calculation
const double kBumpThresholdMultiplier = 2.5;

/// Data class to hold bump threshold calculation results
class _BumpThresholdResult {
  final double threshold;
  final double stdDeviation;

  _BumpThresholdResult(this.threshold, this.stdDeviation);
}

/// A class that contains the business logic for sensor calibration
class CalibrationUseCase {
  /// The sensor service for accessing sensor data
  final SensorService _sensorService;

  /// The calibration repository for accessing stored calibration data
  final CalibrationRepository _calibrationRepository;

  /// Duration for pre-recording calibration in seconds
  static const int preRecordingCalibrationDurationSec = 20;

  /// Standard gravity value in m/s²
  static const double standardGravity = 9.81;

  /// Maximum acceptable gravity deviation during Z-offset adjustment (in m/s²)
  static const double maxGravityDeviation = 0.5;

  /// Maximum acceptable gyro drift (in rad/s)
  static const double maxGyroDrift = 0.02;

  /// Creates a new [CalibrationUseCase]
  CalibrationUseCase({
    required SensorService sensorService,
    required CalibrationRepository calibrationRepository,
  }) : _sensorService = sensorService,
       _calibrationRepository = calibrationRepository;

  /// Performs pre-recording calibration
  ///
  /// This collects 20 seconds of sensor data to:
  /// 1. Validate gravity readings and adjust Z-offset if needed
  /// 2. Check for gyroscope drift
  /// 3. Calculate a dynamic bump threshold baseline
  ///
  /// Returns a [PreRecordingCalibrationResult] with the calibration results
  Future<PreRecordingCalibrationResult> performPreRecordingCalibration() async {
    // Load initial calibration data
    final initialCalibrationData =
        await _calibrationRepository.loadInitialCalibrationData();
    if (initialCalibrationData == null) {
      return PreRecordingCalibrationResult.initial().copyWith(
        isCalibrationSuccessful: false,
      );
    }

    // Initialize sensor data collection if not active
    if (!_sensorService.isSensorDataCollectionActive()) {
      await _sensorService.startSensorDataCollection();
    }

    // Create storage for collected sensor data
    final accelZValues = <double>[];
    final gyroZValues = <double>[];
    final accelMagnitudeValues = <double>[];

    // Create a completer to resolve when calibration is complete
    final completer = Completer<PreRecordingCalibrationResult>();

    // Current timestamp to track collection duration
    final startTime = DateTime.now().millisecondsSinceEpoch;
    final endTime = startTime + (preRecordingCalibrationDurationSec * 1000);

    // Store subscription for later cancellation
    late StreamSubscription<SensorData> subscription;

    // Subscribe to sensor data
    subscription = _sensorService.getSensorDataStream().listen(
      (data) {
        final currentTime = DateTime.now().millisecondsSinceEpoch;

        // Apply initial calibration offsets and orientation adjustments
        double accelX =
            data.accelerometerX - initialCalibrationData.accelerometerXOffset;
        double accelY =
            data.accelerometerY - initialCalibrationData.accelerometerYOffset;
        double accelZ =
            data.accelerometerZ - initialCalibrationData.accelerometerZOffset;
        double gyroZ =
            data.gyroscopeZ - initialCalibrationData.gyroscopeZOffset;

        // Handle orientation swapping if needed based on initial calibration
        if (initialCalibrationData.deviceOrientation ==
                DeviceOrientation.landscapeLeft ||
            initialCalibrationData.deviceOrientation ==
                DeviceOrientation.landscapeRight) {
          final temp = accelX;
          accelX = accelY;
          accelY = temp;
        }

        // Calculate acceleration magnitude
        final accelMagnitude = sqrt(
          accelX * accelX + accelY * accelY + accelZ * accelZ,
        );

        // Store values for analysis
        accelZValues.add(accelZ);
        gyroZValues.add(gyroZ);
        accelMagnitudeValues.add(accelMagnitude);

        // Check if we've collected enough data
        if (currentTime >= endTime) {
          subscription.cancel();

          // Process collected data
          final result = _processCalibrationData(
            accelZValues,
            gyroZValues,
            accelMagnitudeValues,
            initialCalibrationData,
          );

          completer.complete(result);
        }
      },
      onError: (error) {
        // Cancel the subscription on error
        subscription.cancel();

        // Complete with an error result
        completer.complete(
          PreRecordingCalibrationResult.initial().copyWith(
            isCalibrationSuccessful: false,
          ),
        );
      },
    );

    // Set a timeout to ensure we don't wait forever
    Future.delayed(
      Duration(seconds: preRecordingCalibrationDurationSec + 5),
      () {
        if (!completer.isCompleted) {
          subscription.cancel();
          completer.complete(
            PreRecordingCalibrationResult.initial().copyWith(
              isCalibrationSuccessful: false,
            ),
          );
        }
      },
    );

    return completer.future;
  }

  /// Process collected calibration data to produce calibration results
  PreRecordingCalibrationResult _processCalibrationData(
    List<double> accelZValues,
    List<double> gyroZValues,
    List<double> accelMagnitudeValues,
    InitialCalibrationData initialCalibrationData,
  ) {
    if (accelZValues.isEmpty ||
        gyroZValues.isEmpty ||
        accelMagnitudeValues.isEmpty) {
      return PreRecordingCalibrationResult.initial().copyWith(
        isCalibrationSuccessful: false,
      );
    }

    // 1. Gravity Validation / Z-Offset Adjustment
    final zOffsetAdjustment = _calculateZOffsetAdjustment(accelZValues);
    final sessionAccelOffsetZ =
        initialCalibrationData.accelerometerZOffset + zOffsetAdjustment;

    // 2. Gyro Drift Check
    final gyroZDrift = _calculateGyroDrift(gyroZValues);

    // 3. Bump Threshold Baseline
    final bumpThresholdResult = _calculateBumpThreshold(accelMagnitudeValues);

    return PreRecordingCalibrationResult(
      sessionAccelOffsetZ: sessionAccelOffsetZ,
      gyroZDrift: gyroZDrift,
      bumpThreshold: bumpThresholdResult.threshold,
      accelMagnitudeStdDev: bumpThresholdResult.stdDeviation,
      timestamp: DateTime.now().millisecondsSinceEpoch,
      isCalibrationSuccessful: true,
    );
  }

  /// Calculate Z-axis offset adjustment based on gravity validation
  double _calculateZOffsetAdjustment(List<double> accelZValues) {
    // Calculate mean Z acceleration
    final mean = accelZValues.reduce((a, b) => a + b) / accelZValues.length;

    // Calculate the expected Z acceleration based on gravity
    // In a properly leveled device, Z should be close to standard gravity
    final expectedZ = standardGravity;

    // Calculate needed adjustment to correct for gravity
    final adjustment = expectedZ - mean;

    // Only apply adjustment if it's within reasonable limits
    if (adjustment.abs() <= maxGravityDeviation) {
      return adjustment;
    } else {
      // If adjustment is too large, don't apply it as it might indicate
      // the device is not flat or other issues
      return 0.0;
    }
  }

  /// Calculate gyroscope drift from Z-axis gyro readings
  double _calculateGyroDrift(List<double> gyroZValues) {
    // For drift, we're interested in how much the average deviates from zero
    // when the device is stationary
    final mean = gyroZValues.reduce((a, b) => a + b) / gyroZValues.length;

    return mean;
  }

  /// Calculate dynamic bump threshold based on acceleration magnitude
  _BumpThresholdResult _calculateBumpThreshold(
    List<double> accelMagnitudeValues,
  ) {
    // Calculate mean
    final mean =
        accelMagnitudeValues.reduce((a, b) => a + b) /
        accelMagnitudeValues.length;

    // Calculate standard deviation
    double sumSquaredDifferences = 0.0;
    for (final value in accelMagnitudeValues) {
      final difference = value - mean;
      sumSquaredDifferences += difference * difference;
    }

    final variance = sumSquaredDifferences / accelMagnitudeValues.length;
    final stdDeviation = sqrt(variance);

    // Calculate threshold as mean + N * standard deviation
    final threshold = mean + (kBumpThresholdMultiplier * stdDeviation);

    return _BumpThresholdResult(threshold, stdDeviation);
  }
}
