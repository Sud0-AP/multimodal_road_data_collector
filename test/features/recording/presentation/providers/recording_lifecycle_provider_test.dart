import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_road_data_collector/features/recording/domain/managers/recording_session_manager.dart';
import 'package:multimodal_road_data_collector/features/recording/presentation/providers/recording_lifecycle_provider.dart';
import 'package:multimodal_road_data_collector/core/services/sensor_service.dart';
import 'package:multimodal_road_data_collector/core/services/ntp_service.dart';
import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart';

// Fake implementation of RecordingSessionManager for testing
class FakeRecordingSessionManager implements RecordingSessionManager {
  String? sessionDirectory;
  bool isRecording = false;
  int startSessionCount = 0;
  int stopSessionCount = 0;
  
  // Implementation of required methods
  @override
  Future<void> startSession(String sessionDirectory) async {
    this.sessionDirectory = sessionDirectory;
    isRecording = true;
    startSessionCount++;
  }
  
  @override
  Future<void> stopSession() async {
    isRecording = false;
    stopSessionCount++;
  }
  
  // Implement other required methods with minimal functionality
  @override
  void setSessionDirectory(String directory) {
    sessionDirectory = directory;
  }
  
  // No-op implementations for other required methods
  @override
  dynamic noSuchMethod(Invocation invocation) {
    // Return appropriate default values based on return type
    final symbol = invocation.memberName;
    
    if (symbol == #startSensorDataCollection) {
      return Future<void>.value();
    } else if (symbol == #stopSensorDataCollection) {
      return Future<void>.value();
    } else if (symbol.toString().contains('Stream')) {
      return Stream.empty();
    } else if (symbol.toString().contains('Future')) {
      return Future.value();
    } else if (symbol.toString().contains('bool')) {
      return false;
    } else if (symbol.toString().contains('int')) {
      return 0;
    } else if (symbol.toString().contains('double')) {
      return 0.0;
    } else if (symbol.toString().contains('String')) {
      return '';
    } else {
      return null;
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late FakeRecordingSessionManager fakeSessionManager;
  late RecordingLifecycleNotifier lifecycleNotifier;

  setUp(() {
    fakeSessionManager = FakeRecordingSessionManager();
    lifecycleNotifier = RecordingLifecycleNotifier(fakeSessionManager);
  });

  tearDown(() {
    lifecycleNotifier.dispose();
  });

  group('RecordingLifecycleNotifier', () {
    testWidgets('should start recording session', (WidgetTester tester) async {
      // Act
      await lifecycleNotifier.startRecording('/test/session');
      
      // Assert
      expect(lifecycleNotifier.state, true);
      expect(fakeSessionManager.isRecording, true);
      expect(fakeSessionManager.sessionDirectory, '/test/session');
      expect(fakeSessionManager.startSessionCount, 1);
    });

    testWidgets('should stop recording session', (WidgetTester tester) async {
      // Arrange
      await lifecycleNotifier.startRecording('/test/session');
      
      // Act
      await lifecycleNotifier.stopRecording();
      
      // Assert
      expect(lifecycleNotifier.state, false);
      expect(fakeSessionManager.isRecording, false);
      expect(fakeSessionManager.stopSessionCount, 1);
    });

    testWidgets('should stop recording when app is backgrounded', (WidgetTester tester) async {
      // Arrange
      await lifecycleNotifier.startRecording('/test/session');
      
      // Act - simulate app going to background
      lifecycleNotifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      
      // Assert
      expect(lifecycleNotifier.state, false);
      expect(fakeSessionManager.isRecording, false);
      expect(fakeSessionManager.stopSessionCount, 1);
    });

    testWidgets('should stop recording when app is terminated', (WidgetTester tester) async {
      // Arrange
      await lifecycleNotifier.startRecording('/test/session');
      
      // Act - simulate app being terminated
      lifecycleNotifier.didChangeAppLifecycleState(AppLifecycleState.detached);
      
      // Assert
      expect(lifecycleNotifier.state, false);
      expect(fakeSessionManager.isRecording, false);
      expect(fakeSessionManager.stopSessionCount, 1);
    });

    testWidgets('should not attempt to stop if not recording when backgrounded', (WidgetTester tester) async {
      // Arrange - not recording
      expect(lifecycleNotifier.state, false);
      
      // Act - simulate app going to background
      lifecycleNotifier.didChangeAppLifecycleState(AppLifecycleState.paused);
      
      // Assert - no stop attempt was made
      expect(fakeSessionManager.stopSessionCount, 0);
    });

    testWidgets('should clean up observer on dispose', (WidgetTester tester) async {
      // This is hard to test directly, but we can check that the recording stops
      // Arrange
      await lifecycleNotifier.startRecording('/test/session');
      
      // Act
      lifecycleNotifier.dispose();
      
      // Assert - recording was stopped during disposal
      expect(fakeSessionManager.isRecording, false);
      expect(fakeSessionManager.stopSessionCount, 1);
    });
  });
} 