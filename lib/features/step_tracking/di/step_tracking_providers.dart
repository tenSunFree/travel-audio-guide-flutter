import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/data/services/step_tracking_service_impl.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/domain/services/step_tracking_service.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/presentation/controllers/step_tracking_controller.dart';

final stepTrackingServiceProvider = Provider<StepTrackingService>((ref) {
  if (Platform.isAndroid) return StepTrackingServiceImpl();
  return const NoOpStepTrackingService();
});

final StateNotifierProvider<StepTrackingController, StepTrackingState>
stepTrackingControllerProvider =
    StateNotifierProvider.autoDispose<
      StepTrackingController,
      StepTrackingState
    >((ref) {
      return StepTrackingController(ref.watch(stepTrackingServiceProvider));
    });
