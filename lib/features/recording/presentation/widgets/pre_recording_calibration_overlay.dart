import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presentation/state/pre_recording_calibration_state.dart';

/// A widget that displays an overlay during pre-recording calibration
class PreRecordingCalibrationOverlay extends ConsumerWidget {
  /// Callback for when calibration completes
  final Function(
    double sessionAccelOffsetZ,
    double gyroZDrift,
    double bumpThreshold,
  )
  onCalibrationComplete;

  /// Callback for when calibration fails
  final VoidCallback onCalibrationFailed;

  /// Creates a [PreRecordingCalibrationOverlay]
  const PreRecordingCalibrationOverlay({
    super.key,
    required this.onCalibrationComplete,
    required this.onCalibrationFailed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(preRecordingCalibrationProvider);
    final theme = Theme.of(context);
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final screenSize = MediaQuery.of(context).size;

    // Container dimensions based on orientation
    final containerWidth =
        isLandscape
            ? screenSize.width *
                0.6 // Wider in landscape
            : screenSize.width * 0.85;

    // Use specified height for landscape instead of letting it adjust automatically
    final containerHeight =
        isLandscape
            ? screenSize.height *
                0.6 // 60% of screen height in landscape
            : null; // Auto in portrait

    // Start calibration if it's not already in progress or complete
    if (state.status == PreRecordingCalibrationStatus.initial) {
      // Use a post-frame callback to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(preRecordingCalibrationProvider.notifier).startCalibration();
      });
    }

    // Handle calibration completion
    if (state.status == PreRecordingCalibrationStatus.complete &&
        state.result != null) {
      // Use a post-frame callback to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onCalibrationComplete(
          state.result!.sessionAccelOffsetZ,
          state.result!.gyroZDrift,
          state.result!.bumpThreshold,
        );
      });
    }

    // Handle calibration failure
    if (state.status == PreRecordingCalibrationStatus.failed) {
      // Use a post-frame callback to avoid calling during build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onCalibrationFailed();
      });
    }

    return Material(
      // Make sure the Material widget covers the entire screen
      type: MaterialType.transparency,
      child: Container(
        // Add the shadow background across the entire screen
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.7),
        child: SafeArea(
          child: Center(
            child: Container(
              width: containerWidth,
              height: containerHeight,
              constraints:
                  isLandscape ? const BoxConstraints(minHeight: 230) : null,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[850]?.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.7),
                  width: 2.0,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child:
                  isLandscape
                      ? _buildLandscapeLayout(context, state, theme, ref)
                      : _buildPortraitLayout(context, state, theme, ref),
            ),
          ),
        ),
      ),
    );
  }

  /// Build layout for portrait orientation
  Widget _buildPortraitLayout(
    BuildContext context,
    PreRecordingCalibrationState state,
    ThemeData theme,
    WidgetRef ref,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with icon
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sensors_outlined,
              color: theme.colorScheme.primary,
              size: 28,
            ),
            const SizedBox(width: 10),
            const Text(
              'Calibration',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          state.statusMessage,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        LinearProgressIndicator(
          value: state.progress,
          backgroundColor: Colors.grey[700],
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 20),
        const Text(
          'Drive smoothly on a level surface',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        const Text(
          'This helps establish baseline sensor readings and bump detection threshold',
          style: TextStyle(color: Colors.white70, fontSize: 13),
          textAlign: TextAlign.center,
        ),
        if (state.status == PreRecordingCalibrationStatus.failed) ...[
          const SizedBox(height: 20),
          _buildButton(
            label: 'RETRY CALIBRATION',
            backgroundColor: theme.colorScheme.primary,
            onPressed: () {
              ref.read(preRecordingCalibrationProvider.notifier).reset();
              ref
                  .read(preRecordingCalibrationProvider.notifier)
                  .startCalibration();
            },
            icon: Icons.refresh,
          ),
          const SizedBox(height: 12),
          _buildButton(
            label: 'CANCEL',
            backgroundColor: theme.colorScheme.secondary,
            onPressed: onCalibrationFailed,
            icon: Icons.cancel_outlined,
          ),
        ],
      ],
    );
  }

  /// Build layout for landscape orientation
  Widget _buildLandscapeLayout(
    BuildContext context,
    PreRecordingCalibrationState state,
    ThemeData theme,
    WidgetRef ref,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side - Information
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with icon
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.sensors_outlined,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    const Flexible(
                      child: Text(
                        'Calibration',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  state.statusMessage,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                LinearProgressIndicator(
                  value: state.progress,
                  backgroundColor: Colors.grey[700],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.primary,
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Drive smoothly on a level surface',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Right side - Instructions and buttons
        Expanded(
          flex: 5,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'This helps establish baseline sensor readings and detection threshold',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),

                if (state.status == PreRecordingCalibrationStatus.failed) ...[
                  const Spacer(),
                  _buildButton(
                    label: 'RETRY CALIBRATION',
                    backgroundColor: theme.colorScheme.primary,
                    onPressed: () {
                      ref
                          .read(preRecordingCalibrationProvider.notifier)
                          .reset();
                      ref
                          .read(preRecordingCalibrationProvider.notifier)
                          .startCalibration();
                    },
                    icon: Icons.refresh,
                    height: 60,
                  ),
                  const SizedBox(height: 12),
                  _buildButton(
                    label: 'CANCEL',
                    backgroundColor: theme.colorScheme.secondary,
                    onPressed: onCalibrationFailed,
                    icon: Icons.cancel_outlined,
                    height: 60,
                  ),
                  const Spacer(),
                ] else ...[
                  const Spacer(flex: 2),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Helper method to build consistent buttons
  Widget _buildButton({
    required String label,
    required Color backgroundColor,
    required VoidCallback onPressed,
    IconData? icon,
    double? height,
  }) {
    return SizedBox(
      width: double.infinity,
      height: height ?? 48, // Good height for touchability
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: height != null ? 24 : 20),
              const SizedBox(width: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: height != null ? 18 : 15,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
