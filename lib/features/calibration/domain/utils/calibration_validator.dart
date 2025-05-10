import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../domain/models/initial_calibration_data.dart';
import '../../../../core/services/sensor_service.dart';

/// Utility class to validate if recalibration is necessary
class CalibrationValidator {
  /// Maximum allowed time (in milliseconds) since last calibration
  /// Default: 1 hour (3,600,000 milliseconds)
  static const int maxCalibrationAge = 3600000; // 1 hour

  /// Checks if the device needs recalibration based on time elapsed
  /// since the last calibration
  ///
  /// Returns true if recalibration is needed
  static bool isRecalibrationNeededByTime(
    InitialCalibrationData? calibrationData,
  ) {
    if (calibrationData == null) {
      return true;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    final calibrationTime = calibrationData.calibrationTimestamp;
    final elapsedTime = now - calibrationTime;

    debugPrint('Time since last calibration: ${elapsedTime / 1000} seconds');
    return elapsedTime > maxCalibrationAge;
  }

  /// Comprehensive check if recalibration is needed
  /// Now simplified to only check time since last calibration
  static Future<bool> isRecalibrationNeeded(
    InitialCalibrationData? calibrationData,
    SensorService sensorService,
  ) async {
    // If no calibration data, definitely need calibration
    if (calibrationData == null) {
      debugPrint('Recalibration needed: No previous calibration data');
      return true;
    }

    // Only check time - simplified logic
    bool timeExpired = isRecalibrationNeededByTime(calibrationData);

    if (timeExpired) {
      debugPrint('Recalibration needed: Time threshold exceeded');
      return true;
    } else {
      debugPrint('Recalibration not needed: Within time threshold');
      return false;
    }
  }
}

/// Simple 3D vector class for orientation calculations
class Vector3 {
  final double x;
  final double y;
  final double z;

  Vector3(this.x, this.y, this.z);

  double dot(Vector3 other) {
    return x * other.x + y * other.y + z * other.z;
  }

  double magnitude() {
    return sqrt(x * x + y * y + z * z);
  }

  Vector3 normalize() {
    double mag = magnitude();
    if (mag == 0) return Vector3(0, 0, 0);
    return Vector3(x / mag, y / mag, z / mag);
  }
}
