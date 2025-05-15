import 'package:flutter/material.dart';

/// The calibration instructions page explaining the calibration process
class CalibrationInstructionsPage extends StatelessWidget {
  const CalibrationInstructionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Add extra padding at the top
            const SizedBox(height: 16),
            
            // Icon container
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: theme.colorScheme.tertiaryContainer.withOpacity(0.7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.tertiary.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.sensors,
                size: 70,
                color: theme.colorScheme.onTertiaryContainer,
              ),
            ),
            const SizedBox(height: 28),

            // Title
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback:
                  (bounds) => LinearGradient(
                    colors: [
                      theme.colorScheme.tertiary,
                      theme.colorScheme.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
              child: const Text(
                'Calibration Guide',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Ensure accurate data collection with proper calibration',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Calibration steps
            _buildStepCard(
              context,
              1,
              'Mount in Vehicle',
              'Secure your device in the car\'s phone mount in the position you\'ll use for recording',
              Icons.directions_car,
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              context,
              2,
              'Initial Calibration',
              'With device mounted, keep the vehicle stationary for the 15-second calibration',
              Icons.stay_current_portrait,
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              context,
              3,
              'Orientation Detection',
              'The app automatically detects your device\'s orientation during calibration',
              Icons.screen_rotation,
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              context,
              4,
              'Pre-Recording Calibration',
              'Drive on a smooth road segment for 20 seconds to set up bump detection',
              Icons.sensors_outlined,
            ),
            const SizedBox(height: 28),

            // Important notes
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withOpacity(0.6),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.onErrorContainer,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Important Notes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onErrorContainer,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Recalibrate if you change your device mounting position\n'
                    '• Keep the vehicle stationary during the initial calibration\n'
                    '• Ensure the device is securely mounted and won\'t move\n'
                    '• Drive on level ground during pre-recording calibration',
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.colorScheme.onErrorContainer,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepCard(
    BuildContext context,
    int stepNumber,
    String title,
    String description,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step number circle
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                stepNumber.toString(),
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 20, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
