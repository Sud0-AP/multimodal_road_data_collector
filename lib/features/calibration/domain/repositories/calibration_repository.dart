import '../models/initial_calibration_data.dart';

/// Repository interface for managing calibration data
abstract class CalibrationRepository {
  /// Save the initial calibration data to persistent storage
  ///
  /// Returns true if the operation was successful, false otherwise
  Future<bool> saveInitialCalibrationData(InitialCalibrationData data);

  /// Load the initial calibration data from persistent storage
  ///
  /// Returns the calibration data if available, null otherwise
  Future<InitialCalibrationData?> loadInitialCalibrationData();

  /// Check if initial calibration data exists in storage
  ///
  /// Returns true if calibration data exists, false otherwise
  Future<bool> hasInitialCalibrationData();

  /// Clear all stored calibration data
  ///
  /// Returns true if the operation was successful, false otherwise
  Future<bool> clearCalibrationData();
}
