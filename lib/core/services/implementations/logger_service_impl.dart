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

  /// Date format for session directories
  static final DateFormat _sessionDirFormat = DateFormat('yyyyMMdd_HHmmss');

  /// File storage service for writing logs
  final FileStorageService _fileStorageService;

  /// Preferences service for checking debugging mode status
  final PreferencesService _preferencesService;

  /// Current active debug session ID
  String? _currentSessionId;

  /// Current debug session directory path
  String? _currentSessionDirectoryPath;

  /// Current log file path
  String? _currentLogFilePath;

  /// Base logs directory path
  String? _logsDirectory;

  /// Flag to indicate if debug mode is active
  bool _isDebugSessionActive = false;

  /// Static instance to ensure we have only one logger instance
  static String? _appSessionId;

  /// Constructor
  LoggerServiceImpl({
    required FileStorageService fileStorageService,
    required PreferencesService preferencesService,
  }) : _fileStorageService = fileStorageService,
       _preferencesService = preferencesService;

  @override
  Future<void> initialize() async {
    // Setup the consistent logs directory
    final baseDirectory = await _fileStorageService.getSessionsBaseDirectory();
    _logsDirectory = path.join(baseDirectory, 'logs');
    await _fileStorageService.createDirectory(_logsDirectory!);
  }

  @override
  Future<String> startDebugSession() async {
    // If already active, just return current session ID instead of creating a new one
    if (_isDebugSessionActive && _currentSessionId != null) {
      // Log that an attempt was made to start a session when one is already active
      await info(
        'LoggerService',
        'Debug session already active, reusing existing session',
      );
      return _currentSessionId!;
    }

    // Make sure the logs directory is initialized
    if (_logsDirectory == null) {
      await initialize();
    }

    // Generate a new session ID based on timestamp if we don't have an app-wide one yet
    if (_appSessionId == null) {
      final timestamp = DateTime.now();
      _appSessionId = 'debug_${timestamp.millisecondsSinceEpoch}';
    }

    // Use the app-wide session ID
    _currentSessionId = _appSessionId;

    // Create a directory for this debug session
    _currentSessionDirectoryPath = path.join(
      _logsDirectory!,
      _currentSessionId!,
    );
    await _fileStorageService.createDirectory(_currentSessionDirectoryPath!);

    // Create a single app.log file inside the session directory
    _currentLogFilePath = path.join(_currentSessionDirectoryPath!, 'app.log');

    // Check if the file already exists before writing initial entry
    bool fileExists = await File(_currentLogFilePath!).exists();

    if (!fileExists) {
      // Write initial log entry only if this is a new file
      final initialEntry = _formatLogEntry(
        'INFO',
        'LoggerService',
        'Debug session started. Device: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}',
      );

      await _fileStorageService.writeStringToFile(
        initialEntry,
        _currentLogFilePath!,
      );

      // Log basic device info
      await info('LoggerService', 'App Version: ${AppConstants.appVersion}');
    } else {
      // Just append a session continued message
      final continueEntry = _formatLogEntry(
        'INFO',
        'LoggerService',
        'Debug session continued by user from settings',
      );

      final file = File(_currentLogFilePath!);
      await file.writeAsString(continueEntry, mode: FileMode.append);
    }

    _isDebugSessionActive = true;
    return _currentSessionId!;
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
    _currentSessionDirectoryPath = null;
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
    // Ensure logs directory exists
    if (_logsDirectory == null) {
      await initialize();
    }

    // If directory doesn't exist, return empty list
    if (!await Directory(_logsDirectory!).exists()) {
      return [];
    }

    if (sessionId != null) {
      // Check if session directory exists
      final sessionDirectory = path.join(_logsDirectory!, sessionId);
      if (await Directory(sessionDirectory).exists()) {
        return _fileStorageService.listFilesWithExtension(
          sessionDirectory,
          '.log',
        );
      }
      return [];
    } else {
      // Get all log files from all session directories
      List<String> allLogFiles = [];
      try {
        final logsDir = Directory(_logsDirectory!);
        await for (final entity in logsDir.list()) {
          if (entity is Directory &&
              path.basename(entity.path).startsWith('debug_')) {
            final sessionLogFiles = await _fileStorageService
                .listFilesWithExtension(entity.path, '.log');
            allLogFiles.addAll(sessionLogFiles);
          }
        }

        // Sort by modification time in descending order (most recent first)
        allLogFiles.sort((a, b) {
          final fileA = File(a);
          final fileB = File(b);
          return fileB.lastModifiedSync().compareTo(fileA.lastModifiedSync());
        });
      } catch (e) {
        print('Error listing log files: $e');
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
