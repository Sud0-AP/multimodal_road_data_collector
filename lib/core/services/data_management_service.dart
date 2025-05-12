/// Interface for managing recording data and metadata
abstract class DataManagementService {
  /// Generate and save metadata file for a recording session
  ///
  /// Takes the session path and recording completion data and generates a comprehensive
  /// metadata.txt file containing all required information
  Future<bool> generateAndSaveMetadata(
    String sessionPath,
    Map<String, dynamic> recordingData,
  );

  /// Load a list of all recorded sessions
  ///
  /// Returns a list of session paths ordered by most recent first
  Future<List<String>> loadSessionList();

  /// Get recording display information for a specific session
  ///
  /// Returns a map containing key information from the metadata file including:
  /// - timestamp (DateTime)
  /// - duration (in seconds)
  /// - sessionId
  Future<Map<String, dynamic>?> getSessionDisplayInfo(String sessionPath);

  /// Delete a recording session with all its files
  ///
  /// Returns true if deletion was successful
  Future<bool> deleteSession(String sessionPath);

  /// Share a recording session with all related files
  ///
  /// Returns true if sharing was initiated successfully
  Future<bool> shareSession(String sessionPath);

  /// Try to open the session folder in the device's file explorer
  ///
  /// Returns true if the folder was opened successfully
  Future<bool> openSessionInFileExplorer(String sessionPath);
}
