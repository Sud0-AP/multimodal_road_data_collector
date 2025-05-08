import 'package:shared_preferences/shared_preferences.dart';
import '../preferences_service.dart';

/// A constant key for storing whether onboarding is complete
const String kIsOnboardingComplete = 'is_onboarding_complete';

/// Implementation of PreferencesService using shared_preferences
class PreferencesServiceImpl implements PreferencesService {
  final SharedPreferences _preferences;

  /// Constructor that takes in the SharedPreferences instance
  PreferencesServiceImpl(this._preferences);

  /// Factory constructor to create a PreferencesServiceImpl with SharedPreferences.getInstance()
  static Future<PreferencesServiceImpl> create() async {
    final preferences = await SharedPreferences.getInstance();
    return PreferencesServiceImpl(preferences);
  }

  @override
  Future<bool?> getBool(String key) async {
    return _preferences.getBool(key);
  }

  @override
  Future<bool> setBool(String key, bool value) async {
    return await _preferences.setBool(key, value);
  }

  @override
  Future<String?> getString(String key) async {
    return _preferences.getString(key);
  }

  @override
  Future<bool> setString(String key, String value) async {
    return await _preferences.setString(key, value);
  }

  @override
  Future<int?> getInt(String key) async {
    return _preferences.getInt(key);
  }

  @override
  Future<bool> setInt(String key, int value) async {
    return await _preferences.setInt(key, value);
  }

  @override
  Future<double?> getDouble(String key) async {
    return _preferences.getDouble(key);
  }

  @override
  Future<bool> setDouble(String key, double value) async {
    return await _preferences.setDouble(key, value);
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    return _preferences.getStringList(key);
  }

  @override
  Future<bool> setStringList(String key, List<String> value) async {
    return await _preferences.setStringList(key, value);
  }

  @override
  Future<bool> containsKey(String key) async {
    return _preferences.containsKey(key);
  }

  @override
  Future<bool> remove(String key) async {
    return await _preferences.remove(key);
  }

  @override
  Future<bool> clear() async {
    return await _preferences.clear();
  }
}
