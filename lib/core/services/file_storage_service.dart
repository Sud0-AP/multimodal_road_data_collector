/// Interface for managing files on the device
abstract class FileStorageService {
  /// Get the application documents directory path
  Future<String> getDocumentsDirectoryPath();

  /// Get the application temporary directory path
  Future<String> getTemporaryDirectoryPath();

  /// Get the application external storage directory path (if available)
  Future<String?> getExternalStorageDirectoryPath();

  /// Write a string to a file
  Future<bool> writeStringToFile(String content, String filePath);

  /// Read a string from a file
  Future<String?> readStringFromFile(String filePath);

  /// Write bytes to a file
  Future<bool> writeBytesToFile(List<int> bytes, String filePath);

  /// Read bytes from a file
  Future<List<int>?> readBytesFromFile(String filePath);

  /// Check if a file exists
  Future<bool> fileExists(String filePath);

  /// Delete a file
  Future<bool> deleteFile(String filePath);

  /// Create a directory
  Future<bool> createDirectory(String directoryPath);

  /// List files in a directory
  Future<List<String>> listFiles(String directoryPath);

  /// List files in a directory with a specific extension
  Future<List<String>> listFilesWithExtension(
    String directoryPath,
    String extension,
  );

  /// Copy a file from source to destination
  Future<bool> copyFile(String sourcePath, String destinationPath);

  /// Move a file from source to destination
  Future<bool> moveFile(String sourcePath, String destinationPath);

  /// Get file size
  Future<int?> getFileSize(String filePath);

  /// Get available storage space
  Future<int?> getAvailableStorage();

  /// Export file to a shareable location
  Future<String?> exportFile(String sourcePath, String fileName);
}
