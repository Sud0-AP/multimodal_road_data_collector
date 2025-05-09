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
    extends ConsumerState<InitialCalibrationScreen>
    with SingleTickerProviderStateMixin {
  // These will be connected to providers in a later integration task
  bool _isCalibrating = false;
  bool _isComplete = false;
  double _progress = 0.0;
  String _statusMessage =
      'Step 1/2: Phone Orientation. Place phone still in mount.';

  // For animations
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Set up animation controller for visual effects
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _fadeAnimation = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    // Use a post-frame callback to safely update providers after the widget tree is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calibrationInProgressProvider.notifier).state = true;
      ref.read(calibrationCompletedProvider.notifier).state = false;
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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
    final theme = Theme.of(context);

    return Scaffold(
      // Removed AppBar entirely to eliminate the "slab" at the top
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Title with gradient text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: ShaderMask(
                      blendMode: BlendMode.srcIn,
                      shaderCallback:
                          (bounds) => LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.tertiary,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ).createShader(bounds),
                      child: const Text(
                        'Sensor Calibration',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                  // Subtitle text
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Text(
                      'Required for accurate data collection',
                      style: TextStyle(
                        fontSize: 16,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Instruction Card with vehicle mounting instructions
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.secondaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.onSecondaryContainer,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Instructions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'This calibration process is required on every app launch to ensure accurate data collection.',
                            style: TextStyle(
                              fontSize: 16,
                              color: theme.colorScheme.onSurface.withOpacity(
                                0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Phone in landscape orientation
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.tertiaryContainer
                                  .withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Transform.rotate(
                                angle:
                                    90 *
                                    3.14159 /
                                    180, // 90 degrees in radians (landscape orientation)
                                child: Icon(
                                  Icons.phone_android,
                                  size: 64,
                                  color: theme.colorScheme.tertiary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Styled instruction list
                          _buildInstructionItem(
                            context,
                            '1. Place phone securely in the dashboard mount',
                          ),
                          _buildInstructionItem(
                            context,
                            '2. Ensure the phone remains perfectly still during calibration',
                          ),
                          _buildInstructionItem(
                            context,
                            '3. The process will take about 15 seconds',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status and Progress Section
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.pending_actions,
                                  color: theme.colorScheme.onPrimaryContainer,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Status',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  _isCalibrating
                                      ? theme.colorScheme.tertiaryContainer
                                          .withOpacity(0.3)
                                      : _isComplete
                                      ? theme.colorScheme.primaryContainer
                                          .withOpacity(0.3)
                                      : theme.colorScheme.surfaceVariant
                                          .withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color:
                                    _isCalibrating
                                        ? theme.colorScheme.tertiary
                                            .withOpacity(0.5)
                                        : _isComplete
                                        ? theme.colorScheme.primary.withOpacity(
                                          0.5,
                                        )
                                        : theme.colorScheme.outline.withOpacity(
                                          0.2,
                                        ),
                              ),
                            ),
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                          Text(
                            'Progress',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              value: _progress,
                              minHeight: 10,
                              backgroundColor: theme.colorScheme.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                _isComplete
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.tertiary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Center(
                            child: Text(
                              '${(_progress * 100).toInt()}%',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Action Button styled like onboarding
                  Center(
                    child: SizedBox(
                      width: 180,
                      height: 46,
                      child: ElevatedButton(
                        onPressed:
                            _isCalibrating
                                ? null // Disable during calibration
                                : _isComplete
                                ? () =>
                                    Navigator.of(context)
                                        .pop() // Go back when complete
                                : _startCalibration, // Start calibration
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(23),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 10.0),
                        ),
                        child:
                            _isCalibrating
                                ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(
                                  _isComplete ? 'Done' : 'Start Calibration',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInstructionItem(BuildContext context, String instruction) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: theme.colorScheme.primary,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              instruction,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
