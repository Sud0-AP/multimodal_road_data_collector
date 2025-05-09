import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/permission_service.dart';
import '../services/preferences_service.dart';
import '../services/sensor_service.dart';
import '../services/implementations/permission_service_impl.dart';
import '../services/implementations/preferences_service_impl.dart';
import '../services/implementations/sensor_service_impl.dart';

/// Provider for PermissionService
final permissionServiceProvider = Provider<PermissionService>((ref) {
  return PermissionServiceImpl();
});

/// Provider for PreferencesService
final preferencesServiceProvider = FutureProvider<PreferencesService>((
  ref,
) async {
  final prefs = await SharedPreferences.getInstance();
  return PreferencesServiceImpl(prefs);
});

/// Provider for SensorService
final sensorServiceProvider = Provider<SensorService>((ref) {
  final sensorService = SensorServiceImpl();
  ref.onDispose(() => sensorService.dispose());
  return sensorService;
});

/// Key for onboarding completion in preferences
const String kIsOnboardingComplete = 'is_onboarding_complete';
