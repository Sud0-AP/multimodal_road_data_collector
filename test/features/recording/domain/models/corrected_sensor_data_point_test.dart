import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/models/corrected_sensor_data_point.dart';

void main() {
  group('CorrectedSensorDataPoint', () {
    test('constructor creates an instance with correct properties', () {
      final dataPoint = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.1,
        accelY: 2.2,
        accelZ: 3.3,
        accelMagnitude: 4.1,
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
        isPothole: true,
        userFeedback: 'test feedback',
      );

      expect(dataPoint.timestampMs, equals(1000));
      expect(dataPoint.accelX, equals(1.1));
      expect(dataPoint.accelY, equals(2.2));
      expect(dataPoint.accelZ, equals(3.3));
      expect(dataPoint.accelMagnitude, equals(4.1));
      expect(dataPoint.gyroX, equals(0.1));
      expect(dataPoint.gyroY, equals(0.2));
      expect(dataPoint.gyroZ, equals(0.3));
      expect(dataPoint.isPothole, isTrue);
      expect(dataPoint.userFeedback, equals('test feedback'));
    });

    test('copyWith creates a copy with updated values', () {
      final original = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.1,
        accelY: 2.2,
        accelZ: 3.3,
        accelMagnitude: 4.1,
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
        isPothole: false,
        userFeedback: '',
      );

      final copy = original.copyWith(
        timestampMs: 2000,
        accelZ: 9.8,
        isPothole: true,
        userFeedback: 'updated feedback',
      );

      // Verify updated fields
      expect(copy.timestampMs, equals(2000));
      expect(copy.accelZ, equals(9.8));
      expect(copy.isPothole, isTrue);
      expect(copy.userFeedback, equals('updated feedback'));

      // Verify unchanged fields
      expect(copy.accelX, equals(original.accelX));
      expect(copy.accelY, equals(original.accelY));
      expect(copy.accelMagnitude, equals(original.accelMagnitude));
      expect(copy.gyroX, equals(original.gyroX));
      expect(copy.gyroY, equals(original.gyroY));
      expect(copy.gyroZ, equals(original.gyroZ));
    });

    test('fromProcessedData factory creates correct instance', () {
      final dataPoint = CorrectedSensorDataPoint.fromProcessedData(
        relativeTimestampMs: 5000,
        accelX: 1.0,
        accelY: 2.0,
        correctedAccelZ: 3.0,
        accelMagnitude: 3.741657, // approx sqrt(1^2 + 2^2 + 3^2)
        gyroX: 0.1,
        gyroY: 0.2,
        correctedGyroZ: 0.3,
        isPothole: true,
      );

      expect(dataPoint.timestampMs, equals(5000));
      expect(dataPoint.accelX, equals(1.0));
      expect(dataPoint.accelY, equals(2.0));
      expect(dataPoint.accelZ, equals(3.0));
      expect(dataPoint.accelMagnitude, equals(3.741657));
      expect(dataPoint.gyroX, equals(0.1));
      expect(dataPoint.gyroY, equals(0.2));
      expect(dataPoint.gyroZ, equals(0.3));
      expect(dataPoint.isPothole, isTrue);
      expect(dataPoint.userFeedback, isEmpty);
    });

    test('toCsvRow formats data correctly', () {
      final dataPoint = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.1,
        accelY: 2.2,
        accelZ: 3.3,
        accelMagnitude: 4.1,
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
        isPothole: true,
        userFeedback: 'feedback with, comma',
      );

      final csvRow = dataPoint.toCsvRow();

      // Verify CSV formatting
      final parts = csvRow.split(',');
      expect(parts.length, equals(10));
      expect(parts[0], equals('1000'));
      expect(parts[1], equals('1.1'));
      expect(parts[2], equals('2.2'));
      expect(parts[3], equals('3.3'));
      expect(parts[4], equals('4.1'));
      expect(parts[5], equals('0.1'));
      expect(parts[6], equals('0.2'));
      expect(parts[7], equals('0.3'));
      expect(parts[8], equals('1')); // true becomes 1

      // Testing with manual splitting to handle quoted parts correctly
      expect(csvRow.endsWith('"feedback with, comma"'), isTrue);
    });

    test('toCsvRow handles special CSV characters correctly', () {
      // Test with comma and quote in feedback
      final dataPoint1 = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.0,
        accelY: 2.0,
        accelZ: 3.0,
        accelMagnitude: 3.74,
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
        isPothole: false,
        userFeedback: 'has,comma',
      );

      final dataPoint2 = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.0,
        accelY: 2.0,
        accelZ: 3.0,
        accelMagnitude: 3.74,
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
        isPothole: false,
        userFeedback: 'has"quote',
      );

      final csvRow1 = dataPoint1.toCsvRow();
      final csvRow2 = dataPoint2.toCsvRow();

      // Check proper quoting of comma-containing fields
      expect(csvRow1.endsWith('"has,comma"'), isTrue);

      // Check proper escaping of quotes (double quotes become "")
      expect(csvRow2.endsWith('"has""quote"'), isTrue);
    });

    test('toString returns a readable string representation', () {
      final dataPoint = CorrectedSensorDataPoint(
        timestampMs: 1000,
        accelX: 1.1,
        accelY: 2.2,
        accelZ: 3.3,
        accelMagnitude: 4.1,
        gyroX: 0.1,
        gyroY: 0.2,
        gyroZ: 0.3,
        isPothole: true,
        userFeedback: 'test',
      );

      final str = dataPoint.toString();

      // Basic checks for string representation
      expect(str, contains('timestampMs: 1000'));
      expect(str, contains('accelX: 1.1'));
      expect(str, contains('accelY: 2.2'));
      expect(str, contains('accelZ: 3.3'));
      expect(str, contains('accelMagnitude: 4.1'));
      expect(str, contains('gyroX: 0.1'));
      expect(str, contains('gyroY: 0.2'));
      expect(str, contains('gyroZ: 0.3'));
      expect(str, contains('isPothole: true'));
      expect(str, contains('userFeedback: "test"'));
    });
  });
}
