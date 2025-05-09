import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/calibration_provider.dart';

/// A screen that guides the user through the initial static calibration process.
///
/// This screen provides instructions, displays progress, and shows status messages
/// to help users properly calibrate the device's sensors.
class InitialCalibrationScreen extends ConsumerStatefulWidget {
  /// Creates a new [InitialCalibrationScreen].
  const InitialCalibrationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InitialCalibrationScreen> createState() =>
      _InitialCalibrationScreenState();
}

class _InitialCalibrationScreenState
    extends ConsumerState<InitialCalibrationScreen> {
  // These will be connected to providers in a later integration task
  bool _isCalibrating = false;
  bool _isComplete = false;
  double _progress = 0.0;
  String _statusMessage =
      'Step 1/2: Phone Orientation. Place phone still in mount.';

  @override
  void initState() {
    super.initState();
    // Use a post-frame callback to safely update providers after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calibrationInProgressProvider.notifier).state = true;
      ref.read(calibrationCompletedProvider.notifier).state = false;
    });
  }

  // Mock the calibration process for UI demonstration
  void _startCalibration() {
    setState(() {
      _isCalibrating = true;
      _progress = 0.0;
      _statusMessage = 'Step 1/2: Detecting phone orientation...';
    });

    // Simulate Step 1: Orientation detection (1s)
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _progress = 0.3;
        _statusMessage = 'Step 2/2: Calibrating sensor offsets...';
      });

      // Simulate Step 2: Sensor offset calibration (15s)
      Future.delayed(const Duration(seconds: 5), () {
        // Using 5s for demo instead of 15s
        if (!mounted) return;
        setState(() {
          _progress = 1.0;
          _statusMessage = 'Calibration Complete!';
          _isCalibrating = false;
          _isComplete = true;
        });

        // Mark calibration as completed for this session
        ref.read(calibrationInProgressProvider.notifier).state = false;
        ref.read(calibrationCompletedProvider.notifier).state = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Initial Calibration'),
        centerTitle: true,
        // Disable back button since calibration is mandatory
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Instruction Card with vehicle mounting instructions
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Instructions',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'This calibration process is required on every app launch to ensure accurate data collection.',
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      // Add an image placeholder for mounting instructions
                      Container(
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.phone_android,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        '1. Place phone securely in the dashboard mount\n'
                        '2. Ensure the phone remains perfectly still during calibration\n'
                        '3. The process will take about 15 seconds',
                        style: TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status and Progress Section
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _statusMessage,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _progress,
                        minHeight: 10,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progress * 100).toInt()}%',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Action Button
              ElevatedButton(
                onPressed:
                    _isCalibrating
                        ? null // Disable during calibration
                        : _isComplete
                        ? () =>
                            Navigator.of(context)
                                .pop() // Go back when complete
                        : _startCalibration, // Start calibration
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text(_isComplete ? 'Done' : 'Start Calibration'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
