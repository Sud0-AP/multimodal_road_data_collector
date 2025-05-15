import 'dart:async';
import 'dart:math';
import 'dart:isolate';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:collection/collection.dart';

import '../../../../core/services/sensor_service.dart';
import '../../../../core/services/providers.dart';
import '../../../../core/services/ntp_service.dart';
import '../../../../core/services/file_storage_service.dart';
import '../../../../core/services/implementations/file_storage_service_impl.dart';
import '../../../../core/utils/logger.dart';
import '../models/corrected_sensor_data_point.dart';
import '../../../../core/utils/ema_filter.dart';
import '../../../../core/utils/isolate_logger.dart';

/// Processed sensor data for recording and calibration
class ProcessedSensorData {
  /// Original raw sensor data
  final SensorData rawData;

  /// Corrected Z-axis acceleration (with initial calibration applied)
  final double correctedAccelZ;

  /// Corrected Z-axis gyroscope reading (with initial calibration applied)
  final double correctedGyroZ;

  /// Acceleration magnitude (calculated from X, Y, Z components)
  final double accelMagnitude;

  /// Whether this data point represents a bump/pothole detection
  final bool isBumpDetected;

  /// Constructor
  ProcessedSensorData({
    required this.rawData,
    required this.correctedAccelZ,
    required this.correctedGyroZ,
    required this.accelMagnitude,
    this.isBumpDetected = false,
  });
}

/// Structure to pass data for CSV writing in background
class CsvWriteData {
  /// The session directory where to write the CSV file
  final String sessionDirectory;

  /// List of sensor data points to write
  final List<CorrectedSensorDataPoint> dataPoints;

  /// Operation ID for tracking
  final String operationId;

  /// Constructor
  CsvWriteData({
    required this.sessionDirectory,
    required this.dataPoints,
    required this.operationId,
  });
}

/// Result structure returned from background processing
class CsvWriteResult {
  /// Whether the operation was successful
  final bool success;

  /// Number of rows written
  final int rowsWritten;

  /// Error message if operation failed
  final String? errorMessage;

  /// Operation ID for tracking
  final String operationId;

  /// Constructor for successful operation
  CsvWriteResult.success(this.rowsWritten, this.operationId)
    : success = true,
      errorMessage = null;

  /// Constructor for failed operation
  CsvWriteResult.failure(this.errorMessage, this.operationId)
    : success = false,
      rowsWritten = 0;
}

/// Process CSV data in a background isolate
///
/// This function runs in a separate isolate to prevent UI jank when writing
/// large amounts of sensor data to CSV files.
///
/// Returns a CsvWriteResult indicating success/failure and details
Future<CsvWriteResult> _processBufferInBackground(CsvWriteData data) async {
  try {
    if (data.dataPoints.isEmpty) {
      return CsvWriteResult.success(0, data.operationId);
    }

    // Using IsolateLogger instead of debugPrint for better logging format
    IsolateLogger.file(
      'Processing ${data.dataPoints.length} data points for ${data.sessionDirectory}',
    );

    // Create an instance of FileStorageServiceImpl without dependencies
    // This is necessary because we're in a separate isolate
    final fileStorageService = FileStorageServiceImpl();

    // Ensure the CSV file exists with proper headers
    final csvPath = await fileStorageService.getSensorDataCsvPath(
      data.sessionDirectory,
      createIfNotExists: true,
    );

    // Using IsolateLogger for consistent logging
    IsolateLogger.file('Writing to file: $csvPath');

    // Verify directory exists
    final directory = await fileStorageService.createDirectory(
      data.sessionDirectory,
    );

    if (!directory) {
      // Using IsolateLogger for consistent error logging
      IsolateLogger.error(
        'FILE',
        'Failed to create directory: ${data.sessionDirectory}',
      );
      return CsvWriteResult.failure(
        'Failed to create or access directory: ${data.sessionDirectory}',
        data.operationId,
      );
    }

    // Verify we have write access by checking if we can create a temporary file
    final testFilePath = '${data.sessionDirectory}/test_write_access.tmp';
    final hasWriteAccess = await fileStorageService.writeStringToFile(
      'test',
      testFilePath,
    );

    if (!hasWriteAccess) {
      // Using IsolateLogger for consistent error logging
      IsolateLogger.error(
        'FILE',
        'No write access to directory: ${data.sessionDirectory}',
      );
      return CsvWriteResult.failure(
        'No write access to directory: ${data.sessionDirectory}',
        data.operationId,
      );
    }

    // Clean up test file
    await fileStorageService.deleteFile(testFilePath);

    // Convert data points to CSV rows
    final rows = data.dataPoints.map((point) => point.toCsvRow()).toList();

    // Append rows to the CSV file
    final success = await fileStorageService.appendToCsv(csvPath, rows);

    if (success) {
      // Using IsolateLogger for consistent success logging
      IsolateLogger.file('Successfully wrote ${rows.length} rows to $csvPath');
      return CsvWriteResult.success(rows.length, data.operationId);
    } else {
      // Using IsolateLogger for consistent error logging
      IsolateLogger.error('FILE', 'Failed to write data to CSV file: $csvPath');
      return CsvWriteResult.failure(
        'Failed to write data to CSV file: no error details available',
        data.operationId,
      );
    }
  } catch (e, stackTrace) {
    // Return detailed error information for debugging
    // Using IsolateLogger for consistent error logging
    IsolateLogger.error('FILE', 'CSV write error', e, stackTrace);
    return CsvWriteResult.failure(
      'Error writing sensor data to CSV: $e',
      data.operationId,
    );
  }
}

/// Manager responsible for handling sensor data during recording sessions
class RecordingSessionManager {
  /// Instance of SensorService for raw data access
  final SensorService _sensorService;

  /// Instance of NtpService for time synchronization
  final NtpService? _ntpService;

  /// Instance of FileStorageService for data storage
  final FileStorageService? _fileStorageService;

  /// StreamController for processed sensor data
  final _processedDataController =
      StreamController<ProcessedSensorData>.broadcast();

  /// StreamController for CSV write status updates
  final _csvWriteStatusController =
      StreamController<CsvWriteResult>.broadcast();

  /// Buffer for sensor data points ready for CSV writing
  final List<CorrectedSensorDataPoint> _sensorDataBuffer = [];

  /// Maximum buffer size before flushing to disk (configurable)
  /// Increased from 150 to 300 to allow more time for pothole detection updates
  final int _maxBufferSize = 300;

  /// Current recording session directory
  String? _currentSessionDirectory;

  /// Map of Completers for tracking multiple background write operations
  final Map<String, Completer<CsvWriteResult>> _backgroundWriteCompleters = {};

  /// Map for tracking operation status
  final Map<String, bool> _operationStatus = {};

  /// Flag to track if there's an active write operation in progress
  bool _isWriteInProgress = false;

  /// Count of total rows written to CSV during this session
  int _totalRowsWritten = 0;

  /// Counter for failed write attempts
  int _failedWriteAttempts = 0;

  /// Number of concurrent write operations in progress
  int _concurrentWriteCount = 0;

  /// Maximum allowed concurrent write operations
  static const int _maxConcurrentWrites = 3;

  /// Maximum consecutive failed write attempts before notifying
  static const int _maxFailedWriteAttempts = 3;

  /// Retry count for failed operations
  static const int _maxRetryAttempts = 2;

  /// Map to track retry attempts for operations
  final Map<String, int> _retryAttempts = {};

  /// Callback for when buffer reaches capacity
  Function(List<CorrectedSensorDataPoint>)? onBufferFull;

  /// Callback for critical errors during CSV writing
  Function(String errorMessage)? onCsvWriteError;

  /// Subscription to the sensor data stream
  StreamSubscription<SensorData>? _sensorDataSubscription;

  /// Flag indicating if data collection is active
  bool _isDataCollectionActive = false;

  /// Initial calibration values for sensor corrections
  /// These should be set from initial calibration (Task 2)
  double _accelZOffset = 0.0;
  double _gyroZOffset = 0.0;
  bool _swapXY = false;

  /// Session-specific calibration values (from pre-recording calibration)
  double _sessionAccelOffsetZ = 0.0;
  double _gyroZDrift = 0.0;
  double _bumpThreshold = 0.0;
  bool _useSessionParameters = false;

  /// Timestamp tracking for hybrid timestamping
  int?
  _monotonicStartTimeMs; // Device monotonic clock time when sensor stream starts
  DateTime? _ntpStartTime; // NTP-synced time when sensor stream starts
  int?
  _monotonicEndTimeMs; // Device monotonic clock time when sensor stream stops
  DateTime? _ntpEndTime; // NTP-synced time when sensor stream stops

  /// EMA Filters for accelerometer
  final EMAFilter _emaFilterX = EMAFilter(alpha: 0.15);
  final EMAFilter _emaFilterY = EMAFilter(alpha: 0.15);
  final EMAFilter _emaFilterZ = EMAFilter(alpha: 0.15);

  /// Constructor
  RecordingSessionManager(
    this._sensorService, [
    this._ntpService,
    this._fileStorageService,
  ]);

  /// Initialize the manager
  Future<void> initialize() async {
    await _sensorService.initialize();
    if (_ntpService != null) {
      await _ntpService!.initialize();
    }
  }

  /// Set the current session directory for storage
  void setSessionDirectory(String sessionDirectory) {
    _currentSessionDirectory = sessionDirectory;
  }

  /// Get stream of processed sensor data
  Stream<ProcessedSensorData> getProcessedSensorStream() {
    return _processedDataController.stream;
  }

  /// Get stream of CSV write status updates
  Stream<CsvWriteResult> getCsvWriteStatusStream() {
    return _csvWriteStatusController.stream;
  }

  /// Get the NTP start time of the current recording session
  DateTime? getNtpStartTime() {
    return _ntpStartTime;
  }

  /// Get the NTP end time of the current recording session
  DateTime? getNtpEndTime() {
    return _ntpEndTime;
  }

  /// Get the monotonic start time of the current recording session in milliseconds
  int? getMonotonicStartTimeMs() {
    return _monotonicStartTimeMs;
  }

  /// Get the monotonic end time of the current recording session in milliseconds
  int? getMonotonicEndTimeMs() {
    return _monotonicEndTimeMs;
  }

  /// Get the current buffered sensor data points
  List<CorrectedSensorDataPoint> getBufferedDataPoints() {
    return List<CorrectedSensorDataPoint>.from(_sensorDataBuffer);
  }

  /// Update a data point in the buffer (used for pothole detection updates)
  /// Returns true if the data point was found and updated
  bool updateDataPoint(CorrectedSensorDataPoint updatedDataPoint) {
    // We can't directly update the buffer, as the data might have already been flushed
    // or processed. Instead, we'll update it only if it's still in the buffer.

    // Find matching data point by timestamp
    final index = _sensorDataBuffer.indexWhere(
      (dp) => dp.timestampMs == updatedDataPoint.timestampMs,
    );

    // If found, update it with the new data point
    if (index >= 0) {
      _sensorDataBuffer[index] = updatedDataPoint;
      return true;
    }

    // Data point not found (already flushed to file)
    // For pothole annotation window, we won't count this as an error
    // and we'll return true to avoid warning logs about data points that
    // are expected to be already flushed
    return false;
  }

  /// Update multiple data points in a time window
  /// Returns the number of data points successfully updated
  Future<int> updateDataPointsInWindow(
    int startTimestampMs,
    int endTimestampMs,
    Map<String, dynamic> updates,
  ) async {
    int updatedCount = 0;

    try {
      // First, try to update any data points still in the buffer
      for (int i = 0; i < _sensorDataBuffer.length; i++) {
        final dp = _sensorDataBuffer[i];
        if (dp.timestampMs >= startTimestampMs &&
            dp.timestampMs <= endTimestampMs) {
          // Apply updates
          final updated = dp.copyWith(
            isBump: updates['isBump'] ?? dp.isBump,
            // Note: using userFeedback instead of bumpSeverity/annotation
            // which aren't defined in the model
            userFeedback: updates['userFeedback'] ?? dp.userFeedback,
          );
          _sensorDataBuffer[i] = updated;
          updatedCount++;
        }
      }

      // Then, try to update data points that have already been written to the CSV
      if (_currentSessionDirectory != null && _fileStorageService != null) {
        final csvPath = await _fileStorageService!.getSensorDataCsvPath(
          _currentSessionDirectory!,
        );

        if (await _fileStorageService!.fileExists(csvPath)) {
          final csvString = await _fileStorageService!.readStringFromFile(
            csvPath,
          );
          if (csvString != null) {
            final lines = csvString.split('\n');
            bool fileModified = false;

            // Skip header row
            for (int i = 1; i < lines.length; i++) {
              try {
                if (lines[i].trim().isEmpty) continue;

                final columns = lines[i].split(',');
                if (columns.length >= 10) {
                  // Make sure we have enough columns
                  // Parse timestamp
                  final timestampMs = int.tryParse(columns[0]);
                  if (timestampMs == null) continue;

                  if (timestampMs >= startTimestampMs &&
                      timestampMs <= endTimestampMs) {
                    final List<String> updatedColumns = List<String>.from(
                      columns,
                    );

                    // Apply updates - note that column indices match the CSV format
                    if (updates.containsKey('isBump')) {
                      updatedColumns[8] =
                          (updates['isBump'] as bool) ? '1' : '0';
                    }
                    if (updates.containsKey('userFeedback')) {
                      updatedColumns[9] = updates['userFeedback'].toString();
                    }

                    // Replace the line in the file
                    lines[i] = updatedColumns.join(',');
                    fileModified = true;
                    updatedCount++;
                  }
                }
              } catch (e) {
                // Skip invalid rows
                Logger.error('CSV', 'Error parsing CSV row', e);
              }
            }

            // Write the modified CSV back to the file if changes were made
            if (fileModified) {
              await _fileStorageService!.writeStringToFile(
                lines.join('\n'),
                csvPath,
              );
              Logger.file('Updated CSV file on disk with bump annotations');
            }
          }
        }
      }
    } catch (e, stackTrace) {
      Logger.error('CSV', 'Error updating CSV on disk', e, stackTrace);
    }

    return updatedCount;
  }

  /// Clear the sensor data buffer
  void clearBuffer() {
    _sensorDataBuffer.clear();
  }

  /// Force flush the current buffer regardless of size
  /// Returns the flushed data points for processing
  Future<List<CorrectedSensorDataPoint>> flushBuffer() async {
    if (_sensorDataBuffer.isEmpty) {
      return [];
    }

    final dataPoints = List<CorrectedSensorDataPoint>.from(_sensorDataBuffer);
    clearBuffer();

    // If a session directory is set and we have a file storage service,
    // write the data to a CSV file in the background
    if (_currentSessionDirectory != null && _fileStorageService != null) {
      await _writeBufferToFileInBackground(
        _currentSessionDirectory!,
        dataPoints,
      );
    }

    return dataPoints;
  }

  /// Generate a unique operation ID for tracking
  String _generateOperationId() {
    return 'write_op_${DateTime.now().millisecondsSinceEpoch}_${_concurrentWriteCount}';
  }

  /// Write buffer data to file in background using compute
  /// Returns true if the write was successful
  Future<bool> _writeBufferToFileInBackground(
    String sessionDirectory,
    List<CorrectedSensorDataPoint> dataPoints,
  ) async {
    // Check if too many concurrent writes
    if (_concurrentWriteCount >= _maxConcurrentWrites) {
      Logger.recording(
        'Too many concurrent write operations. Waiting for completion...',
      );
      // Wait for any operation to complete before continuing
      await Future.any(
        _backgroundWriteCompleters.values.map((completer) => completer.future),
      );
    }

    // Generate a unique operation ID
    final operationId = _generateOperationId();

    // Create a completer for this operation
    final completer = Completer<CsvWriteResult>();
    _backgroundWriteCompleters[operationId] = completer;
    _operationStatus[operationId] = false;
    _retryAttempts[operationId] = 0;

    // Increment counter for concurrent writes
    _concurrentWriteCount++;
    _isWriteInProgress = true;

    try {
      // Create data package for background processing
      final writeData = CsvWriteData(
        sessionDirectory: sessionDirectory,
        dataPoints: dataPoints,
        operationId: operationId,
      );

      // Use compute to offload CSV writing to a separate isolate
      // This prevents UI jank during heavy I/O operations
      final result = await compute<CsvWriteData, CsvWriteResult>(
        _processBufferInBackground,
        writeData,
      );

      if (result.success) {
        _totalRowsWritten += result.rowsWritten;
        _failedWriteAttempts = 0; // Reset failed attempts counter on success
        _operationStatus[operationId] = true;

        // Notify success via the stream
        _csvWriteStatusController.add(result);

        completer.complete(result);
        return true;
      } else {
        // Handle write failure - attempt retry if below threshold
        _failedWriteAttempts++;
        final retryCount = _retryAttempts[operationId] ?? 0;

        if (retryCount < _maxRetryAttempts) {
          _retryAttempts[operationId] = retryCount + 1;
          Logger.warning(
            'CSV',
            'CSV write failed, retrying (${retryCount + 1}/$_maxRetryAttempts): ${result.errorMessage}',
          );

          // Brief delay before retry
          await Future.delayed(Duration(milliseconds: 500));

          // Remove the current completer and create a new one
          _backgroundWriteCompleters.remove(operationId);
          _concurrentWriteCount--;

          // Retry the operation
          return await _writeBufferToFileInBackground(
            sessionDirectory,
            dataPoints,
          );
        }

        // Max retries reached, report failure
        if (_failedWriteAttempts >= _maxFailedWriteAttempts &&
            onCsvWriteError != null) {
          onCsvWriteError!(
            result.errorMessage ?? 'Multiple CSV write failures detected',
          );
        }

        Logger.critical(
          'CSV',
          'CSV write failed after $_maxRetryAttempts retries: ${result.errorMessage}',
        );

        // Notify failure via the stream
        _csvWriteStatusController.add(result);

        completer.complete(result);
        return false;
      }
    } catch (e, stackTrace) {
      _failedWriteAttempts++;
      final errorMsg = 'Error writing buffer to file: $e';
      Logger.error('CSV', errorMsg, e, stackTrace);

      // Handle write failure - attempt retry if below threshold
      // Create a failure result
      final result = CsvWriteResult.failure(errorMsg, operationId);

      // Check if we should retry
      final retryCount = _retryAttempts[operationId] ?? 0;
      if (retryCount < _maxRetryAttempts) {
        _retryAttempts[operationId] = retryCount + 1;
        Logger.warning(
          'CSV',
          'CSV write error, retrying (${retryCount + 1}/$_maxRetryAttempts): $errorMsg',
        );

        // Brief delay before retry
        await Future.delayed(Duration(milliseconds: 500));

        // Remove the current completer and create a new one
        _backgroundWriteCompleters.remove(operationId);
        _concurrentWriteCount--;

        // Retry the operation
        return await _writeBufferToFileInBackground(
          sessionDirectory,
          dataPoints,
        );
      }

      if (_failedWriteAttempts >= _maxFailedWriteAttempts &&
          onCsvWriteError != null) {
        onCsvWriteError!(errorMsg);
      }

      // Notify failure via the stream
      _csvWriteStatusController.add(result);

      if (!completer.isCompleted) {
        completer.complete(result);
      }
      return false;
    } finally {
      // Clean up operation tracking regardless of outcome
      if (_backgroundWriteCompleters.containsKey(operationId)) {
        _backgroundWriteCompleters.remove(operationId);
        _concurrentWriteCount--;
      }

      _retryAttempts.remove(operationId);
      _operationStatus.remove(operationId);

      if (_concurrentWriteCount == 0) {
        _isWriteInProgress = false;
      }
    }
  }

  /// Set callback for when buffer is full
  void setBufferFullCallback(
    Function(List<CorrectedSensorDataPoint>) callback,
  ) {
    onBufferFull = callback;
  }

  /// Set callback for critical CSV write errors
  void setCsvWriteErrorCallback(Function(String) callback) {
    onCsvWriteError = callback;
  }

  /// Get the total number of rows written to CSV in this session
  int getTotalRowsWritten() {
    return _totalRowsWritten;
  }

  /// Get the number of failed write attempts
  int getFailedWriteAttempts() {
    return _failedWriteAttempts;
  }

  /// Wait for all pending write operations to complete
  /// Returns true if all completed successfully, false if any failed
  Future<bool> waitForPendingWrites({Duration? timeout}) async {
    if (_backgroundWriteCompleters.isEmpty) {
      return true;
    }

    // Create a list of futures to wait for
    final futures =
        _backgroundWriteCompleters.values.map((c) => c.future).toList();

    try {
      // Apply timeout to all futures individually if specified
      List<Future<CsvWriteResult>> timedFutures = futures;
      if (timeout != null) {
        timedFutures = futures.map((f) => f.timeout(timeout)).toList();
      }

      // Wait for all operations to complete
      final results = await Future.wait(timedFutures, eagerError: false);

      // Check if any operations failed
      return results.every((result) => result.success);
    } on TimeoutException {
      Logger.warning('CSV', 'Timeout waiting for write operations to complete');
      return false;
    } catch (e) {
      Logger.error('CSV', 'Error waiting for write operations', e);
      return false;
    }
  }

  /// Start collecting sensor data
  Future<void> startSensorDataCollection() async {
    if (_isDataCollectionActive) {
      return;
    }

    // Clear any existing buffer
    clearBuffer();

    // Reset counters
    _totalRowsWritten = 0;
    _failedWriteAttempts = 0;
    _concurrentWriteCount = 0;
    _isWriteInProgress = false;
    _backgroundWriteCompleters.clear();
    _operationStatus.clear();
    _retryAttempts.clear();

    // Record start timestamps (both monotonic and NTP)
    _monotonicStartTimeMs = DateTime.now().millisecondsSinceEpoch;

    // Attempt to get NTP time if service is available
    if (_ntpService != null) {
      try {
        _ntpStartTime = await _ntpService!.getCurrentNtpTime();
        Logger.sensor(
          'SENSOR START: NTP time: ${_ntpStartTime!.toIso8601String()}',
        );
      } catch (e) {
        // Fallback to device time if NTP fails
        _ntpStartTime = DateTime.now().toUtc();
        Logger.sensor(
          'SENSOR START: Using device time (NTP failed): ${_ntpStartTime!.toIso8601String()}',
        );
        Logger.warning('NTP', 'Failed to get NTP time: $e');
      }
    } else {
      // No NTP service, use device time
      _ntpStartTime = DateTime.now().toUtc();
      Logger.sensor(
        'SENSOR START: Using device time (no NTP service): ${_ntpStartTime!.toIso8601String()}',
      );
    }

    Logger.sensor('SENSOR START: Monotonic time: $_monotonicStartTimeMs ms');
    Logger.sensor('Starting data collection...');

    // Initialize sensor service if needed
    if (!_sensorService.isSensorDataCollectionActive()) {
      await _sensorService.startSensorDataCollection();
    }

    // Subscribe to sensor data stream
    _sensorDataSubscription = _sensorService.getSensorDataStream().listen(
      _processSensorData,
      onError: (error) {
        Logger.error('SENSOR', 'Error in sensor data stream', error);
        _processedDataController.addError(error);
      },
    );

    _isDataCollectionActive = true;
    Logger.sensor('Data collection started');
  }

  /// Stop collecting sensor data
  Future<bool> stopSensorDataCollection() async {
    if (!_isDataCollectionActive) {
      return true;
    }

    Logger.sensor('Stopping data collection...');

    // Record end timestamps (both monotonic and NTP)
    _monotonicEndTimeMs = DateTime.now().millisecondsSinceEpoch;

    if (_ntpService != null) {
      try {
        _ntpEndTime = await _ntpService!.getCurrentNtpTime();
        Logger.sensor(
          'SENSOR STOP: NTP time: ${_ntpEndTime!.toIso8601String()}',
        );
      } catch (e) {
        // Fallback to device time if NTP fails
        _ntpEndTime = DateTime.now().toUtc();
        Logger.sensor(
          'SENSOR STOP: Using device time (NTP failed): ${_ntpEndTime!.toIso8601String()}',
        );
        Logger.warning('NTP', 'Failed to get NTP time: $e');
      }
    } else {
      // No NTP service, use device time
      _ntpEndTime = DateTime.now().toUtc();
      Logger.sensor(
        'SENSOR STOP: Using device time (no NTP service): ${_ntpEndTime!.toIso8601String()}',
      );
    }

    Logger.sensor('SENSOR STOP: Monotonic time: $_monotonicEndTimeMs ms');

    // Calculate and log duration
    final durationMs = _monotonicEndTimeMs! - _monotonicStartTimeMs!;
    Logger.sensor(
      'Recording duration: ${(durationMs / 1000).toStringAsFixed(2)} seconds',
    );

    // Cancel subscription to sensor data stream
    await _sensorDataSubscription?.cancel();
    _sensorDataSubscription = null;

    // Stop sensor service if needed
    if (_sensorService.isSensorDataCollectionActive()) {
      await _sensorService.stopSensorDataCollection();
    }

    // Force flush any remaining buffer entries
    if (_sensorDataBuffer.isNotEmpty) {
      Logger.sensor(
        'Flushing ${_sensorDataBuffer.length} remaining data points...',
      );
      await flushBuffer();
    }

    // Wait for all background write operations to complete
    // Use a timeout to avoid blocking indefinitely
    Logger.sensor('Waiting for all write operations to complete...');
    final allWritesSuccessful = await waitForPendingWrites(
      timeout: Duration(seconds: 10),
    );

    if (!allWritesSuccessful) {
      Logger.warning(
        'SENSOR',
        'Some CSV write operations did not complete successfully',
      );
    } else {
      Logger.sensor('All CSV write operations completed successfully');
    }

    Logger.info(
      'SENSOR',
      'Sampling stats - Wrote $_totalRowsWritten data points',
    );
    final samplingRate = calculateActualSamplingRateHz();
    if (samplingRate != null) {
      Logger.info(
        'SENSOR',
        'Actual sampling rate: ${samplingRate.toStringAsFixed(2)} Hz',
      );
    }

    _isDataCollectionActive = false;
    Logger.sensor('Data collection stopped');

    return allWritesSuccessful;
  }

  /// Set calibration values for sensor corrections
  void setCalibrationParameters({
    double accelZOffset = 0.0,
    double gyroZOffset = 0.0,
    bool swapXY = false,
  }) {
    _accelZOffset = accelZOffset;
    _gyroZOffset = gyroZOffset;
    _swapXY = swapXY;
  }

  /// Set session-specific calibration parameters from pre-recording calibration
  void setSessionCalibrationParameters({
    required double sessionAccelOffsetZ,
    required double gyroZDrift,
    required double bumpThreshold,
    bool useSessionParameters = true,
  }) {
    _sessionAccelOffsetZ = sessionAccelOffsetZ;
    _gyroZDrift = gyroZDrift;
    _bumpThreshold = bumpThreshold;
    _useSessionParameters = useSessionParameters;
  }

  /// Clear session-specific calibration parameters
  void clearSessionCalibrationParameters() {
    _sessionAccelOffsetZ = 0.0;
    _gyroZDrift = 0.0;
    _bumpThreshold = 0.0;
    _useSessionParameters = false;

    // Reset EMA filters here as well if a session is cleared mid-way
    // or if these params affect EMA (though currently they don't directly)
    _emaFilterX.reset();
    _emaFilterY.reset();
    _emaFilterZ.reset();
  }

  /// Process raw sensor data and apply corrections
  void _processSensorData(SensorData data) {
    // Skip processing if recording hasn't properly started
    if (_monotonicStartTimeMs == null) {
      return;
    }

    // Calculate relative timestamp from start of recording
    final int relativeTimestampMs = data.timestamp - _monotonicStartTimeMs!;

    // Apply EMA filter to raw accelerometer data
    double rawAccelX = _emaFilterX.filter(data.accelerometerX);
    double rawAccelY = _emaFilterY.filter(data.accelerometerY);
    double rawAccelZ = _emaFilterZ.filter(data.accelerometerZ);

    // Apply sensor corrections based on initial calibration
    double accelX = rawAccelX; // Use filtered X
    double accelY = rawAccelY; // Use filtered Y

    // Swap X and Y if required by calibration
    if (_swapXY) {
      final temp = accelX;
      accelX = accelY;
      accelY = temp;
    }

    // Apply initial Z-offset correction to filtered Z
    double correctedAccelZ = rawAccelZ - _accelZOffset;

    // Apply session-specific Z-offset if available
    if (_useSessionParameters) {
      correctedAccelZ -= _sessionAccelOffsetZ;
    }

    // Apply initial gyro Z-offset correction
    double correctedGyroZ = data.gyroscopeZ - _gyroZOffset;

    // Apply session-specific gyro drift correction if available
    if (_useSessionParameters) {
      correctedGyroZ -= _gyroZDrift;
    }

    // Calculate acceleration magnitude (for bump detection)
    final accelMagnitude = sqrt(
      accelX * accelX + accelY * accelY + correctedAccelZ * correctedAccelZ,
    );

    // We'll no longer detect bumps directly here
    // SpikeDetectionService will handle proper detection with consecutive readings and refractory periods
    // This fixes false positives in the CSV data

    // Create processed data for the stream
    final processedData = ProcessedSensorData(
      rawData: data,
      correctedAccelZ: correctedAccelZ,
      correctedGyroZ: correctedGyroZ,
      accelMagnitude: accelMagnitude,
      isBumpDetected: false, // Always initialize to false
    );

    // Create CorrectedSensorDataPoint for buffering/CSV
    final correctedDataPoint = CorrectedSensorDataPoint.fromProcessedData(
      relativeTimestampMs: relativeTimestampMs,
      accelX: accelX,
      accelY: accelY,
      correctedAccelZ: correctedAccelZ,
      accelMagnitude: accelMagnitude,
      gyroX: data.gyroscopeX,
      gyroY: data.gyroscopeY,
      correctedGyroZ: correctedGyroZ,
      isBump:
          false, // Always initialize to false, will be updated by SpikeDetectionService
    );

    // Add to buffer
    _sensorDataBuffer.add(correctedDataPoint);

    // Check if buffer is full and trigger write if needed
    if (_sensorDataBuffer.length >= _maxBufferSize) {
      _handleBufferFull();
    }

    // Add processed data to stream for UI updates
    _processedDataController.add(processedData);

    // Process the data point with the SpikeDetectionNotifier if available
    // This is done outside this class in the recording_screen.dart when reading the sensor stream
  }

  /// Handle buffer full event
  Future<void> _handleBufferFull() async {
    final dataPoints = await flushBuffer();

    // If callback is set, notify
    if (onBufferFull != null) {
      onBufferFull!(dataPoints);
    }
  }

  /// Check if data collection is active
  bool isDataCollectionActive() {
    return _isDataCollectionActive;
  }

  /// Check if initial calibration has been completed
  /// Returns true if calibration parameters have been set
  bool isInitialCalibrationDone() {
    // Check if any calibration values have been set
    // This is a simple check - you may want to enhance this with persistent storage
    // to properly track calibration status across app restarts
    return _accelZOffset != 0.0 || _gyroZOffset != 0.0 || _swapXY;
  }

  /// Calculate actual sensor sampling rate based on recording duration
  double? calculateActualSamplingRateHz() {
    if (_monotonicStartTimeMs == null || _monotonicEndTimeMs == null) {
      return null;
    }

    final durationMs = _monotonicEndTimeMs! - _monotonicStartTimeMs!;
    if (durationMs <= 0) {
      return null;
    }

    // Use the actual number of samples written to CSV
    final totalSamples = _totalRowsWritten;

    return totalSamples / (durationMs / 1000.0);
  }

  /// Get total number of processed samples
  int _getTotalProcessedSamples() {
    // Return the actual count of samples written to CSV
    return _totalRowsWritten;
  }

  /// Dispose of resources
  Future<void> dispose() async {
    await stopSensorDataCollection();
    await _processedDataController.close();
    await _csvWriteStatusController.close();
  }

  /// Start a recording session with the specified directory
  Future<void> startSession(String sessionDirectory) async {
    // Set session directory
    setSessionDirectory(sessionDirectory);

    // Start sensor data collection
    await startSensorDataCollection();
  }

  /// Stop the current recording session
  Future<void> stopSession() async {
    // Stop data collection and flush buffers
    await stopSensorDataCollection();

    // Wait for any background operations to complete with timeout
    final allWritesSuccessful = await waitForPendingWrites(
      timeout: Duration(seconds: 5),
    );

    if (!allWritesSuccessful) {
      debugPrint(
        'Warning: Some CSV write operations did not complete successfully during session stop',
      );
    }
  }
}

/// Provider for RecordingSessionManager
final recordingSessionManagerProvider = Provider<RecordingSessionManager>((
  ref,
) {
  final sensorService = ref.watch(sensorServiceProvider);
  final ntpService = ref.watch(ntpServiceProvider);
  final fileStorageService = ref.watch(fileStorageServiceProvider);
  return RecordingSessionManager(sensorService, ntpService, fileStorageService);
});
