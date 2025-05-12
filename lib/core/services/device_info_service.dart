/// Interface for accessing device information
abstract class DeviceInfoService {
  /// Get device model name
  Future<String> getDeviceModel();

  /// Get device manufacturer
  Future<String> getDeviceManufacturer();

  /// Get operating system version (e.g., Android 13 or iOS 16.2)
  Future<String> getOsVersion();

  /// Get device brand name
  Future<String> getDeviceBrand();

  /// Get detailed device information as a map
  Future<Map<String, dynamic>> getDeviceInfo();
}
