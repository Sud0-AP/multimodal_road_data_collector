import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/models/initial_calibration_data.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/repositories/calibration_repository.dart';

/// Filename for storing initial calibration data
const String kInitialCalibrationDataFilename = 'initial_calibration.json';

/// Implementation of [CalibrationRepository] using [FileStorageService]
class CalibrationRepositoryFileImpl implements CalibrationRepository {
  final FileStorageService _fileStorageService;
  String? _documentsDirectoryPath;

  /// Creates a new [CalibrationRepositoryFileImpl] with the given [FileStorageService]
  CalibrationRepositoryFileImpl(this._fileStorageService);

  /// Get the full path for the calibration data file
  Future<String> get _calibrationFilePath async {
    _documentsDirectoryPath ??=
        await _fileStorageService.getDocumentsDirectoryPath();
    return '$_documentsDirectoryPath/$kInitialCalibrationDataFilename';
  }

  @override
  Future<bool> saveInitialCalibrationData(InitialCalibrationData data) async {
    try {
      final jsonString = data.toJsonString();
      final filePath = await _calibrationFilePath;
      return await _fileStorageService.writeStringToFile(jsonString, filePath);
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<InitialCalibrationData?> loadInitialCalibrationData() async {
    try {
      final filePath = await _calibrationFilePath;

      if (!await _fileStorageService.fileExists(filePath)) {
        return null;
      }

      final jsonString = await _fileStorageService.readStringFromFile(filePath);

      if (jsonString == null || jsonString.isEmpty) {
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
      final filePath = await _calibrationFilePath;
      return await _fileStorageService.fileExists(filePath);
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<bool> clearCalibrationData() async {
    try {
      final filePath = await _calibrationFilePath;

      if (!await _fileStorageService.fileExists(filePath)) {
        return true; // Already cleared
      }

      return await _fileStorageService.deleteFile(filePath);
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }
}
