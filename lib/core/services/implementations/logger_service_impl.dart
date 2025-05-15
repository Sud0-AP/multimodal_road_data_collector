import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import '../logger_service.dart';
import '../file_storage_service.dart';
import '../preferences_service.dart';
import '../../../constants/app_constants.dart';

/// Implementation of Logger service that writes to files
class LoggerServiceImpl implements LoggerService {
  /// Date format for timestamps in logs
  static final DateFormat _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');

  /// File storage service for writing logs
  final FileStorageService _fileStorageService;

  /// Preferences service for checking debugging mode status
  final PreferencesService _preferencesService;

  /// Current active debug session ID
  String? _currentSessionId;

  /// Current log file path
  String? _currentLogFilePath;

  /// Flag to indicate if debug mode is active
  bool _isDebugSessionActive = false;

  /// Constructor
  LoggerServiceImpl({
    required FileStorageService fileStorageService,
    required PreferencesService preferencesService,
  }) : _fileStorageService = fileStorageService,
       _preferencesService = preferencesService;

  @override
  Future<void> initialize() async {
    // No initialization required for now
    // In the future, we might want to:
    // - Check if previous sessions were interrupted
    // - Create log directory if it doesn't exist
    // - Set up log rotation policies
  }

  @override
  Future<String> startDebugSession() async {
    if (_isDebugSessionActive) {
      // If already active, just return current session ID
      return _currentSessionId!;
    }

    // Generate a new session ID based on timestamp
    final timestamp = DateTime.now();
    final sessionId = 'debug_${timestamp.millisecondsSinceEpoch}';
    _currentSessionId = sessionId;

    // Create log directory
    final baseDirectory = await _fileStorageService.getSessionsBaseDirectory();
    final logsDirectory = path.join(baseDirectory, 'logs');
    await _fileStorageService.createDirectory(logsDirectory);

    // Create session-specific directory
    final sessionDirectory = path.join(logsDirectory, sessionId);
    await _fileStorageService.createDirectory(sessionDirectory);

    // Create main log file
    _currentLogFilePath = path.join(sessionDirectory, 'app.log');

    // Write initial log entry
    final initialEntry = _formatLogEntry(
      'INFO',
      'LoggerService',
      'Debug session started. Device: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
    );

    await _fileStorageService.writeStringToFile(
      initialEntry,
      _currentLogFilePath!,
    );
    _isDebugSessionActive = true;

    // Log basic device info
    await info('LoggerService', 'App Version: ${AppConstants.appVersion}');

    return sessionId;
  }

  @override
  Future<void> endDebugSession() async {
    if (!_isDebugSessionActive || _currentLogFilePath == null) {
      return;
    }

    // Write ending log entry
    final finalEntry = _formatLogEntry(
      'INFO',
      'LoggerService',
      'Debug session ended.',
    );

    try {
      final file = File(_currentLogFilePath!);
      await file.writeAsString(finalEntry, mode: FileMode.append);
    } catch (e) {
      // If we can't write to the log file, there's not much we can do
      print('Failed to write final log entry: $e');
    }

    _isDebugSessionActive = false;
    _currentSessionId = null;
    _currentLogFilePath = null;
  }

  @override
  bool isDebugSessionActive() {
    return _isDebugSessionActive;
  }

  @override
  Future<void> info(String tag, String message) async {
    await _log('INFO', tag, message);
  }

  @override
  Future<void> debug(String tag, String message) async {
    if (!_isDebugSessionActive) {
      // Only log debug messages when debug mode is active
      return;
    }
    await _log('DEBUG', tag, message);
  }

  @override
  Future<void> warning(String tag, String message) async {
    await _log('WARN', tag, message);
  }

  @override
  Future<void> error(
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) async {
    String fullMessage = message;

    if (exception != null) {
      fullMessage += '\nException: $exception';

      if (stackTrace != null) {
        fullMessage += '\nStackTrace: $stackTrace';
      }
    }

    await _log('ERROR', tag, fullMessage);
  }

  @override
  Future<void> critical(
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]) async {
    String fullMessage = message;

    if (exception != null) {
      fullMessage += '\nException: $exception';

      if (stackTrace != null) {
        fullMessage += '\nStackTrace: $stackTrace';
      }
    }

    await _log('CRITICAL', tag, fullMessage);
  }

  @override
  Future<String?> getCurrentLogFilePath() async {
    return _currentLogFilePath;
  }

  @override
  Future<List<String>> getLogFilePaths([String? sessionId]) async {
    final baseDirectory = await _fileStorageService.getSessionsBaseDirectory();
    final logsDirectory = path.join(baseDirectory, 'logs');

    // If directory doesn't exist, return empty list
    if (!await Directory(logsDirectory).exists()) {
      return [];
    }

    if (sessionId != null) {
      // Get logs for specific session
      final sessionDirectory = path.join(logsDirectory, sessionId);

      if (!await Directory(sessionDirectory).exists()) {
        return [];
      }

      return _fileStorageService.listFilesWithExtension(
        sessionDirectory,
        '.log',
      );
    } else {
      // Get logs from all sessions
      List<String> allLogFiles = [];

      // Get all session directories
      final sessionDirs = await _fileStorageService.listFiles(logsDirectory);

      // For each session directory, get all log files
      for (final sessionDir in sessionDirs) {
        if (await Directory(sessionDir).exists()) {
          final logFiles = await _fileStorageService.listFilesWithExtension(
            sessionDir,
            '.log',
          );
          allLogFiles.addAll(logFiles);
        }
      }

      return allLogFiles;
    }
  }

  /// Internal helper to format a log entry with timestamp
  String _formatLogEntry(String level, String tag, String message) {
    final timestamp = _dateFormat.format(DateTime.now());
    // Format: [TIMESTAMP] [LEVEL] [TAG] Message
    return '[$timestamp] [$level] [$tag] $message\n';
  }

  /// Internal helper to append an entry to the log file
  Future<void> _log(String level, String tag, String message) async {
    // Always print to console for debugging during development
    if (AppConstants.enableDebugLogs) {
      print('${level.padRight(8)} [$tag] $message');
    }

    // If we're in a debug session, write to file
    if (_isDebugSessionActive && _currentLogFilePath != null) {
      try {
        final entry = _formatLogEntry(level, tag, message);
        final file = File(_currentLogFilePath!);
        await file.writeAsString(entry, mode: FileMode.append);
      } catch (e) {
        // If we can't write to the log file, at least print to console
        print('Failed to write log: $e');
      }
    }
  }
}
