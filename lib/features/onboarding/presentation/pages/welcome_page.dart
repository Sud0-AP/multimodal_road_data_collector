import 'package:flutter/material.dart';
import '../../../../constants/app_constants.dart';

/// The welcome page for onboarding, introducing the app to users
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // App icon / logo placeholder
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.directions_car_filled,
              size: 80,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 40),

          // Welcome Title
          Text(
            'Welcome to ${AppConstants.appName}',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Welcome message
          Text(
            'An innovative tool to collect and analyze road data for improving transportation infrastructure.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),

          // Get started info
          Text(
            'Swipe or use the navigation buttons to learn more.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
