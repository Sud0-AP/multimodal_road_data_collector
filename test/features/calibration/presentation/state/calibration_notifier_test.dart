import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:multimodal_road_data_collector/core/services/sensor_service.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/models/initial_calibration_data.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/repositories/calibration_repository.dart';
import 'package:multimodal_road_data_collector/features/calibration/presentation/state/calibration_state.dart';

@GenerateMocks([CalibrationRepository, SensorService])
import 'calibration_notifier_test.mocks.dart';

void main() {
  late MockCalibrationRepository mockRepository;
  late MockSensorService mockSensorService;
  late CalibrationNotifier calibrationNotifier;
  late StreamController<SensorData> sensorStreamController;

  setUp(() {
    mockRepository = MockCalibrationRepository();
    mockSensorService = MockSensorService();
    sensorStreamController = StreamController<SensorData>.broadcast();

    // Configure mock repository
    when(
      mockRepository.hasInitialCalibrationData(),
    ).thenAnswer((_) async => false);
    when(mockRepository.clearCalibrationData()).thenAnswer((_) async => true);

    // Configure mock sensor service
    when(mockSensorService.initialize()).thenAnswer((_) async {});
    when(
      mockSensorService.startSensorDataCollection(),
    ).thenAnswer((_) async {});
    when(mockSensorService.stopSensorDataCollection()).thenAnswer((_) async {});
    when(mockSensorService.isSensorDataCollectionActive()).thenReturn(true);
    when(
      mockSensorService.getSensorDataStream(),
    ).thenAnswer((_) => sensorStreamController.stream);

    // Create the notifier with mocks
    calibrationNotifier = CalibrationNotifier(
      calibrationRepository: mockRepository,
      sensorService: mockSensorService,
    );
  });

  tearDown(() {
    sensorStreamController.close();
  });

  test('Initial state should have unknown orientation', () {
    expect(
      calibrationNotifier.state.deviceOrientation,
      equals(DeviceOrientation.unknown),
    );
  });

  // Helper function to test orientation detection
  Future<void> testOrientationDetection({
    required List<SensorData> sensorDataPoints,
    required DeviceOrientation expectedOrientation,
    String testDescription = '',
  }) async {
    // Configure mock repository to accept save calls
    when(
      mockRepository.saveInitialCalibrationData(any),
    ).thenAnswer((_) async => true);

    // Create a completer to track when calibration is done
    final completer = Completer<void>();

    // Start the calibration process
    final calibrationFuture = calibrationNotifier.startCalibration();

    // Wait a bit to ensure startCalibration has started
    await Future.delayed(const Duration(milliseconds: 50));

    // Emit the sensor data in small batches
    for (final dataPoint in sensorDataPoints) {
      sensorStreamController.add(dataPoint);
      // Small delay between data points to simulate real sensor readings
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // Wait with timeout for the calibration to complete
    await Future.any([
      calibrationFuture.then((_) => completer.complete()),
      Future.delayed(const Duration(seconds: 5)).then((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      }),
    ]);

    // Assert the orientation was detected correctly
    expect(
      calibrationNotifier.state.deviceOrientation,
      equals(expectedOrientation),
      reason: testDescription,
    );
  }

  group('Orientation Detection', () {
    test(
      'should detect flat orientation when Z axis has dominant gravity',
      () async {
        final testData = List.generate(
          20,
          (i) => SensorData(
            accelerometerX: 0.0, // Little to no gravity in X
            accelerometerY: 0.0, // Little to no gravity in Y
            accelerometerZ: 9.81, // Full gravity in Z (screen up)
            gyroscopeX: 0.0,
            gyroscopeY: 0.0,
            gyroscopeZ: 0.0,
            timestamp: DateTime.now().millisecondsSinceEpoch + i,
          ),
        );

        await testOrientationDetection(
          sensorDataPoints: testData,
          expectedOrientation: DeviceOrientation.flat,
          testDescription:
              'Device lying flat with screen up should be detected as flat orientation',
        );
      },
    );

    test(
      'should detect portrait orientation when Y axis has dominant gravity',
      () async {
        final testData = List.generate(
          20,
          (i) => SensorData(
            accelerometerX: 0.0, // Little to no gravity in X
            accelerometerY:
                -9.81, // Gravity in negative Y (device upright, top away from ground)
            accelerometerZ: 0.0, // Little to no gravity in Z
            gyroscopeX: 0.0,
            gyroscopeY: 0.0,
            gyroscopeZ: 0.0,
            timestamp: DateTime.now().millisecondsSinceEpoch + i,
          ),
        );

        await testOrientationDetection(
          sensorDataPoints: testData,
          expectedOrientation: DeviceOrientation.portrait,
          testDescription:
              'Device in portrait mode should be detected as portrait orientation',
        );
      },
    );

    test(
      'should detect landscape right orientation when X axis has positive dominant gravity',
      () async {
        final testData = List.generate(
          20,
          (i) => SensorData(
            accelerometerX: 9.81, // Gravity in positive X (right side down)
            accelerometerY: 0.0, // Little to no gravity in Y
            accelerometerZ: 0.0, // Little to no gravity in Z
            gyroscopeX: 0.0,
            gyroscopeY: 0.0,
            gyroscopeZ: 0.0,
            timestamp: DateTime.now().millisecondsSinceEpoch + i,
          ),
        );

        await testOrientationDetection(
          sensorDataPoints: testData,
          expectedOrientation: DeviceOrientation.landscapeRight,
          testDescription:
              'Device rotated right should be detected as landscape right orientation',
        );
      },
    );

    test(
      'should detect landscape left orientation when X axis has negative dominant gravity',
      () async {
        final testData = List.generate(
          20,
          (i) => SensorData(
            accelerometerX: -9.81, // Gravity in negative X (left side down)
            accelerometerY: 0.0, // Little to no gravity in Y
            accelerometerZ: 0.0, // Little to no gravity in Z
            gyroscopeX: 0.0,
            gyroscopeY: 0.0,
            gyroscopeZ: 0.0,
            timestamp: DateTime.now().millisecondsSinceEpoch + i,
          ),
        );

        await testOrientationDetection(
          sensorDataPoints: testData,
          expectedOrientation: DeviceOrientation.landscapeLeft,
          testDescription:
              'Device rotated left should be detected as landscape left orientation',
        );
      },
    );

    test('should detect unknown orientation when device is moving', () async {
      final testData = List.generate(
        20,
        (i) => SensorData(
          accelerometerX: 5.0, // Significant acceleration in X
          accelerometerY: 8.0, // Significant acceleration in Y
          accelerometerZ: 3.0, // Some acceleration in Z
          gyroscopeX: 0.5, // Some rotation
          gyroscopeY: 0.5, // Some rotation
          gyroscopeZ: 0.5, // Some rotation
          timestamp: DateTime.now().millisecondsSinceEpoch + i,
        ),
      );

      // For this test, we expect unknown orientation due to movement
      // So we'll use a direct approach

      // Configure mock repository to accept save calls
      when(
        mockRepository.saveInitialCalibrationData(any),
      ).thenAnswer((_) async => true);

      // Start calibration
      final calibrationFuture = calibrationNotifier.startCalibration();

      // Wait a bit to ensure startCalibration has started
      await Future.delayed(const Duration(milliseconds: 50));

      // Add the test data
      for (final dataPoint in testData) {
        sensorStreamController.add(dataPoint);
        // Small delay between data points
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Wait for calibration to complete
      await calibrationFuture;

      // In a real scenario with movement, the magnitude would be significantly different from g
      // so we expect unknown orientation to be detected
      expect(
        calibrationNotifier.state.deviceOrientation,
        equals(DeviceOrientation.unknown),
      );
    });
  });

  test('should clean up resources when calibration is cancelled', () async {
    // Create a completer to track when calibration starts
    final completer = Completer<void>();

    // Schedule cancellation after a short delay
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!completer.isCompleted) {
        completer.complete();
        calibrationNotifier.cancelCalibration();
      }
    });

    // Configure repository
    when(
      mockRepository.saveInitialCalibrationData(any),
    ).thenAnswer((_) async => true);

    // Start calibration
    final calibrationFuture = calibrationNotifier.startCalibration();

    // Wait for the scheduled cancellation
    await completer.future;

    // Wait for calibration to finish (should be cancelled)
    await calibrationFuture;

    // Verify that sensor service resources were cleaned up
    verify(mockSensorService.stopSensorDataCollection()).called(greaterThan(0));
    expect(calibrationNotifier.state.isCalibrating, isFalse);
  });

  test('should clean up resources when calibration completes', () async {
    // Generate flat orientation data
    final testData = List.generate(
      20,
      (i) => SensorData(
        accelerometerX: 0.0,
        accelerometerY: 0.0,
        accelerometerZ: 9.81,
        gyroscopeX: 0.0,
        gyroscopeY: 0.0,
        gyroscopeZ: 0.0,
        timestamp: DateTime.now().millisecondsSinceEpoch + i,
      ),
    );

    // Configure repository to accept saves
    when(
      mockRepository.saveInitialCalibrationData(any),
    ).thenAnswer((_) async => true);

    // Start calibration
    final calibrationFuture = calibrationNotifier.startCalibration();

    // Wait a bit to ensure startCalibration has started
    await Future.delayed(const Duration(milliseconds: 50));

    // Add the test data
    for (final dataPoint in testData) {
      sensorStreamController.add(dataPoint);
      // Small delay between data points
      await Future.delayed(const Duration(milliseconds: 10));
    }

    // Wait for calibration to complete
    await calibrationFuture;

    // Verify that sensor service resources were cleaned up
    verify(mockSensorService.stopSensorDataCollection()).called(1);
    expect(calibrationNotifier.state.isCalibrating, isFalse);
    expect(calibrationNotifier.state.isCalibrationComplete, isTrue);
  });

  group('Offset Calibration and Movement Detection', () {
    // Helper function to simulate a complete calibration sequence with specificed sensor data
    Future<void> simulateFullCalibration({
      required List<SensorData> initialOrientationData,
      required List<SensorData> offsetCalibrationData,
      required DeviceOrientation expectedOrientation,
      required bool expectMovementDetection,
      required bool expectSuccess,
    }) async {
      // Configure repository
      when(
        mockRepository.saveInitialCalibrationData(any),
      ).thenAnswer((_) async => true);

      // Start calibration
      final calibrationFuture = calibrationNotifier.startCalibration();

      // Wait a bit to ensure startCalibration has started
      await Future.delayed(const Duration(milliseconds: 50));

      // First phase: Orientation detection
      for (final dataPoint in initialOrientationData) {
        sensorStreamController.add(dataPoint);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Wait a bit for orientation detection to complete
      await Future.delayed(const Duration(milliseconds: 50));
      expect(
        calibrationNotifier.state.deviceOrientation,
        equals(expectedOrientation),
      );

      // Second phase: Offset calibration
      for (final dataPoint in offsetCalibrationData) {
        sensorStreamController.add(dataPoint);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Wait for calibration to complete with a safe timeout
      try {
        await calibrationFuture.timeout(const Duration(seconds: 5));
      } catch (e) {
        fail('Calibration timed out: $e');
      }

      // Verify expected outcomes
      expect(
        calibrationNotifier.state.movementDetected,
        equals(expectMovementDetection),
      );
      expect(
        calibrationNotifier.state.isCalibrationComplete,
        equals(expectSuccess),
      );
    }

    test('should calculate correct offsets for flat orientation', () async {
      // Generate stable flat orientation data for both phases
      final orientationData = List.generate(
        20,
        (i) => SensorData(
          accelerometerX: 0.0,
          accelerometerY: 0.0,
          accelerometerZ: 9.81, // Full gravity in Z (screen up)
          gyroscopeX: 0.0,
          gyroscopeY: 0.0,
          gyroscopeZ: 0.0,
          timestamp: DateTime.now().millisecondsSinceEpoch + i,
        ),
      );

      // For offset calibration, add some slight sensor bias
      final offsetData = List.generate(
        150, // 15 seconds worth at 10ms intervals
        (i) => SensorData(
          accelerometerX: 0.02, // Small X bias
          accelerometerY: -0.03, // Small Y bias
          accelerometerZ: 9.75, // Slightly less than g due to sensor error
          gyroscopeX: 0.001, // Small gyro bias
          gyroscopeY: -0.002, // Small gyro bias
          gyroscopeZ: 0.003, // Small gyro bias
          timestamp: DateTime.now().millisecondsSinceEpoch + i * 10,
        ),
      );

      // Configure the repository to capture saved data
      InitialCalibrationData? capturedData;
      when(mockRepository.saveInitialCalibrationData(any)).thenAnswer((
        invocation,
      ) {
        capturedData =
            invocation.positionalArguments[0] as InitialCalibrationData;
        return Future.value(true);
      });

      // Start calibration
      final calibrationFuture = calibrationNotifier.startCalibration();

      // Wait a bit to ensure startCalibration has started
      await Future.delayed(const Duration(milliseconds: 50));

      // First phase: Orientation detection
      for (final dataPoint in orientationData) {
        sensorStreamController.add(dataPoint);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Wait a bit for orientation detection to complete
      await Future.delayed(const Duration(milliseconds: 100));

      // Second phase: Offset calibration
      for (final dataPoint in offsetData) {
        sensorStreamController.add(dataPoint);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Wait for calibration to complete
      await calibrationFuture;

      // Verify calculated offsets
      expect(capturedData, isNotNull);
      expect(capturedData!.deviceOrientation, equals(DeviceOrientation.flat));

      // Accelerometer offsets (adjusted for gravity in flat position)
      expect(capturedData!.accelerometerXOffset, equals(0.02));
      expect(capturedData!.accelerometerYOffset, equals(-0.03));
      expect(
        capturedData!.accelerometerZOffset,
        closeTo(9.75 - 9.81, 0.1),
      ); // Z offset should be ~-0.06

      // Gyroscope offsets (raw averages)
      expect(capturedData!.gyroscopeXOffset, equals(0.001));
      expect(capturedData!.gyroscopeYOffset, equals(-0.002));
      expect(capturedData!.gyroscopeZOffset, equals(0.003));

      // State should be properly updated
      expect(calibrationNotifier.state.isCalibrationComplete, isTrue);
      expect(calibrationNotifier.state.movementDetected, isFalse);
    });

    test('should detect movement during offset calibration', () async {
      // Generate stable flat orientation data for orientation phase
      final orientationData = List.generate(
        20,
        (i) => SensorData(
          accelerometerX: 0.0,
          accelerometerY: 0.0,
          accelerometerZ: 9.81,
          gyroscopeX: 0.0,
          gyroscopeY: 0.0,
          gyroscopeZ: 0.0,
          timestamp: DateTime.now().millisecondsSinceEpoch + i,
        ),
      );

      // Start with stable data
      final stableData = List.generate(
        50,
        (i) => SensorData(
          accelerometerX: 0.0,
          accelerometerY: 0.0,
          accelerometerZ: 9.81,
          gyroscopeX: 0.0,
          gyroscopeY: 0.0,
          gyroscopeZ: 0.0,
          timestamp: DateTime.now().millisecondsSinceEpoch + i * 10,
        ),
      );

      // Then introduce significant movement
      final movementData = List.generate(
        20,
        (i) => SensorData(
          accelerometerX:
              2.0 *
              (i % 2 == 0 ? 1 : -1), // Oscillating values to simulate shaking
          accelerometerY: 1.5 * (i % 3 == 0 ? 1 : -1),
          accelerometerZ: 9.81 + (1.0 * (i % 2 == 0 ? 1 : -1)),
          gyroscopeX: 0.5 * (i % 2 == 0 ? 1 : -1),
          gyroscopeY: 0.5 * (i % 3 == 0 ? 1 : -1),
          gyroscopeZ: 0.5 * (i % 4 == 0 ? 1 : -1),
          timestamp: DateTime.now().millisecondsSinceEpoch + 500 + i * 10,
        ),
      );

      // Then back to stable data
      final finalStableData = List.generate(
        50,
        (i) => SensorData(
          accelerometerX: 0.0,
          accelerometerY: 0.0,
          accelerometerZ: 9.81,
          gyroscopeX: 0.0,
          gyroscopeY: 0.0,
          gyroscopeZ: 0.0,
          timestamp: DateTime.now().millisecondsSinceEpoch + 700 + i * 10,
        ),
      );

      // Combine all data for the offset calibration phase
      final offsetData = [...stableData, ...movementData, ...finalStableData];

      // Start calibration
      final calibrationFuture = calibrationNotifier.startCalibration();

      // Wait a bit to ensure startCalibration has started
      await Future.delayed(const Duration(milliseconds: 50));

      // First phase: Orientation detection
      for (final dataPoint in orientationData) {
        sensorStreamController.add(dataPoint);
        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Wait a bit for orientation detection to complete
      await Future.delayed(const Duration(milliseconds: 100));

      bool movementWasDetected = false;

      // Second phase: Offset calibration with movement
      for (final dataPoint in offsetData) {
        sensorStreamController.add(dataPoint);

        // Check if movement is detected during data emission
        if (calibrationNotifier.state.movementDetected) {
          movementWasDetected = true;
        }

        await Future.delayed(const Duration(milliseconds: 10));
      }

      // Wait for calibration to complete
      await calibrationFuture;

      // Movement should have been detected during the process
      expect(movementWasDetected, isTrue);

      // Calibration should have failed due to movement
      expect(calibrationNotifier.state.isCalibrationComplete, isFalse);
      expect(
        calibrationNotifier.state.statusMessage,
        contains('Excessive movement detected'),
      );
    });

    test(
      'should use correct gravity compensation based on orientation',
      () async {
        // Test with portrait orientation
        final portraitOrientationData = List.generate(
          20,
          (i) => SensorData(
            accelerometerX: 0.0,
            accelerometerY: -9.81, // Gravity in negative Y (portrait)
            accelerometerZ: 0.0,
            gyroscopeX: 0.0,
            gyroscopeY: 0.0,
            gyroscopeZ: 0.0,
            timestamp: DateTime.now().millisecondsSinceEpoch + i,
          ),
        );

        // Offset data for portrait mode with small biases
        final portraitOffsetData = List.generate(
          150,
          (i) => SensorData(
            accelerometerX: 0.01,
            accelerometerY: -9.81 + 0.05, // -9.76, slightly off from ideal
            accelerometerZ: 0.02,
            gyroscopeX: 0.001,
            gyroscopeY: 0.002,
            gyroscopeZ: 0.003,
            timestamp: DateTime.now().millisecondsSinceEpoch + i * 10,
          ),
        );

        // Configure the repository to capture saved data
        InitialCalibrationData? capturedData;
        when(mockRepository.saveInitialCalibrationData(any)).thenAnswer((
          invocation,
        ) {
          capturedData =
              invocation.positionalArguments[0] as InitialCalibrationData;
          return Future.value(true);
        });

        // Start calibration
        final calibrationFuture = calibrationNotifier.startCalibration();

        // Provide orientation data
        for (final dataPoint in portraitOrientationData) {
          sensorStreamController.add(dataPoint);
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Wait for orientation detection
        await Future.delayed(const Duration(milliseconds: 100));

        // Provide offset calibration data
        for (final dataPoint in portraitOffsetData) {
          sensorStreamController.add(dataPoint);
          await Future.delayed(const Duration(milliseconds: 10));
        }

        // Wait for calibration to complete
        await calibrationFuture;

        // Verify the offsets were calculated with correct gravity compensation
        expect(capturedData, isNotNull);
        expect(
          capturedData!.deviceOrientation,
          equals(DeviceOrientation.portrait),
        );

        // For portrait, Y should be compensated by adding gravity
        expect(capturedData!.accelerometerXOffset, equals(0.01));
        expect(
          capturedData!.accelerometerYOffset,
          closeTo(-9.76 + 9.81, 0.1),
        ); // Should be ~0.05
        expect(capturedData!.accelerometerZOffset, equals(0.02));

        // Verify state is updated correctly
        expect(calibrationNotifier.state.isCalibrationComplete, isTrue);
      },
    );
  });
}
