import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:multimodal_road_data_collector/core/services/camera_service.dart';
import 'package:multimodal_road_data_collector/core/services/implementations/camera_service_impl.dart';

import 'camera_service_test.mocks.dart';

// Generate mock classes
@GenerateMocks([CameraController])
void main() {
  group('CameraServiceImpl', () {
    late CameraServiceImpl cameraService;
    late MockCameraController mockCameraController;

    setUp(() {
      mockCameraController = MockCameraController();

      // Set up camera service for testing
      cameraService = CameraServiceImpl();

      // Replace the real controller with our mock
      cameraService.testSetController(mockCameraController);
    });

    test('isInitialized returns false when controller is null', () {
      // Reset controller to null
      cameraService.testSetController(null);

      // Check that isInitialized returns false
      expect(cameraService.isInitialized, false);
    });

    test('isInitialized returns value from controller', () {
      // Setup mock controller
      when(
        mockCameraController.value,
      ).thenReturn(const CameraValue(isInitialized: true));

      // Check that isInitialized returns true
      expect(cameraService.isInitialized, true);

      // Change mock to return false
      when(
        mockCameraController.value,
      ).thenReturn(const CameraValue(isInitialized: false));

      // Check that isInitialized returns false
      expect(cameraService.isInitialized, false);
    });

    test('dispose properly releases the controller', () async {
      // Mock the controller's dispose method
      when(mockCameraController.dispose()).thenAnswer((_) async {});

      // Call the service's dispose method
      await cameraService.dispose();

      // Verify that the controller's dispose method was called
      verify(mockCameraController.dispose()).called(1);

      // Verify controller is set to null
      expect(cameraService.testGetController(), null);
    });

    test('startVideoRecording calls the controller method', () async {
      // Setup mock for video recording
      when(mockCameraController.startVideoRecording()).thenAnswer((_) async {});
      when(mockCameraController.value).thenReturn(
        const CameraValue(isInitialized: true, isRecordingVideo: false),
      );

      // Call the service method
      await cameraService.startVideoRecording();

      // Verify the controller method was called
      verify(mockCameraController.startVideoRecording()).called(1);
    });

    test(
      'stopVideoRecording calls the controller method and returns the path',
      () async {
        // Setup mock for video recording
        final mockXFile = XFile('test/video/path.mp4');
        when(
          mockCameraController.stopVideoRecording(),
        ).thenAnswer((_) async => mockXFile);
        when(mockCameraController.value).thenReturn(
          const CameraValue(isInitialized: true, isRecordingVideo: true),
        );

        // Call the service method
        final result = await cameraService.stopVideoRecording();

        // Verify the controller method was called
        verify(mockCameraController.stopVideoRecording()).called(1);

        // Verify the expected path is returned
        expect(result, 'test/video/path.mp4');
      },
    );

    test('previewWidget returns CameraPreview when initialized', () {
      // Setup mock controller
      when(
        mockCameraController.value,
      ).thenReturn(const CameraValue(isInitialized: true));

      // Get the preview widget
      final preview = cameraService.previewWidget;

      // Verify it's a CameraPreview widget
      expect(preview, isA<CameraPreview>());
      expect(
        (preview as CameraPreview).controller,
        equals(mockCameraController),
      );
    });

    test('previewWidget returns placeholder when not initialized', () {
      // Setup mock controller
      when(
        mockCameraController.value,
      ).thenReturn(const CameraValue(isInitialized: false));

      // Get the preview widget
      final preview = cameraService.previewWidget;

      // Verify it's not a CameraPreview widget
      expect(preview, isA<ColoredBox>());
    });
  });
}
