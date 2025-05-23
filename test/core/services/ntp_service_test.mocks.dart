// Mocks generated by Mockito 5.4.6 from annotations
// in multimodal_road_data_collector/test/core/services/ntp_service_test.dart.
// Do not manually edit this file.

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'dart:async' as _i3;

import 'package:mockito/mockito.dart' as _i1;
import 'package:multimodal_road_data_collector/core/services/ntp_service.dart'
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

class _FakeDateTime_0 extends _i1.SmartFake implements DateTime {
  _FakeDateTime_0(Object parent, Invocation parentInvocation)
    : super(parent, parentInvocation);
}

/// A class which mocks [NtpService].
///
/// See the documentation for Mockito's code generation for more information.
class MockNtpService extends _i1.Mock implements _i2.NtpService {
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
