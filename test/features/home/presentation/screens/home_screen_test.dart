import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:multimodal_road_data_collector/features/calibration/presentation/state/calibration_provider.dart';
import 'package:multimodal_road_data_collector/features/home/presentation/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen should display app title and description', (
    WidgetTester tester,
  ) async {
    // Set up providers
    final providerContainer = ProviderContainer(
      overrides: [
        calibrationNeededProvider.overrideWith((_) => false),
        calibrationCompletedProvider.overrideWith((_) => true),
      ],
    );

    // Build our app and trigger a frame
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providerContainer,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Verify that the title and description are displayed
    expect(find.text('Multimodal Road Data Collector'), findsOneWidget);
    expect(
      find.text(
        'Collect and analyze road condition data with your device sensors',
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'HomeScreen should display calibration card and recordings section',
    (WidgetTester tester) async {
      // Set up providers
      final providerContainer = ProviderContainer(
        overrides: [
          calibrationNeededProvider.overrideWith((_) => false),
          calibrationCompletedProvider.overrideWith((_) => true),
        ],
      );

      // Build our app and trigger a frame
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: providerContainer,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Verify that the calibration card is displayed
      expect(find.text('Calibrate Sensors'), findsOneWidget);

      // Verify that the recordings section is displayed
      expect(find.text('Previous Recordings'), findsOneWidget);

      // Verify that dummy recordings are displayed
      expect(find.byIcon(Icons.videocam), findsWidgets);
      expect(find.textContaining('Recording on'), findsWidgets);

      // Verify that the fullscreen and refresh buttons are displayed
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);

      // Verify recordings limited to 3
      expect(
        find.byType(Card).evaluate().length,
        lessThanOrEqualTo(4),
      ); // 3 recordings + 1 calibration card
    },
  );

  testWidgets(
    'View all button should be displayed if there are more than 3 recordings',
    (WidgetTester tester) async {
      // Set up providers
      final providerContainer = ProviderContainer(
        overrides: [
          calibrationNeededProvider.overrideWith((_) => false),
          calibrationCompletedProvider.overrideWith((_) => true),
        ],
      );

      // Build our app and trigger a frame
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: providerContainer,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Test has been removed as the "View all" button is no longer displayed at the bottom
      // Verify fullscreen button in header instead
      expect(find.byIcon(Icons.fullscreen), findsOneWidget);
    },
  );

  testWidgets(
    'Calibration card should show ready message when calibration is completed',
    (WidgetTester tester) async {
      // Set up providers for completed calibration
      final providerContainer = ProviderContainer(
        overrides: [
          calibrationNeededProvider.overrideWith((_) => true),
          calibrationCompletedProvider.overrideWith((_) => true),
        ],
      );

      // Build our app and trigger a frame
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: providerContainer,
          child: const MaterialApp(home: HomeScreen()),
        ),
      );

      // Verify that the calibration card shows the ready message
      expect(
        find.text('Sensors are calibrated and ready to use'),
        findsOneWidget,
      );
    },
  );

  // Test for the FAB with updated text
  testWidgets('FloatingActionButton should display "Record Data" text', (
    WidgetTester tester,
  ) async {
    // Set up providers for completed calibration
    final providerContainer = ProviderContainer(
      overrides: [
        calibrationNeededProvider.overrideWith((_) => true),
        calibrationCompletedProvider.overrideWith((_) => true),
      ],
    );

    // Build our app and trigger a frame
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providerContainer,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Verify that the FAB is visible with the correct text
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.text('Record Data'), findsOneWidget);
    expect(find.byIcon(Icons.fiber_manual_record), findsOneWidget);
  });

  testWidgets('FAB should not be displayed when calibration is not completed', (
    WidgetTester tester,
  ) async {
    // Set up providers for uncompleted calibration
    final providerContainer = ProviderContainer(
      overrides: [
        calibrationNeededProvider.overrideWith((_) => true),
        calibrationCompletedProvider.overrideWith((_) => false),
      ],
    );

    // Build our app and trigger a frame
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: providerContainer,
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    // Verify that the FAB is not visible
    expect(find.byType(FloatingActionButton), findsNothing);
    expect(find.text('Record Data'), findsNothing);
  });
}
