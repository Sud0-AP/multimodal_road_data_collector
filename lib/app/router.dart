import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/providers/service_providers.dart';
import '../features/onboarding/presentation/screens/onboarding_screen.dart';

/// Routes names used throughout the app
class AppRoutes {
  static const String onboarding = 'onboarding';
  static const String home = 'home';

  // Path names
  static const String onboardingPath = '/onboarding';
  static const String homePath = '/';
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
          // For now, we'll use a placeholder home screen
          return const Scaffold(
            body: Center(child: Text('Home Screen - Coming Soon')),
          );
        },
      ),
      GoRoute(
        path: AppRoutes.onboardingPath,
        name: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
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

    // Redirect to Home if onboarding is completed and we're on the onboarding page
    if (onboardingCompleted && currentLocation == AppRoutes.onboardingPath) {
      return AppRoutes.homePath;
    }

    // No redirect needed
    return null;
  }
}
