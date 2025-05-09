import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';
import '../file_storage_service.dart';

/// Implementation of FileStorageService using dart:io and path_provider
class FileStorageServiceImpl implements FileStorageService {
  @override
  Future<String> getDocumentsDirectoryPath() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  @override
  Future<String> getTemporaryDirectoryPath() async {
    final directory = await getTemporaryDirectory();
    return directory.path;
  }

  @override
  Future<String?> getExternalStorageDirectoryPath() async {
    try {
      final directory = await getExternalStorageDirectory();
      return directory?.path;
    } catch (e) {
      // External storage might not be available on all platforms
      return null;
    }
  }

  @override
  Future<bool> writeStringToFile(String content, String filePath) async {
    try {
      final file = File(filePath);

      // Create the parent directory if it doesn't exist
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await file.writeAsString(content);
      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<String?> readStringFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsString();
      }
      return null;
    } catch (e) {
      // Log error in a real application
      return null;
    }
  }

  @override
  Future<bool> writeBytesToFile(List<int> bytes, String filePath) async {
    try {
      final file = File(filePath);

      // Create the parent directory if it doesn't exist
      final dir = file.parent;
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      await file.writeAsBytes(bytes);
      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<List<int>?> readBytesFromFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.readAsBytes();
      }
      return null;
    } catch (e) {
      // Log error in a real application
      return null;
    }
  }

  @override
  Future<bool> fileExists(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<bool> deleteFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      // Return true even if file doesn't exist, as the goal (file not existing) is achieved
      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<bool> createDirectory(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<List<String>> listFiles(String directoryPath) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return [];
      }

      final List<String> fileList = [];
      await for (final entity in directory.list()) {
        if (entity is File) {
          fileList.add(entity.path);
        }
      }
      return fileList;
    } catch (e) {
      // Log error in a real application
      return [];
    }
  }

  @override
  Future<List<String>> listFilesWithExtension(
    String directoryPath,
    String extension,
  ) async {
    try {
      final directory = Directory(directoryPath);
      if (!await directory.exists()) {
        return [];
      }

      final List<String> fileList = [];
      await for (final entity in directory.list()) {
        if (entity is File && entity.path.endsWith(extension)) {
          fileList.add(entity.path);
        }
      }
      return fileList;
    } catch (e) {
      // Log error in a real application
      return [];
    }
  }

  @override
  Future<bool> copyFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return false;
      }

      // Create the directory for the destination file if it doesn't exist
      final destFile = File(destinationPath);
      final destDir = destFile.parent;
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      await sourceFile.copy(destinationPath);
      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<bool> moveFile(String sourcePath, String destinationPath) async {
    try {
      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        return false;
      }

      // Create the directory for the destination file if it doesn't exist
      final destFile = File(destinationPath);
      final destDir = destFile.parent;
      if (!await destDir.exists()) {
        await destDir.create(recursive: true);
      }

      await sourceFile.rename(destinationPath);
      return true;
    } catch (e) {
      // Log error in a real application
      return false;
    }
  }

  @override
  Future<int?> getFileSize(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        final stat = await file.stat();
        return stat.size;
      }
      return null;
    } catch (e) {
      // Log error in a real application
      return null;
    }
  }

  @override
  Future<int?> getAvailableStorage() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final stat = await directory.stat();

      // Note: This is a simplistic approximation as Flutter doesn't provide
      // a direct way to get available storage space
      return stat.size;
    } catch (e) {
      // Log error in a real application
      return null;
    }
  }

  @override
  Future<String?> exportFile(String sourcePath, String fileName) async {
    try {
      // Currently just copies to external storage if available
      final externalPath = await getExternalStorageDirectoryPath();
      if (externalPath == null) {
        return null;
      }

      final destinationPath = '$externalPath/$fileName';
      final success = await copyFile(sourcePath, destinationPath);

      if (success) {
        return destinationPath;
      }
      return null;
    } catch (e) {
      // Log error in a real application
      return null;
    }
  }
}
