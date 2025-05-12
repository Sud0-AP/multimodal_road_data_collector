import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../device_info_service.dart';

/// Implementation of DeviceInfoService using device_info_plus package
class DeviceInfoServiceImpl implements DeviceInfoService {
  final DeviceInfoPlugin _deviceInfoPlugin;

  /// Constructor
  DeviceInfoServiceImpl(this._deviceInfoPlugin);

  /// Factory constructor to create a new instance with default dependencies
  factory DeviceInfoServiceImpl.create() {
    return DeviceInfoServiceImpl(DeviceInfoPlugin());
  }

  @override
  Future<String> getDeviceModel() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      return info.model;
    } else if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      return info.model;
    }
    return 'Unknown device model';
  }

  @override
  Future<String> getDeviceManufacturer() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      return info.manufacturer;
    } else if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      return 'Apple Inc.';
    }
    return 'Unknown manufacturer';
  }

  @override
  Future<String> getOsVersion() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      return 'Android ${info.version.release} (SDK ${info.version.sdkInt})';
    } else if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      return 'iOS ${info.systemVersion}';
    }
    return 'Unknown OS version';
  }

  @override
  Future<String> getDeviceBrand() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      return info.brand;
    } else if (Platform.isIOS) {
      return 'Apple';
    }
    return 'Unknown brand';
  }

  @override
  Future<Map<String, dynamic>> getDeviceInfo() async {
    if (Platform.isAndroid) {
      final info = await _deviceInfoPlugin.androidInfo;
      return {
        'model': info.model,
        'brand': info.brand,
        'manufacturer': info.manufacturer,
        'device': info.device,
        'product': info.product,
        'isPhysicalDevice': info.isPhysicalDevice,
        'androidId': info.id,
        'androidVersion': info.version.release,
        'sdkInt': info.version.sdkInt,
        'hardware': info.hardware,
        'host': info.host,
        'display': info.display,
      };
    } else if (Platform.isIOS) {
      final info = await _deviceInfoPlugin.iosInfo;
      return {
        'name': info.name,
        'model': info.model,
        'systemName': info.systemName,
        'systemVersion': info.systemVersion,
        'localizedModel': info.localizedModel,
        'isPhysicalDevice': info.isPhysicalDevice,
        'utsname.sysname:': info.utsname.sysname,
        'utsname.nodename:': info.utsname.nodename,
        'utsname.release:': info.utsname.release,
        'utsname.version:': info.utsname.version,
        'utsname.machine:': info.utsname.machine,
      };
    }
    return {'error': 'Unsupported platform'};
  }
}
