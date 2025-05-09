import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/calibration_provider.dart';
import '../state/calibration_state.dart';
import '../../domain/models/initial_calibration_data.dart';
import '../../data/repositories/providers.dart';
import '../../../../core/services/providers.dart';
import '../../../../app/router.dart';

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
  // For animations
  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  // Local state for calibration
  bool _isCalibrating = false;
  bool _isComplete = false;
  double _progress = 0.0;
  String _statusMessage =
      'Place your device in the mount and keep it still to begin calibration';
  bool _movementDetected = false;
  DeviceOrientation _orientation = DeviceOrientation.unknown;
  InitialCalibrationData? _calibrationData;

  // Repository initialization state
  bool _isRepositoryReady = false;
  bool _isInitializing = true;
  String _initializationError = '';

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

    // Set calibration flags
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calibrationInProgressProvider.notifier).state = true;
      ref.read(calibrationCompletedProvider.notifier).state = false;

      // Initialize the calibration repository
      _initializeRepository();
    });
  }

  // Initialize the repository before allowing calibration to start
  Future<void> _initializeRepository() async {
    setState(() {
      _isInitializing = true;
      _initializationError = '';
    });

    try {
      // Pre-initialize the repository
      final repositoryAsyncValue = await ref.read(
        calibrationRepositoryAsyncProvider.future,
      );

      setState(() {
        _isRepositoryReady = true;
        _isInitializing = false;

        // Check for existing calibration data
        _checkForExistingCalibrationData(repositoryAsyncValue);
      });
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _isRepositoryReady = false;
        _initializationError =
            'Failed to initialize calibration storage: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Repository initialization error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Check if we have existing calibration data
  Future<void> _checkForExistingCalibrationData(dynamic repository) async {
    try {
      final hasData = await repository.hasInitialCalibrationData();

      if (hasData) {
        final data = await repository.loadInitialCalibrationData();
        if (data != null) {
          setState(() {
            _calibrationData = data;
            _orientation = data.deviceOrientation;
            _statusMessage = 'Previous calibration data loaded.';
          });
        }
      }
    } catch (e) {
      print('Error checking existing calibration data: $e');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // Start the actual calibration process
  void _startCalibration() async {
    // Don't allow starting calibration if the repository isn't ready
    if (!_isRepositoryReady) {
      setState(() {
        _statusMessage = 'Cannot start calibration: storage not initialized';
      });
      return;
    }

    // Always completely reset the state when starting a new calibration
    setState(() {
      _isCalibrating = true;
      _progress = 0.0;
      _statusMessage = 'Starting calibration...';
      _movementDetected = false;
      _orientation = DeviceOrientation.unknown;
      _isComplete = false; // Explicitly reset completion flag
      _calibrationData = null; // Clear any previous calibration data
    });

    try {
      // Wait for the repository to be available
      final repositoryAsyncValue = await ref.read(
        calibrationRepositoryAsyncProvider.future,
      );

      // Create a calibration notifier manually
      final sensorService = ref.read(sensorServiceProvider);
      final calibrationNotifier = CalibrationNotifier(
        calibrationRepository: repositoryAsyncValue,
        sensorService: sensorService,
      );

      // Listen for state changes
      final subscription = calibrationNotifier.stream.listen((state) {
        if (mounted) {
          setState(() {
            _progress = state.calibrationProgress;
            _statusMessage = state.statusMessage;
            _movementDetected = state.movementDetected;
            _orientation = state.deviceOrientation;
            _isComplete = state.isCalibrationComplete;
            _calibrationData = state.calibrationData;
            _isCalibrating = state.isCalibrating;

            // If movement was detected and calibration was stopped, we need to handle that
            if (state.movementDetected &&
                !state.isCalibrating &&
                !state.isCalibrationComplete) {
              _isCalibrating = false;
              _progress = 0.0;
              _statusMessage = 'Excessive movement detected. Please try again.';
            }

            // If calibration is complete, make sure we save the data
            if (state.isCalibrationComplete && state.calibrationData != null) {
              _calibrationData = state.calibrationData;
              _isComplete = true;
              _progress = 1.0;

              // Print debug info about the calibration data
              print('Calibration complete with data: ${state.calibrationData}');

              // Set flags in the provider
              ref.read(calibrationInProgressProvider.notifier).state = false;
              ref.read(calibrationCompletedProvider.notifier).state = true;

              // Force UI update to show completion state
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted) {
                  setState(() {
                    _isCalibrating = false;
                    _isComplete = true;
                    _progress = 1.0;
                  });
                }
              });
            }
          });
        }
      });

      // Start the calibration process
      await calibrationNotifier.startCalibration();

      // Clean up
      subscription.cancel();
    } catch (e) {
      setState(() {
        _isCalibrating = false;
        _statusMessage = 'Calibration error: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Calibration error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cancel the calibration process
  void _cancelCalibration() {
    setState(() {
      _isCalibrating = false;
      _progress = 0.0;
      _statusMessage = 'Calibration cancelled';
    });
  }

  // Format calibration data for display
  String _formatCalibrationData(InitialCalibrationData data) {
    String formattedString = '';

    formattedString +=
        'Orientation: ${_orientationToString(data.deviceOrientation)}\n\n';
    formattedString += 'Accelerometer Offsets (m/s²):\n';
    formattedString += '  X: ${data.accelerometerXOffset.toStringAsFixed(4)}\n';
    formattedString += '  Y: ${data.accelerometerYOffset.toStringAsFixed(4)}\n';
    formattedString +=
        '  Z: ${data.accelerometerZOffset.toStringAsFixed(4)}\n\n';
    formattedString += 'Gyroscope Offsets (rad/s):\n';
    formattedString += '  X: ${data.gyroscopeXOffset.toStringAsFixed(4)}\n';
    formattedString += '  Y: ${data.gyroscopeYOffset.toStringAsFixed(4)}\n';
    formattedString += '  Z: ${data.gyroscopeZOffset.toStringAsFixed(4)}\n';
    formattedString +=
        '\nCalibration Timestamp: ${DateTime.fromMillisecondsSinceEpoch(data.calibrationTimestamp).toString()}';

    return formattedString;
  }

  // Get the current phase of calibration based on progress
  String _getCurrentPhase(double progress) {
    if (progress < 0.1) {
      return 'Ready to calibrate';
    } else if (progress < 0.3) {
      return 'Phase 1: Orientation Detection';
    } else if (progress < 0.9) {
      return 'Phase 2: Sensor Offset Calibration';
    } else if (progress < 1.0) {
      return 'Phase 3: Finalizing & Saving';
    } else {
      return 'Calibration Complete';
    }
  }

  // Helper method to convert orientation enum to user-friendly string
  String _orientationToString(DeviceOrientation orientation) {
    switch (orientation) {
      case DeviceOrientation.portrait:
        return 'Portrait';
      case DeviceOrientation.landscapeRight:
        return 'Landscape Right';
      case DeviceOrientation.landscapeLeft:
        return 'Landscape Left';
      case DeviceOrientation.flat:
        return 'Flat (screen up)';
      case DeviceOrientation.unknown:
      default:
        return 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use local state variables instead of provider state
    final bool isCalibrating = _isCalibrating;
    final bool isComplete = _isComplete;
    final double progress = _progress;
    final String statusMessage = _statusMessage;
    final bool movementDetected = _movementDetected;
    final InitialCalibrationData? calibrationData = _calibrationData;
    final DeviceOrientation orientation = _orientation;

    final currentPhase = _getCurrentPhase(progress);

    return Scaffold(
      // Removed AppBar entirely to eliminate the "slab" at the top
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child:
                _isInitializing
                    ? _buildInitializingView(theme)
                    : !_isRepositoryReady && _initializationError.isNotEmpty
                    ? _buildErrorView(theme)
                    : SingleChildScrollView(
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
                                color: theme.colorScheme.onSurface.withOpacity(
                                  0.8,
                                ),
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
                                          color:
                                              theme
                                                  .colorScheme
                                                  .secondaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.info_outline,
                                          color:
                                              theme
                                                  .colorScheme
                                                  .onSecondaryContainer,
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
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.8),
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
                                          color:
                                              theme
                                                  .colorScheme
                                                  .primaryContainer,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.pending_actions,
                                          color:
                                              theme
                                                  .colorScheme
                                                  .onPrimaryContainer,
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
                                          isCalibrating
                                              ? theme
                                                  .colorScheme
                                                  .tertiaryContainer
                                                  .withOpacity(0.3)
                                              : isComplete
                                              ? theme
                                                  .colorScheme
                                                  .primaryContainer
                                                  .withOpacity(0.3)
                                              : movementDetected
                                              ? theme.colorScheme.errorContainer
                                                  .withOpacity(0.3)
                                              : theme.colorScheme.surfaceVariant
                                                  .withOpacity(0.3),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            isCalibrating
                                                ? theme.colorScheme.tertiary
                                                    .withOpacity(0.5)
                                                : isComplete
                                                ? theme.colorScheme.primary
                                                    .withOpacity(0.5)
                                                : movementDetected
                                                ? theme.colorScheme.error
                                                    .withOpacity(0.5)
                                                : theme.colorScheme.outline
                                                    .withOpacity(0.2),
                                      ),
                                    ),
                                    child: Text(
                                      statusMessage,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                        color:
                                            movementDetected
                                                ? theme.colorScheme.error
                                                : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),

                                  // Current phase indicator
                                  if (isCalibrating || isComplete)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Current Phase:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: theme
                                                  .colorScheme
                                                  .primaryContainer
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: theme.colorScheme.primary
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              currentPhase,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onPrimaryContainer,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Display detected orientation if available
                                  if (orientation != DeviceOrientation.unknown)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Detected Orientation:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: theme
                                                  .colorScheme
                                                  .secondaryContainer
                                                  .withOpacity(0.5),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              _orientationToString(orientation),
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onSecondaryContainer,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // Display calibration data if available and complete
                                  if (calibrationData != null &&
                                      (isComplete || !isCalibrating))
                                    Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Calibration Results:',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  theme.colorScheme.onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: theme
                                                  .colorScheme
                                                  .tertiaryContainer
                                                  .withOpacity(0.3),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: theme
                                                    .colorScheme
                                                    .tertiary
                                                    .withOpacity(0.3),
                                              ),
                                            ),
                                            child: Text(
                                              _formatCalibrationData(
                                                calibrationData,
                                              ),
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w500,
                                                color:
                                                    theme
                                                        .colorScheme
                                                        .onTertiaryContainer,
                                                height: 1.4,
                                              ),
                                            ),
                                          ),
                                        ],
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
                                  // Linear progress indicator
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              child: Stack(
                                                children: [
                                                  // Background
                                                  Container(
                                                    height: 10,
                                                    color:
                                                        theme
                                                            .colorScheme
                                                            .surfaceVariant,
                                                  ),
                                                  // Progress
                                                  TweenAnimationBuilder<double>(
                                                    // Use TweenAnimationBuilder for smoother progress transitions
                                                    duration: const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                    tween: Tween<double>(
                                                      begin: 0.0,
                                                      end: _progress.clamp(
                                                        0.0,
                                                        1.0,
                                                      ), // Clamp to ensure valid range
                                                    ),
                                                    builder:
                                                        (
                                                          context,
                                                          animatedProgress,
                                                          _,
                                                        ) => Container(
                                                          height: 10,
                                                          width:
                                                              MediaQuery.of(
                                                                context,
                                                              ).size.width *
                                                              0.8 *
                                                              animatedProgress,
                                                          color:
                                                              isComplete
                                                                  ? theme
                                                                      .colorScheme
                                                                      .primary
                                                                  : movementDetected
                                                                  ? theme
                                                                      .colorScheme
                                                                      .error
                                                                  : theme
                                                                      .colorScheme
                                                                      .tertiary,
                                                        ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                          // Progress percentage
                                          Container(
                                            margin: const EdgeInsets.only(
                                              left: 8,
                                            ),
                                            child: Text(
                                              // Clamp progress to 100% for the UI display
                                              '${(_progress.clamp(0.0, 1.0) * 100).toInt()}%',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color:
                                                    isComplete
                                                        ? theme
                                                            .colorScheme
                                                            .primary
                                                        : movementDetected
                                                        ? theme
                                                            .colorScheme
                                                            .error
                                                        : theme
                                                            .colorScheme
                                                            .tertiary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (_isComplete &&
                                          _calibrationData != null)
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 8.0,
                                          ),
                                          child: Text(
                                            'Calibration complete!',
                                            style: TextStyle(
                                              color: theme.colorScheme.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                    ],
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
                                    _isRepositoryReady
                                        ? (isCalibrating
                                            ? () =>
                                                _cancelCalibration() // Cancel during calibration
                                            : isComplete
                                            ? () {
                                              // Mark calibration as complete in providers
                                              ref
                                                  .read(
                                                    calibrationCompletedProvider
                                                        .notifier,
                                                  )
                                                  .state = true;

                                              // Navigate to home screen
                                              if (context.mounted) {
                                                context.go(AppRoutes.homePath);
                                              }
                                            } // Go to home when complete
                                            : movementDetected
                                            ? () =>
                                                _startCalibration() // Re-calibrate when movement detected
                                            : () =>
                                                _startCalibration()) // Start calibration
                                        : null, // Disable button if repository isn't ready
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      isCalibrating
                                          ? Colors
                                              .redAccent // Red for cancel
                                          : movementDetected && !isComplete
                                          ? Colors
                                              .orange // Orange for re-calibrate
                                          : theme
                                              .colorScheme
                                              .primary, // Default color
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(23),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10.0,
                                  ),
                                ),
                                child:
                                    isCalibrating
                                        ? const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Cancel',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        )
                                        : Text(
                                          isComplete
                                              ? 'Done'
                                              : movementDetected
                                              ? 'Re-Calibrate'
                                              : 'Start Calibration',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                              ),
                            ),
                          ),

                          // Retry initialization button if there was an error
                          if (!_isRepositoryReady &&
                              _initializationError.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: TextButton(
                                onPressed: _initializeRepository,
                                child: const Text('Retry Initialization'),
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

  // Loading view shown during repository initialization
  Widget _buildInitializingView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: theme.colorScheme.primary),
          const SizedBox(height: 24),
          Text(
            'Initializing calibration storage...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  // Error view shown if repository initialization fails
  Widget _buildErrorView(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Storage Initialization Error',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.error,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _initializationError,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _initializeRepository,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
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
