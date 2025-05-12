import 'package:flutter/foundation.dart';
import 'package:multimodal_road_data_collector/features/recordings/domain/models/recording_display_info.dart';

/// Enum for the status of recordings list screen
enum RecordingsStatus {
  /// Initial state
  initial,

  /// Loading recordings
  loading,

  /// Successfully loaded recordings
  loaded,

  /// Error loading recordings
  error,
}

/// The state for the recordings screen
@immutable
class RecordingsState {
  /// Status of the recordings list
  final RecordingsStatus status;

  /// List of recordings display info
  final List<RecordingDisplayInfo> recordings;

  /// Error message if loading failed
  final String? errorMessage;

  /// Whether a delete operation is in progress
  final bool isDeletingRecording;

  /// Whether a share operation is in progress
  final bool isSharingRecording;

  /// Whether a metadata operation is in progress
  final bool isProcessingMetadata;

  /// Constructor
  const RecordingsState({
    this.status = RecordingsStatus.initial,
    this.recordings = const [],
    this.errorMessage,
    this.isDeletingRecording = false,
    this.isSharingRecording = false,
    this.isProcessingMetadata = false,
  });

  /// Create a copy of this state with optional parameter changes
  RecordingsState copyWith({
    RecordingsStatus? status,
    List<RecordingDisplayInfo>? recordings,
    String? errorMessage,
    bool? isDeletingRecording,
    bool? isSharingRecording,
    bool? isProcessingMetadata,
  }) {
    return RecordingsState(
      status: status ?? this.status,
      recordings: recordings ?? this.recordings,
      errorMessage: errorMessage ?? this.errorMessage,
      isDeletingRecording: isDeletingRecording ?? this.isDeletingRecording,
      isSharingRecording: isSharingRecording ?? this.isSharingRecording,
      isProcessingMetadata: isProcessingMetadata ?? this.isProcessingMetadata,
    );
  }
}
