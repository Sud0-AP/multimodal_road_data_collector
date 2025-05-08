import 'package:flutter/material.dart';

/// The data explanation page for onboarding, describing what data
/// is collected and how it's used
class DataExplanationPage extends StatelessWidget {
  const DataExplanationPage({super.key});

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
            'Data Collection',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Data types section
          _buildDataSection(
            context,
            title: 'What We Collect',
            items: [
              _DataItem(
                icon: Icons.camera_alt,
                title: 'Camera Feed',
                description: 'Video for road condition analysis',
              ),
              _DataItem(
                icon: Icons.sensors,
                title: 'Motion Data',
                description: 'From accelerometer and gyroscope to detect bumps',
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Data usage section
          _buildDataSection(
            context,
            title: 'How It\'s Used',
            items: [
              _DataItem(
                icon: Icons.analytics,
                title: 'Road Quality Analysis',
                description: 'Identifying potholes, cracks, and surface issues',
              ),
              _DataItem(
                icon: Icons.auto_awesome,
                title: 'Research & Deep Learning',
                description:
                    'Training AI models to automatically detect road defects',
              ),
              _DataItem(
                icon: Icons.map,
                title: 'Infrastructure Planning',
                description: 'Helping prioritize road maintenance',
              ),
              _DataItem(
                icon: Icons.privacy_tip,
                title: 'Privacy Focused',
                description: 'No personally identifiable information is shared',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDataSection(
    BuildContext context, {
    required String title,
    required List<_DataItem> items,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.secondary,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.tertiary.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    item.icon,
                    color: theme.colorScheme.tertiary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DataItem {
  final IconData icon;
  final String title;
  final String description;

  const _DataItem({
    required this.icon,
    required this.title,
    required this.description,
  });
}
