import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/providers/service_providers.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';
import '../features/calibration/presentation/screens/initial_calibration_screen.dart';
import '../features/calibration/presentation/state/calibration_provider.dart';

/// Routes names used throughout the app
class AppRoutes {
  static const String onboarding = 'onboarding';
  static const String home = 'home';
  static const String calibration = 'calibration';

  // Path names
  static const String onboardingPath = '/onboarding';
  static const String homePath = '/';
  static const String calibrationPath = '/calibration';
}

/// Provider for the initial onboarding status
final initialOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  // Get shared preferences directly
  final prefs = await SharedPreferences.getInstance();
  // Check if onboarding is completed
  return prefs.getBool(kIsOnboardingComplete) ?? false;
});

/// Provider for the app router
final routerProvider = Provider<GoRouter>((ref) {
  // Create a router notifier to handle rebuilds when auth state changes
  final routerNotifier = RouterNotifier(ref);

  return GoRouter(
    // We'll redirect in the routes instead of setting initialLocation
    // to ensure we handle the async nature of checking onboarding status
    initialLocation: AppRoutes.onboardingPath,
    debugLogDiagnostics: true,
    refreshListenable: routerNotifier,
    redirect: routerNotifier._redirectLogic,
    routes: [
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.home,
        builder: (context, state) {
          // Placeholder home screen with a button to navigate to calibration screen
          return Scaffold(
            appBar: AppBar(title: const Text('Road Data Collector')),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Home Screen - Coming Soon',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.pushNamed(AppRoutes.calibration),
                    child: const Text('Calibrate Sensors'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboardingPath,
        name: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.calibrationPath,
        name: AppRoutes.calibration,
        builder: (context, state) => const InitialCalibrationScreen(),
      ),
    ],
  );
});

/// Router notifier to handle changes in auth state
class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    // Listen for changes in the onboarding completed state
    _ref.listen<AsyncValue<bool>>(
      initialOnboardingCompletedProvider,
      (_, __) => notifyListeners(),
    );

    // Listen for changes in calibration completion state
    _ref.listen<bool>(
      calibrationCompletedProvider,
      (_, __) => notifyListeners(),
    );
  }

  String? _redirectLogic(BuildContext context, GoRouterState state) {
    final onboardingCompletedAsync = _ref.read(
      initialOnboardingCompletedProvider,
    );

    // If still loading, don't redirect yet
    if (onboardingCompletedAsync is AsyncLoading) {
      return null;
    }

    // Get onboarding status
    final onboardingCompleted = onboardingCompletedAsync.value ?? false;

    // Current location
    final currentLocation = state.matchedLocation;

    // Check for calibration status
    final calibrationNeeded = _ref.read(calibrationNeededProvider);
    final calibrationCompleted = _ref.read(calibrationCompletedProvider);

    // First handle onboarding redirection
    if (onboardingCompleted && currentLocation == AppRoutes.onboardingPath) {
      // If onboarding is complete, redirect to calibration if needed
      if (calibrationNeeded && !calibrationCompleted) {
        return AppRoutes.calibrationPath;
      }
      // Otherwise, go to home
      return AppRoutes.homePath;
    }

    // For all other cases, if we're on the home screen and calibration is needed but not completed,
    // redirect to the calibration screen (ensures calibration on every app launch)
    if (onboardingCompleted &&
        currentLocation == AppRoutes.homePath &&
        calibrationNeeded &&
        !calibrationCompleted) {
      return AppRoutes.calibrationPath;
    }

    // No redirect needed
    return null;
  }
}
