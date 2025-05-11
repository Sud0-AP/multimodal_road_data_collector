import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/services/providers/ntp_service_provider.dart';

/// A widget that displays the current NTP-synchronized time
/// and the device's synchronization status
class NtpTimeDisplay extends ConsumerStatefulWidget {
  const NtpTimeDisplay({Key? key}) : super(key: key);

  @override
  ConsumerState<NtpTimeDisplay> createState() => _NtpTimeDisplayState();
}

class _NtpTimeDisplayState extends ConsumerState<NtpTimeDisplay> {
  DateTime? _currentTime;
  Timer? _timer;
  final DateFormat _timeFormat = DateFormat('HH:mm:ss.SSS');

  @override
  void initState() {
    super.initState();
    // Start a timer to update the display every 100ms
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTime() {
    // Get the current device time
    final deviceTime = DateTime.now();

    // Get the NTP offset
    final offsetAsync = ref.read(ntpOffsetProvider);

    // Apply the offset to the device time if available
    offsetAsync.whenData((offset) {
      if (mounted) {
        setState(() {
          _currentTime = deviceTime.add(Duration(milliseconds: -offset));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get the synchronization status
    final isSynchronized = ref.watch(ntpSynchronizedProvider);

    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Network Time',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _currentTime != null
                  ? _timeFormat.format(_currentTime!)
                  : 'Synchronizing...',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _currentTime != null ? Colors.black : Colors.grey,
                fontFamily: 'monospace',
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                isSynchronized.when(
                  data:
                      (synced) => Icon(
                        synced
                            ? Icons.check_circle
                            : Icons.warning_amber_rounded,
                        color: synced ? Colors.green : Colors.orange,
                      ),
                  loading:
                      () => const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  error:
                      (_, __) =>
                          const Icon(Icons.error_outline, color: Colors.red),
                ),
                const SizedBox(width: 8),
                isSynchronized.when(
                  data:
                      (synced) => Text(
                        synced ? 'Synchronized' : 'Not synchronized',
                        style: TextStyle(
                          color: synced ? Colors.green : Colors.orange,
                        ),
                      ),
                  loading: () => const Text('Checking...'),
                  error:
                      (_, __) => const Text(
                        'Connection error',
                        style: TextStyle(color: Colors.red),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Consumer(
              builder: (context, ref, _) {
                final offset = ref.watch(ntpOffsetProvider);
                return offset.when(
                  data:
                      (offsetMs) => Text(
                        'Device offset: ${offsetMs > 0 ? '+' : ''}${offsetMs}ms',
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              offsetMs.abs() < 100
                                  ? Colors.green
                                  : Colors.orange,
                        ),
                      ),
                  loading:
                      () => const Text(
                        'Calculating offset...',
                        style: TextStyle(fontSize: 12),
                      ),
                  error:
                      (error, _) => Text(
                        'Error: $error',
                        style: const TextStyle(fontSize: 12, color: Colors.red),
                      ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
