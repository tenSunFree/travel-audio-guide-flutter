import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/app.dart';
import 'package:flutter_travel_audio_guide/core/analytics/analytics_service.dart';
import 'package:flutter_travel_audio_guide/core/constants/api_constants.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/network/network_providers.dart';
import 'package:flutter_travel_audio_guide/core/preferences/shared_preferences_provider.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/di/audio_guide_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/reminder/di/reminder_providers.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/data/services/step_tracking_service_impl.dart';
import 'package:flutter_travel_audio_guide/features/step_tracking/di/step_tracking_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

import 'fakes.dart';

/// Handles to everything a test may want to assert on after pumping.
class TestApp {
  const TestApp({
    required this.db,
    required this.prefs,
    required this.api,
    required this.auth,
    required this.playback,
    required this.notifications,
  });

  final AppDatabase db;
  final SharedPreferencesWithCache prefs;
  final FakeTravelApi api;
  final FakeAuthRepository auth;
  final FakeAudioPlaybackService playback;
  final FakeNotificationService notifications;
}

/// Pumps the *real* app (`TravelAudioGuideApp`: real GoRouter, real
/// Riverpod graph, real Drift, real controllers and pages) with only the
/// outside world replaced:
///
///   Real                           | Fake / No-op
///   -------------------------------|-------------------------------------
///   GoRouter + redirect rules      | Taipei Travel API (HttpClientAdapter)
///   Riverpod providers / DI        | Supabase Auth (AuthRepository)
///   Drift (SQLite, in-memory)      | audioplayers (AudioPlaybackService)
///   AppSyncService, DAOs, mapping  | Local notifications
///   Real file system (downloads)   | Health Connect / step sensor
///   SharedPreferencesWithCache     | Firebase Analytics, Sentry (not init)
///
/// Why this skips `bootstrap()`: bootstrap initialises Supabase, Firebase
/// and Sentry against real projects. The integration test builds the same
/// widget tree bootstrap builds, but with hermetic dependencies.
///
/// Customising a test:
/// - To change a default fake (API data, auth behaviour, playback duration,
///   notifications), pass your own instance via [api], [auth], [playback]
///   or [notifications].
/// - To override any *other* provider, use [extraOverrides]. Do not put a
///   provider that is already overridden here into [extraOverrides]:
///   Riverpod rejects overriding the same provider twice in one scope, so it
///   would fail instead of replacing the default.
Future<TestApp> pumpTestApp(
  WidgetTester tester, {
  bool hasSeenWelcome = true,
  FakeTravelApi? api,
  FakeAuthRepository? auth,
  FakeAudioPlaybackService? playback,
  FakeNotificationService? notifications,
  Future<void> Function(AppDatabase db)? seed,
  List<Override> extraOverrides = const [],
}) async {
  // Analytics must be swapped before the router is built, because
  // `AnalyticsService.observer` is read when GoRouter is created.
  AnalyticsService.debugSetInstance(NoopFirebaseAnalytics());

  // SharedPreferences: real SharedPreferencesWithCache API, in-memory
  // backend, so nothing leaks between tests or between CI runs.
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  final prefs = await createSharedPreferencesWithCache();
  if (hasSeenWelcome) {
    await prefs.setBool(AppPreferenceKeys.hasSeenWelcome, true);
  }

  // Drift: the real schema and DAOs, on a fresh in-memory SQLite.
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  if (seed != null) await seed(db);

  final travelApi = api ?? FakeTravelApi();
  final fakeAuth = auth ?? FakeAuthRepository();
  final fakePlayback = playback ?? FakeAudioPlaybackService();
  final fakeNotifications = notifications ?? FakeNotificationService();

  // Same base URL/headers as the production dioProvider, but without the
  // retry interceptor: a 5xx would otherwise wait 1s + 3s + 5s per request.
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      headers: ApiConstants.defaultHeaders,
    ),
  )..httpClientAdapter = travelApi;

  addTearDown(() async {
    AnalyticsService.debugResetInstance();
    await fakePlayback.close();
    await fakeAuth.dispose();
    await db.close();
    // Strict fake: an endpoint the fake does not know about is a test gap
    // (or an unintended new network call), never something to ignore.
    expect(
      travelApi.unhandledRequests,
      isEmpty,
      reason: 'FakeTravelApi received requests it does not handle',
    );
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        appDatabaseProvider.overrideWithValue(db),
        dioProvider.overrideWithValue(dio),
        authRepositoryProvider.overrideWithValue(fakeAuth),
        notificationServiceProvider.overrideWithValue(fakeNotifications),
        audioPlaybackServiceProvider.overrideWith((ref, path) => fakePlayback),
        stepTrackingServiceProvider.overrideWithValue(
          const NoOpStepTrackingService(),
        ),
        ...extraOverrides,
      ],
      child: const TravelAudioGuideApp(),
    ),
  );

  return TestApp(
    db: db,
    prefs: prefs,
    api: travelApi,
    auth: fakeAuth,
    playback: fakePlayback,
    notifications: fakeNotifications,
  );
}

/// Finds a bottom-navigation tab by its label.
///
/// Scoped to the NavigationBar because the same text is often also a page
/// title (e.g. the attractions AppBar is titled '遊憩景點').
Finder findTab(String label) => find.descendant(
  of: find.byType(NavigationBar),
  matching: find.text(label),
);
