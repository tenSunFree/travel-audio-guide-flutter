import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:talker_riverpod_logger/talker_riverpod_logger.dart';
import 'app.dart';
import 'core/debug/app_debug_options.dart';
import 'core/monitoring/monitoring_service.dart';
import 'core/preferences/shared_preferences_provider.dart';
import 'core/utils/app_logger.dart';

/// Shared App launch process, called by the entrypoints of each flavor
/// (`main_staging.dart` / `main_production.dart`)
///
/// [firebaseOptions] are injected by each entrypoint with the corresponding Firebase settings for the environment,
/// making staging and production point to different Firebase Apps.
Future<void> bootstrap({required FirebaseOptions firebaseOptions}) async {
  WidgetsFlutterBinding.ensureInitialized();
  // SharedPreferencesWithCache must complete await before runApp,
  // Ensure sharedPreferencesProvider has a value in the first frame,
  // Prevent GoRouter from receiving an uninitialized state on the first redirect.
  final prefs = await createSharedPreferencesWithCache();
  // Firebase must be initialized before Sentry.
  await Firebase.initializeApp(options: firebaseOptions);
  // Injected via CI/CD through --dart-define; default behavior is used when `flutter run` is not specified.
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  const appEnv = String.fromEnvironment('APP_ENV', defaultValue: 'debug');
  const appRelease = String.fromEnvironment('APP_RELEASE');
  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.environment = appEnv;
      options.release = appRelease.isEmpty ? null : appRelease;
      // Set the portfolio to 20% (release)
      // set the debug to 100% for easier verification.
      options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
      // No PII (Personal Information) sent.
      options.sendDefaultPii = false;
      // In debug mode, you can check in the console whether to send the output.
      options.debug = kDebugMode;
      // Automatically take a screenshot when an error occurs
      // view the screenshot directly on the Sentry Issue page.
      options.attachScreenshot = true;
      // Session tracking (Crash Free Rate)
      options.enableAutoSessionTracking = true;
    },
    appRunner: () {
      // Flutter framework errors (Widget build, setState, etc.)
      FlutterError.onError = (details) {
        AppLogger.talker.handle(details.exception, details.stack);
        Sentry.captureException(details.exception, stackTrace: details.stack);
      };
      // Async/Platform Dispatcher error (Future not caught, Platform channel, etc.)
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.talker.handle(error, stack);
        Sentry.captureException(error, stackTrace: stack);
        return true;
      };
      // Debug mode: Mark users in Sentry for easy filtering of your own test events.
      MonitoringService.identifyDebugUser();
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
