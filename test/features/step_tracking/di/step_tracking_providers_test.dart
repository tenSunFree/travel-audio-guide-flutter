import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/data/services/step_tracking_service_impl.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/di/step_tracking_providers.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/presentation/controllers/step_tracking_controller.dart';

void main() {
  test('desktop test environment 回傳 NoOpStepTrackingService', () {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return;
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final service = container.read(stepTrackingServiceProvider);
    expect(service, isA<NoOpStepTrackingService>());
  });

  test(
    'stepTrackingControllerProvider 組裝出綁定 stepTrackingServiceProvider 的 controller',
    () async {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return;
      final container = ProviderContainer();
      addTearDown(container.dispose);
      // Providers marked .autoDispose are immediately disposed when they have
      // no listeners. Keep an active subscription with container.listen so the
      // controller stays alive for the duration of the test.
      final subscription = container.listen(
        stepTrackingControllerProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      final controller = container.read(
        stepTrackingControllerProvider.notifier,
      );
      // Await the controller's own initialization signal instead of guessing how
      // many microtasks to flush. This keeps the test stable even if `_init()`
      // later adds more awaits.
      await controller.initialized;
      expect(controller, isA<StepTrackingController>());
    },
  );
}
