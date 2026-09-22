import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/app.dart';
import 'package:flutter_travel_audio_guide/core/debug/app_debug_options.dart';
import 'package:flutter_travel_audio_guide/core/monitoring/monitoring_service.dart';
import 'package:flutter_travel_audio_guide/core/preferences/shared_preferences_provider.dart';
import 'package:flutter_travel_audio_guide/core/utils/app_logger.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';

Future<void> bootstrap({required FirebaseOptions firebaseOptions}) async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await createSharedPreferencesWithCache();
  // Initialize Supabase before Firebase
  await Supabase.initialize(
    url: const String.fromEnvironment('SUPABASE_URL'),
    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );
  await Firebase.initializeApp(options: firebaseOptions);
  // Injected via CI/CD through --dart-define; default behavior is used when `flutter run` is not specified.
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'debug');
  const appRelease = String.fromEnvironment('APP_RELEASE');
  await SentryFlutter.init(
    (options) {
      options
        ..dsn = sentryDsn
        ..environment = appEnv
        ..release = appRelease.isEmpty ? null : appRelease
        // Set the portfolio to 20% (release)
        // set the debug to 100% for easier verification.
        ..tracesSampleRate = kReleaseMode ? 0.2 : 1.0
        // No PII (Personal Information) sent.
        ..sendDefaultPii = false
        // In debug mode, you can check in the console whether to send the output.
        ..debug = kDebugMode
        // Automatically take a screenshot when an error occurs
        // view the screenshot directly on the Sentry Issue page.
        ..attachScreenshot = true
        // Session tracking (Crash Free Rate)
        ..enableAutoSessionTracking = true;
    },
    appRunner: () async {
      // Flutter framework errors (Widget build, setState, etc.)
      FlutterError.onError = (details) async {
        AppLogger.talker.handle(details.exception, details.stack);
        await Sentry.captureException(
          details.exception,
          stackTrace: details.stack,
        );
      };
      // Async/Platform Dispatcher error (Future not caught, Platform channel, etc.)
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.talker.handle(error, stack);
        Sentry.captureException(error, stackTrace: stack);
        return true;
      };
      // Debug mode: Mark users in Sentry for easy filtering of your own test events.
      await MonitoringService.identifyDebugUser();
      AppDebugOptions.configure();
      runApp(
        // SentryWidget automatically attaches a screenshot when an error occurs.
        SentryWidget(
          child: ProviderScope(
            observers: [TalkerRiverpodObserver(talker: AppLogger.talker)],
            overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
            child: const TravelAudioGuideApp(),
          ),
        ),
      );
    },
  );
}
