import 'package:flutter/material.dart';

/// The permissions rationale page for onboarding, explaining why
/// each permission is needed and preparing the user to grant them
class PermissionsRationalePage extends StatelessWidget {
  const PermissionsRationalePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Title
          Text(
            'Required Permissions',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            'To provide the best experience, we\'ll need these permissions:',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Scrollable permission list for smaller screens
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildPermissionItem(
                    context,
                    icon: Icons.camera_alt,
                    title: 'Camera',
                    description: 'To capture road conditions in real-time',
                    iconColor: Colors.blue,
                  ),
                  const Divider(),
                  _buildPermissionItem(
                    context,
                    icon: Icons.sensors,
                    title: 'Motion Sensors',
                    description:
                        'To detect vibrations from road irregularities',
                    iconColor: Colors.green,
                  ),
                  const Divider(),
                  _buildPermissionItem(
                    context,
                    icon: Icons.sd_storage,
                    title: 'Storage',
                    description:
                        'To save collected data for processing and upload',
                    iconColor: Colors.orange,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Privacy note
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.privacy_tip, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your privacy is important. All data is handled according to our privacy policy.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
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
