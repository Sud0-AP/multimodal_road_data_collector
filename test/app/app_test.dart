import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multimodal_road_data_collector/app/app.dart';

void main() {
  testWidgets('App should build without errors', (WidgetTester tester) async {
    // Build our app inside a ProviderScope
    await tester.pumpWidget(const ProviderScope(child: App()));

    // Wait for all animations to complete
    await tester.pumpAndSettle();

    // The app should build without throwing any errors
    expect(find.byType(App), findsOneWidget);
  });
}
