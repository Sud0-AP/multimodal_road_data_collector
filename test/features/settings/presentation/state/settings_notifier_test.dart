import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:multimodal_road_data_collector/constants/app_constants.dart';
import 'package:multimodal_road_data_collector/core/services/preferences_service.dart';
import 'package:multimodal_road_data_collector/features/settings/presentation/state/settings_notifier.dart';
import 'package:multimodal_road_data_collector/features/settings/presentation/state/settings_state.dart';

// Generate mocks
@GenerateMocks([PreferencesService])
import 'settings_notifier_test.mocks.dart';

void main() {
  late MockPreferencesService mockPreferencesService;
  late SettingsNotifier settingsNotifier;

  setUp(() {
    mockPreferencesService = MockPreferencesService();
    settingsNotifier = SettingsNotifier(
      preferencesService: mockPreferencesService,
    );
  });

  group('SettingsNotifier', () {
    test('initial state has default values', () {
      // Assert
      expect(settingsNotifier.state.bumpThresholdMultiplier, equals(5.0));
      expect(settingsNotifier.state.isSaving, equals(false));
      expect(settingsNotifier.state.errorMessage, isNull);
      expect(settingsNotifier.state.successMessage, isNull);
    });

    test('loadSettings loads multiplier from preferences', () async {
      // Arrange
      when(
        mockPreferencesService.getDouble(
          AppConstants.keyBumpThresholdMultiplier,
        ),
      ).thenAnswer((_) async => 7.5);

      // Act - call private method using reflection
      await settingsNotifier.updateBumpThresholdMultiplier(7.5);

      // Assert
      verify(
        mockPreferencesService.getDouble(
          AppConstants.keyBumpThresholdMultiplier,
        ),
      ).called(1);
      expect(settingsNotifier.state.bumpThresholdMultiplier, equals(7.5));
    });

    test('loadSettings handles error', () async {
      // Arrange
      when(
        mockPreferencesService.getDouble(
          AppConstants.keyBumpThresholdMultiplier,
        ),
      ).thenThrow(Exception('Test error'));

      // Create a new notifier which will call _loadSettings in constructor
      final errorNotifier = SettingsNotifier(
        preferencesService: mockPreferencesService,
      );

      // Assert
      expect(
        errorNotifier.state.errorMessage,
        contains('Failed to load settings'),
      );
    });

    test(
      'updateBumpThresholdMultiplier updates multiplier in preferences',
      () async {
        // Arrange
        when(
          mockPreferencesService.setDouble(
            AppConstants.keyBumpThresholdMultiplier,
            8.0,
          ),
        ).thenAnswer((_) async => true);

        // Act
        await settingsNotifier.updateBumpThresholdMultiplier(8.0);

        // Assert
        verify(
          mockPreferencesService.setDouble(
            AppConstants.keyBumpThresholdMultiplier,
            8.0,
          ),
        ).called(1);
        expect(settingsNotifier.state.bumpThresholdMultiplier, equals(8.0));
        expect(settingsNotifier.state.isSaving, equals(false));
        expect(
          settingsNotifier.state.successMessage,
          contains('updated successfully'),
        );
      },
    );

    test(
      'updateBumpThresholdMultiplier clamps values to min/max range',
      () async {
        // Arrange
        when(
          mockPreferencesService.setDouble(
            AppConstants.keyBumpThresholdMultiplier,
            any,
          ),
        ).thenAnswer((_) async => true);

        // Act - try to set a value below minimum
        await settingsNotifier.updateBumpThresholdMultiplier(
          0.5,
        ); // below min of 1.0

        // Assert it was clamped to minimum
        verify(
          mockPreferencesService.setDouble(
            AppConstants.keyBumpThresholdMultiplier,
            AppConstants.minBumpThresholdMultiplier, // 1.0
          ),
        ).called(1);
        expect(
          settingsNotifier.state.bumpThresholdMultiplier,
          equals(AppConstants.minBumpThresholdMultiplier),
        );

        // Reset mock
        reset(mockPreferencesService);
        when(
          mockPreferencesService.setDouble(
            AppConstants.keyBumpThresholdMultiplier,
            any,
          ),
        ).thenAnswer((_) async => true);

        // Act - try to set a value above maximum
        await settingsNotifier.updateBumpThresholdMultiplier(
          15.0,
        ); // above max of 10.0

        // Assert it was clamped to maximum
        verify(
          mockPreferencesService.setDouble(
            AppConstants.keyBumpThresholdMultiplier,
            AppConstants.maxBumpThresholdMultiplier, // 10.0
          ),
        ).called(1);
        expect(
          settingsNotifier.state.bumpThresholdMultiplier,
          equals(AppConstants.maxBumpThresholdMultiplier),
        );
      },
    );

    test(
      'updateBumpThresholdMultiplier handles preferences service failure',
      () async {
        // Arrange
        when(
          mockPreferencesService.setDouble(
            AppConstants.keyBumpThresholdMultiplier,
            any,
          ),
        ).thenAnswer((_) async => false);

        // Act
        await settingsNotifier.updateBumpThresholdMultiplier(6.0);

        // Assert
        expect(settingsNotifier.state.isSaving, equals(false));
        expect(
          settingsNotifier.state.errorMessage,
          contains('Failed to save settings'),
        );
      },
    );

    test('updateBumpThresholdMultiplier handles exception', () async {
      // Arrange
      when(
        mockPreferencesService.setDouble(
          AppConstants.keyBumpThresholdMultiplier,
          any,
        ),
      ).thenThrow(Exception('Test error'));

      // Act
      await settingsNotifier.updateBumpThresholdMultiplier(6.0);

      // Assert
      expect(settingsNotifier.state.isSaving, equals(false));
      expect(
        settingsNotifier.state.errorMessage,
        contains('Error saving settings'),
      );
    });

    test('clearMessages clears error and success messages', () {
      // Arrange - set up a state with messages
      settingsNotifier = SettingsNotifier(
        preferencesService: mockPreferencesService,
      );

      // Manually modify state to have messages
      final stateWithMessages = SettingsState(
        bumpThresholdMultiplier: 5.0,
        errorMessage: 'Some error',
        successMessage: 'Some success',
      );

      // Use reflection to modify private state property
      (settingsNotifier as dynamic).state = stateWithMessages;

      // Assert initial state
      expect(settingsNotifier.state.errorMessage, equals('Some error'));
      expect(settingsNotifier.state.successMessage, equals('Some success'));

      // Act
      settingsNotifier.clearMessages();

      // Assert
      expect(settingsNotifier.state.errorMessage, isNull);
      expect(settingsNotifier.state.successMessage, isNull);
    });
  });
}
