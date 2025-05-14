import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../constants/app_constants.dart';
import '../../../../core/services/preferences_service.dart';
import 'settings_state.dart';

/// Notifier for managing settings state
class SettingsNotifier extends StateNotifier<SettingsState> {
  /// The preferences service for persisting settings
  final PreferencesService _preferencesService;

  /// Creates a new [SettingsNotifier]
  SettingsNotifier({required PreferencesService preferencesService})
    : _preferencesService = preferencesService,
      super(const SettingsState()) {
    // Load initial settings when created
    _loadSettings();
  }

  /// Loads settings from preferences
  Future<void> _loadSettings() async {
    try {
      // Load bump threshold multiplier
      final multiplier = await _preferencesService.getDouble(
        AppConstants.keyBumpThresholdMultiplier,
      );

      // Load annotation enabled setting
      final annotationEnabled = await _preferencesService.getBool(
        AppConstants.keyAnnotationEnabled,
      );

      // Load debugging mode setting
      final debuggingModeEnabled = await _preferencesService.getBool(
        AppConstants.keyDebuggingModeEnabled,
      );

      // Update state with loaded values or use defaults
      state = state.copyWith(
        bumpThresholdMultiplier:
            multiplier ?? AppConstants.defaultBumpThresholdMultiplier,
        annotationEnabled:
            annotationEnabled ?? AppConstants.defaultAnnotationEnabled,
        debuggingModeEnabled:
            debuggingModeEnabled ?? AppConstants.defaultDebuggingModeEnabled,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Failed to load settings: ${e.toString()}',
      );
    }
  }

  /// Updates the bump threshold multiplier
  Future<void> updateBumpThresholdMultiplier(double value) async {
    // Validate the value to ensure it's within the allowed range
    final clampedValue = value.clamp(
      AppConstants.minBumpThresholdMultiplier,
      AppConstants.maxBumpThresholdMultiplier,
    );

    // Set saving state
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      // Save to preferences
      final success = await _preferencesService.setDouble(
        AppConstants.keyBumpThresholdMultiplier,
        clampedValue,
      );

      if (success) {
        // Update state with new value and success message
        state = state.copyWith(
          bumpThresholdMultiplier: clampedValue,
          isSaving: false,
          successMessage: 'Bump threshold multiplier updated successfully',
        );
      } else {
        // Update state with error message
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save settings',
        );
      }
    } catch (e) {
      // Update state with error message
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error saving settings: ${e.toString()}',
      );
    }
  }

  /// Updates the annotation enabled setting
  Future<void> updateAnnotationEnabled(bool value) async {
    // Set saving state
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      // Save to preferences
      final success = await _preferencesService.setBool(
        AppConstants.keyAnnotationEnabled,
        value,
      );

      if (success) {
        // Update state with new value and success message
        state = state.copyWith(
          annotationEnabled: value,
          isSaving: false,
          successMessage: 'Annotation setting updated successfully',
        );
      } else {
        // Update state with error message
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save annotation setting',
        );
      }
    } catch (e) {
      // Update state with error message
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error saving settings: ${e.toString()}',
      );
    }
  }

  /// Updates the debugging mode enabled setting
  Future<void> updateDebuggingModeEnabled(bool value) async {
    // Set saving state
    state = state.copyWith(
      isSaving: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      // Save to preferences
      final success = await _preferencesService.setBool(
        AppConstants.keyDebuggingModeEnabled,
        value,
      );

      if (success) {
        // Update state with new value and success message
        state = state.copyWith(
          debuggingModeEnabled: value,
          isSaving: false,
          successMessage: 'Debugging mode setting updated successfully',
        );
      } else {
        // Update state with error message
        state = state.copyWith(
          isSaving: false,
          errorMessage: 'Failed to save debugging mode setting',
        );
      }
    } catch (e) {
      // Update state with error message
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Error saving settings: ${e.toString()}',
      );
    }
  }

  /// Clear any displayed messages
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}
