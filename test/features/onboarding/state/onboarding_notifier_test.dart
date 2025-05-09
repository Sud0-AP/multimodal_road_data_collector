import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_road_data_collector/core/providers/service_providers.dart';
import 'package:multimodal_road_data_collector/core/services/permission_service.dart';
import 'package:multimodal_road_data_collector/core/services/preferences_service.dart';
import 'package:multimodal_road_data_collector/features/onboarding/presentation/state/onboarding_state.dart';

// Mock implementations for testing
class MockPermissionService implements PermissionService {
  bool shouldGrantPermissions;
  bool didOpenSettings = false;

  MockPermissionService({this.shouldGrantPermissions = true});

  @override
  Future<bool> requestCameraPermission() async {
    return shouldGrantPermissions;
  }

  @override
  Future<bool> requestStoragePermission() async {
    return shouldGrantPermissions;
  }

  @override
  Future<bool> requestSensorPermission() async {
    return shouldGrantPermissions;
  }

  @override
  Future<bool> openAppSettings() async {
    didOpenSettings = true;
    return true;
  }

  @override
  Future<bool> isCameraPermissionGranted() async {
    return shouldGrantPermissions;
  }

  @override
  Future<bool> isStoragePermissionGranted() async {
    return shouldGrantPermissions;
  }

  @override
  Future<bool> isSensorPermissionGranted() async {
    return shouldGrantPermissions;
  }
}

class MockPreferencesService implements PreferencesService {
  final Map<String, dynamic> storage = {};

  @override
  Future<bool> setBool(String key, bool value) async {
    storage[key] = value;
    return true;
  }

  @override
  Future<bool?> getBool(String key) async {
    return storage[key] as bool?;
  }

  @override
  Future<bool> clear() async {
    storage.clear();
    return true;
  }

  @override
  Future<bool> containsKey(String key) async {
    return storage.containsKey(key);
  }

  @override
  Future<double?> getDouble(String key) async {
    return storage[key] as double?;
  }

  @override
  Future<int?> getInt(String key) async {
    return storage[key] as int?;
  }

  @override
  Future<String?> getString(String key) async {
    return storage[key] as String?;
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    return storage[key] as List<String>?;
  }

  @override
  Future<bool> remove(String key) async {
    storage.remove(key);
    return true;
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    storage[key] = value;
    return true;
  }

  @override
  Future<bool> setInt(String key, int value) async {
    storage[key] = value;
    return true;
  }

  @override
  Future<bool> setString(String key, String value) async {
    storage[key] = value;
    return true;
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    storage[key] = value;
    return true;
  }
}

void main() {
  group('OnboardingNotifier', () {
    late MockPermissionService permissionService;
    late MockPreferencesService preferencesService;
    late OnboardingNotifier notifier;

    setUp(() {
      permissionService = MockPermissionService();
      preferencesService = MockPreferencesService();
      notifier = OnboardingNotifier(permissionService, preferencesService);
    });

    test('initial state has correct values', () {
      expect(notifier.state.currentPage, 0);
      expect(notifier.state.isLoading, false);
      expect(notifier.state.isComplete, false);
      expect(
        notifier.state.permissionStatuses['camera'],
        PermissionStatus.initial,
      );
      expect(
        notifier.state.permissionStatuses['storage'],
        PermissionStatus.initial,
      );
      expect(
        notifier.state.permissionStatuses['sensor'],
        PermissionStatus.initial,
      );
    });

    test('setCurrentPage updates current page', () {
      notifier.setCurrentPage(2);
      expect(notifier.state.currentPage, 2);
    });

    test('checkOnboardingStatus reads from preferences service', () async {
      // Initially not completed
      await notifier.checkOnboardingStatus();
      expect(notifier.state.isComplete, false);

      // Set as completed
      await preferencesService.setBool(kIsOnboardingComplete, true);
      await notifier.checkOnboardingStatus();
      expect(notifier.state.isComplete, true);
    });

    test('completeOnboarding sets flag in preferences', () async {
      expect(notifier.state.isComplete, false);
      await notifier.completeOnboarding();
      expect(notifier.state.isComplete, true);

      // Verify it was stored in preferences
      final storedValue = await preferencesService.getBool(
        kIsOnboardingComplete,
      );
      expect(storedValue, true);
    });

    test(
      'requestCameraPermission updates permission status when granted',
      () async {
        permissionService.shouldGrantPermissions = true;
        await notifier.requestCameraPermission();
        expect(
          notifier.state.permissionStatuses['camera'],
          PermissionStatus.granted,
        );
      },
    );

    test(
      'requestCameraPermission updates permission status when denied',
      () async {
        permissionService.shouldGrantPermissions = false;
        await notifier.requestCameraPermission();
        expect(
          notifier.state.permissionStatuses['camera'],
          PermissionStatus.denied,
        );
      },
    );

    test('requestStoragePermission updates permission status', () async {
      permissionService.shouldGrantPermissions = true;
      await notifier.requestStoragePermission();
      expect(
        notifier.state.permissionStatuses['storage'],
        PermissionStatus.granted,
      );
    });

    test('requestSensorPermission updates permission status', () async {
      permissionService.shouldGrantPermissions = true;
      await notifier.requestSensorPermission();
      expect(
        notifier.state.permissionStatuses['sensor'],
        PermissionStatus.granted,
      );
    });

    test('requestAllPermissions requests all permissions', () async {
      permissionService.shouldGrantPermissions = true;
      await notifier.requestAllPermissions();

      expect(
        notifier.state.permissionStatuses['camera'],
        PermissionStatus.granted,
      );
      expect(
        notifier.state.permissionStatuses['storage'],
        PermissionStatus.granted,
      );
      expect(
        notifier.state.permissionStatuses['sensor'],
        PermissionStatus.granted,
      );
    });

    test('openAppSettings calls service method', () async {
      await notifier.openAppSettings();
      expect(permissionService.didOpenSettings, true);
    });

    test('areAllPermissionsGranted returns correct value', () async {
      // Initially none are granted
      expect(notifier.areAllPermissionsGranted, false);

      // Grant all permissions
      permissionService.shouldGrantPermissions = true;
      await notifier.requestAllPermissions();
      expect(notifier.areAllPermissionsGranted, true);

      // Grant only some permissions
      notifier = OnboardingNotifier(permissionService, preferencesService);
      await notifier.requestCameraPermission();
      await notifier.requestStoragePermission();
      expect(notifier.areAllPermissionsGranted, false);
    });

    test('isAnyPermissionPermanentlyDenied initially returns false', () {
      expect(notifier.isAnyPermissionPermanentlyDenied, false);
    });
  });
}
