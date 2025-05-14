/// State class for the settings screen
class SettingsState {
  /// The multiplier value for bump detection threshold calculation
  final double bumpThresholdMultiplier;

  /// Controls whether annotation prompts appear during recording
  final bool annotationEnabled;

  /// Controls whether debug logging is enabled
  final bool debuggingModeEnabled;

  /// Indicates if settings are currently being saved
  final bool isSaving;

  /// Any error message that needs to be displayed
  final String? errorMessage;

  /// Success message to display after a successful operation
  final String? successMessage;

  /// Constructor
  const SettingsState({
    this.bumpThresholdMultiplier = 5.0,
    this.annotationEnabled = true,
    this.debuggingModeEnabled = false,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  /// Create a copy of this state with the given fields replaced
  SettingsState copyWith({
    double? bumpThresholdMultiplier,
    bool? annotationEnabled,
    bool? debuggingModeEnabled,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return SettingsState(
      bumpThresholdMultiplier:
          bumpThresholdMultiplier ?? this.bumpThresholdMultiplier,
      annotationEnabled: annotationEnabled ?? this.annotationEnabled,
      debuggingModeEnabled: debuggingModeEnabled ?? this.debuggingModeEnabled,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}
