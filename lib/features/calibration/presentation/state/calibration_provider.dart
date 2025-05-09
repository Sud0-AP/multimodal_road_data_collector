import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that determines if calibration is needed
///
/// Since we want calibration to happen on every app launch,
/// this will always return true
final calibrationNeededProvider = Provider<bool>((ref) {
  // Always return true to force calibration on every app launch
  return true;
});

/// State provider to track if calibration is currently in progress
final calibrationInProgressProvider = StateProvider<bool>((ref) => false);

/// State provider to track if calibration is completed for the current session
final calibrationCompletedProvider = StateProvider<bool>((ref) => false);

/// Constant key for storing calibration data in preferences
const String kCalibrationDataKey = 'calibration_data';
