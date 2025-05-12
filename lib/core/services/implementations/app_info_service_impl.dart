import 'package:package_info_plus/package_info_plus.dart';
import '../app_info_service.dart';

/// Implementation of AppInfoService using package_info_plus
class AppInfoServiceImpl implements AppInfoService {
  final PackageInfo _packageInfo;

  /// Private constructor
  AppInfoServiceImpl(this._packageInfo);

  /// Factory constructor to create a new instance asynchronously
  static Future<AppInfoServiceImpl> create() async {
    final packageInfo = await PackageInfo.fromPlatform();
    return AppInfoServiceImpl(packageInfo);
  }

  @override
  Future<String> getAppName() async {
    return _packageInfo.appName;
  }

  @override
  Future<String> getAppVersion() async {
    return _packageInfo.version;
  }

  @override
  Future<String> getBuildNumber() async {
    return _packageInfo.buildNumber;
  }

  @override
  Future<String> getPackageName() async {
    return _packageInfo.packageName;
  }

  @override
  Future<Map<String, dynamic>> getAppInfo() async {
    return {
      'appName': _packageInfo.appName,
      'packageName': _packageInfo.packageName,
      'version': _packageInfo.version,
      'buildNumber': _packageInfo.buildNumber,
    };
  }
}
