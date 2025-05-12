import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:multimodal_road_data_collector/core/services/providers.dart';

import '../../domain/models/recording_display_info.dart';
import '../providers/recordings_providers.dart';
import '../state/recordings_state.dart';
import '../widgets/recording_list_item.dart';

/// Screen that displays a list of past recording sessions
class RecordingsListScreen extends ConsumerStatefulWidget {
  /// Constructor
  const RecordingsListScreen({super.key});

  @override
  ConsumerState<RecordingsListScreen> createState() =>
      _RecordingsListScreenState();
}

class _RecordingsListScreenState extends ConsumerState<RecordingsListScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    // Register the observer to listen for app lifecycle changes
    WidgetsBinding.instance.addObserver(this);
    // Load recordings when screen is first displayed
    Future.microtask(
      () => ref.read(recordingsNotifierProvider.notifier).loadRecordings(),
    );
  }

  @override
  void dispose() {
    // Remove the observer when the widget is disposed
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh recordings when app is resumed
    if (state == AppLifecycleState.resumed) {
      ref.read(recordingsNotifierProvider.notifier).loadRecordings();
    }
  }

  // Also add a didChangeDependencies method to refresh when navigating back to this screen
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when user navigates back to this screen
    ref.read(recordingsNotifierProvider.notifier).loadRecordings();
  }

  @override
  Widget build(BuildContext context) {
    final recordingsState = ref.watch(recordingsNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Previous Recordings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(recordingsNotifierProvider.notifier).loadRecordings();
            },
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _buildBody(recordingsState),
    );
  }

  Widget _buildBody(RecordingsState state) {
    // Show loading indicator
    if (state.status == RecordingsStatus.loading) {
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

    // Show error message
    if (state.status == RecordingsStatus.error) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(state.errorMessage ?? 'Unknown error'),
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

    // Show empty state
    if (state.recordings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.videocam_off_outlined,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            const Text(
              'No recordings found',
              style: TextStyle(fontSize: 18, color: Colors.grey),
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
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                final fileService = ref.read(fileStorageServiceProvider);
                final baseDir = await fileService.getSessionsBaseDirectory();

                // Show a dialog with the recordings directory path
                if (context.mounted) {
                  showDialog(
                    context: context,
                    builder:
                        (ctx) => AlertDialog(
                          title: const Text('Recordings Directory'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Check if recordings exist in this folder:',
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  baseDir,
                                  style: const TextStyle(
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                  );
                }
              },
              icon: const Icon(Icons.folder),
              label: const Text('Show Recordings Location'),
            ),
          ],
        ),
      );
    }

    // Show the list of recordings
    return RefreshIndicator(
      onRefresh: () async {
        await ref.read(recordingsNotifierProvider.notifier).loadRecordings();
      },
      child: ListView.builder(
        itemCount: state.recordings.length,
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemBuilder: (context, index) {
          final recording = state.recordings[index];
          return RecordingListItem(
            recording: recording,
            onDelete:
                state.isDeletingRecording
                    ? null
                    : () => _deleteRecording(recording),
            onShare:
                state.isSharingRecording
                    ? null
                    : () => _shareRecording(recording),
          );
        },
      ),
    );
  }

  Future<void> _deleteRecording(RecordingDisplayInfo recording) async {
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

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success ? 'Recording deleted' : 'Failed to delete recording',
            ),
          ),
        );
      }
    }
  }

  Future<void> _shareRecording(RecordingDisplayInfo recording) async {
    final success = await ref
        .read(recordingsNotifierProvider.notifier)
        .shareRecording(recording.sessionPath);

    if (mounted && !success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to share recording')),
      );
    }
  }
}
