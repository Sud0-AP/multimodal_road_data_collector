// Mocks generated by Mockito 5.4.6 from annotations
// in multimodal_road_data_collector/test/features/calibration/domain/usecases/calibration_usecase_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:mockito/mockito.dart' as _i1;
import 'package:multimodal_road_data_collector/core/services/sensor_service.dart'
    as _i2;
import 'package:multimodal_road_data_collector/features/calibration/domain/models/initial_calibration_data.dart'
    as _i5;
import 'package:multimodal_road_data_collector/features/calibration/domain/repositories/calibration_repository.dart'
    as _i4;

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

/// A class which mocks [CalibrationRepository].
///
/// See the documentation for Mockito's code generation for more information.
class MockCalibrationRepository extends _i1.Mock
    implements _i4.CalibrationRepository {
  MockCalibrationRepository() {
    _i1.throwOnMissingStub(this);
  }

  @override
  _i3.Future<bool> saveInitialCalibrationData(
    _i5.InitialCalibrationData? data,
  ) =>
      (super.noSuchMethod(
            Invocation.method(#saveInitialCalibrationData, [data]),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<_i5.InitialCalibrationData?> loadInitialCalibrationData() =>
      (super.noSuchMethod(
            Invocation.method(#loadInitialCalibrationData, []),
            returnValue: _i3.Future<_i5.InitialCalibrationData?>.value(),
          )
          as _i3.Future<_i5.InitialCalibrationData?>);

  @override
  _i3.Future<bool> hasInitialCalibrationData() =>
      (super.noSuchMethod(
            Invocation.method(#hasInitialCalibrationData, []),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);

  @override
  _i3.Future<bool> clearCalibrationData() =>
      (super.noSuchMethod(
            Invocation.method(#clearCalibrationData, []),
            returnValue: _i3.Future<bool>.value(false),
          )
          as _i3.Future<bool>);
}
