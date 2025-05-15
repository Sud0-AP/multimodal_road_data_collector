import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:multimodal_road_data_collector/core/services/providers.dart';
import 'package:multimodal_road_data_collector/core/services/sensor_service.dart';
import 'package:multimodal_road_data_collector/core/utils/logger.dart';
import 'package:multimodal_road_data_collector/features/calibration/data/repositories/providers.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/models/initial_calibration_data.dart';
import 'package:multimodal_road_data_collector/features/calibration/domain/utils/calibration_validator.dart';
import 'package:multimodal_road_data_collector/features/calibration/presentation/state/calibration_provider.dart';
import 'package:multimodal_road_data_collector/features/calibration/presentation/state/calibration_state.dart';

import '../../../../app/router.dart';
import '../../domain/utils/calibration_validator.dart';
import '../state/calibration_provider.dart';
import '../state/calibration_state.dart';

/// Initial Calibration Screen for sensor calibration
///
/// This calibration process determines device orientation and sensor offsets
/// which must be performed at least once each time the app is launched.
class InitialCalibrationScreen extends ConsumerStatefulWidget {
  const InitialCalibrationScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<InitialCalibrationScreen> createState() =>
      _InitialCalibrationScreenState();
}

class _InitialCalibrationScreenState
    extends ConsumerState<InitialCalibrationScreen> {
  // Calibration state
  bool _isCalibrating = false;
  bool _isComplete = false;
  bool _forceRecalibration = false;
  String _recalibrationReason = '';
  double _progress = 0.0;
  String _statusMessage =
      'Place your device in the mount and keep it perfectly still.';
  bool _movementDetected = false;
  DeviceOrientation _orientation = DeviceOrientation.unknown;
  InitialCalibrationData? _calibrationData;

  // Repository state
  bool _isRepositoryReady = false;
  bool _isInitializing = true;
  String _initializationError = '';

  // Checking calibration validity
  bool _isCheckingValidity = false;

  // Stream subscription for calibration updates
  StreamSubscription? _calibrationSubscription;

  @override
  void initState() {
    super.initState();

    // Initialize and prepare repository
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calibrationInProgressProvider.notifier).state = true;
      ref.read(calibrationCompletedProvider.notifier).state = false;
      _initializeRepository();
    });
  }

  @override
  void dispose() {
    _cancelCalibrationSubscription();
    super.dispose();
  }

  // Initialize repository for storing calibration data
  Future<void> _initializeRepository() async {
    setState(() {
      _isInitializing = true;
      _initializationError = '';
    });

    try {
      final repository = await ref.read(
        calibrationRepositoryAsyncProvider.future,
      );

      setState(() {
        _isRepositoryReady = true;
        _isInitializing = false;
      });

      // Check for existing calibration data
      await _checkForExistingCalibrationData(repository);
    } catch (e) {
      setState(() {
        _isInitializing = false;
        _isRepositoryReady = false;
        _initializationError = 'Storage initialization failed: ${e.toString()}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not initialize calibration storage: ${e.toString()}',
            ),
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
        // Set state to checking validity
        setState(() {
          _isCheckingValidity = true;
          _statusMessage = 'Checking calibration validity...';
        });

        final data = await repository.loadInitialCalibrationData();
        if (data != null) {
          // Check if recalibration is needed
          final sensorService = ref.read(sensorServiceProvider);
          final recalibrationNeeded =
              await CalibrationValidator.isRecalibrationNeeded(
                data,
                sensorService,
              );

          if (recalibrationNeeded) {
            // Simplified recalibration flow - treat all recalibration reasons the same
            setState(() {
              _forceRecalibration = true;
              _recalibrationReason = 'Recalibration required';
              _statusMessage =
                  'Recalibration required for accurate data collection.';
              _calibrationData = data;
              _orientation = data.deviceOrientation;
              _isCheckingValidity = false;
              _isComplete = false; // Ensure we don't show the Continue button
              _movementDetected =
                  true; // Use same styling as movement detection
            });
          } else {
            // Calibration data is still valid
            setState(() {
              _calibrationData = data;
              _orientation = data.deviceOrientation;
              _statusMessage = 'Previous calibration data loaded and is valid.';
              _isComplete =
                  true; // Mark as complete if we have existing valid data
              _isCheckingValidity = false;
            });
          }
        } else {
          setState(() {
            _isCheckingValidity = false;
          });
        }
      }
    } catch (e) {
      Logger.error(
        'CALIBRATION',
        'Error checking existing calibration data: $e',
      );
      // We don't set an error state here because it's not critical
      // The user can still perform a new calibration
      setState(() {
        _isCheckingValidity = false;
      });
    }
  }

  // Cancel any active subscription
  void _cancelCalibrationSubscription() {
    if (_calibrationSubscription != null) {
      _calibrationSubscription!.cancel();
      _calibrationSubscription = null;
    }
  }

  // Start the calibration process
  Future<void> _startCalibration() async {
    if (!_isRepositoryReady) {
      setState(() {
        _statusMessage = 'Cannot start calibration: storage not initialized';
      });
      return;
    }

    // Cancel any existing subscription
    _cancelCalibrationSubscription();

    // Clear existing calibration data if this is a manual recalibration
    if (_calibrationData != null) {
      try {
        final repository = await ref.read(
          calibrationRepositoryAsyncProvider.future,
        );
        // Force delete existing calibration data
        await repository.clearCalibrationData();
        Logger.info(
          'CALIBRATION',
          'Previous calibration data cleared for fresh calibration',
        );
      } catch (e) {
        Logger.error(
          'CALIBRATION',
          'Error clearing previous calibration data: $e',
        );
        // Continue anyway as we'll overwrite the data
      }
    }

    // Reset the state
    setState(() {
      _isCalibrating = true;
      _progress = 0.0;
      _statusMessage = 'Starting calibration...';
      _movementDetected = false;
      _orientation = DeviceOrientation.unknown;
      _isComplete = false;
      _calibrationData = null;
      _forceRecalibration = false;
      _recalibrationReason = '';
    });

    try {
      final repository = await ref.read(
        calibrationRepositoryAsyncProvider.future,
      );
      final sensorService = ref.read(sensorServiceProvider);

      // Create a calibration notifier
      final calibrationNotifier = CalibrationNotifier(
        calibrationRepository: repository,
        sensorService: sensorService,
      );

      // Subscribe to calibration updates
      _calibrationSubscription = calibrationNotifier.stream.listen((state) {
        if (mounted) {
          setState(() {
            _progress = state.calibrationProgress;
            _statusMessage = state.statusMessage;
            _movementDetected = state.movementDetected;
            _orientation = state.deviceOrientation;
            _isComplete = state.isCalibrationComplete;
            _calibrationData = state.calibrationData;
            _isCalibrating = state.isCalibrating;

            // Enhanced movement detection handling - immediately cancel calibration
            if (state.movementDetected && state.isCalibrating) {
              // Stop calibration if movement detected during the process
              _cancelCalibrationSubscription();
              _isCalibrating = false;
              _progress = 0.0;
              _statusMessage =
                  'Excessive movement detected. Please keep the device perfectly still and try again.';
              _movementDetected = true;
            }
            // Regular completion path remains the same
            else if (state.isCalibrationComplete &&
                state.calibrationData != null) {
              _calibrationData = state.calibrationData;
              _isComplete = true;
              _progress = 1.0;

              // Update providers
              ref.read(calibrationInProgressProvider.notifier).state = false;
              ref.read(calibrationCompletedProvider.notifier).state = true;
            }
          });
        }
      });

      // Start the calibration
      await calibrationNotifier.startCalibration();
    } catch (e) {
      _cancelCalibrationSubscription();

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

  // Cancel calibration
  void _cancelCalibration() {
    _cancelCalibrationSubscription();

    setState(() {
      _isCalibrating = false;
      _progress = 0.0;
      _statusMessage = 'Calibration cancelled';
    });
  }

  // Format the text representation of orientation
  String _orientationToString(DeviceOrientation orientation) {
    switch (orientation) {
      case DeviceOrientation.portrait:
        return 'Portrait';
      case DeviceOrientation.landscapeRight:
        return 'Landscape Left';
      case DeviceOrientation.landscapeLeft:
        return 'Landscape Right';
      case DeviceOrientation.flat:
        return 'Flat (screen up)';
      case DeviceOrientation.unknown:
      default:
        return 'Unknown';
    }
  }

  // Get calibration phase based on progress
  String _getCurrentPhase() {
    if (_progress < 0.1) {
      return 'Ready to begin';
    } else if (_progress < 0.3) {
      return 'Phase 1: Detecting Orientation';
    } else if (_progress < 0.9) {
      return 'Phase 2: Calculating Sensor Offsets';
    } else if (_progress < 1.0) {
      return 'Phase 3: Finalizing Calibration';
    } else {
      return 'Calibration Complete';
    }
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
    formattedString += '  Z: ${data.gyroscopeZOffset.toStringAsFixed(4)}\n\n';
    formattedString += 'Samples Collected: ${data.calibrationSamplesCount}\n\n';
    formattedString +=
        'Timestamp: ${DateTime.fromMillisecondsSinceEpoch(data.calibrationTimestamp).toString()}';

    return formattedString;
  }

  // Show calibration details dialog
  void _showCalibrationDetailsDialog() {
    if (_calibrationData == null) return;

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Row(
            children: [
              Icon(Icons.sensors, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 8),
              const Text('Calibration Details'),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              _formatCalibrationData(_calibrationData!),
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isInitializing) {
      return _buildLoadingView(theme);
    }

    if (_isCheckingValidity) {
      return _buildCheckingValidityView(theme);
    }

    if (!_isRepositoryReady && _initializationError.isNotEmpty) {
      return _buildErrorView(theme);
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              _buildHeader(theme),
              const SizedBox(height: 24),

              // Instructions card
              _buildInstructionsCard(theme),
              const SizedBox(height: 20),

              // Status card
              _buildStatusCard(theme),
              const SizedBox(height: 24),

              // Action button
              _buildActionButton(theme),
            ],
          ),
        ),
      ),
    );
  }

  // Loading view
  Widget _buildLoadingView(ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Initializing calibration...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Checking calibration validity view
  Widget _buildCheckingValidityView(ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(
              'Checking calibration validity...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please keep your device still',
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Error view
  Widget _buildErrorView(ThemeData theme) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Initialization Error',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.error,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _initializationError,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: theme.colorScheme.onSurface,
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
        ),
      ),
    );
  }

  // Header section
  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Initial Calibration',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Calibration is required each time the app is launched for accurate data collection.',
          style: TextStyle(
            fontSize: 16,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  // Instructions card
  Widget _buildInstructionsCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Instructions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Phone placement illustration
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Phone in portrait
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.phone_android,
                        size: 48,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Portrait',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),

                  // Phone in landscape
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.rotate(
                        angle: 1.5708, // 90 degrees in radians
                        child: Icon(
                          Icons.phone_android,
                          size: 48,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Landscape',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Step-by-step instructions
            _buildInstructionItem(
              theme,
              '1. Place your phone securely in your vehicle mount',
            ),
            _buildInstructionItem(
              theme,
              '2. Keep the phone completely still during calibration',
            ),
            _buildInstructionItem(
              theme,
              '3. The process takes approximately 15 seconds',
            ),
          ],
        ),
      ),
    );
  }

  // Status and progress card
  Widget _buildStatusCard(ThemeData theme) {
    Color statusColor =
        _isCalibrating
            ? theme.colorScheme.tertiary
            : _isComplete
            ? theme.colorScheme.primary
            : _movementDetected ||
                _forceRecalibration // Treat force recalibration like movement detection
            ? theme.colorScheme.error
            : theme.colorScheme.onSurface;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.sensors, color: statusColor),
                const SizedBox(width: 8),
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

            // Current status message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.2)),
              ),
              child: Text(
                _statusMessage,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: statusColor,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Current phase
            if (_isCalibrating || _isComplete)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _getCurrentPhase(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ),

            // Progress indicator
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      tween: Tween<double>(
                        begin: 0.0,
                        end: _progress.clamp(0.0, 1.0),
                      ),
                      builder: (context, animatedValue, _) {
                        return LinearProgressIndicator(
                          value: animatedValue,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          color:
                              _isComplete
                                  ? theme.colorScheme.primary
                                  : _movementDetected ||
                                      _forceRecalibration // Treat the same
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.tertiary,
                          minHeight: 8,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(_progress.clamp(0.0, 1.0) * 100).toInt()}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),

            // Display orientation if detected
            if (_orientation != DeviceOrientation.unknown)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Row(
                  children: [
                    Text(
                      'Detected Orientation: ',
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _orientationToString(_orientation),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),

            // Completion message with details button - only show if complete and not needing recalibration
            if (_isComplete && _calibrationData != null && !_forceRecalibration)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Completion status
                          Row(
                            children: [
                              Icon(
                                Icons.check_circle,
                                color: theme.colorScheme.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Calibration Complete',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),

                          // Info button
                          IconButton(
                            onPressed: _showCalibrationDetailsDialog,
                            icon: Icon(
                              Icons.info_outline,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                            tooltip: 'View Calibration Details',
                            constraints: const BoxConstraints(),
                            padding: const EdgeInsets.all(4),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Your device is calibrated and ready for this session.',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Action button
  Widget _buildActionButton(ThemeData theme) {
    // If calibration is complete and valid (not requiring recalibration),
    // show both continue and recalibrate buttons
    if (_isComplete && _calibrationData != null && !_forceRecalibration) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Recalibrate button
          OutlinedButton.icon(
            onPressed: _startCalibration,
            icon: const Icon(Icons.refresh),
            label: const Text('Recalibrate'),
            style: OutlinedButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              side: BorderSide(color: theme.colorScheme.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),

          const SizedBox(width: 16),

          // Continue button
          ElevatedButton.icon(
            onPressed: () {
              // Mark calibration as complete
              ref.read(calibrationCompletedProvider.notifier).state = true;
              // Navigate to home screen
              if (context.mounted) {
                context.go(AppRoutes.homePath);
              }
            },
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Continue'),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
      );
    }

    // For forced recalibration, movement detection, or starting a new calibration,
    // show a single "Calibrate Now" button with consistent styling
    if (_forceRecalibration || _movementDetected || !_isCalibrating) {
      return Center(
        child: SizedBox(
          width: 200,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: _startCalibration,
            icon: const Icon(Icons.refresh),
            label: const Text('Calibrate Now'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  _forceRecalibration || _movementDetected
                      ? theme.colorScheme.error
                      : theme.colorScheme.tertiary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              elevation: 2,
            ),
          ),
        ),
      );
    }

    // For ongoing calibration, show cancel button
    return Center(
      child: SizedBox(
        width: 200,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _cancelCalibration,
          icon: const Icon(Icons.cancel),
          label: Row(
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
              const SizedBox(width: 8),
              const Text(
                'Cancel',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.redAccent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            elevation: 2,
          ),
        ),
      ),
    );
  }

  // Instruction item
  Widget _buildInstructionItem(ThemeData theme, String text) {
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
              text,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
