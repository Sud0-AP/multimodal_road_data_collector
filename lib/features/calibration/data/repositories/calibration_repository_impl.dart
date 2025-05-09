import 'package:multimodal_road_data_collector/core/services/preferences_service.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/models/initial_calibration_data.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/repositories/calibration_repository.dart';

/// Key for storing initial calibration data in preferences
const String kInitialCalibrationData = 'initial_calibration_data';

/// Implementation of [CalibrationRepository] using [PreferencesService]
class CalibrationRepositoryImpl implements CalibrationRepository {
  final PreferencesService _preferencesService;

  /// Creates a new [CalibrationRepositoryImpl] with the given [PreferencesService]
  CalibrationRepositoryImpl(this._preferencesService);

  @override
  Future<bool> saveInitialCalibrationData(InitialCalibrationData data) async {
    try {
      final jsonString = data.toJsonString();
      return await _preferencesService.setString(
        kInitialCalibrationData,
        jsonString,
      );
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<InitialCalibrationData?> loadInitialCalibrationData() async {
    try {
      final jsonString = await _preferencesService.getString(
        kInitialCalibrationData,
      );

      if (jsonString == null) {
        return null;
      }

      return InitialCalibrationData.fromJsonString(jsonString);
    } catch (e) {
      // Log error in a real application
      return null;
    }
  }

  @override
  Future<bool> hasInitialCalibrationData() async {
    try {
      return await _preferencesService.containsKey(kInitialCalibrationData);
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<bool> clearCalibrationData() async {
    try {
      return await _preferencesService.remove(kInitialCalibrationData);
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }
}
