import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:ntp/ntp.dart';
import 'package:multimodal_road_data_collector/core/services/ntp_service.dart';
import 'package:multimodal_road_data_collector/core/services/implementations/ntp_service_impl.dart';

@GenerateMocks([NtpService])
void main() {
  group('NtpServiceImpl', () {
    late NtpServiceImpl ntpService;

    setUp(() {
      ntpService = NtpServiceImpl();
    });

    test('deviceTimeToNtpTime converts timestamps correctly', () {
      // Create a test DateTime
      final now = DateTime.now();

      // The default offset in a new instance is 0, so timestamps should be identical
      expect(
        ntpService.deviceTimeToNtpTime(now).millisecondsSinceEpoch,
        equals(now.millisecondsSinceEpoch),
      );

      // Since we can't modify the private offset directly in tests, we'll test
      // that passing in different device times produces expected results
      final futureTime = now.add(const Duration(seconds: 5));
      final pastTime = now.subtract(const Duration(seconds: 5));

      // The offset between these timestamps should be consistently applied
      final diff1 = futureTime.difference(now).inMilliseconds;
      final ntpDiff1 =
          ntpService
              .deviceTimeToNtpTime(futureTime)
              .difference(ntpService.deviceTimeToNtpTime(now))
              .inMilliseconds;

      expect(ntpDiff1, equals(diff1));

      final diff2 = now.difference(pastTime).inMilliseconds;
      final ntpDiff2 =
          ntpService
              .deviceTimeToNtpTime(now)
              .difference(ntpService.deviceTimeToNtpTime(pastTime))
              .inMilliseconds;

      expect(ntpDiff2, equals(diff2));
    });

    test(
      'deviceTimestampToNtpTimestamp preserves relative time differences',
      () {
        final now = DateTime.now().millisecondsSinceEpoch;

        // Default offset is 0, so timestamp conversion should be identical
        expect(ntpService.deviceTimestampToNtpTimestamp(now), equals(now));

        // Test relative time differences
        final futureTime = now + 10000; // 10 seconds in the future
        final pastTime = now - 10000; // 10 seconds in the past

        // The difference between these timestamps should be preserved
        expect(
          ntpService.deviceTimestampToNtpTimestamp(futureTime) -
              ntpService.deviceTimestampToNtpTimestamp(now),
          equals(10000),
        );

        expect(
          ntpService.deviceTimestampToNtpTimestamp(now) -
              ntpService.deviceTimestampToNtpTimestamp(pastTime),
          equals(10000),
        );
      },
    );

    test('initialize should not throw exception', () async {
      // This test just verifies that initialize completes without errors
      await expectLater(ntpService.initialize(), completes);
    });
  });
}
