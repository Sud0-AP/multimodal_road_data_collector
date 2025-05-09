import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:multimodal_road_data_collector/app/router.dart';
import 'package:multimodal_road_data_collector/core/providers/service_providers.dart';
import 'package:multimodal_road_data_collector/core/services/permission_service.dart';
import 'package:multimodal_road_data_collector/core/services/preferences_service.dart';
import 'package:multimodal_road_data_collector/features/onboarding/presentation/screens/onboarding_screen.dart';
import 'package:multimodal_road_data_collector/features/onboarding/presentation/state/onboarding_state.dart';

// Mock classes
class MockPermissionService implements PermissionService {
  bool shouldGrantPermissions;

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

// More comprehensive mock GoRouter for testing
class MockGoRouter implements GoRouter {
  final List<String> navigationHistory = [];

  @override
  void go(String location, {Object? extra}) {
    navigationHistory.add(location);
  }

  // Implement required methods with minimal functionality
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('OnboardingScreen', () {
    late MockPermissionService permissionService;
    late MockPreferencesService preferencesService;
    late MockGoRouter mockRouter;
    late ProviderContainer container;

    setUp(() {
      permissionService = MockPermissionService();
      preferencesService = MockPreferencesService();
      mockRouter = MockGoRouter();

      // Create a provider container for testing
      container = ProviderContainer(
        overrides: [
          // Override the permission service provider
          permissionServiceProvider.overrideWithValue(permissionService),

          // Override the preferences service provider with a synchronous value
          preferencesServiceProvider.overrideWith(
            (ref) async => preferencesService,
          ),

          // Override the router provider with our mock
          routerProvider.overrideWithValue(mockRouter),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    Widget buildOnboardingScreen() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: InheritedGoRouter(
            goRouter: mockRouter,
            child: const OnboardingScreen(),
          ),
        ),
      );
    }

    // Helper function to wait for async operations to complete
    Future<void> pumpAndWaitForAsyncOperations(WidgetTester tester) async {
      // First pump to build the widget
      await tester.pumpAndSettle();

      // Trigger a frame after a delay to allow microtask operations to complete
      await Future.delayed(Duration.zero);

      // Pump again to process the results of the microtasks
      await tester.pumpAndSettle();
    }

    testWidgets('navigates to home screen if onboarding is complete', (
      WidgetTester tester,
    ) async {
      // Set onboarding as complete in preferences
      await preferencesService.setBool(kIsOnboardingComplete, true);

      // Pre-initialize the onboarding notifier
      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.checkOnboardingStatus();

      // Build the app with a provider scope that will preserve the notifier
      await tester.pumpWidget(buildOnboardingScreen());

      // Pump a few times to process all frames and async operations
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify it attempted to navigate to home
      expect(mockRouter.navigationHistory, contains(AppRoutes.homePath));
    });

    testWidgets('displays onboarding UI if onboarding is not complete', (
      WidgetTester tester,
    ) async {
      // Ensure onboarding is not complete
      await preferencesService.setBool(kIsOnboardingComplete, false);

      // Pre-initialize the onboarding notifier
      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.checkOnboardingStatus();

      // Build the app
      await tester.pumpWidget(buildOnboardingScreen());

      // Pump a few times to process all frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Verify onboarding UI is shown (check for Next button)
      expect(find.text('Next'), findsOneWidget);
      expect(mockRouter.navigationHistory, isEmpty);
    });

    testWidgets('can navigate through onboarding pages', (
      WidgetTester tester,
    ) async {
      // Ensure onboarding is not complete
      await preferencesService.setBool(kIsOnboardingComplete, false);

      // Pre-initialize the onboarding notifier
      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.checkOnboardingStatus();

      // Build the app
      await tester.pumpWidget(buildOnboardingScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap 'Next' button three times to go through pages
      for (int i = 0; i < 3; i++) {
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();
      }

      // On the last page, "Next" should change to "Get Started"
      expect(find.text('Get Started'), findsOneWidget);

      // 'Skip' button should not be visible on the last page
      expect(find.text('Skip'), findsNothing);
    });

    testWidgets('can skip to permissions page', (WidgetTester tester) async {
      // Ensure onboarding is not complete
      await preferencesService.setBool(kIsOnboardingComplete, false);

      // Pre-initialize the onboarding notifier
      final notifier = container.read(onboardingNotifierProvider.notifier);
      await notifier.checkOnboardingStatus();

      // Build the app
      await tester.pumpWidget(buildOnboardingScreen());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pumpAndSettle();

      // Tap 'Skip' button to go to the last page
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Should be on the last page with "Get Started" button
      expect(find.text('Get Started'), findsOneWidget);
    });

    testWidgets(
      'completes onboarding and navigates home on final button press',
      (WidgetTester tester) async {
        // Ensure onboarding is not complete
        await preferencesService.setBool(kIsOnboardingComplete, false);

        // Pre-initialize the onboarding notifier
        final notifier = container.read(onboardingNotifierProvider.notifier);
        await notifier.checkOnboardingStatus();

        // Build the app
        await tester.pumpWidget(buildOnboardingScreen());
        await pumpAndWaitForAsyncOperations(tester);

        // Skip to the last page
        await tester.tap(find.text('Skip'));
        await tester.pumpAndSettle();

        // Click "Get Started"
        await tester.tap(find.text('Get Started'));
        await tester.pumpAndSettle();

        // Wait for the async operations to complete
        await pumpAndWaitForAsyncOperations(tester);

        // Verify onboarding was completed
        final isComplete = await preferencesService.getBool(
          kIsOnboardingComplete,
        );
        expect(isComplete, true);

        // Verify it navigated to home
        expect(mockRouter.navigationHistory, contains(AppRoutes.homePath));
      },
    );
  });
}
