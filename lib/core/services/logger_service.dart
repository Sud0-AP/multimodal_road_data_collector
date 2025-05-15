/// Interface for application-wide logging functionality
abstract class LoggerService {
  /// Initialize logger with default settings
  Future<void> initialize();

  /// Start debug logging session
  /// Returns a session ID that can be used to identify this debug session
  Future<String> startDebugSession();

  /// End debug logging session
  Future<void> endDebugSession();

  /// Check if debug logging is currently active
  bool isDebugSessionActive();

  /// Log an info message
  Future<void> info(String tag, String message);

  /// Log a debug message (only recorded when debug mode is active)
  Future<void> debug(String tag, String message);

  /// Log a warning message
  Future<void> warning(String tag, String message);

  /// Log an error message
  Future<void> error(
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]);

  /// Log a critical message
  Future<void> critical(
    String tag,
    String message, [
    dynamic exception,
    StackTrace? stackTrace,
  ]);

  /// Get path to current debug log file (if any)
  Future<String?> getCurrentLogFilePath();

  /// Get all log files for a specific session (if specified)
  /// or all sessions (if null)
  Future<List<String>> getLogFilePaths([String? sessionId]);
}
