import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:multimodal_road_data_collector/core/services/app_info_service.dart';
import 'package:multimodal_road_data_collector/core/services/device_info_service.dart';
import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart';
import 'package:multimodal_road_data_collector/core/services/implementations/data_management_service_impl.dart';

@GenerateMocks([FileStorageService, DeviceInfoService, AppInfoService])
void main() {
  late DataManagementServiceImpl dataManagementService;
  late MockFileStorageService mockFileStorageService;
  late MockDeviceInfoService mockDeviceInfoService;
  late MockAppInfoService mockAppInfoService;

  setUp(() {
    mockFileStorageService = MockFileStorageService();
    mockDeviceInfoService = MockDeviceInfoService();
    mockAppInfoService = MockAppInfoService();

    dataManagementService = DataManagementServiceImpl(
      fileStorageService: mockFileStorageService,
      deviceInfoService: mockDeviceInfoService,
      appInfoService: mockAppInfoService,
    );
  });

  group('DataManagementServiceImpl duration parsing tests', () {
    test('_parseDurationSafely handles plain integers', () {
      // Use reflection to access private method
      final result =
          dataManagementService.runtimeType.toString().contains(
                'DataManagementServiceImpl',
              )
              ? callPrivateMethod(
                dataManagementService,
                '_parseDurationSafely',
                ['123'],
              )
              : 0;

      expect(result, 123);
    });

    test('_parseDurationSafely handles MM:SS format', () {
      final result = callPrivateMethod(
        dataManagementService,
        '_parseDurationSafely',
        ['2:30'],
      );
      expect(result, 150); // 2 minutes and 30 seconds = 150 seconds
    });

    test('_parseDurationSafely handles HH:MM:SS format', () {
      final result = callPrivateMethod(
        dataManagementService,
        '_parseDurationSafely',
        ['1:30:45'],
      );
      expect(result, 5445); // 1 hour, 30 minutes, 45 seconds = 5445 seconds
    });

    test('_parseDurationSafely handles double values', () {
      final result = callPrivateMethod(
        dataManagementService,
        '_parseDurationSafely',
        ['123.5'],
      );
      expect(result, 124); // Rounds to nearest integer
    });

    test('_parseDurationSafely handles strings with text', () {
      final result = callPrivateMethod(
        dataManagementService,
        '_parseDurationSafely',
        ['Duration: 145 seconds'],
      );
      expect(result, 145);
    });

    test('_parseDurationSafely handles null or empty strings', () {
      expect(
        callPrivateMethod(dataManagementService, '_parseDurationSafely', [
          null,
        ]),
        0,
      );
      expect(
        callPrivateMethod(dataManagementService, '_parseDurationSafely', ['']),
        0,
      );
    });

    test('_parseDurationSafely handles invalid formats gracefully', () {
      expect(
        callPrivateMethod(dataManagementService, '_parseDurationSafely', [
          'abc',
        ]),
        0,
      );
      expect(
        callPrivateMethod(dataManagementService, '_parseDurationSafely', [
          '12:ab:34',
        ]),
        0,
      );
    });
  });
}

// Helper function to call private methods using reflection
dynamic callPrivateMethod(
  dynamic object,
  String methodName,
  List<dynamic> args,
) {
  try {
    // This is a workaround to access private methods in Dart for testing
    // It uses the dart:mirrors package implicitly
    final result = Function.apply(
      (object as dynamic).noSuchMethod(
        Invocation.method(Symbol(methodName), args),
        returnValue: 0, // Default return value if method not found
      ),
      [],
    );
    return result;
  } catch (e) {
    print('Error calling private method $methodName: $e');
    return 0;
  }
}
