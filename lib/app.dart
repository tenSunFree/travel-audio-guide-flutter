import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/sync/sync_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/reminder/di/reminder_providers.dart';

class TravelAudioGuideApp extends ConsumerStatefulWidget {
  const TravelAudioGuideApp({super.key});

  @override
  ConsumerState<TravelAudioGuideApp> createState() =>
      _TravelAudioGuideAppState();
}

class _TravelAudioGuideAppState extends ConsumerState<TravelAudioGuideApp> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      ref.read(appSyncServiceProvider).syncAllIfNeeded();
      final notificationService = ref.read(notificationServiceProvider);
      await notificationService.initialize();
      await notificationService.requestPermission();
      await ref.read(reschedulePendingRemindersUseCaseProvider).call();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: '語音導覽',
      theme: AppTheme.light,
      routerConfig: ref.watch(appRouterProvider),
    );
  }
}
