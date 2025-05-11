/// Service for fetching and managing Network Time Protocol (NTP) synchronization
abstract class NtpService {
  /// Initialize the NTP service
  Future<void> initialize();

  /// Get the current offset between device time and NTP time in milliseconds
  /// A positive offset means the device clock is ahead of NTP time
  /// A negative offset means the device clock is behind NTP time
  Future<int> getOffset();

  /// Get the current time from an NTP server in milliseconds since epoch
  /// Returns UTC time based on NTP server sync
  /// Throws error if time couldn't be fetched and no cached time is available
  Future<DateTime> getCurrentNtpTime();

  /// Convert a device time to NTP-corrected time
  /// Applies the current offset to the provided device time
  DateTime deviceTimeToNtpTime(DateTime deviceTime);

  /// Convert a device timestamp (milliseconds since epoch) to NTP-corrected timestamp
  /// Applies the current offset to the provided device timestamp
  int deviceTimestampToNtpTimestamp(int deviceTimestampMs);

  /// Check if the NTP service is properly synchronized with an NTP server
  /// Returns true if the time is considered synchronized (within acceptable threshold)
  Future<bool> isSynchronized();
}
