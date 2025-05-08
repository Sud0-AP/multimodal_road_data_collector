/// Interface for managing local key-value storage
abstract class PreferencesService {
  /// Get a boolean value from preferences
  Future<bool?> getBool(String key);

  /// Save a boolean value to preferences
  Future<bool> setBool(String key, bool value);

  /// Get a string value from preferences
  Future<String?> getString(String key);

  /// Save a string value to preferences
  Future<bool> setString(String key, String value);

  /// Get an integer value from preferences
  Future<int?> getInt(String key);

  /// Save an integer value to preferences
  Future<bool> setInt(String key, int value);

  /// Get a double value from preferences
  Future<double?> getDouble(String key);

  /// Save a double value to preferences
  Future<bool> setDouble(String key, double value);

  /// Check if preferences contains a key
  Future<bool> containsKey(String key);

  /// Remove a key from preferences
  Future<bool> remove(String key);

  /// Clear all preferences
  Future<bool> clear();
}
