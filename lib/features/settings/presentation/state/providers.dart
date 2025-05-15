import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/services/preferences_service.dart';
import '../../../../core/services/providers.dart';
import 'settings_notifier.dart';
import 'settings_state.dart';

/// Provider for the resolved preferences service
final resolvedPreferencesServiceProvider = Provider<PreferencesService>(
  (ref) => ref.watch(preferencesServiceProvider).value!,
);

/// Provider for the settings state notifier
final settingsProvider = StateNotifierProvider<SettingsNotifier, SettingsState>(
  (ref) => SettingsNotifier(
    preferencesService: ref.watch(resolvedPreferencesServiceProvider),
    loggerService: ref.watch(loggerServiceProvider),
  ),
);
