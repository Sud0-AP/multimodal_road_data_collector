import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../constants/app_constants.dart';
import '../state/providers.dart';

/// Screen for adjusting app settings
class SettingsScreen extends ConsumerWidget {
  /// Route name for the settings screen
  static const routeName = '/settings';

  /// Creates a new [SettingsScreen]
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    // Get the notifier to update settings
    final notifier = ref.watch(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            _buildSectionHeader(context, 'Bump Detection Settings'),
            _buildBumpThresholdMultiplierSlider(
              context,
              settings.bumpThresholdMultiplier,
              settings.isSaving,
              (value) => notifier.updateBumpThresholdMultiplier(value),
            ),
            const SizedBox(height: 24),

            _buildSectionHeader(context, 'Calibration'),
            _buildRecalibrateButton(context),
            const SizedBox(height: 24),

            // Show success or error messages
            if (settings.successMessage != null)
              _buildMessageCard(
                context,
                settings.successMessage!,
                Colors.green.shade100,
                Icons.check_circle,
                Colors.green,
                () => notifier.clearMessages(),
              ),

            if (settings.errorMessage != null)
              _buildMessageCard(
                context,
                settings.errorMessage!,
                Colors.red.shade100,
                Icons.error,
                Colors.red,
                () => notifier.clearMessages(),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a section header with a given title
  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge),
    );
  }

  /// Builds the slider for adjusting the bump threshold multiplier
  Widget _buildBumpThresholdMultiplierSlider(
    BuildContext context,
    double value,
    bool isLoading,
    Function(double) onChanged,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Bump Detection Sensitivity',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Adjust how sensitive the app is to detecting bumps. '
              'Higher values make the app more sensitive to detecting bumps.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Less Sensitive'),
                Expanded(
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
                const Text('More Sensitive'),
              ],
            ),
            Center(
              child: Text(
                'Current Value: ${value.toStringAsFixed(1)}',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the button to re-trigger initial calibration
  Widget _buildRecalibrateButton(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Initial Static Calibration',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Re-run the initial static calibration if you think the sensor readings '
              'are no longer accurate or if you want to use a different device orientation.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text('Recalibrate Sensors?'),
                          content: const Text(
                            'This will clear your current calibration data and '
                            'start a new calibration process. Do you want to continue?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();

                                // Navigate to the onboarding screen which will start
                                // the calibration process
                                GoRouter.of(context).go('/onboarding');
                              },
                              child: const Text('Recalibrate'),
                            ),
                          ],
                        ),
                  );
                },
                icon: const Icon(Icons.sensors),
                label: const Text('Recalibrate Sensors'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a message card for displaying success or error messages
  Widget _buildMessageCard(
    BuildContext context,
    String message,
    Color backgroundColor,
    IconData icon,
    Color iconColor,
    VoidCallback onDismiss,
  ) {
    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
            IconButton(icon: const Icon(Icons.close), onPressed: onDismiss),
          ],
        ),
      ),
    );
  }
}
