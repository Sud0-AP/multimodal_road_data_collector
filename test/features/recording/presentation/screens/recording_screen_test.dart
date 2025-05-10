import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:multimodal_road_data_collector/core/services/camera_service.dart';
import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart';
import 'package:multimodal_road_data_collector/core/services/permission_service.dart';
import 'package:multimodal_road_data_collector/core/services/providers.dart';
import 'package:multimodal_road_data_collector/features/recording/presentation/screens/recording_screen.dart';
import 'package:multimodal_road_data_collector/features/recording/presentation/state/recording_state.dart';

import 'recording_screen_test.mocks.dart';

// Generate mocks for the services
@GenerateMocks([CameraService, FileStorageService, PermissionService])
void main() {
  group('RecordingScreen', () {
    late MockCameraService mockCameraService;
    late MockFileStorageService mockFileStorageService;
    late MockPermissionService mockPermissionService;

    setUp(() {
      mockCameraService = MockCameraService();
      mockFileStorageService = MockFileStorageService();
      mockPermissionService = MockPermissionService();
    });

    // Helper method to create the widget under test
    Widget createRecordingScreen() {
      return ProviderScope(
        overrides: [
          cameraServiceProvider.overrideWithValue(mockCameraService),
          fileStorageServiceProvider.overrideWithValue(mockFileStorageService),
          permissionServiceProvider.overrideWithValue(mockPermissionService),
        ],
        child: const MaterialApp(home: RecordingScreen()),
      );
    }

    testWidgets('displays loading indicator when initializing', (
      WidgetTester tester,
    ) async {
      // Setup mocks
      when(
        mockPermissionService.requestCameraPermission(),
      ).thenAnswer((_) async => true);
      when(
        mockPermissionService.requestStoragePermission(),
      ).thenAnswer((_) async => true);

      // The camera initialization will be delayed, so we can check the loading state
      when(mockCameraService.initialize()).thenAnswer((_) async {
        // Delay to allow testing the loading state
        await Future.delayed(const Duration(milliseconds: 100));
      });

      // Build the widget
      await tester.pumpWidget(createRecordingScreen());

      // Initially should show loading indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Initializing camera...'), findsOneWidget);
    });

    testWidgets('displays error message when permissions denied', (
      WidgetTester tester,
    ) async {
      // Setup mocks - camera permission denied
      when(
        mockPermissionService.requestCameraPermission(),
      ).thenAnswer((_) async => false);
      when(
        mockPermissionService.requestStoragePermission(),
      ).thenAnswer((_) async => true);

      // Build the widget
      await tester.pumpWidget(createRecordingScreen());

      // Need to wait for async permission check to complete
      await tester.pumpAndSettle();

      // Should show error about camera permission
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
      expect(find.text('Camera or storage permission denied'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('shows camera preview when initialized', (
      WidgetTester tester,
    ) async {
      // Setup mocks for successful initialization
      when(
        mockPermissionService.requestCameraPermission(),
      ).thenAnswer((_) async => true);
      when(
        mockPermissionService.requestStoragePermission(),
      ).thenAnswer((_) async => true);
      when(mockCameraService.initialize()).thenAnswer((_) async {});
      when(mockCameraService.isInitialized).thenReturn(true);

      // Setup mock for camera preview
      final previewWidget = Container(key: const Key('camera_preview'));
      when(mockCameraService.previewWidget).thenReturn(previewWidget);

      // Build the widget
      await tester.pumpWidget(createRecordingScreen());

      // Need to wait for async initialization to complete
      await tester.pumpAndSettle();

      // Should show the camera preview and record button
      expect(find.byKey(const Key('camera_preview')), findsOneWidget);
      expect(find.text('Record'), findsOneWidget);
    });
  });
}
