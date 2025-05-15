import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../../app/router.dart';
import '../../../../constants/app_constants.dart';
import '../../../calibration/presentation/state/calibration_provider.dart';
import '../../../recordings/domain/models/recording_display_info.dart';
import '../../../recordings/presentation/providers/recordings_providers.dart';
import '../../../recordings/presentation/state/recordings_state.dart';
import '../../../recordings/presentation/widgets/recording_list_item.dart';

/// A redesigned home screen with a more polished and modern UI
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();

    // Load recordings when the screen is first shown with no conditions
    // Using a small delay to ensure widget is properly mounted
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        // Always load recordings when the home screen is opened
        ref.read(recordingsNotifierProvider.notifier).loadRecordings();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Detect orientation for responsive layout
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    // Get screen size for responsive adjustments
    final screenSize = MediaQuery.of(context).size;
    final screenWidth = screenSize.width;
    final screenHeight = screenSize.height;

    // Get the calibration status to conditionally show the recording button
    final calibrationNeeded = ref.watch(calibrationNeededProvider);
    final calibrationCompleted = ref.watch(calibrationCompletedProvider);
    final showRecordButton = !calibrationNeeded || calibrationCompleted;

    // Calculate appropriate heights for components based on orientation
    final titleHeight = isLandscape ? 60.0 : 90.0;
    final recordingsListMaxHeight =
        isLandscape
            ? screenHeight *
                0.5 // 50% of screen height in landscape
            : screenHeight * 0.43; // 43% of screen height in portrait

    return Scaffold(
      appBar: AppBar(
        title: ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback:
              (bounds) => LinearGradient(
                colors: [colorScheme.primary, colorScheme.tertiary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds),
          child:
              isLandscape
                  ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Multimodal ',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        'Road Data Collector',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  )
                  : Column(
                    children: [
                      Text(
                        'Multimodal',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 32,
                        ),
                      ),
                      Text(
                        'Road Data Collector',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 30,
                        ),
                      ),
                    ],
                  ),
        ),
        centerTitle: true,
        toolbarHeight: titleHeight,
        elevation: 0,
        backgroundColor: colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: colorScheme.primary, size: 28),
            onPressed: () => context.pushNamed(AppRoutes.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child:
                isLandscape
                    ? _buildLandscapeLayout(context, recordingsListMaxHeight)
                    : _buildPortraitLayout(context, recordingsListMaxHeight),
          ),
        ),
      ),
      // Updated floating action button positioning
      floatingActionButton:
          showRecordButton
              ? Padding(
                padding: EdgeInsets.only(bottom: isLandscape ? 8.0 : 12.0),
                child: FloatingActionButton.extended(
                  onPressed: () => context.pushNamed(AppRoutes.recording),
                  label: const Text('Record Data'),
                  icon: const Icon(Icons.fiber_manual_record),
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  elevation: 4,
                  tooltip: 'Start recording road data',
                  extendedTextStyle: textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
              : null, // Don't show FAB if calibration is needed
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // Portrait layout (stacked vertically)
  Widget _buildPortraitLayout(
    BuildContext context,
    double recordingsListMaxHeight,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 16),
        // Welcome description
        Text(
          'Collect and analyze road condition data with your device sensors',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 24),

        // Calibration card
        _buildFeatureCard(
          context,
          icon: Icons.sensors,
          title: 'Calibrate Sensors',
          description:
              ref.watch(calibrationCompletedProvider)
                  ? 'Sensors are calibrated and ready to use'
                  : 'Calibrate device sensors for accurate data collection',
          iconColor:
              ref.watch(calibrationCompletedProvider)
                  ? Colors.green
                  : colorScheme.primary,
          onTap: () => context.pushNamed(AppRoutes.calibration),
        ),

        const SizedBox(height: 16),

        // Instructions card
        _buildFeatureCard(
          context,
          icon: Icons.help_outline,
          title: 'Instructions',
          description: 'Learn how to use the app and collect data properly',
          iconColor: colorScheme.tertiary,
          onTap: () => context.pushNamed(AppRoutes.instructions),
        ),

        const SizedBox(height: 24),

        // Recordings section
        _buildRecordingsSection(context, recordingsListMaxHeight),

        // Add spacer to push content up and leave room for FAB
        const SizedBox(height: 85),
      ],
    );
  }

  // Landscape layout (side-by-side arrangement)
  Widget _buildLandscapeLayout(
    BuildContext context,
    double recordingsListMaxHeight,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Get screen width to calculate constraint
    final screenWidth = MediaQuery.of(context).size.width;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        // Welcome description
        Text(
          'Collect and analyze road condition data with your device sensors',
          style: textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 16),

        // Two-column layout for feature cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left column - Calibration card
            Expanded(
              child: _buildFeatureCard(
                context,
                icon: Icons.sensors,
                title: 'Calibrate Sensors',
                description:
                    ref.watch(calibrationCompletedProvider)
                        ? 'Sensors are calibrated and ready to use'
                        : 'Calibrate device sensors for accurate data collection',
                iconColor:
                    ref.watch(calibrationCompletedProvider)
                        ? Colors.green
                        : colorScheme.primary,
                onTap: () => context.pushNamed(AppRoutes.calibration),
              ),
            ),

            const SizedBox(width: 16),

            // Right column - Instructions card
            Expanded(
              child: _buildFeatureCard(
                context,
                icon: Icons.help_outline,
                title: 'Instructions',
                description:
                    'Learn how to use the app and collect data properly',
                iconColor: colorScheme.tertiary,
                onTap: () => context.pushNamed(AppRoutes.instructions),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Recordings section - Constrained width in landscape mode
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: screenWidth * 0.65, // Reduced width in landscape mode
            ),
            child: _buildRecordingsSection(context, recordingsListMaxHeight),
          ),
        ),

        // Spacer for FAB
        const SizedBox(height: 70),
      ],
    );
  }

  // Extracted recordings section to avoid duplication
  Widget _buildRecordingsSection(BuildContext context, double maxHeight) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Recordings section header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Previous Recordings',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            Row(
              children: [
                // Button to open full recordings screen
                IconButton(
                  icon: Icon(
                    Icons.fullscreen,
                    size: 24,
                    color: colorScheme.primary,
                  ),
                  onPressed: () => context.pushNamed(AppRoutes.recordings),
                  tooltip: 'View all recordings',
                ),
                // Refresh button
                IconButton(
                  icon: Icon(
                    Icons.refresh,
                    size: 24,
                    color: colorScheme.primary,
                  ),
                  onPressed: () {
                    ref
                        .read(recordingsNotifierProvider.notifier)
                        .loadRecordings();
                  },
                  tooltip: 'Refresh recordings',
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Recordings list with fixed height
        SizedBox(height: maxHeight, child: _buildRecordingsList(context, ref)),
      ],
    );
  }

  // Building the recordings list with real data from the provider
  Widget _buildRecordingsList(BuildContext context, WidgetRef ref) {
    final recordingsState = ref.watch(recordingsNotifierProvider);
    final theme = Theme.of(context);

    // If recordings are still loading, show loading indicator
    if (recordingsState.status == RecordingsStatus.loading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading recordings...'),
          ],
        ),
      );
    }

    // If there was an error loading recordings
    if (recordingsState.status == RecordingsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(recordingsState.errorMessage ?? 'Unknown error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                ref.read(recordingsNotifierProvider.notifier).loadRecordings();
              },
              child: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // If there are no recordings
    if (recordingsState.recordings.isEmpty) {
      // Empty state
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.videocam_off_outlined,
              size: 64,
              color: Colors.grey.withOpacity(0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'No recordings found',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Complete a recording to see it listed here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ),
          ],
        ),
      );
    }

    // Show a limited list of recordings (max 3)
    final allRecordings = recordingsState.recordings;
    final recordingsToShow = allRecordings.take(3).toList();

    // Reverse the list display order so newest is at the top
    // This keeps the display order (#N to #1) from newest to oldest
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Limited list of recordings
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.zero, // Remove padding to make it more compact
            itemCount: recordingsToShow.length,
            itemBuilder: (context, index) {
              final recording = recordingsToShow[index];
              // Calculate recording number (total count - index) for reverse numbering
              final recordingNumber = allRecordings.length - index;

              // Use a more compact version for the home screen, but not too small
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  margin: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => context.pushNamed(AppRoutes.recordings),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          // Recording icon
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.secondaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.videocam,
                              color: theme.colorScheme.onSecondaryContainer,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Recording info with new naming convention
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Recording #$recordingNumber',
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                // Remove the Session ID line from home page
                                Text(
                                  'Time: ${DateFormat('MMM dd, yyyy - HH:mm').format(recording.timestamp)}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                                Text(
                                  'Duration: ${_formatDuration(recording.durationSeconds)}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),

                          // Actions
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Share button
                              IconButton(
                                icon: const Icon(Icons.share, size: 20),
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Share',
                                onPressed:
                                    recordingsState.isSharingRecording
                                        ? null
                                        : () => _shareRecording(
                                          context,
                                          ref,
                                          recording,
                                        ),
                              ),

                              if (Platform.isAndroid)
                                IconButton(
                                  icon: const Icon(Icons.folder_open, size: 20),
                                  visualDensity: VisualDensity.compact,
                                  tooltip: 'Open in folder',
                                  onPressed:
                                      recordingsState.isDeletingRecording
                                          ? null
                                          : () => _viewInFolder(
                                            context,
                                            ref,
                                            recording,
                                          ),
                                ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                visualDensity: VisualDensity.compact,
                                tooltip: 'Delete',
                                color: Colors.red,
                                onPressed:
                                    recordingsState.isDeletingRecording
                                        ? null
                                        : () => _deleteRecording(
                                          context,
                                          ref,
                                          recording,
                                        ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Removed "View all N recordings" button as requested
      ],
    );
  }

  // Helper method to format duration
  String _formatDuration(int seconds) {
    if (seconds <= 0) {
      return '0:00'; // Handle zero or negative values
    }

    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;

    if (hours > 0) {
      // Format with hours (HH:MM:SS)
      return '$hours:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
    } else {
      // Format without hours (MM:SS)
      return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
    }
  }

  // Handle deleting a recording
  Future<void> _deleteRecording(
    BuildContext context,
    WidgetRef ref,
    RecordingDisplayInfo recording,
  ) async {
    // Ask for confirmation before deleting
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Recording'),
            content: Text(
              'Are you sure you want to delete this recording from '
              '${DateFormat('MMM dd, yyyy - HH:mm').format(recording.timestamp)}? '
              'This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    // If user confirmed deletion
    if (confirmed == true) {
      final success = await ref
          .read(recordingsNotifierProvider.notifier)
          .deleteRecording(recording.sessionPath);

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Recording deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete recording'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  // Handle sharing a recording
  Future<void> _shareRecording(
    BuildContext context,
    WidgetRef ref,
    RecordingDisplayInfo recording,
  ) async {
    final success = await ref
        .read(recordingsNotifierProvider.notifier)
        .shareRecording(recording.sessionPath);

    if (context.mounted) {
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to share recording'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Handle viewing a recording in the file explorer
  Future<void> _viewInFolder(
    BuildContext context,
    WidgetRef ref,
    RecordingDisplayInfo recording,
  ) async {
    final success = await ref
        .read(recordingsNotifierProvider.notifier)
        .openSessionInFileExplorer(recording.sessionPath);

    if (context.mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open folder in file explorer'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    Color? iconColor,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDisabled = onTap == null;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;

    // Adjust padding based on orientation
    final cardPadding =
        isLandscape
            ? const EdgeInsets.symmetric(horizontal: 16, vertical: 14)
            : const EdgeInsets.all(20);

    // Adjust icon size based on orientation
    final iconSize = isLandscape ? 28.0 : 32.0;

    // Adjust text styles based on orientation
    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.bold,
      color: isDisabled ? Colors.grey : colorScheme.onSurface,
      fontSize: isLandscape ? 18 : null, // Smaller font in landscape
    );

    final descriptionStyle = theme.textTheme.bodyMedium?.copyWith(
      color: isDisabled ? Colors.grey : colorScheme.onSurfaceVariant,
      fontSize: isLandscape ? 13 : null, // Smaller font in landscape
    );

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color:
              isDisabled
                  ? Colors.grey.withOpacity(0.3)
                  : colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: cardPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(isLandscape ? 10 : 12),
                decoration: BoxDecoration(
                  color: (iconColor ?? colorScheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: iconSize,
                  color:
                      isDisabled
                          ? Colors.grey
                          : (iconColor ?? colorScheme.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: titleStyle),
                    const SizedBox(height: 4),
                    Text(description, style: descriptionStyle),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color:
                    isDisabled
                        ? Colors.grey.withOpacity(0.3)
                        : colorScheme.primary.withOpacity(0.6),
                size: isLandscape ? 20 : 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
