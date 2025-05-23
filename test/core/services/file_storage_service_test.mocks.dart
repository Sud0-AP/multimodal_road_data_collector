// Mocks generated by Mockito 5.4.6 from annotations
// in multimodal_road_data_collector/test/core/services/file_storage_service_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i4;
import 'dart:io' as _i2;

import 'package:mockito/mockito.dart' as _i1;
import 'package:mockito/src/dummies.dart' as _i3;
import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart'
    as _i5;
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart'
    as _i6;

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

class _FakeUri_0 extends _i1.SmartFake implements Uri {
  _FakeUri_0(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeDirectory_1 extends _i1.SmartFake implements _i2.Directory {
  _FakeDirectory_1(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeFileSystemEntity_2 extends _i1.SmartFake
    implements _i2.FileSystemEntity {
  _FakeFileSystemEntity_2(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

class _FakeFileStat_3 extends _i1.SmartFake implements _i2.FileStat {
  _FakeFileStat_3(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

/// A class which mocks [Directory].
///
/// See the documentation for Mockito's code generation for more information.
class MockDirectory extends _i1.Mock implements _i2.Directory {
  MockDirectory() {
    _i1.throwOnMissingStub(this);
  }

  @override
  String get path =>
      (super.noSuchMethod(
            Invocation.getter(#path),
            returnValue: _i3.dummyValue<String>(this, Invocation.getter(#path)),
          )
          as String);

  @override
  Uri get uri =>
      (super.noSuchMethod(
            Invocation.getter(#uri),
            returnValue: _FakeUri_0(this, Invocation.getter(#uri)),
          )
          as Uri);

  @override
  _i2.Directory get absolute =>
      (super.noSuchMethod(
            Invocation.getter(#absolute),
            returnValue: _FakeDirectory_1(this, Invocation.getter(#absolute)),
          )
          as _i2.Directory);

  @override
  bool get isAbsolute =>
      (super.noSuchMethod(Invocation.getter(#isAbsolute), returnValue: false)
          as bool);

  @override
  _i2.Directory get parent =>
      (super.noSuchMethod(
            Invocation.getter(#parent),
            returnValue: _FakeDirectory_1(this, Invocation.getter(#parent)),
          )
          as _i2.Directory);

  @override
  _i4.Future<_i2.Directory> create({bool? recursive = false}) =>
      (super.noSuchMethod(
            Invocation.method(#create, [], {#recursive: recursive}),
            returnValue: _i4.Future<_i2.Directory>.value(
              _FakeDirectory_1(
                this,
                Invocation.method(#create, [], {#recursive: recursive}),
              ),
            ),
          )
          as _i4.Future<_i2.Directory>);

  @override
  void createSync({bool? recursive = false}) => super.noSuchMethod(
    Invocation.method(#createSync, [], {#recursive: recursive}),
    returnValueForMissingStub: null,
  );

  @override
  _i4.Future<_i2.Directory> createTemp([String? prefix]) =>
      (super.noSuchMethod(
            Invocation.method(#createTemp, [prefix]),
            returnValue: _i4.Future<_i2.Directory>.value(
              _FakeDirectory_1(this, Invocation.method(#createTemp, [prefix])),
            ),
          )
          as _i4.Future<_i2.Directory>);

  @override
  _i2.Directory createTempSync([String? prefix]) =>
      (super.noSuchMethod(
            Invocation.method(#createTempSync, [prefix]),
            returnValue: _FakeDirectory_1(
              this,
              Invocation.method(#createTempSync, [prefix]),
            ),
          )
          as _i2.Directory);

  @override
  _i4.Future<String> resolveSymbolicLinks() =>
      (super.noSuchMethod(
            Invocation.method(#resolveSymbolicLinks, []),
            returnValue: _i4.Future<String>.value(
              _i3.dummyValue<String>(
                this,
                Invocation.method(#resolveSymbolicLinks, []),
              ),
            ),
          )
          as _i4.Future<String>);

  @override
  String resolveSymbolicLinksSync() =>
      (super.noSuchMethod(
            Invocation.method(#resolveSymbolicLinksSync, []),
            returnValue: _i3.dummyValue<String>(
              this,
              Invocation.method(#resolveSymbolicLinksSync, []),
            ),
          )
          as String);

  @override
  _i4.Future<_i2.Directory> rename(String? newPath) =>
      (super.noSuchMethod(
            Invocation.method(#rename, [newPath]),
            returnValue: _i4.Future<_i2.Directory>.value(
              _FakeDirectory_1(this, Invocation.method(#rename, [newPath])),
            ),
          )
          as _i4.Future<_i2.Directory>);

  @override
  _i2.Directory renameSync(String? newPath) =>
      (super.noSuchMethod(
            Invocation.method(#renameSync, [newPath]),
            returnValue: _FakeDirectory_1(
              this,
              Invocation.method(#renameSync, [newPath]),
            ),
          )
          as _i2.Directory);

  @override
  _i4.Future<_i2.FileSystemEntity> delete({bool? recursive = false}) =>
      (super.noSuchMethod(
            Invocation.method(#delete, [], {#recursive: recursive}),
            returnValue: _i4.Future<_i2.FileSystemEntity>.value(
              _FakeFileSystemEntity_2(
                this,
                Invocation.method(#delete, [], {#recursive: recursive}),
              ),
            ),
          )
          as _i4.Future<_i2.FileSystemEntity>);

  @override
  void deleteSync({bool? recursive = false}) => super.noSuchMethod(
    Invocation.method(#deleteSync, [], {#recursive: recursive}),
    returnValueForMissingStub: null,
  );

  @override
  _i4.Stream<_i2.FileSystemEntity> list({
    bool? recursive = false,
    bool? followLinks = true,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#list, [], {
              #recursive: recursive,
              #followLinks: followLinks,
            }),
            returnValue: _i4.Stream<_i2.FileSystemEntity>.empty(),
          )
          as _i4.Stream<_i2.FileSystemEntity>);

  @override
  List<_i2.FileSystemEntity> listSync({
    bool? recursive = false,
    bool? followLinks = true,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#listSync, [], {
              #recursive: recursive,
              #followLinks: followLinks,
            }),
            returnValue: <_i2.FileSystemEntity>[],
          )
          as List<_i2.FileSystemEntity>);

  @override
  _i4.Future<bool> exists() =>
      (super.noSuchMethod(
            Invocation.method(#exists, []),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  bool existsSync() =>
      (super.noSuchMethod(
            Invocation.method(#existsSync, []),
            returnValue: false,
          )
          as bool);

  @override
  _i4.Future<_i2.FileStat> stat() =>
      (super.noSuchMethod(
            Invocation.method(#stat, []),
            returnValue: _i4.Future<_i2.FileStat>.value(
              _FakeFileStat_3(this, Invocation.method(#stat, [])),
            ),
          )
          as _i4.Future<_i2.FileStat>);

  @override
  _i2.FileStat statSync() =>
      (super.noSuchMethod(
            Invocation.method(#statSync, []),
            returnValue: _FakeFileStat_3(
              this,
              Invocation.method(#statSync, []),
            ),
          )
          as _i2.FileStat);

  @override
  _i4.Stream<_i2.FileSystemEvent> watch({
    int? events = 15,
    bool? recursive = false,
  }) =>
      (super.noSuchMethod(
            Invocation.method(#watch, [], {
              #events: events,
              #recursive: recursive,
            }),
            returnValue: _i4.Stream<_i2.FileSystemEvent>.empty(),
          )
          as _i4.Stream<_i2.FileSystemEvent>);
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
  _i4.Future<String> getDocumentsDirectoryPath() =>
      (super.noSuchMethod(
            Invocation.method(#getDocumentsDirectoryPath, []),
            returnValue: _i4.Future<String>.value(
              _i3.dummyValue<String>(
                this,
                Invocation.method(#getDocumentsDirectoryPath, []),
              ),
            ),
          )
          as _i4.Future<String>);

  @override
  _i4.Future<String> getTemporaryDirectoryPath() =>
      (super.noSuchMethod(
            Invocation.method(#getTemporaryDirectoryPath, []),
            returnValue: _i4.Future<String>.value(
              _i3.dummyValue<String>(
                this,
                Invocation.method(#getTemporaryDirectoryPath, []),
              ),
            ),
          )
          as _i4.Future<String>);

  @override
  _i4.Future<String?> getExternalStorageDirectoryPath() =>
      (super.noSuchMethod(
            Invocation.method(#getExternalStorageDirectoryPath, []),
            returnValue: _i4.Future<String?>.value(),
          )
          as _i4.Future<String?>);

  @override
  _i4.Future<bool> writeStringToFile(String? content, String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#writeStringToFile, [content, filePath]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<String?> readStringFromFile(String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#readStringFromFile, [filePath]),
            returnValue: _i4.Future<String?>.value(),
          )
          as _i4.Future<String?>);

  @override
  _i4.Future<bool> writeBytesToFile(List<int>? bytes, String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#writeBytesToFile, [bytes, filePath]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<List<int>?> readBytesFromFile(String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#readBytesFromFile, [filePath]),
            returnValue: _i4.Future<List<int>?>.value(),
          )
          as _i4.Future<List<int>?>);

  @override
  _i4.Future<bool> fileExists(String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#fileExists, [filePath]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<bool> deleteFile(String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#deleteFile, [filePath]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<bool> createDirectory(String? directoryPath) =>
      (super.noSuchMethod(
            Invocation.method(#createDirectory, [directoryPath]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<List<String>> listFiles(String? directoryPath) =>
      (super.noSuchMethod(
            Invocation.method(#listFiles, [directoryPath]),
            returnValue: _i4.Future<List<String>>.value(<String>[]),
          )
          as _i4.Future<List<String>>);

  @override
  _i4.Future<List<String>> listFilesWithExtension(
    String? directoryPath,
    String? extension,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#listFilesWithExtension, [
              directoryPath,
              extension,
            ]),
            returnValue: _i4.Future<List<String>>.value(<String>[]),
          )
          as _i4.Future<List<String>>);

  @override
  _i4.Future<bool> copyFile(String? sourcePath, String? destinationPath) =>
      (super.noSuchMethod(
            Invocation.method(#copyFile, [sourcePath, destinationPath]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<bool> moveFile(String? sourcePath, String? destinationPath) =>
      (super.noSuchMethod(
            Invocation.method(#moveFile, [sourcePath, destinationPath]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<int?> getFileSize(String? filePath) =>
      (super.noSuchMethod(
            Invocation.method(#getFileSize, [filePath]),
            returnValue: _i4.Future<int?>.value(),
          )
          as _i4.Future<int?>);

  @override
  _i4.Future<int?> getAvailableStorage() =>
      (super.noSuchMethod(
            Invocation.method(#getAvailableStorage, []),
            returnValue: _i4.Future<int?>.value(),
          )
          as _i4.Future<int?>);

  @override
  _i4.Future<String?> exportFile(String? sourcePath, String? fileName) =>
      (super.noSuchMethod(
            Invocation.method(#exportFile, [sourcePath, fileName]),
            returnValue: _i4.Future<String?>.value(),
          )
          as _i4.Future<String?>);

  @override
  _i4.Future<String> createNewSessionDirectory() =>
      (super.noSuchMethod(
            Invocation.method(#createNewSessionDirectory, []),
            returnValue: _i4.Future<String>.value(
              _i3.dummyValue<String>(
                this,
                Invocation.method(#createNewSessionDirectory, []),
              ),
            ),
          )
          as _i4.Future<String>);

  @override
  _i4.Future<bool> writeMetadata(
    String? metadataContent,
    String? sessionPath,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#writeMetadata, [metadataContent, sessionPath]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<Map<String, String>?> readMetadataSummary(
    String? sessionPath, [
    List<String>? keysToRead,
  ]) =>
      (super.noSuchMethod(
            Invocation.method(#readMetadataSummary, [sessionPath, keysToRead]),
            returnValue: _i4.Future<Map<String, String>?>.value(),
          )
          as _i4.Future<Map<String, String>?>);

  @override
  _i4.Future<List<String>> listRecordingSessionPaths() =>
      (super.noSuchMethod(
            Invocation.method(#listRecordingSessionPaths, []),
            returnValue: _i4.Future<List<String>>.value(<String>[]),
          )
          as _i4.Future<List<String>>);

  @override
  _i4.Future<List<String>> getSessionFilePathsForSharing(String? sessionPath) =>
      (super.noSuchMethod(
            Invocation.method(#getSessionFilePathsForSharing, [sessionPath]),
            returnValue: _i4.Future<List<String>>.value(<String>[]),
          )
          as _i4.Future<List<String>>);

  @override
  _i4.Future<bool> deleteDirectoryRecursive(String? directoryPath) =>
      (super.noSuchMethod(
            Invocation.method(#deleteDirectoryRecursive, [directoryPath]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<bool> openDirectoryInFileExplorer(String? directoryPath) =>
      (super.noSuchMethod(
            Invocation.method(#openDirectoryInFileExplorer, [directoryPath]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<String> createSessionDirectory() =>
      (super.noSuchMethod(
            Invocation.method(#createSessionDirectory, []),
            returnValue: _i4.Future<String>.value(
              _i3.dummyValue<String>(
                this,
                Invocation.method(#createSessionDirectory, []),
              ),
            ),
          )
          as _i4.Future<String>);

  @override
  _i4.Future<String> getSessionsBaseDirectory() =>
      (super.noSuchMethod(
            Invocation.method(#getSessionsBaseDirectory, []),
            returnValue: _i4.Future<String>.value(
              _i3.dummyValue<String>(
                this,
                Invocation.method(#getSessionsBaseDirectory, []),
              ),
            ),
          )
          as _i4.Future<String>);

  @override
  _i4.Future<String> saveVideoToSession(
    String? videoPath,
    String? sessionDirectory,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#saveVideoToSession, [
              videoPath,
              sessionDirectory,
            ]),
            returnValue: _i4.Future<String>.value(
              _i3.dummyValue<String>(
                this,
                Invocation.method(#saveVideoToSession, [
                  videoPath,
                  sessionDirectory,
                ]),
              ),
            ),
          )
          as _i4.Future<String>);

  @override
  _i4.Future<List<String>> listSessions() =>
      (super.noSuchMethod(
            Invocation.method(#listSessions, []),
            returnValue: _i4.Future<List<String>>.value(<String>[]),
          )
          as _i4.Future<List<String>>);

  @override
  _i4.Future<bool> createCsvWithHeader(
    String? filePath,
    List<String>? headerColumns,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#createCsvWithHeader, [filePath, headerColumns]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<bool> appendToCsv(String? filePath, List<String>? rows) =>
      (super.noSuchMethod(
            Invocation.method(#appendToCsv, [filePath, rows]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<String> getSensorDataCsvPath(
    String? sessionDirectory, {
    bool? createIfNotExists = false,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #getSensorDataCsvPath,
              [sessionDirectory],
              {#createIfNotExists: createIfNotExists},
            ),
            returnValue: _i4.Future<String>.value(
              _i3.dummyValue<String>(
                this,
                Invocation.method(
                  #getSensorDataCsvPath,
                  [sessionDirectory],
                  {#createIfNotExists: createIfNotExists},
                ),
              ),
            ),
          )
          as _i4.Future<String>);

  @override
  _i4.Future<bool> appendToSensorDataCsv(
    String? sessionDirectory,
    List<_i6.CorrectedSensorDataPoint>? dataPoints,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#appendToSensorDataCsv, [
              sessionDirectory,
              dataPoints,
            ]),
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);

  @override
  _i4.Future<String> getAnnotationsLogPath(
    String? sessionDirectory, {
    bool? createIfNotExists = false,
  }) =>
      (super.noSuchMethod(
            Invocation.method(
              #getAnnotationsLogPath,
              [sessionDirectory],
              {#createIfNotExists: createIfNotExists},
            ),
            returnValue: _i4.Future<String>.value(
              _i3.dummyValue<String>(
                this,
                Invocation.method(
                  #getAnnotationsLogPath,
                  [sessionDirectory],
                  {#createIfNotExists: createIfNotExists},
                ),
              ),
            ),
          )
          as _i4.Future<String>);

  @override
  _i4.Future<bool> logAnnotation(
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
            returnValue: _i4.Future<bool>.value(false),
          )
          as _i4.Future<bool>);
}
