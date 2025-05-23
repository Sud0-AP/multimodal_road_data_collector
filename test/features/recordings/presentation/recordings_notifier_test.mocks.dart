// Mocks generated by Mockito 5.4.6 from annotations
// in multimodal_road_data_collector/test/features/recordings/presentation/recordings_notifier_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:mockito/mockito.dart' as _i1;
import 'package:multimodal_road_data_collector/core/services/data_management_service.dart'
    as _i2;

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

/// A class which mocks [DataManagementService].
///
/// See the documentation for Mockito's code generation for more information.
class MockDataManagementService extends _i1.Mock
    implements _i2.DataManagementService {
  MockDataManagementService() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<bool> generateAndSaveMetadata(
    String? sessionPath,
    Map<String, dynamic>? recordingData,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#generateAndSaveMetadata, [
              sessionPath,
              recordingData,
            ]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<List<String>> loadSessionList() =>
      (super.noSuchMethod(
            Invocation.method(#loadSessionList, []),
            returnValue: _i3.Future<List<String>>.value(<String>[]),
          )
          as _i3.Future<List<String>>);

  @override
  _i3.Future<Map<String, dynamic>?> getSessionDisplayInfo(
    String? sessionPath,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#getSessionDisplayInfo, [sessionPath]),
            returnValue: _i3.Future<Map<String, dynamic>?>.value(),
          )
          as _i3.Future<Map<String, dynamic>?>);

  @override
  _i3.Future<bool> deleteSession(String? sessionPath) =>
      (super.noSuchMethod(
            Invocation.method(#deleteSession, [sessionPath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<bool> shareSession(String? sessionPath) =>
      (super.noSuchMethod(
            Invocation.method(#shareSession, [sessionPath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<bool> openSessionInFileExplorer(String? sessionPath) =>
      (super.noSuchMethod(
            Invocation.method(#openSessionInFileExplorer, [sessionPath]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);
}
