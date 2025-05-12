/// State class for the settings screen
class SettingsState {
  /// The multiplier value for bump detection threshold calculation
  final double bumpThresholdMultiplier;

  /// Indicates if settings are currently being saved
  final bool isSaving;

  /// Any error message that needs to be displayed
  final String? errorMessage;

  /// Success message to display after a successful operation
  final String? successMessage;

  /// Constructor
  const SettingsState({
    this.bumpThresholdMultiplier = 5.0,
    this.isSaving = false,
    this.errorMessage,
    this.successMessage,
  });

  /// Create a copy of this state with the given fields replaced
  SettingsState copyWith({
    double? bumpThresholdMultiplier,
    bool? isSaving,
    String? errorMessage,
    String? successMessage,
  }) {
    return SettingsState(
      bumpThresholdMultiplier:
          bumpThresholdMultiplier ?? this.bumpThresholdMultiplier,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage ?? this.errorMessage,
      successMessage: successMessage ?? this.successMessage,
    );
  }
}
