import 'package:flutter/material.dart';

/// The data management page explaining how to access and manage recorded data
class DataManagementPage extends StatelessWidget {
  const DataManagementPage({super.key});

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
                color: theme.colorScheme.secondaryContainer.withOpacity(0.7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.secondary.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.folder_open,
                size: 70,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
            const SizedBox(height: 28),

            // Title
            ShaderMask(
              blendMode: BlendMode.srcIn,
              shaderCallback:
                  (bounds) => LinearGradient(
                    colors: [
                      theme.colorScheme.secondary,
                      theme.colorScheme.primary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ).createShader(bounds),
              child: const Text(
                'Data Management',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              'Accessing and managing your recorded data',
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Features section
            _buildFeatureCard(
              context,
              'Accessing Your Recordings',
              'Recordings are listed on the home screen. Tap "View all recordings" to see the complete list.',
              Icons.list_alt,
            ),
            const SizedBox(height: 18),

            _buildFeatureCard(
              context,
              'Understanding Recording Data',
              'Each recording contains synchronized video, sensor data (CSV), and metadata files, all stored in a timestamped folder.',
              Icons.insert_drive_file,
            ),
            const SizedBox(height: 18),

            _buildFeatureCard(
              context,
              'Sharing Recordings',
              'Tap the share icon on any recording to export the entire dataset (video, CSV, metadata) as a zip file to other apps.',
              Icons.share,
            ),
            const SizedBox(height: 18),

            _buildFeatureCard(
              context,
              'Viewing in File Explorer',
              'Tap the folder icon to open the recording directory in your device\'s file explorer for advanced management.',
              Icons.folder_open,
            ),
            const SizedBox(height: 18),

            _buildFeatureCard(
              context,
              'Deleting Recordings',
              'Tap the delete icon to permanently remove a recording. You\'ll be asked to confirm this action.',
              Icons.delete_outline,
            ),
            const SizedBox(height: 24),

            // Data format info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: theme.colorScheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Data Format',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDataItem(
                    context,
                    'video.mp4',
                    'Video recording from the camera',
                    Icons.videocam,
                  ),
                  _buildDataItem(
                    context,
                    'sensors.csv',
                    'Timestamped accelerometer and gyroscope readings',
                    Icons.equalizer,
                  ),
                  _buildDataItem(
                    context,
                    'metadata.txt',
                    'Recording details, device info, and calibration data',
                    Icons.description,
                  ),
                  _buildDataItem(
                    context,
                    'annotations.log',
                    'User feedback on detected road anomalies',
                    Icons.bookmark,
                    showDivider: false,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withOpacity(0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 24, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
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

  Widget _buildDataItem(
    BuildContext context,
    String fileName,
    String description,
    IconData icon, {
    bool showDivider = true,
  }) {
    final theme = Theme.of(context);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, size: 18, color: theme.colorScheme.secondary),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(color: theme.colorScheme.outline.withOpacity(0.2), height: 1),
      ],
    );
  }
}
