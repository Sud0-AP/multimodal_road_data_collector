import 'package:flutter/material.dart';

/// The recording instructions page explaining how to use the recording feature
class RecordingInstructionsPage extends StatelessWidget {
  const RecordingInstructionsPage({super.key});

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
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withOpacity(0.7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.videocam,
                size: 70,
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 28),

            // Title
            ShaderMask(
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
                'Recording Process',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'How to capture data effectively while driving',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Recording flow
            _buildInstructionCard(
              context,
              'Before Recording',
              [
                'Ensure your device is properly calibrated',
                'Mount the device securely in landscape mode',
                'Make sure the camera has a clear view of the road',
                'Connect to a power source for longer recordings',
              ],
              Icons.checklist,
              theme.colorScheme.primary,
            ),
            const SizedBox(height: 16),

            _buildInstructionCard(
              context,
              'Starting a Recording',
              [
                'Tap the "Record Data" button on the home screen',
                'Wait 20 seconds for pre-recording calibration',
                'Maintain a steady speed during this calibration',
                'Recording starts automatically after calibration',
              ],
              Icons.play_circle_outline,
              theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),

            _buildInstructionCard(
              context,
              'During Recording',
              [
                'Drive normally over various road conditions',
                'Respond to bump detection prompts when safe to do so',
                'Press "Yes" if a pothole was detected, "No" if not',
                'Keep the app in the foreground during recording',
              ],
              Icons.sensors_outlined,
              theme.colorScheme.tertiary,
            ),
            const SizedBox(height: 16),

            _buildInstructionCard(
              context,
              'Ending a Recording',
              [
                'Press the "Stop" button when finished',
                'Wait for data to be processed and saved',
                'Recording will be listed on the home screen',
                'Use the recordings list to manage or share data',
              ],
              Icons.stop_circle_outlined,
              Colors.red,
            ),
            const SizedBox(height: 24),

            // Warning note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber, width: 1),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber[800],
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Safety Warning',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.amber[800],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Always prioritize safe driving. Do not interact with the app while driving unless safely pulled over or stopped. Consider having a passenger operate the app if possible.',
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.5,
                            color: Colors.amber[900],
                          ),
                        ),
                      ],
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

  Widget _buildInstructionCard(
    BuildContext context,
    String title,
    List<String> steps,
    IconData icon,
    Color iconColor,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with title and icon
          Row(
            children: [
              Icon(icon, color: iconColor, size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Steps list
          ...steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}.',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: iconColor,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      step,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
