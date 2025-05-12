import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/models/recording_display_info.dart';

/// Widget to display a single recording item in the list
class RecordingListItem extends StatelessWidget {
  /// Recording data to display
  final RecordingDisplayInfo recording;

  /// Callback for when the user wants to delete the recording
  final VoidCallback? onDelete;

  /// Callback for when the user wants to share the recording
  final VoidCallback? onShare;

  /// Callback for when the user taps on the item (view details)
  final VoidCallback? onTap;

  /// Constructor
  const RecordingListItem({
    super.key,
    required this.recording,
    this.onDelete,
    this.onShare,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Format timestamp
    final date = DateFormat('MMM dd, yyyy').format(recording.timestamp);
    final time = DateFormat('HH:mm:ss').format(recording.timestamp);

    // Format duration
    final duration = _formatDuration(recording.durationSeconds);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.videocam_outlined,
                  color: theme.colorScheme.onSecondaryContainer,
                  size: 30,
                ),
              ),
              title: Text(date, style: theme.textTheme.titleMedium),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text('Time: $time', style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Duration: $duration',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  // Share button
                  if (onShare != null)
                    IconButton(
                      icon: const Icon(Icons.share),
                      tooltip: 'Share Recording',
                      onPressed: onShare,
                    ),
                  // Delete button
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete Recording',
                      onPressed: onDelete,
                      color: Colors.red,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Format duration in seconds to a readable string (MM:SS)
  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }
}
