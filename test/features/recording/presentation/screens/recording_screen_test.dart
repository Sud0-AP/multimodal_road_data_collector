import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:multimodal_road_data_collector/core/services/camera_service.dart';
import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart';
import 'package:multimodal_road_data_collector/core/services/permission_service.dart';
import 'package:multimodal_road_data_collector/core/services/providers.dart';
import 'package:multimodal_road_data_collector/features/calibration/presentation/state/calibration_provider.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/managers/recording_session_manager.dart';
import 'package:multimodal_road_data_collector/features/recording/presentation/providers/recording_lifecycle_provider.dart';
import 'package:multimodal_road_data_collector/features/recording/presentation/screens/recording_screen.dart';
import 'package:multimodal_road_data_collector/features/recording/presentation/state/recording_state.dart';
import 'package:multimodal_road_data_collector/features/recording/presentation/state/pre_recording_calibration_state.dart';

import 'recording_screen_test.mocks.dart';

// Generate mocks for the services
@GenerateMocks([
  CameraService, 
  FileStorageService, 
  PermissionService, 
  RecordingSessionManager,
  RecordingLifecycleNotifier,
])
void main() {
  group('RecordingScreen', () {
    late MockCameraService mockCameraService;
    late MockFileStorageService mockFileStorageService;
    late MockPermissionService mockPermissionService;
    late MockRecordingSessionManager mockRecordingSessionManager;
    late MockRecordingLifecycleNotifier mockRecordingLifecycleNotifier;

    setUp(() {
      mockCameraService = MockCameraService();
      mockFileStorageService = MockFileStorageService();
      mockPermissionService = MockPermissionService();
      mockRecordingSessionManager = MockRecordingSessionManager();
      mockRecordingLifecycleNotifier = MockRecordingLifecycleNotifier();

      // Mock permission requests to return true
      when(mockPermissionService.requestCameraPermission())
          .thenAnswer((_) async => true);
      when(mockPermissionService.requestStoragePermission())
          .thenAnswer((_) async => true);

      // Mock camera initialization
      when(mockCameraService.initialize()).thenAnswer((_) async => {});
      when(mockCameraService.isInitialized).thenReturn(true);
      
      // Setup mock for camera preview
      final previewWidget = Container(key: const Key('camera_preview'));
      when(mockCameraService.previewWidget).thenReturn(previewWidget);

      // Mock RecordingSessionManager
      when(mockRecordingSessionManager.initialize()).thenAnswer((_) async => {});
      when(mockRecordingSessionManager.isDataCollectionActive()).thenReturn(false);
      when(mockRecordingSessionManager.getProcessedSensorStream())
          .thenAnswer((_) => const Stream.empty());
      
      // Mock FileStorageService
      when(mockFileStorageService.createSessionDirectory())
          .thenAnswer((_) async => '/test/session');
      when(mockFileStorageService.saveVideoToSession(any, any))
          .thenAnswer((_) async => '/test/session/video.mp4');
          
      // Mock RecordingLifecycleNotifier
      when(mockRecordingLifecycleNotifier.startRecording(any))
          .thenAnswer((_) async => {});
      when(mockRecordingLifecycleNotifier.stopRecording())
          .thenAnswer((_) async => {});
    });

    Widget createRecordingScreen() {
      return ProviderScope(
        overrides: [
          cameraServiceProvider.overrideWithValue(mockCameraService),
          fileStorageServiceProvider.overrideWithValue(mockFileStorageService),
          permissionServiceProvider.overrideWithValue(mockPermissionService),
          recordingSessionManagerProvider.overrideWithValue(mockRecordingSessionManager),
          recordingLifecycleProvider.overrideWith((_) => mockRecordingLifecycleNotifier),
          calibrationNeededProvider.overrideWithValue(false),
          calibrationCompletedProvider.overrideWithValue(true),
          preRecordingCalibrationProvider.overrideWith((_) => StateController(false)),
        ],
        child: const MaterialApp(home: RecordingScreen()),
      );
    }

    testWidgets(
      'shows loading indicator while initializing',
      (
        WidgetTester tester,
      ) async {
        // The camera initialization will be delayed, so we can check the loading state
        when(mockCameraService.initialize()).thenAnswer((_) async {
          // Delay to allow testing the loading state
          await Future.delayed(const Duration(milliseconds: 100));
        });

        // Build the widget
        await tester.pumpWidget(createRecordingScreen());

        // Verify loading indicator is shown
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Initializing camera...'), findsOneWidget);
      },
    );

    testWidgets(
      'shows camera preview after initialization',
      (
        WidgetTester tester,
      ) async {
        // Build the widget
        await tester.pumpWidget(createRecordingScreen());

        // Skip loading state
        await tester.pumpAndSettle();

        // Verify camera preview is shown
        expect(find.byKey(const Key('camera_preview')), findsOneWidget);
        // Verify record button is present
        expect(find.byIcon(Icons.fiber_manual_record), findsOneWidget);
      },
    );

    testWidgets(
      'displays error when camera initialization fails',
      (
        WidgetTester tester,
      ) async {
        // Setup mock to simulate failure
        when(mockCameraService.initialize())
            .thenThrow(Exception('Camera initialization failed'));

        // Build the widget
        await tester.pumpWidget(createRecordingScreen());

        // Skip to error state
        await tester.pumpAndSettle();

        // Verify error UI is shown
        expect(find.byIcon(Icons.error_outline), findsOneWidget);
        expect(find.text('Error initializing services: Exception: Camera initialization failed'),
            findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);
      },
    );

    testWidgets(
      'retries initialization when retry button is pressed',
      (
        WidgetTester tester,
      ) async {
        // Setup mock to simulate failure then success
        var initializationAttempts = 0;
        when(mockCameraService.initialize()).thenAnswer((_) async {
          if (initializationAttempts == 0) {
            initializationAttempts++;
            throw Exception('Camera initialization failed');
          }
        });

        // Build the widget
        await tester.pumpWidget(createRecordingScreen());

        // Skip to error state
        await tester.pumpAndSettle();

        // Verify error UI is shown
        expect(find.text('Retry'), findsOneWidget);

        // Press retry button
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        // Verify camera preview is shown after successful retry
        expect(find.byKey(const Key('camera_preview')), findsOneWidget);
      },
    );

    testWidgets(
      'has a title',
      (
        WidgetTester tester,
      ) async {
        // Build the widget
        await tester.pumpWidget(createRecordingScreen());

        // Skip loading state
        await tester.pumpAndSettle();

        // Verify title is shown
        expect(find.text('Record Road Data'), findsOneWidget);
      },
    );

    testWidgets('RecordingScreen uses lifecycle provider when starting recording',
        (WidgetTester tester) async {
      // Build the widget
      await tester.pumpWidget(createRecordingScreen());

      // Ensure the screen is initialized
      await tester.pumpAndSettle();

      // Find and press the record button
      final recordButton = find.byIcon(Icons.fiber_manual_record);
      expect(recordButton, findsOneWidget);
      await tester.tap(recordButton);
      await tester.pumpAndSettle();

      // Verify that startRecording was called on the lifecycleNotifier
      verify(mockRecordingLifecycleNotifier.startRecording(any)).called(1);
    });

    testWidgets('RecordingScreen uses lifecycle provider when stopping recording',
        (WidgetTester tester) async {
      // Mock that we're recording
      when(mockCameraService.startVideoRecording()).thenAnswer((_) async => {});
      when(mockCameraService.stopVideoRecording())
          .thenAnswer((_) async => '/test/temp/video.mp4');
      
      // Mock RecordingStateNotifier to be in recording state after starting
      final recordingStateOverride = StateProvider<RecordingState>((ref) => 
          const RecordingState(status: RecordingStatus.recording));

      // Build the widget with modified state
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(mockCameraService),
            fileStorageServiceProvider.overrideWithValue(mockFileStorageService),
            permissionServiceProvider.overrideWithValue(mockPermissionService),
            recordingSessionManagerProvider.overrideWithValue(mockRecordingSessionManager),
            recordingLifecycleProvider.overrideWith((_) => mockRecordingLifecycleNotifier),
            calibrationNeededProvider.overrideWithValue(false),
            calibrationCompletedProvider.overrideWithValue(true),
            preRecordingCalibrationProvider.overrideWith((_) => StateController(false)),
            // Override with a recording state
            recordingStateProvider.overrideWith((ref) => 
                RecordingStateNotifier()..startRecording()),
          ],
          child: const MaterialApp(home: RecordingScreen()),
        ),
      );

      // Ensure the screen is initialized
      await tester.pumpAndSettle();

      // Expect to find the stop button (since we're in recording state)
      final stopButton = find.byIcon(Icons.stop);
      expect(stopButton, findsOneWidget);
      
      // Press the stop button
      await tester.tap(stopButton);
      await tester.pumpAndSettle();

      // Verify that stopRecording was called on the lifecycleNotifier
      verify(mockRecordingLifecycleNotifier.stopRecording()).called(1);
    });

    testWidgets('AppLifecycleState changes are handled through the RecordingLifecycleNotifier',
        (WidgetTester tester) async {
      // Create a real lifecycleNotifier for this test to test the observer behavior
      final realLifecycleNotifier = RecordingLifecycleNotifier(mockRecordingSessionManager);
      
      // Build the widget
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cameraServiceProvider.overrideWithValue(mockCameraService),
            fileStorageServiceProvider.overrideWithValue(mockFileStorageService),
            permissionServiceProvider.overrideWithValue(mockPermissionService),
            recordingSessionManagerProvider.overrideWithValue(mockRecordingSessionManager),
            recordingLifecycleProvider.overrideWithValue(realLifecycleNotifier),
            calibrationNeededProvider.overrideWithValue(false),
            calibrationCompletedProvider.overrideWithValue(true),
            preRecordingCalibrationProvider.overrideWith((_) => StateController(false)),
          ],
          child: const MaterialApp(home: RecordingScreen()),
        ),
      );

      // Ensure the screen is initialized
      await tester.pumpAndSettle();

      // Start recording
      when(mockCameraService.startVideoRecording()).thenAnswer((_) async => {});
      when(mockRecordingSessionManager.startSession(any)).thenAnswer((_) async => {});
      
      // Find and press the record button
      final recordButton = find.byIcon(Icons.fiber_manual_record);
      expect(recordButton, findsOneWidget);
      await tester.tap(recordButton);
      await tester.pumpAndSettle();

      // Simulate the app being backgrounded
      realLifecycleNotifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      await tester.pumpAndSettle();

      // Verify the recording was stopped when app went to background
      verify(mockRecordingSessionManager.stopSession()).called(1);
      
      // Clean up
      realLifecycleNotifier.dispose();
    });
  });
}
