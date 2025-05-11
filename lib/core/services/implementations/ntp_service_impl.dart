import 'dart:async';
import 'dart:io';

import 'package:ntp/ntp.dart';
import '../ntp_service.dart';

/// Implementation of the NtpService using the ntp package
class NtpServiceImpl implements NtpService {
  /// Default NTP server pool to use
  static const String _defaultNtpPool = 'pool.ntp.org';

  /// Secondary NTP server pools to try if the primary fails
  static const List<String> _fallbackNtpPools = [
    'time.google.com',
    'time.apple.com',
    'time.windows.com',
  ];

  /// Maximum allowed lookup timeout in milliseconds
  static const int _lookupTimeout = 5000; // 5 seconds

  /// Time between synchronization attempts in milliseconds
  static const int _syncInterval = 600000; // 10 minutes

  /// Threshold in milliseconds below which we consider a clock "synchronized enough"
  static const int _syncThreshold = 50; // 50ms

  /// Maximum age of offset before we force a resync
  static const int _maxOffsetAge = 3600000; // 1 hour

  /// Current offset between device clock and NTP in milliseconds
  int _currentOffset = 0;

  /// When the offset was last updated
  DateTime? _lastSyncTime;

  /// Timer for periodic sync
  Timer? _syncTimer;

  /// Internal flag to track initialization status
  bool _isInitialized = false;

  @override
  Future<void> initialize() async {
    if (_isInitialized) return;

    // Try initial sync
    try {
      await _updateOffset();
    } catch (e) {
      // On initialization, we'll try again later, so just log the error
      print('NTP initial sync failed: $e');
    }

    // Set up periodic sync
    _syncTimer = Timer.periodic(
      Duration(milliseconds: _syncInterval),
      (_) => _updateOffset(),
    );

    _isInitialized = true;
  }

  @override
  Future<int> getOffset() async {
    // If we don't have an offset or it's too old, try to update it
    if (_lastSyncTime == null ||
        DateTime.now().difference(_lastSyncTime!).inMilliseconds >
            _maxOffsetAge) {
      await _updateOffset();
    }
    return _currentOffset;
  }

  @override
  Future<DateTime> getCurrentNtpTime() async {
    final offset = await getOffset();
    return DateTime.now().toUtc().add(Duration(milliseconds: -offset));
  }

  @override
  DateTime deviceTimeToNtpTime(DateTime deviceTime) {
    return deviceTime.add(Duration(milliseconds: -_currentOffset));
  }

  @override
  int deviceTimestampToNtpTimestamp(int deviceTimestampMs) {
    return deviceTimestampMs - _currentOffset;
  }

  @override
  Future<bool> isSynchronized() async {
    // Get the latest offset
    final offset = await getOffset();

    // If absolute offset is below threshold, we're synchronized enough
    return offset.abs() < _syncThreshold;
  }

  /// Updates the current offset by querying an NTP server
  /// Tries fallback servers if the primary fails
  Future<void> _updateOffset() async {
    final servers = [_defaultNtpPool, ..._fallbackNtpPools];
    Exception? lastException;

    // Try each server until one succeeds
    for (final server in servers) {
      try {
        // Use the correct method from the NTP package
        final int offset = await NTP.getNtpOffset(
          lookUpAddress: server,
          timeout: Duration(milliseconds: _lookupTimeout),
        );

        // Store the offset directly
        _currentOffset = offset;
        _lastSyncTime = DateTime.now().toUtc();

        print('NTP sync successful. Offset: $_currentOffset ms');
        return; // Success, exit the method
      } catch (e) {
        lastException = e is Exception ? e : Exception('NTP sync error: $e');
        print('NTP sync failed with server $server: $e');

        // Small delay before trying the next server
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    // If we have no offset at all (first run), throw an error
    // Otherwise, keep using the old offset
    if (_lastSyncTime == null) {
      throw lastException ??
          Exception('Failed to synchronize with any NTP server');
    }
  }

  /// Disposes resources used by the service
  void dispose() {
    _syncTimer?.cancel();
    _syncTimer = null;
  }
}
