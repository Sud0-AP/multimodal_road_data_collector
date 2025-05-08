import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/onboarding/presentation/screens/onboarding_screen.dart';

/// Routes names used throughout the app
class AppRoutes {
  static const String onboarding = 'onboarding';
  static const String home = 'home';
  
  // Path names
  static const String onboardingPath = '/onboarding';
  static const String homePath = '/';
}

/// Provider for the app router
final routerProvider = Provider<GoRouter>((ref) {
  // In a real application, you'd inject services and check if onboarding is completed
  // For now, we'll always show the onboarding screen
  final bool onboardingCompleted = false;
  
  return GoRouter(
    initialLocation: onboardingCompleted ? AppRoutes.homePath : AppRoutes.onboardingPath,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.home,
        builder: (context, state) {
          // For now, we'll use a placeholder home screen
          return const Scaffold(
            body: Center(
              child: Text('Home Screen - Coming Soon'),
            ),
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