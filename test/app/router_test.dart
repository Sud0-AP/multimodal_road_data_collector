import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multimodal_road_data_collector/app/router.dart';

void main() {
  group('Router Provider Tests', () {
    test('Router provider should return a GoRouter instance', () {
      final container = ProviderContainer();

      // Get the router instance from the provider
      final router = container.read(routerProvider);

      // Verify it's a GoRouter
      expect(router, isA<GoRouter>());
    });

    test('Router should have the correct routes configured', () {
      final container = ProviderContainer();
      final router = container.read(routerProvider);

      // Verify onboarding path is configured
      final hasOnboardingRoute = router
          .routeInformationParser
          .configuration
          .routes
          .any(
            (route) =>
                route is GoRoute && route.path == AppRoutes.onboardingPath,
          );

      expect(hasOnboardingRoute, true);

      // Verify home path is configured
      final hasHomeRoute = router.routeInformationParser.configuration.routes
          .any((route) => route is GoRoute && route.path == AppRoutes.homePath);

      expect(hasHomeRoute, true);
    });
  });
}
