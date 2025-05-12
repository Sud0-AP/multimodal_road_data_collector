import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multimodal_road_data_collector/core/services/providers.dart';
import 'package:multimodal_road_data_collector/features/recording/presentation/state/spike_detection_notifier.dart';

/// Provider for SpikeDetectionNotifier
final spikeDetectionProvider =
    StateNotifierProvider<SpikeDetectionNotifier, SpikeDetectionState>((ref) {
      final spikeDetectionService = ref.watch(spikeDetectionServiceProvider);
      return SpikeDetectionNotifier(spikeDetectionService);
    });
