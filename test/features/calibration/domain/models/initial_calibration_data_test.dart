import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/models/initial_calibration_data.dart';

void main() {
  group('InitialCalibrationData', () {
    test('should create an instance with the correct values', () {
      // Create a timestamp for testing
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      // Create an instance
      final data = InitialCalibrationData(
        deviceOrientation: DeviceOrientation.portrait,
        accelerometerXOffset: 0.1,
        accelerometerYOffset: 0.2,
        accelerometerZOffset: 0.3,
        gyroscopeXOffset: 0.01,
        gyroscopeYOffset: 0.02,
        gyroscopeZOffset: 0.03,
        calibrationTimestamp: timestamp,
      );

      // Verify the values are set correctly
      expect(data.deviceOrientation, equals(DeviceOrientation.portrait));
      expect(data.accelerometerXOffset, equals(0.1));
      expect(data.accelerometerYOffset, equals(0.2));
      expect(data.accelerometerZOffset, equals(0.3));
      expect(data.gyroscopeXOffset, equals(0.01));
      expect(data.gyroscopeYOffset, equals(0.02));
      expect(data.gyroscopeZOffset, equals(0.03));
      expect(data.calibrationTimestamp, equals(timestamp));
    });

    test(
      'initial factory creates default instance with unknown orientation and zero offsets',
      () {
        final data = InitialCalibrationData.initial();

        expect(data.deviceOrientation, equals(DeviceOrientation.unknown));
        expect(data.accelerometerXOffset, equals(0.0));
        expect(data.accelerometerYOffset, equals(0.0));
        expect(data.accelerometerZOffset, equals(0.0));
        expect(data.gyroscopeXOffset, equals(0.0));
        expect(data.gyroscopeYOffset, equals(0.0));
        expect(data.gyroscopeZOffset, equals(0.0));
        expect(data.calibrationTimestamp, isNotNull);
      },
    );

    test('copyWith creates a new instance with updated values', () {
      // Create an original instance
      final original = InitialCalibrationData(
        deviceOrientation: DeviceOrientation.portrait,
        accelerometerXOffset: 0.1,
        accelerometerYOffset: 0.2,
        accelerometerZOffset: 0.3,
        gyroscopeXOffset: 0.01,
        gyroscopeYOffset: 0.02,
        gyroscopeZOffset: 0.03,
        calibrationTimestamp: 1000,
      );

      // Create a copy with some updated values
      final copy = original.copyWith(
        deviceOrientation: DeviceOrientation.landscapeRight,
        accelerometerXOffset: 0.5,
        gyroscopeYOffset: 0.07,
        calibrationTimestamp: 2000,
      );

      // Verify updated values
      expect(copy.deviceOrientation, equals(DeviceOrientation.landscapeRight));
      expect(copy.accelerometerXOffset, equals(0.5));
      expect(copy.accelerometerYOffset, equals(0.2)); // Unchanged
      expect(copy.accelerometerZOffset, equals(0.3)); // Unchanged
      expect(copy.gyroscopeXOffset, equals(0.01)); // Unchanged
      expect(copy.gyroscopeYOffset, equals(0.07));
      expect(copy.gyroscopeZOffset, equals(0.03)); // Unchanged
      expect(copy.calibrationTimestamp, equals(2000));
    });

    test('toJson converts model to correct JSON map', () {
      final data = InitialCalibrationData(
        deviceOrientation: DeviceOrientation.landscapeRight,
        accelerometerXOffset: 0.1,
        accelerometerYOffset: 0.2,
        accelerometerZOffset: 0.3,
        gyroscopeXOffset: 0.01,
        gyroscopeYOffset: 0.02,
        gyroscopeZOffset: 0.03,
        calibrationTimestamp: 1000,
      );

      final json = data.toJson();

      expect(json['deviceOrientation'], equals('landscapeRight'));
      expect(json['accelerometerXOffset'], equals(0.1));
      expect(json['accelerometerYOffset'], equals(0.2));
      expect(json['accelerometerZOffset'], equals(0.3));
      expect(json['gyroscopeXOffset'], equals(0.01));
      expect(json['gyroscopeYOffset'], equals(0.02));
      expect(json['gyroscopeZOffset'], equals(0.03));
      expect(json['calibrationTimestamp'], equals(1000));
    });

    test('fromJson creates model from JSON map correctly', () {
      final json = {
        'deviceOrientation': 'landscapeLeft',
        'accelerometerXOffset': 0.1,
        'accelerometerYOffset': 0.2,
        'accelerometerZOffset': 0.3,
        'gyroscopeXOffset': 0.01,
        'gyroscopeYOffset': 0.02,
        'gyroscopeZOffset': 0.03,
        'calibrationTimestamp': 1000,
      };

      final data = InitialCalibrationData.fromJson(json);

      expect(data.deviceOrientation, equals(DeviceOrientation.landscapeLeft));
      expect(data.accelerometerXOffset, equals(0.1));
      expect(data.accelerometerYOffset, equals(0.2));
      expect(data.accelerometerZOffset, equals(0.3));
      expect(data.gyroscopeXOffset, equals(0.01));
      expect(data.gyroscopeYOffset, equals(0.02));
      expect(data.gyroscopeZOffset, equals(0.03));
      expect(data.calibrationTimestamp, equals(1000));
    });

    test('toJsonString and fromJsonString round trip works correctly', () {
      final original = InitialCalibrationData(
        deviceOrientation: DeviceOrientation.flat,
        accelerometerXOffset: 0.1,
        accelerometerYOffset: 0.2,
        accelerometerZOffset: 0.3,
        gyroscopeXOffset: 0.01,
        gyroscopeYOffset: 0.02,
        gyroscopeZOffset: 0.03,
        calibrationTimestamp: 1000,
      );

      final jsonString = original.toJsonString();
      final decoded = InitialCalibrationData.fromJsonString(jsonString);

      expect(decoded.deviceOrientation, equals(original.deviceOrientation));
      expect(
        decoded.accelerometerXOffset,
        equals(original.accelerometerXOffset),
      );
      expect(
        decoded.accelerometerYOffset,
        equals(original.accelerometerYOffset),
      );
      expect(
        decoded.accelerometerZOffset,
        equals(original.accelerometerZOffset),
      );
      expect(decoded.gyroscopeXOffset, equals(original.gyroscopeXOffset));
      expect(decoded.gyroscopeYOffset, equals(original.gyroscopeYOffset));
      expect(decoded.gyroscopeZOffset, equals(original.gyroscopeZOffset));
      expect(
        decoded.calibrationTimestamp,
        equals(original.calibrationTimestamp),
      );
    });

    test('unknown device orientation is handled correctly', () {
      final json = {
        'deviceOrientation': 'invalid_value',
        'accelerometerXOffset': 0.1,
        'accelerometerYOffset': 0.2,
        'accelerometerZOffset': 0.3,
        'gyroscopeXOffset': 0.01,
        'gyroscopeYOffset': 0.02,
        'gyroscopeZOffset': 0.03,
        'calibrationTimestamp': 1000,
      };

      final data = InitialCalibrationData.fromJson(json);

      expect(data.deviceOrientation, equals(DeviceOrientation.unknown));
    });

    test('toString returns a formatted string representation', () {
      final data = InitialCalibrationData(
        deviceOrientation: DeviceOrientation.portrait,
        accelerometerXOffset: 0.1,
        accelerometerYOffset: 0.2,
        accelerometerZOffset: 0.3,
        gyroscopeXOffset: 0.01,
        gyroscopeYOffset: 0.02,
        gyroscopeZOffset: 0.03,
        calibrationTimestamp: 1000,
      );

      final string = data.toString();

      expect(string, contains('deviceOrientation: ${data.deviceOrientation}'));
      expect(
        string,
        contains('accelerometerXOffset: ${data.accelerometerXOffset}'),
      );
      expect(
        string,
        contains('accelerometerYOffset: ${data.accelerometerYOffset}'),
      );
      expect(
        string,
        contains('accelerometerZOffset: ${data.accelerometerZOffset}'),
      );
      expect(string, contains('gyroscopeXOffset: ${data.gyroscopeXOffset}'));
      expect(string, contains('gyroscopeYOffset: ${data.gyroscopeYOffset}'));
      expect(string, contains('gyroscopeZOffset: ${data.gyroscopeZOffset}'));
      expect(
        string,
        contains('calibrationTimestamp: ${data.calibrationTimestamp}'),
      );
    });
  });
}
