import 'package:flutter/material.dart';
import 'package:flutter/services.dart';  // For PredictiveBack types
import 'dart:ui';  // For AppExitResponse
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/managers/recording_session_manager.dart';

/// Provider that manages recording lifecycle with app state awareness
/// 
/// This provider implements WidgetsBindingObserver to detect app lifecycle changes
/// and manage recording session graceful shutdowns when the app is backgrounded.
class RecordingLifecycleNotifier extends StateNotifier<bool> implements WidgetsBindingObserver {
  final RecordingSessionManager _sessionManager;
  final WidgetsBinding? _binding;
  bool _isRecording = false;
  
  RecordingLifecycleNotifier(this._sessionManager, {WidgetsBinding? binding}) : 
    _binding = binding,
    super(false) {
    // Register for app lifecycle events
    (_binding ?? WidgetsBinding.instance).addObserver(this);
  }
  
  @override
  void dispose() {
    // Unregister from app lifecycle events
    (_binding ?? WidgetsBinding.instance).removeObserver(this);
    
    // Ensure recording is stopped when provider is disposed
    if (_isRecording) {
      _stopRecording();
    }
    
    super.dispose();
  }
  
  /// Start recording session
  Future<void> startRecording(String sessionDirectory) async {
    if (_isRecording) return;
    
    await _sessionManager.startSession(sessionDirectory);
    _isRecording = true;
    state = true;
  }
  
  /// Stop recording session
  Future<void> stopRecording() async {
    if (!_isRecording) return;
    
    await _stopRecording();
  }
  
  /// Internal method to stop recording and update state
  Future<void> _stopRecording() async {
    try {
      await _sessionManager.stopSession();
    } catch (e) {
      print('Error stopping recording session: $e');
    } finally {
      _isRecording = false;
      state = false;
    }
  }
  
  /// Called when app state changes - implement required method from WidgetsBindingObserver
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.detached) {
      // App is going to background or being terminated
      if (_isRecording) {
        print('App backgrounded during recording - stopping recording gracefully');
        _stopRecording();
      }
    }
  }
  
  // Implement other required methods from WidgetsBindingObserver with empty implementations
  @override
  void didChangeAccessibilityFeatures() {}
  
  @override
  void didChangeLocales(List<Locale>? locales) {}
  
  @override
  void didChangeMetrics() {}
  
  @override
  void didChangePlatformBrightness() {}
  
  @override
  void didChangeTextScaleFactor() {}
  
  @override
  void didHaveMemoryPressure() {}
  
  @override
  Future<bool> didPopRoute() => Future<bool>.value(false);
  
  @override
  Future<bool> didPushRoute(String route) => Future<bool>.value(false);
  
  @override
  Future<bool> didPushRouteInformation(RouteInformation routeInformation) {
    return Future<bool>.value(false);
  }
  
  // Some of these methods might not be available in older Flutter versions
  // Implementation varies based on Flutter version
  
  @override
  // ignore: override_on_non_overriding_member
  void didChangeViewFocus(Object event) {}
  
  @override
  Future<AppExitResponse> didRequestAppExit() async {
    return AppExitResponse.exit;
  }
  
  @override
  void handleCancelBackGesture() {}
  
  @override
  void handleCommitBackGesture() {}
  
  @override
  // ignore: override_on_non_overriding_member
  bool handleStartBackGesture(Object backEvent) => false;
  
  @override
  // ignore: override_on_non_overriding_member
  void handleUpdateBackGestureProgress(Object backEvent) {}
}

/// Provider for recording lifecycle management
final recordingLifecycleProvider = StateNotifierProvider<RecordingLifecycleNotifier, bool>((ref) {
  final sessionManager = ref.watch(recordingSessionManagerProvider);
  return RecordingLifecycleNotifier(sessionManager);
}); 