import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'dart:io';

import '../../../../app/router.dart';
import '../../../../constants/app_constants.dart';
import '../../../calibration/presentation/state/calibration_provider.dart';
import '../../../recordings/domain/models/recording_display_info.dart';

/// A redesigned home screen with a more polished and modern UI
class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    // Get the calibration status to conditionally show the recording button
    final calibrationNeeded = ref.watch(calibrationNeededProvider);
    final calibrationCompleted = ref.watch(calibrationCompletedProvider);
    final showRecordButton = !calibrationNeeded || calibrationCompleted;

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
          child: Column(
            children: [
              Text(
                'Multimodal',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 28,
                ),
              ),
              Text(
                'Road Data Collector',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 26,
                ),
              ),
            ],
          ),
        ),
        centerTitle: true,
        toolbarHeight: 80, // Increased to accommodate two lines
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
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16), // Reduced gap after title
              // Welcome description (removed redundant title)
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
                    calibrationCompleted
                        ? 'Sensors are calibrated and ready to use'
                        : 'Calibrate device sensors for accurate data collection',
                iconColor:
                    calibrationCompleted ? Colors.green : colorScheme.primary,
                onTap: () => context.pushNamed(AppRoutes.calibration),
              ),

              const SizedBox(height: 16),

              // Instructions card
              _buildFeatureCard(
                context,
                icon: Icons.help_outline,
                title: 'Instructions',
                description:
                    'Learn how to use the app and collect data properly',
                iconColor: colorScheme.tertiary,
                onTap: () {
                  // Will implement navigation to Instructions later
                },
              ),

              const SizedBox(height: 24),

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
                        onPressed:
                            () => context.pushNamed(AppRoutes.recordings),
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
                          // Would implement refresh functionality here
                        },
                        tooltip: 'Refresh recordings',
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Recordings list - further increased height
              Expanded(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    // Further increased height for recordings section
                    maxHeight: MediaQuery.of(context).size.height * 0.45,
                  ),
                  child: _buildRecordingsList(context),
                ),
              ),

              // Add spacer to push content up and leave room for FAB
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      // Updated floating action button position and text
      floatingActionButton:
          showRecordButton
              ? Padding(
                padding: const EdgeInsets.only(
                  bottom: 30.0,
                ), // Move it up a bit
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

  // Building the recordings list with dummy data for now
  Widget _buildRecordingsList(BuildContext context) {
    final theme = Theme.of(context);

    // Create dummy recordings for UI demonstration
    final dummyRecordings = _createDummyRecordings();

    if (dummyRecordings.isEmpty) {
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
    final recordingsToShow = dummyRecordings.take(3).toList();
    final totalRecordings = dummyRecordings.length;

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
              return _buildRecordingCard(context, recording);
            },
          ),
        ),
      ],
    );
  }

  // Build an individual recording card
  Widget _buildRecordingCard(
    BuildContext context,
    RecordingDisplayInfo recording,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Format timestamp
    final date = DateFormat('MMM dd, yyyy').format(recording.timestamp);
    final time = DateFormat('HH:mm:ss').format(recording.timestamp);

    // Format duration
    final duration = _formatDuration(recording.durationSeconds);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior:
          Clip.hardEdge, // Change to hardEdge to prevent any unwanted decorations
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Would navigate to recording details page
        },
        child: Container(
          // Wrapped in Container to ensure clean rendering
          color: theme.cardColor, // Explicitly set background color
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Recording icon
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.videocam,
                    color: colorScheme.onSecondaryContainer,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 12),

                // Recording info with optimized text size
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recording on $date',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                        overflow:
                            TextOverflow.ellipsis, // Prevent text overflow
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Time: $time',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                              ),
                              overflow:
                                  TextOverflow
                                      .ellipsis, // Prevent text overflow
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'Duration: $duration',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontSize: 13,
                              ),
                              overflow:
                                  TextOverflow
                                      .ellipsis, // Prevent text overflow
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action buttons with adjusted sizing
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Open in folder button (only show on Android)
                    if (Platform.isAndroid)
                      Material(
                        type: MaterialType.transparency,
                        child: IconButton(
                          icon: const Icon(Icons.folder_open),
                          onPressed: () {
                            // Would implement open in folder functionality
                          },
                          iconSize: 20,
                          tooltip: 'Open in folder',
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                        ),
                      ),

                    // Share button
                    Material(
                      type: MaterialType.transparency,
                      child: IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          // Would implement share functionality
                        },
                        iconSize: 20,
                        tooltip: 'Share recording',
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                      ),
                    ),

                    // Delete button
                    Material(
                      type: MaterialType.transparency,
                      child: IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () {
                          // Would implement delete functionality
                        },
                        color: Colors.red,
                        iconSize: 20,
                        tooltip: 'Delete recording',
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
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

  // Create dummy recordings for UI demonstration
  List<RecordingDisplayInfo> _createDummyRecordings() {
    // Comment/uncomment the return [] line to toggle between empty state and dummy recordings
    // return [];

    final now = DateTime.now();
    return [
      RecordingDisplayInfo(
        sessionId: 'session_1',
        sessionPath: '/dummy/path/1',
        timestamp: now.subtract(const Duration(hours: 2)),
        durationSeconds: 185,
        videoFileName: 'video.mp4',
        sensorDataFileName: 'sensors.csv',
      ),
      RecordingDisplayInfo(
        sessionId: 'session_2',
        sessionPath: '/dummy/path/2',
        timestamp: now.subtract(const Duration(days: 1, hours: 5)),
        durationSeconds: 310,
        videoFileName: 'video.mp4',
        sensorDataFileName: 'sensors.csv',
      ),
      RecordingDisplayInfo(
        sessionId: 'session_3',
        sessionPath: '/dummy/path/3',
        timestamp: now.subtract(const Duration(days: 3)),
        durationSeconds: 478,
        videoFileName: 'video.mp4',
        sensorDataFileName: 'sensors.csv',
      ),
      RecordingDisplayInfo(
        sessionId: 'session_4',
        sessionPath: '/dummy/path/4',
        timestamp: now.subtract(const Duration(days: 5, hours: 12)),
        durationSeconds: 7200, // 2 hours
        videoFileName: 'video.mp4',
        sensorDataFileName: 'sensors.csv',
      ),
      RecordingDisplayInfo(
        sessionId: 'session_5',
        sessionPath: '/dummy/path/5',
        timestamp: now.subtract(const Duration(days: 7)),
        durationSeconds: 540,
        videoFileName: 'video.mp4',
        sensorDataFileName: 'sensors.csv',
      ),
    ];
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
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (iconColor ?? colorScheme.primary).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 32,
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
                    Text(
                      title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDisabled ? Colors.grey : colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color:
                            isDisabled
                                ? Colors.grey
                                : colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color:
                    isDisabled
                        ? Colors.grey.withOpacity(0.3)
                        : colorScheme.primary.withOpacity(0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
