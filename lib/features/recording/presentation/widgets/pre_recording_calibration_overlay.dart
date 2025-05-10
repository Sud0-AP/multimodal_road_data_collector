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

    return Container(
      color: Colors.black.withOpacity(0.7),
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pre-Recording Calibration',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                state.statusMessage,
                style: const TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: state.progress,
                backgroundColor: Colors.grey[700],
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).colorScheme.primary,
                ),
                minHeight: 10,
                borderRadius: BorderRadius.circular(5),
              ),
              const SizedBox(height: 20),
              const Text(
                'Drive smoothly on a level surface for 20 seconds',
                style: TextStyle(color: Colors.white70, fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              const Text(
                'This helps establish baseline sensor readings and bump detection threshold',
                style: TextStyle(color: Colors.white70, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              if (state.status == PreRecordingCalibrationStatus.failed) ...[
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    ref.read(preRecordingCalibrationProvider.notifier).reset();
                    ref
                        .read(preRecordingCalibrationProvider.notifier)
                        .startCalibration();
                  },
                  child: const Text('Retry Calibration'),
                ),
                TextButton(
                  onPressed: onCalibrationFailed,
                  child: const Text('Cancel'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
