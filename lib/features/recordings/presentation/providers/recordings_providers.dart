import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multimodal_road_data_collector/core/services/app_info_service.dart';
import 'package:multimodal_road_data_collector/core/services/data_management_service.dart';
import 'package:multimodal_road_data_collector/core/services/device_info_service.dart';
import 'package:multimodal_road_data_collector/core/services/file_storage_service.dart';
import 'package:multimodal_road_data_collector/core/services/implementations/app_info_service_impl.dart';
import 'package:multimodal_road_data_collector/core/services/implementations/data_management_service_impl.dart';
import 'package:multimodal_road_data_collector/core/services/implementations/device_info_service_impl.dart';
import 'package:multimodal_road_data_collector/core/services/providers.dart';
import '../state/recordings_notifier.dart';
import '../state/recordings_state.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Provider for DeviceInfoService
final deviceInfoServiceProvider = Provider<DeviceInfoService>((ref) {
  return DeviceInfoServiceImpl.create();
});

/// Fallback implementation of AppInfoService when package info is not available yet
class FallbackAppInfoService implements AppInfoService {
  @override
  Future<String> getAppName() async => 'Road Data Collector';

  @override
  Future<String> getAppVersion() async => 'Unknown';

  @override
  Future<String> getBuildNumber() async => 'Unknown';

  @override
  Future<String> getPackageName() async =>
      'com.example.multimodal_road_data_collector';

  @override
  Future<Map<String, dynamic>> getAppInfo() async => {
    'appName': 'Road Data Collector',
    'packageName': 'com.example.multimodal_road_data_collector',
    'version': 'Unknown',
    'buildNumber': 'Unknown',
  };
}

/// Provider for AppInfoService
final appInfoServiceProvider = Provider<AppInfoService>((ref) {
  final packageInfo = ref.watch(_packageInfoProvider).value;
  if (packageInfo == null) {
    // Return fallback implementation instead of throwing an exception
    return FallbackAppInfoService();
  }
  return AppInfoServiceImpl(packageInfo);
});

/// Internal provider for PackageInfo
final _packageInfoProvider = FutureProvider<PackageInfo>((ref) {
  return PackageInfo.fromPlatform();
});

/// Provider for DataManagementService
final dataManagementServiceProvider = Provider<DataManagementService>((ref) {
  final fileStorageService = ref.watch(fileStorageServiceProvider);
  final deviceInfoService = ref.watch(deviceInfoServiceProvider);

  // We need to handle the case where appInfoService might not be ready
  final appInfoService = ref.watch(appInfoServiceProvider);

  return DataManagementServiceImpl(
    fileStorageService: fileStorageService,
    deviceInfoService: deviceInfoService,
    appInfoService: appInfoService,
  );
});

/// Provider for RecordingsNotifier
final recordingsNotifierProvider =
    StateNotifierProvider<RecordingsNotifier, RecordingsState>((ref) {
      final dataManagementService = ref.watch(dataManagementServiceProvider);

      return RecordingsNotifier(dataManagementService: dataManagementService);
    });
