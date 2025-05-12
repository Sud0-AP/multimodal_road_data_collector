import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multimodal_road_data_collector/core/services/data_management_service.dart';
import 'package:multimodal_road_data_collector/features/recordings/domain/models/recording_display_info.dart';
import 'recordings_state.dart';
import 'package:path/path.dart' as path;

/// Notifier for managing recordings data and UI state
class RecordingsNotifier extends StateNotifier<RecordingsState> {
  final DataManagementService _dataManagementService;

  // Track load attempt count to handle retries
  int _loadAttemptCount = 0;
  static const int _maxRetryAttempts = 2;

  /// Constructor
  RecordingsNotifier({required DataManagementService dataManagementService})
    : _dataManagementService = dataManagementService,
      super(const RecordingsState());

  /// Load the list of recorded sessions
  Future<void> loadRecordings() async {
    // Set loading state
    state = state.copyWith(
      status: RecordingsStatus.loading,
      errorMessage: null,
    );

    try {
      // Get list of session paths
      final sessionPaths = await _dataManagementService.loadSessionList();
      print('Found ${sessionPaths.length} session paths');

      if (sessionPaths.isEmpty) {
        print('No recording sessions found - setting empty state');
        state = state.copyWith(status: RecordingsStatus.loaded, recordings: []);
        // Reset retry counter on success
        _loadAttemptCount = 0;
        return;
      }

      // Transform paths to display info
      final List<RecordingDisplayInfo> recordings = [];

      for (final sessionPath in sessionPaths) {
        print('Processing session: $sessionPath');

        try {
          final infoMap = await _dataManagementService.getSessionDisplayInfo(
            sessionPath,
          );

          if (infoMap != null) {
            print('Session info retrieved: $infoMap');
            final recordingInfo = RecordingDisplayInfo(
              sessionId: infoMap['sessionId'] as String,
              sessionPath: infoMap['sessionPath'] as String,
              timestamp: infoMap['timestamp'] as DateTime,
              durationSeconds: infoMap['durationSeconds'] as int,
              videoFileName: infoMap['videoFileName'] as String?,
              sensorDataFileName: infoMap['sensorDataFileName'] as String?,
            );

            recordings.add(recordingInfo);
            print('Added recording: ${recordingInfo.sessionId}');
          } else {
            print('Failed to get display info for session: $sessionPath');

            // Try to extract basic info from the path as a fallback
            final sessionId = path.basename(sessionPath);

            // Add a minimal recording info with the available data
            recordings.add(
              RecordingDisplayInfo(
                sessionId: sessionId,
                sessionPath: sessionPath,
                timestamp: DateTime.now(), // Use current time as fallback
                durationSeconds: 0, // Unknown duration
                videoFileName: null,
                sensorDataFileName: null,
              ),
            );
            print('Added minimal fallback recording for: $sessionId');
          }
        } catch (e) {
          print('Error processing session $sessionPath: $e');
          // Continue to next session rather than failing the whole list
        }
      }

      // Update state with loaded recordings
      print('Final recordings list contains ${recordings.length} recordings');
      state = state.copyWith(
        status: RecordingsStatus.loaded,
        recordings: recordings,
      );

      // Reset retry counter on success
      _loadAttemptCount = 0;
    } catch (e) {
      print('Error loading recordings: $e');

      // Check if this is a specific "package not found" or similar initialization error
      final errorMsg = e.toString().toLowerCase();
      final isInitError =
          errorMsg.contains('package') &&
          (errorMsg.contains('not found') ||
              errorMsg.contains('missing') ||
              errorMsg.contains('null'));

      // If it's a potential init error and we haven't retried too many times
      if (isInitError && _loadAttemptCount < _maxRetryAttempts) {
        _loadAttemptCount++;
        print(
          'Detected initialization error, retrying (attempt $_loadAttemptCount)...',
        );

        // Set temporary error state
        state = state.copyWith(
          status: RecordingsStatus.error,
          errorMessage: 'Initializing services, please wait...',
        );

        // Wait a moment before retrying
        await Future.delayed(const Duration(milliseconds: 1500));
        await loadRecordings(); // Recursive retry
        return;
      }

      // If we've exhausted retries or it's not an init error, report the error
      state = state.copyWith(
        status: RecordingsStatus.error,
        errorMessage: 'Error loading recordings: $e',
      );
    }
  }

  /// Delete a recording session
  Future<bool> deleteRecording(String sessionPath) async {
    state = state.copyWith(isDeletingRecording: true);

    try {
      final success = await _dataManagementService.deleteSession(sessionPath);

      if (success) {
        // Remove from state if deletion was successful
        final updatedRecordings =
            state.recordings
                .where((rec) => rec.sessionPath != sessionPath)
                .toList();

        state = state.copyWith(
          recordings: updatedRecordings,
          isDeletingRecording: false,
        );
      } else {
        state = state.copyWith(isDeletingRecording: false);
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isDeletingRecording: false,
        errorMessage: 'Error deleting recording: $e',
      );
      return false;
    }
  }

  /// Share a recording session
  Future<bool> shareRecording(String sessionPath) async {
    state = state.copyWith(isSharingRecording: true);

    try {
      final success = await _dataManagementService.shareSession(sessionPath);
      state = state.copyWith(isSharingRecording: false);
      return success;
    } catch (e) {
      state = state.copyWith(
        isSharingRecording: false,
        errorMessage: 'Error sharing recording: $e',
      );
      return false;
    }
  }

  /// Generate and save metadata for a recording
  Future<bool> generateAndSaveMetadata(
    String sessionPath,
    Map<String, dynamic> recordingData,
  ) async {
    state = state.copyWith(isProcessingMetadata: true);

    try {
      final success = await _dataManagementService.generateAndSaveMetadata(
        sessionPath,
        recordingData,
      );

      state = state.copyWith(isProcessingMetadata: false);

      // If successful, reload recordings to update list with new metadata
      if (success) {
        await loadRecordings();
      }

      return success;
    } catch (e) {
      state = state.copyWith(
        isProcessingMetadata: false,
        errorMessage: 'Error generating metadata: $e',
      );
      return false;
    }
  }

  /// Try to open the session folder in device's file explorer
  Future<bool> openSessionInFileExplorer(String sessionPath) async {
    try {
      return await _dataManagementService.openSessionInFileExplorer(
        sessionPath,
      );
    } catch (e) {
      state = state.copyWith(errorMessage: 'Error opening file explorer: $e');
      return false;
    }
  }

  /// Clear any error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}
