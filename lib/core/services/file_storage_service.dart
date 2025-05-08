/// Interface for managing files on the device
abstract class FileStorageService {
  /// Get the application documents directory path
  Future<String> getDocumentsDirectoryPath();

  /// Get the application temporary directory path
  Future<String> getTemporaryDirectoryPath();

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

  /// Get file size
  Future<int?> getFileSize(String filePath);

  /// Get available storage space
  Future<int?> getAvailableStorage();
}
