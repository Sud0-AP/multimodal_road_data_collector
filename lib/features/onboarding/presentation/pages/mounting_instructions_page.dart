import 'package:flutter/material.dart';

/// The mounting instructions page for onboarding, showing how to position
/// the device for optimal data collection
class MountingInstructionsPage extends StatelessWidget {
  const MountingInstructionsPage({super.key});

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
            'Device Mounting',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 30),

          // Illustration of mounting
          Container(
            width: 250,
            height: 200,
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.phone_android, size: 80),
                Container(
                  width: 140,
                  height: 20,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                Container(
                  width: 180,
                  height: 40,
                  margin: const EdgeInsets.only(top: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          // Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                _buildInstructionItem(
                  context,
                  icon: Icons.dock,
                  text:
                      'Secure your device in a stable mount on your dashboard',
                ),
                const SizedBox(height: 16),
                _buildInstructionItem(
                  context,
                  icon: Icons.screen_rotation,
                  text:
                      'Position in landscape orientation with camera facing forward',
                ),
                const SizedBox(height: 16),
                _buildInstructionItem(
                  context,
                  icon: Icons.power,
                  text:
                      'Connect to a power source for extended recording sessions',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(
    BuildContext context, {
    required IconData icon,
    required String text,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 16),
        Expanded(child: Text(text, style: theme.textTheme.bodyMedium)),
      ],
    );
  }
}
