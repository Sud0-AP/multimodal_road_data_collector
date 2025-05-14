/// App-wide constants
class AppConstants {
  // App information
  static const String appName = 'Multimodal Road Data Collector';
  static const String appVersion = '1.0.0';

  // Preference keys
  static const String keyIsOnboardingComplete = 'is_onboarding_complete';
  static const String keyBumpThresholdMultiplier = 'bump_threshold_multiplier';
  static const String keyAnnotationEnabled = 'annotation_enabled';
  static const String keyDebuggingModeEnabled = 'debugging_mode_enabled';

  // Default values for settings
  static const double defaultBumpThresholdMultiplier = 5.0;
  static const double minBumpThresholdMultiplier = 1.0;
  static const double maxBumpThresholdMultiplier = 10.0;
  static const bool defaultAnnotationEnabled = true;
  static const bool defaultDebuggingModeEnabled = false;

  // Timeout values
  static const int defaultTimeoutSeconds = 30;

  // Feature toggles
  static const bool enableDebugLogs = true;

  // Storage constants
  static const String rootFolderName = 'road_data';
}
