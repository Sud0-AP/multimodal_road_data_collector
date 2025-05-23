// Mocks generated by Mockito 5.4.6 from annotations
// in multimodal_road_data_collector/test/features/recording/domain/managers/background_csv_isolate_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i6;
import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart'
    as _i5;
import 'package:multimodal_road_data_collector/core/services/ntp_service.dart'
    as _i4;
import 'package:multimodal_road_data_collector/core/services/sensor_service.dart'
    as _i2;
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart'
    as _i7;

// ignore_for_file: type=lint
// ignore_for_file: avoid_redundant_argument_values
// ignore_for_file: avoid_setters_without_getters
// ignore_for_file: comment_references
// ignore_for_file: deprecated_member_use
// ignore_for_file: deprecated_member_use_from_same_package
// ignore_for_file: implementation_imports
// ignore_for_file: invalid_use_of_visible_for_testing_member
// ignore_for_file: must_be_immutable
// ignore_for_file: prefer_const_constructors
// ignore_for_file: unnecessary_parenthesis
// ignore_for_file: camel_case_types
// ignore_for_file: subtype_of_sealed_class

class _FakeDateTime_0 extends _i1.SmartFake implements DateTime {
  _FakeDateTime_0(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

/// A class which mocks [SensorService].
///
/// See the documentation for Mockito's code generation for more information.
class MockSensorService extends _i1.Mock implements _i2.SensorService {
  MockSensorService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<void> initialize() =>
      (super.noSuchMethod(
            Invocation.method(#initialize, []),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Stream<_i2.SensorData> getSensorDataStream() =>
      (super.noSuchMethod(
            Invocation.method(#getSensorDataStream, []),
            returnValue: _i3.Stream<_i2.SensorData>.empty(),
          )
          as _i3.Stream<_i2.SensorData>);

  @override
  _i3.Future<void> startSensorDataCollection() =>
      (super.noSuchMethod(
            Invocation.method(#startSensorDataCollection, []),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<void> stopSensorDataCollection() =>
      (super.noSuchMethod(
            Invocation.method(#stopSensorDataCollection, []),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  bool isSensorDataCollectionActive() =>
      (super.noSuchMethod(
            Invocation.method(#isSensorDataCollectionActive, []),
            returnValue: false,
          )
          as bool);

  @override
  _i3.Future<void> dispose() =>
      (super.noSuchMethod(
            Invocation.method(#dispose, []),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);
}

/// A class which mocks [NtpService].
///
/// See the documentation for Mockito's code generation for more information.
class MockNtpService extends _i1.Mock implements _i4.NtpService {
  MockNtpService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<void> initialize() =>
      (super.noSuchMethod(
            Invocation.method(#initialize, []),
            returnValue: _i3.Future<void>.value(),
            returnValueForMissingStub: _i3.Future<void>.value(),
          )
          as _i3.Future<void>);

  @override
  _i3.Future<int> getOffset() =>
      (super.noSuchMethod(
            Invocation.method(#getOffset, []),
            returnValue: _i3.Future<int>.value(0),
          )
          as _i3.Future<int>);

  @override
  _i3.Future<DateTime> getCurrentNtpTime() =>
      (super.noSuchMethod(
            Invocation.method(#getCurrentNtpTime, []),
            returnValue: _i3.Future<DateTime>.value(
              _FakeDateTime_0(this, Invocation.method(#getCurrentNtpTime, [])),
            ),
          )
          as _i3.Future<DateTime>);

  @override
  DateTime deviceTimeToNtpTime(DateTime? deviceTime) =>
      (super.noSuchMethod(
            Invocation.method(#deviceTimeToNtpTime, [deviceTime]),
            returnValue: _FakeDateTime_0(
              this,
              Invocation.method(#deviceTimeToNtpTime, [deviceTime]),
            ),
          )
          as DateTime);

  @override
  int deviceTimestampToNtpTimestamp(int? deviceTimestampMs) =>
      (super.noSuchMethod(
            Invocation.method(#deviceTimestampToNtpTimestamp, [
              deviceTimestampMs,
            ]),
            returnValue: 0,
          )
          as int);

  @override
  _i3.Future<bool> isSynchronized() =>
      (super.noSuchMethod(
            Invocation.method(#isSynchronized, []),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);
}

/// A class which mocks [FileStorageService].
///
/// See the documentation for Mockito's code generation for more information.
class MockFileStorageService extends _i1.Mock
    implements _i5.FileStorageService {
  MockFileStorageService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<String> getDocumentsDirectoryPath() =>
      (super.noSuchMethod(
            Invocation.method(#getDocumentsDirectoryPath, []),
            returnValue: _i3.Future<String>.value(
              _i6.dummyValue<String>(
                this,
                Invocation.method(#getDocumentsDirectoryPath, []),
              ),
            ),
          )
          as _i3.Future<String>);

  @override
  _i3.Future<String> getTemporaryDirectoryPath() =>
      (super.noSuchMethod(
            Invocation.method(#getTemporaryDirectoryPath, []),
            returnValue: _i3.Future<String>.value(
              _i6.dummyValue<String>(
                this,
                Invocation.method(#getTemporaryDirectoryPath, []),
              ),
            ),
          )
          as _i3.Future<String>);

  @override
  _i3.Future<String?> getExternalStorageDirectoryPath() =>
      (super.noSuchMethod(
            Invocation.method(#getExternalStorageDirectoryPath, []),
            returnValue: _i3.Future<String?>.value(),
          )
          as _i3.Future<String?>);

  @override
  _i3.Future<bool> writeStringToFile(String? content, String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#writeStringToFile, [content, filePath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<String?> readStringFromFile(String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#readStringFromFile, [filePath]),
            returnValue: _i3.Future<String?>.value(),
          )
          as _i3.Future<String?>);

  @override
  _i3.Future<bool> writeBytesToFile(List<int>? bytes, String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#writeBytesToFile, [bytes, filePath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<List<int>?> readBytesFromFile(String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#readBytesFromFile, [filePath]),
            returnValue: _i3.Future<List<int>?>.value(),
          )
          as _i3.Future<List<int>?>);

  @override
  _i3.Future<bool> fileExists(String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#fileExists, [filePath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<bool> deleteFile(String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#deleteFile, [filePath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<bool> createDirectory(String? directoryPath) =>
      (super.noSuchMethod(
            Invocation.method(#createDirectory, [directoryPath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<List<String>> listFiles(String? directoryPath) =>
      (super.noSuchMethod(
            Invocation.method(#listFiles, [directoryPath]),
            returnValue: _i3.Future<List<String>>.value(<String>[]),
          )
          as _i3.Future<List<String>>);

  @override
  _i3.Future<List<String>> listFilesWithExtension(
    String? directoryPath,
    String? extension,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#listFilesWithExtension, [
              directoryPath,
              extension,
            ]),
            returnValue: _i3.Future<List<String>>.value(<String>[]),
          )
          as _i3.Future<List<String>>);

  @override
  _i3.Future<bool> copyFile(String? sourcePath, String? destinationPath) =>
      (super.noSuchMethod(
            Invocation.method(#copyFile, [sourcePath, destinationPath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<bool> moveFile(String? sourcePath, String? destinationPath) =>
      (super.noSuchMethod(
            Invocation.method(#moveFile, [sourcePath, destinationPath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<int?> getFileSize(String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#getFileSize, [filePath]),
            returnValue: _i3.Future<int?>.value(),
          )
          as _i3.Future<int?>);

  @override
  _i3.Future<int?> getAvailableStorage() =>
      (super.noSuchMethod(
            Invocation.method(#getAvailableStorage, []),
            returnValue: _i3.Future<int?>.value(),
          )
          as _i3.Future<int?>);

  @override
  _i3.Future<String?> exportFile(String? sourcePath, String? fileName) =>
      (super.noSuchMethod(
            Invocation.method(#exportFile, [sourcePath, fileName]),
            returnValue: _i3.Future<String?>.value(),
          )
          as _i3.Future<String?>);

  @override
  _i3.Future<String> createNewSessionDirectory() =>
      (super.noSuchMethod(
            Invocation.method(#createNewSessionDirectory, []),
            returnValue: _i3.Future<String>.value(
              _i6.dummyValue<String>(
                this,
                Invocation.method(#createNewSessionDirectory, []),
              ),
            ),
          )
          as _i3.Future<String>);

  @override
  _i3.Future<bool> writeMetadata(
    String? metadataContent,
    String? sessionPath,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#writeMetadata, [metadataContent, sessionPath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<Map<String, String>?> readMetadataSummary(
    String? sessionPath, [
    List<String>? keysToRead,
  ]) =>
      (super.noSuchMethod(
            Invocation.method(#readMetadataSummary, [sessionPath, keysToRead]),
            returnValue: _i3.Future<Map<String, String>?>.value(),
          )
          as _i3.Future<Map<String, String>?>);

  @override
  _i3.Future<List<String>> listRecordingSessionPaths() =>
      (super.noSuchMethod(
            Invocation.method(#listRecordingSessionPaths, []),
            returnValue: _i3.Future<List<String>>.value(<String>[]),
          )
          as _i3.Future<List<String>>);

  @override
  _i3.Future<List<String>> getSessionFilePathsForSharing(String? sessionPath) =>
      (super.noSuchMethod(
            Invocation.method(#getSessionFilePathsForSharing, [sessionPath]),
            returnValue: _i3.Future<List<String>>.value(<String>[]),
          )
          as _i3.Future<List<String>>);

  @override
  _i3.Future<bool> deleteDirectoryRecursive(String? directoryPath) =>
      (super.noSuchMethod(
            Invocation.method(#deleteDirectoryRecursive, [directoryPath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<bool> openDirectoryInFileExplorer(String? directoryPath) =>
      (super.noSuchMethod(
            Invocation.method(#openDirectoryInFileExplorer, [directoryPath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<String> createSessionDirectory() =>
      (super.noSuchMethod(
            Invocation.method(#createSessionDirectory, []),
            returnValue: _i3.Future<String>.value(
              _i6.dummyValue<String>(
                this,
                Invocation.method(#createSessionDirectory, []),
              ),
            ),
          )
          as _i3.Future<String>);

  @override
  _i3.Future<String> getSessionsBaseDirectory() =>
      (super.noSuchMethod(
            Invocation.method(#getSessionsBaseDirectory, []),
            returnValue: _i3.Future<String>.value(
              _i6.dummyValue<String>(
                this,
                Invocation.method(#getSessionsBaseDirectory, []),
              ),
            ),
          )
          as _i3.Future<String>);

  @override
  _i3.Future<String> saveVideoToSession(
    String? videoPath,
    String? sessionDirectory,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#saveVideoToSession, [
              videoPath,
              sessionDirectory,
            ]),
            returnValue: _i3.Future<String>.value(
              _i6.dummyValue<String>(
                this,
                Invocation.method(#saveVideoToSession, [
                  videoPath,
                  sessionDirectory,
                ]),
              ),
            ),
          )
          as _i3.Future<String>);

  @override
  _i3.Future<List<String>> listSessions() =>
      (super.noSuchMethod(
            Invocation.method(#listSessions, []),
            returnValue: _i3.Future<List<String>>.value(<String>[]),
          )
          as _i3.Future<List<String>>);

  @override
  _i3.Future<bool> createCsvWithHeader(
    String? filePath,
    List<String>? headerColumns,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#createCsvWithHeader, [filePath, headerColumns]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<bool> appendToCsv(String? filePath, List<String>? rows) =>
      (super.noSuchMethod(
            Invocation.method(#appendToCsv, [filePath, rows]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<String> getSensorDataCsvPath(
    String? sessionDirectory, {
    bool? createIfNotExists = false,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #getSensorDataCsvPath,
              [sessionDirectory],
              {#createIfNotExists: createIfNotExists},
            ),
            returnValue: _i3.Future<String>.value(
              _i6.dummyValue<String>(
                this,
                Invocation.method(
                  #getSensorDataCsvPath,
                  [sessionDirectory],
                  {#createIfNotExists: createIfNotExists},
                ),
              ),
            ),
          )
          as _i3.Future<String>);

  @override
  _i3.Future<bool> appendToSensorDataCsv(
    String? sessionDirectory,
    List<_i7.CorrectedSensorDataPoint>? dataPoints,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#appendToSensorDataCsv, [
              sessionDirectory,
              dataPoints,
            ]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<String> getAnnotationsLogPath(
    String? sessionDirectory, {
    bool? createIfNotExists = false,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #getAnnotationsLogPath,
              [sessionDirectory],
              {#createIfNotExists: createIfNotExists},
            ),
            returnValue: _i3.Future<String>.value(
              _i6.dummyValue<String>(
                this,
                Invocation.method(
                  #getAnnotationsLogPath,
                  [sessionDirectory],
                  {#createIfNotExists: createIfNotExists},
                ),
              ),
            ),
          )
          as _i3.Future<String>);

  @override
  _i3.Future<bool> logAnnotation(
    String? sessionDirectory,
    int? spikeTimestampMs,
    String? feedbackType,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#logAnnotation, [
              sessionDirectory,
              spikeTimestampMs,
              feedbackType,
            ]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);
}
