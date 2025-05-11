import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ntp_service.dart';
import '../implementations/ntp_service_impl.dart';

/// Provider for the NtpService
final ntpServiceProvider = Provider<NtpService>((ref) {
  final ntpService = NtpServiceImpl();

  // Initialize the service on creation
  // We use the Future to prevent blocking, but don't await it
  ntpService.initialize();

  // Properly dispose the service when the provider is disposed
  ref.onDispose(() {
    (ntpService as NtpServiceImpl).dispose();
  });

  return ntpService;
});

/// Provider that delivers the current NTP time
/// This can be used by widgets or services that need the current accurate time
final ntpTimeProvider = FutureProvider.autoDispose<DateTime>((ref) async {
  final ntpService = ref.watch(ntpServiceProvider);
  return await ntpService.getCurrentNtpTime();
});

/// Provider that indicates whether the device is synchronized with NTP time
final ntpSynchronizedProvider = FutureProvider.autoDispose<bool>((ref) async {
  final ntpService = ref.watch(ntpServiceProvider);
  return await ntpService.isSynchronized();
});

/// Provider that gives the current offset between device time and NTP time in milliseconds
final ntpOffsetProvider = FutureProvider.autoDispose<int>((ref) async {
  final ntpService = ref.watch(ntpServiceProvider);
  return await ntpService.getOffset();
});
