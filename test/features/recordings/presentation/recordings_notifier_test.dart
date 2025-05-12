import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:multimodal_road_data_collector/core/services/data_management_service.dart';
import 'package:multimodal_road_data_collector/features/recordings/domain/models/recording_display_info.dart';
import 'package:multimodal_road_data_collector/features/recordings/presentation/state/recordings_notifier.dart';
import 'package:multimodal_road_data_collector/features/recordings/presentation/state/recordings_state.dart';

@GenerateMocks([DataManagementService])
void main() {
  late DataManagementService mockDataManagementService;
  late RecordingsNotifier notifier;

  setUp(() {
    mockDataManagementService = MockDataManagementService();
    notifier = RecordingsNotifier(
      dataManagementService: mockDataManagementService,
    );
  });

  group('RecordingsNotifier', () {
    test(
      'shareRecording should update state correctly when successful',
      () async {
        // Arrange
        final sessionPath = '/test/path/123456';

        // Mock the DataManagementService to return success
        when(
          mockDataManagementService.shareSession(sessionPath),
        ).thenAnswer((_) async => true);

        // Act
        final result = await notifier.shareRecording(sessionPath);

        // Assert
        expect(result, true);
        expect(
          notifier.state.isSharingRecording,
          false,
        ); // Sharing state should be reset
        expect(notifier.state.errorMessage, null); // No error
        verify(mockDataManagementService.shareSession(sessionPath)).called(1);
      },
    );

    test('shareRecording should update state correctly when failed', () async {
      // Arrange
      final sessionPath = '/test/path/123456';

      // Mock the DataManagementService to return failure
      when(
        mockDataManagementService.shareSession(sessionPath),
      ).thenAnswer((_) async => false);

      // Act
      final result = await notifier.shareRecording(sessionPath);

      // Assert
      expect(result, false);
      expect(
        notifier.state.isSharingRecording,
        false,
      ); // Sharing state should be reset
      expect(
        notifier.state.errorMessage,
        null,
      ); // No error (error is handled by UI toast)
      verify(mockDataManagementService.shareSession(sessionPath)).called(1);
    });

    test('shareRecording should handle exceptions', () async {
      // Arrange
      final sessionPath = '/test/path/123456';

      // Mock the DataManagementService to throw an exception
      when(
        mockDataManagementService.shareSession(sessionPath),
      ).thenThrow(Exception('Test error'));

      // Act
      final result = await notifier.shareRecording(sessionPath);

      // Assert
      expect(result, false);
      expect(
        notifier.state.isSharingRecording,
        false,
      ); // Sharing state should be reset
      expect(
        notifier.state.errorMessage,
        contains('Error sharing recording'),
      ); // Error message should be set
      verify(mockDataManagementService.shareSession(sessionPath)).called(1);
    });

    test(
      'openSessionInFileExplorer should call through to data management service',
      () async {
        // Arrange
        final sessionPath = '/test/path/123456';

        // Mock the DataManagementService to return success
        when(
          mockDataManagementService.openSessionInFileExplorer(sessionPath),
        ).thenAnswer((_) async => true);

        // Act
        final result = await notifier.openSessionInFileExplorer(sessionPath);

        // Assert
        expect(result, true);
        verify(
          mockDataManagementService.openSessionInFileExplorer(sessionPath),
        ).called(1);
      },
    );

    test('openSessionInFileExplorer should handle exceptions', () async {
      // Arrange
      final sessionPath = '/test/path/123456';

      // Mock the DataManagementService to throw an exception
      when(
        mockDataManagementService.openSessionInFileExplorer(sessionPath),
      ).thenThrow(Exception('Test error'));

      // Act
      final result = await notifier.openSessionInFileExplorer(sessionPath);

      // Assert
      expect(result, false);
      expect(
        notifier.state.errorMessage,
        contains('Error opening file explorer'),
      ); // Error message should be set
      verify(
        mockDataManagementService.openSessionInFileExplorer(sessionPath),
      ).called(1);
    });
  });
}
