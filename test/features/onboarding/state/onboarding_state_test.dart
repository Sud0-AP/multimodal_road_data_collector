import 'package:flutter_test/flutter_test.dart';
import 'package:multimodal_road_data_collector/features/onboarding/presentation/state/onboarding_state.dart';

void main() {
  group('OnboardingState', () {
    test('default constructor initializes with correct default values', () {
      final state = OnboardingState();

      expect(state.currentPage, 0);
      expect(state.isLoading, false);
      expect(state.isComplete, false);
      expect(state.permissionStatuses, {
        'camera': PermissionStatus.initial,
        'storage': PermissionStatus.initial,
        'sensor': PermissionStatus.initial,
      });
    });

    test('copyWith creates a new instance with updated values', () {
      final initialState = OnboardingState();
      final updatedState = initialState.copyWith(
        currentPage: 2,
        isLoading: true,
        isComplete: true,
      );

      // Original state should remain unchanged
      expect(initialState.currentPage, 0);
      expect(initialState.isLoading, false);
      expect(initialState.isComplete, false);

      // New state should have updated values
      expect(updatedState.currentPage, 2);
      expect(updatedState.isLoading, true);
      expect(updatedState.isComplete, true);
      // Permissions should be carried over
      expect(updatedState.permissionStatuses, initialState.permissionStatuses);
    });

    test(
      'updatePermissionStatus creates a new instance with updated permission',
      () {
        final initialState = OnboardingState();
        final updatedState = initialState.updatePermissionStatus(
          'camera',
          PermissionStatus.granted,
        );

        // Original state should remain unchanged
        expect(
          initialState.permissionStatuses['camera'],
          PermissionStatus.initial,
        );

        // New state should have updated permission
        expect(
          updatedState.permissionStatuses['camera'],
          PermissionStatus.granted,
        );
        expect(
          updatedState.permissionStatuses['storage'],
          PermissionStatus.initial,
        );
        expect(
          updatedState.permissionStatuses['sensor'],
          PermissionStatus.initial,
        );

        // Other values should remain the same
        expect(updatedState.currentPage, initialState.currentPage);
        expect(updatedState.isLoading, initialState.isLoading);
        expect(updatedState.isComplete, initialState.isComplete);
      },
    );

    test('multiple permission updates accumulate correctly', () {
      final initialState = OnboardingState();
      final firstUpdate = initialState.updatePermissionStatus(
        'camera',
        PermissionStatus.granted,
      );
      final secondUpdate = firstUpdate.updatePermissionStatus(
        'storage',
        PermissionStatus.denied,
      );

      expect(
        secondUpdate.permissionStatuses['camera'],
        PermissionStatus.granted,
      );
      expect(
        secondUpdate.permissionStatuses['storage'],
        PermissionStatus.denied,
      );
      expect(
        secondUpdate.permissionStatuses['sensor'],
        PermissionStatus.initial,
      );
    });
  });
}
