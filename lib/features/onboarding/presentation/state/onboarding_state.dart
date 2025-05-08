import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/service_providers.dart';
import '../../../../core/services/permission_service.dart';
import '../../../../core/services/preferences_service.dart';

/// Represents the different permission statuses
enum PermissionStatus { initial, granted, denied, permanentlyDenied }

/// The state for the onboarding flow
class OnboardingState {
  final int currentPage;
  final bool isLoading;
  final bool isComplete;
  final Map<String, PermissionStatus> permissionStatuses;

  const OnboardingState({
    this.currentPage = 0,
    this.isLoading = false,
    this.isComplete = false,
    this.permissionStatuses = const {
      'camera': PermissionStatus.initial,
      'storage': PermissionStatus.initial,
      'sensor': PermissionStatus.initial,
    },
  });

  /// Creates a copy of the current state with selected fields modified
  OnboardingState copyWith({
    int? currentPage,
    bool? isLoading,
    bool? isComplete,
    Map<String, PermissionStatus>? permissionStatuses,
  }) {
    return OnboardingState(
      currentPage: currentPage ?? this.currentPage,
      isLoading: isLoading ?? this.isLoading,
      isComplete: isComplete ?? this.isComplete,
      permissionStatuses: permissionStatuses ?? this.permissionStatuses,
    );
  }

  /// Updates a specific permission status
  OnboardingState updatePermissionStatus(
    String permission,
    PermissionStatus status,
  ) {
    final updatedStatuses = Map<String, PermissionStatus>.from(
      permissionStatuses,
    );
    updatedStatuses[permission] = status;
    return copyWith(permissionStatuses: updatedStatuses);
  }
}

/// The notifier for managing onboarding state
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final PermissionService _permissionService;
  final PreferencesService _preferencesService;

  OnboardingNotifier(this._permissionService, this._preferencesService)
    : super(const OnboardingState());

  /// Checks if onboarding is already completed
  Future<void> checkOnboardingStatus() async {
    state = state.copyWith(isLoading: true);
    final isComplete = await _preferencesService.getBool(kIsOnboardingComplete);
    state = state.copyWith(isLoading: false, isComplete: isComplete ?? false);
  }

  /// Changes the current page in the onboarding flow
  void setCurrentPage(int page) {
    state = state.copyWith(currentPage: page);
  }

  /// Completes the onboarding process
  Future<void> completeOnboarding() async {
    state = state.copyWith(isLoading: true);
    await _preferencesService.setBool(kIsOnboardingComplete, true);
    state = state.copyWith(isLoading: false, isComplete: true);
  }

  /// Requests camera permission
  Future<void> requestCameraPermission() async {
    state = state.copyWith(isLoading: true);
    final isGranted = await _permissionService.requestCameraPermission();
    state = state
        .copyWith(isLoading: false)
        .updatePermissionStatus(
          'camera',
          isGranted ? PermissionStatus.granted : PermissionStatus.denied,
        );
  }

  /// Requests storage permission
  Future<void> requestStoragePermission() async {
    state = state.copyWith(isLoading: true);
    final isGranted = await _permissionService.requestStoragePermission();
    state = state
        .copyWith(isLoading: false)
        .updatePermissionStatus(
          'storage',
          isGranted ? PermissionStatus.granted : PermissionStatus.denied,
        );
  }

  /// Requests sensor permission
  Future<void> requestSensorPermission() async {
    state = state.copyWith(isLoading: true);
    final isGranted = await _permissionService.requestSensorPermission();
    state = state
        .copyWith(isLoading: false)
        .updatePermissionStatus(
          'sensor',
          isGranted ? PermissionStatus.granted : PermissionStatus.denied,
        );
  }

  /// Requests all permissions
  Future<void> requestAllPermissions() async {
    await requestCameraPermission();
    await requestStoragePermission();
    await requestSensorPermission();
  }

  /// Opens app settings
  Future<void> openAppSettings() async {
    await _permissionService.openAppSettings();
  }

  /// Checks if all required permissions are granted
  bool get areAllPermissionsGranted {
    return state.permissionStatuses['camera'] == PermissionStatus.granted &&
        state.permissionStatuses['storage'] == PermissionStatus.granted &&
        state.permissionStatuses['sensor'] == PermissionStatus.granted;
  }

  /// Checks if any permission is permanently denied
  bool get isAnyPermissionPermanentlyDenied {
    return state.permissionStatuses.values.any(
      (status) => status == PermissionStatus.permanentlyDenied,
    );
  }
}

/// Factory provider for OnboardingNotifier
final onboardingNotifierProvider = Provider<OnboardingNotifier>((ref) {
  // Get the permission service
  final permissionService = ref.watch(permissionServiceProvider);

  // Use a dummy preferences service initially
  final dummyPreferences = _DummyPreferencesService();

  // Create and return the notifier
  return OnboardingNotifier(permissionService, dummyPreferences);
});

/// Provider for OnboardingState, depending on the preferences service being initialized
final onboardingStateProvider = FutureProvider<
  StateNotifierProvider<OnboardingNotifier, OnboardingState>
>((ref) async {
  // Get the notifier factory
  final notifierFactory = ref.watch(onboardingNotifierProvider);

  // Get the real preferences service when it's ready
  final preferencesService = await ref.watch(preferencesServiceProvider.future);

  // Create the provider with the real services
  return StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
    return OnboardingNotifier(
      ref.watch(permissionServiceProvider),
      preferencesService,
    );
  });
});

/// A temporary dummy implementation of PreferencesService until the real one is available
class _DummyPreferencesService implements PreferencesService {
  @override
  Future<bool> clear() async => false;

  @override
  Future<bool> containsKey(String key) async => false;

  @override
  Future<bool?> getBool(String key) async => null;

  @override
  Future<double?> getDouble(String key) async => null;

  @override
  Future<int?> getInt(String key) async => null;

  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<List<String>?> getStringList(String key) async => null;

  @override
  Future<bool> remove(String key) async => false;

  @override
  Future<bool> setBool(String key, bool value) async => false;

  @override
  Future<bool> setDouble(String key, double value) async => false;

  @override
  Future<bool> setInt(String key, int value) async => false;

  @override
  Future<bool> setString(String key, String value) async => false;

  @override
  Future<bool> setStringList(String key, List<String> value) async => false;
}
