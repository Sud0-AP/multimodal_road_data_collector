/// Interface for accessing application information
abstract class AppInfoService {
  /// Get application name
  Future<String> getAppName();

  /// Get application version (e.g., 1.0.0)
  Future<String> getAppVersion();

  /// Get application build number (e.g., 15)
  Future<String> getBuildNumber();

  /// Get application package name / bundle ID
  Future<String> getPackageName();

  /// Get detailed application information as a map
  Future<Map<String, dynamic>> getAppInfo();
}
