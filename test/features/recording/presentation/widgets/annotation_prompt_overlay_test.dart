import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_road_data_collector/features/recording/presentation/widgets/annotation_prompt_overlay.dart';

void main() {
  group('AnnotationPromptWidget', () {
    testWidgets('should render correctly with all elements', (
      WidgetTester tester,
    ) async {
      // Callback to capture responses
      String? capturedResponse;

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnotationPromptWidget(
              displayDuration: const Duration(seconds: 10),
              onResponse: (response) {
                capturedResponse = response;
              },
            ),
          ),
        ),
      );

      // Verify widget elements
      expect(find.text('Bump Detected!'), findsOneWidget);
      expect(find.text('Was this a pothole?'), findsOneWidget);
      expect(find.text('Please classify the road anomaly:'), findsOneWidget);
      expect(find.text('Yes, Pothole'), findsOneWidget);
      expect(find.text('No, Not Pothole'), findsOneWidget);
      expect(find.text('Dismissing in 10 seconds...'), findsOneWidget);

      // Test YES response
      await tester.tap(find.text('Yes, Pothole'));
      await tester.pump();

      expect(capturedResponse, equals('Yes'));

      // Reset test
      capturedResponse = null;
    });

    testWidgets('should handle No button press', (WidgetTester tester) async {
      // Callback to capture responses
      String? capturedResponse;

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnotationPromptWidget(
              displayDuration: const Duration(seconds: 10),
              onResponse: (response) {
                capturedResponse = response;
              },
            ),
          ),
        ),
      );

      // Test NO response
      await tester.tap(find.text('No, Not Pothole'));
      await tester.pump();

      expect(capturedResponse, equals('No'));
    });

    testWidgets('should handle timeout', (WidgetTester tester) async {
      // Callback to capture responses
      String? capturedResponse;

      // Build the widget with shorter duration for testing
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AnnotationPromptWidget(
              displayDuration: const Duration(seconds: 2),
              onResponse: (response) {
                capturedResponse = response;
              },
            ),
          ),
        ),
      );

      // Verify initial state
      expect(find.text('Dismissing in 2 seconds...'), findsOneWidget);

      // Wait for 1 second
      await tester.pump(const Duration(seconds: 1));

      // Countdown should update
      expect(find.text('Dismissing in 1 seconds...'), findsOneWidget);

      // Wait for timeout
      await tester.pump(const Duration(seconds: 1));

      // Response should be triggered with 'Uncategorized'
      expect(capturedResponse, equals('Uncategorized'));
    });
  });

  group('AnnotationPromptOverlay', () {
    testWidgets('should show and hide overlay', (WidgetTester tester) async {
      // Build a basic app
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // Show the overlay
                      final overlay = AnnotationPromptOverlay(context);
                      overlay.show(onResponse: (_) {});
                    },
                    child: const Text('Show Overlay'),
                  ),
                ),
              );
            },
          ),
        ),
      );

      // Press the button to show overlay
      await tester.tap(find.text('Show Overlay'));
      await tester.pump();

      // Verify overlay is shown
      expect(find.text('Bump Detected!'), findsOneWidget);
      expect(find.text('Was this a pothole?'), findsOneWidget);

      // Tap Yes to dismiss
      await tester.tap(find.text('Yes, Pothole'));
      await tester.pump();

      // Overlay should be gone
      expect(find.text('Bump Detected!'), findsNothing);
    });
  });
}
