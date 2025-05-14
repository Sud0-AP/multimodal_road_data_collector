import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../constants/app_constants.dart';
import '../state/providers.dart';

/// Screen for adjusting app settings
class SettingsScreen extends ConsumerWidget {
  /// Route name for the settings screen
  static const routeName = '/settings';

  // Track processed message IDs to prevent duplicates
  static final Set<String> _processedMessageIds = <String>{};

  /// Creates a new [SettingsScreen]
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Get the notifier to update settings
    final notifier = ref.watch(settingsProvider.notifier);

    // Process messages that haven't been shown yet
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Generate a unique ID based on the message content
      final String? successId =
          settings.successMessage != null
              ? 'success:${settings.successMessage}'
              : null;

      final String? errorId =
          settings.errorMessage != null
              ? 'error:${settings.errorMessage}'
              : null;

      // Check if we have a new success message
      if (successId != null && !_processedMessageIds.contains(successId)) {
        // Mark this message as processed
        _processedMessageIds.add(successId);

        // Show success message with app theme colors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    settings.successMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: theme.cardColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            action: SnackBarAction(
              label: 'OK',
              textColor: colorScheme.primary,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Clear the success message
        Future.microtask(() => notifier.clearMessages());
      }
      // Check if we have a new error message
      else if (errorId != null && !_processedMessageIds.contains(errorId)) {
        // Mark this message as processed
        _processedMessageIds.add(errorId);

        // Show error message with app theme colors
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: colorScheme.error),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    settings.errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: theme.cardColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: BorderSide(
                color: colorScheme.error.withOpacity(0.3),
                width: 1,
              ),
            ),
            action: SnackBarAction(
              label: 'OK',
              textColor: colorScheme.error,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
            duration: const Duration(seconds: 2),
          ),
        );

        // Clear the error message
        Future.microtask(() => notifier.clearMessages());
      }
      // Always clear any messages after processing them
      else if (settings.successMessage != null ||
          settings.errorMessage != null) {
        notifier.clearMessages();
      }

      // Cap the size of the processed messages set to prevent memory leaks
      if (_processedMessageIds.length > 100) {
        _processedMessageIds.clear();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          children: [
            _buildSectionHeader(context, 'Bump Detection & Annotation'),
            _buildAnnotationToggle(
              context,
              settings.annotationEnabled,
              settings.isSaving,
              (value) => notifier.updateAnnotationEnabled(value),
            ),
            const SizedBox(height: 12),
            _buildBumpThresholdMultiplierSlider(
              context,
              settings.bumpThresholdMultiplier,
              settings.isSaving,
              (value) => notifier.updateBumpThresholdMultiplier(value),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(context, 'Debugging Options'),
            _buildDebuggingModeToggle(
              context,
              settings.debuggingModeEnabled,
              settings.isSaving,
              (value) => notifier.updateDebuggingModeEnabled(value),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(context, 'Calibration'),
            _buildRecalibrateButton(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Builds a section header with a given title
  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(top: 8.0, bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Divider(
            color: theme.colorScheme.primary.withOpacity(0.2),
            thickness: 1,
          ),
        ],
      ),
    );
  }

  /// Builds a toggle switch for the annotation setting
  Widget _buildAnnotationToggle(
    BuildContext context,
    bool value,
    bool isLoading,
    Function(bool) onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.comment, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Annotation Prompts & Logging',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: colorScheme.primary,
                    ),
                  ),
                const SizedBox(width: 8),
                Switch(
                  value: value,
                  onChanged: isLoading ? null : onChanged,
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'When enabled, annotation prompts appear during recording, and CSVs include the "is pothole" '
              'user feedback column. When disabled, prompts are suppressed, and CSVs log only sensor readings.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    value
                        ? colorScheme.primaryContainer.withOpacity(0.3)
                        : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value ? 'Annotation Prompts: ON' : 'Annotation Prompts: OFF',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      value
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a toggle switch for the debugging mode setting
  Widget _buildDebuggingModeToggle(
    BuildContext context,
    bool value,
    bool isLoading,
    Function(bool) onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.developer_mode, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Debugging Mode',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: colorScheme.primary,
                    ),
                  ),
                const SizedBox(width: 8),
                Switch(
                  value: value,
                  onChanged: isLoading ? null : onChanged,
                  activeColor: colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'When enabled, comprehensive local log files are generated on the device during field data collection. '
              'These logs include timestamps, recording activities, and any errors encountered.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    value
                        ? colorScheme.primaryContainer.withOpacity(0.3)
                        : colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                value ? 'Debug Logging: ON' : 'Debug Logging: OFF',
                style: theme.textTheme.bodySmall?.copyWith(
                  color:
                      value
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the slider for adjusting the bump threshold multiplier
  Widget _buildBumpThresholdMultiplierSlider(
    BuildContext context,
    double value,
    bool isLoading,
    Function(double) onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.speed, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Bump Detection Sensitivity',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (isLoading)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Adjust how sensitive the app is to detecting bumps. '
              'Higher values make the app more sensitive to detecting bumps.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  'Less',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: colorScheme.primary,
                      inactiveTrackColor: colorScheme.primaryContainer,
                      thumbColor: colorScheme.primary,
                      overlayColor: colorScheme.primary.withOpacity(0.2),
                      valueIndicatorColor: colorScheme.primary,
                      valueIndicatorTextStyle: TextStyle(
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    child: Slider(
                      value: value,
                      min: AppConstants.minBumpThresholdMultiplier,
                      max: AppConstants.maxBumpThresholdMultiplier,
                      divisions:
                          ((AppConstants.maxBumpThresholdMultiplier -
                                      AppConstants.minBumpThresholdMultiplier) *
                                  2)
                              .toInt(),
                      label: value.toStringAsFixed(1),
                      onChanged: isLoading ? null : onChanged,
                    ),
                  ),
                ),
                Text(
                  'More',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Current Value: ${value.toStringAsFixed(1)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the button to re-trigger initial calibration
  Widget _buildRecalibrateButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Initial Static Calibration',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Re-run the initial static calibration if you think the sensor readings '
              'are no longer accurate or if you want to use a different device orientation.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          title: Text(
                            'Recalibrate Sensors?',
                            style: TextStyle(color: colorScheme.primary),
                          ),
                          content: const Text(
                            'This will clear your current calibration data and '
                            'start a new calibration process. Do you want to continue?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: Text(
                                'Cancel',
                                style: TextStyle(color: colorScheme.secondary),
                              ),
                            ),
                            FilledButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();

                                // Navigate to the calibration screen directly
                                GoRouter.of(context).go('/calibration');
                              },
                              style: FilledButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                              ),
                              child: const Text('Recalibrate'),
                            ),
                          ],
                        ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.sensors),
                label: const Text('Recalibrate Sensors'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
