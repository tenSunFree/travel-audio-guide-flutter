import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_playback_state.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/services/audio_playback_service.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/entities/app_user.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/services/notification_service.dart';

import 'fixtures.dart';

// Fake Remote API (Taipei Travel Open API + audio download)

/// Replaces the network layer *below* Dio.
///
/// Everything above it stays real: `AttractionRemoteDataSource`,
/// JSON -> Model mapping, `AppSyncService`, the Drift upsert, the DAO watch
/// streams, the controllers and the UI. Only the HTTP transport is fake.
///
/// Set [offline] to `true` to simulate "no network": every request throws,
/// exactly like a real `SocketException` would.
class FakeTravelApi implements HttpClientAdapter {
  FakeTravelApi({
    List<Map<String, dynamic>> attractions = const [],
    List<Map<String, dynamic>> audioGuides = const [],
    this.offline = false,
  }) : //
       // Preserve a public parameter name while using a private field.
       // ignore: prefer_initializing_formals
       _attractions = attractions,
       // Preserve a public parameter name while using a private field.
       // ignore: prefer_initializing_formals
       _audioGuides = audioGuides;

  final List<Map<String, dynamic>> _attractions;
  final List<Map<String, dynamic>> _audioGuides;

  /// Can be flipped in the middle of a test.
  bool offline;

  /// Every request the app attempted, for assertions.
  final List<Uri> requests = <Uri>[];

  /// Requests that matched no known endpoint. The harness asserts this is
  /// empty after each test, so a new/renamed endpoint fails loudly instead
  /// of being silently answered with fake data.
  final List<Uri> unhandledRequests = <Uri>[];

  bool requestedPathEndingWith(String suffix) =>
      requests.any((uri) => uri.path.endsWith(suffix));

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final uri = options.uri;
    requests.add(uri);
    if (offline) {
      throw SocketException('FakeTravelApi is offline: $uri');
    }
    final path = uri.path;
    final page = int.tryParse('${options.queryParameters['page'] ?? 1}') ?? 1;

    // AppSyncService.syncAllIfNeeded() calls these three, in this order.
    if (path.endsWith('/Attractions/All')) {
      return _pageOf(_attractions, page);
    }
    if (path.endsWith('/Media/Audio')) {
      return _pageOf(_audioGuides, page);
    }
    if (path.endsWith('/Events/Activity')) {
      return _pageOf(const [], page);
    }
    // Attraction categories (repository API, not called by today's UI).
    if (path.endsWith('/Miscellaneous/Categories')) {
      return _json({'data': <Object>[]});
    }
    // Audio file download (absolute URL, bypasses baseUrl).
    if (path.endsWith('.mp3')) {
      return ResponseBody.fromBytes(
        fakeMp3Bytes,
        200,
        headers: {
          Headers.contentTypeHeader: ['audio/mpeg'],
        },
      );
    }

    unhandledRequests.add(uri);
    return ResponseBody.fromString('Not handled by FakeTravelApi', 404);
  }

  /// Everything is returned on page 1; later pages are empty, which is how
  /// `AppSyncService._fetchAllPages` knows to stop.
  ResponseBody _pageOf(List<Map<String, dynamic>> items, int page) {
    return _json({
      'total': items.length,
      'data': page == 1 ? items : <Map<String, dynamic>>[],
    });
  }

  ResponseBody _json(Map<String, dynamic> body) {
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

// Fake Auth (replaces Supabase Auth)

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.validPassword = fixturePassword});

  final String validPassword;
  final _changes = StreamController<bool>.broadcast();
  AppUser? _user;

  final List<String> signInEmails = <String>[];
  int signOutCount = 0;

  @override
  AppUser? get currentUser => _user;

  @override
  bool get isSignedIn => _user != null;

  @override
  Stream<bool> get authStateChanges => _changes.stream;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    signInEmails.add(email);
    if (password != validPassword) {
      throw const ServerException('帳號或密碼錯誤');
    }
    _user = AppUser(id: 'fake-user-1', email: email);
    _changes.add(true);
  }

  @override
  Future<bool> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    _user = AppUser(id: 'fake-user-1', email: email);
    _changes.add(true);
    return true;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    _user = null;
    _changes.add(false);
  }

  Future<void> dispose() => _changes.close();
}

// Fake audio playback (replaces audioplayers)

/// Behaves like a real player from the controller's point of view:
/// initialize -> ready (paused, with a duration), play -> playing,
/// pause -> paused. No real audio output, so CI emulators stay stable.
class FakeAudioPlaybackService implements AudioPlaybackService {
  FakeAudioPlaybackService({this.duration = const Duration(minutes: 3)});

  final Duration duration;
  final _states = StreamController<AudioPlaybackState>.broadcast();
  AudioPlaybackState _state = const AudioPlaybackState();

  String? initializedPath;
  int playCallCount = 0;
  int pauseCallCount = 0;

  @override
  Stream<AudioPlaybackState> get stateStream => _states.stream;

  void _emit(AudioPlaybackState next) {
    _state = next;
    if (!_states.isClosed) _states.add(next);
  }

  @override
  Future<void> initialize(String filePath) async {
    initializedPath = filePath;
    _emit(
      AudioPlaybackState(
        status: AudioPlaybackStatus.paused,
        duration: duration,
      ),
    );
  }

  @override
  Future<void> play() async {
    playCallCount++;
    _emit(
      _state.copyWith(
        status: AudioPlaybackStatus.playing,
        position: const Duration(seconds: 1),
      ),
    );
  }

  @override
  Future<void> pause() async {
    pauseCallCount++;
    _emit(_state.copyWith(status: AudioPlaybackStatus.paused));
  }

  @override
  Future<void> seek(Duration position) async {
    _emit(_state.copyWith(position: position));
  }

  /// The provider override shares one instance per test, so the widget
  /// tree must not close it; the harness closes it in tearDown instead.
  @override
  Future<void> dispose() async {}

  Future<void> close() => _states.close();
}

// Fake notifications (no OS permission dialog on CI)

class FakeNotificationService implements NotificationService {
  int initializeCount = 0;
  int permissionRequestCount = 0;
  final List<Reminder> scheduled = <Reminder>[];

  @override
  Future<void> initialize() async {
    initializeCount++;
  }

  @override
  Future<bool> requestPermission() async {
    permissionRequestCount++;
    return true;
  }

  @override
  Future<void> scheduleReminder(Reminder reminder) async {
    scheduled.add(reminder);
  }

  @override
  Future<void> cancelReminder(int notificationId) async {}

  @override
  Future<void> reschedulePendingReminders(List<Reminder> reminders) async {}
}

// No-op analytics (nothing reaches Firebase from a test run)

/// Every FirebaseAnalytics method the app calls (`logEvent`,
/// `logScreenView` from both AnalyticsService and the GoRouter observer)
/// returns `Future<void>` and is silently swallowed here.
///
/// Using noSuchMethod instead of overriding each method keeps this fake
/// independent of firebase_analytics' exact method signatures across
/// upgrades.
class NoopFirebaseAnalytics implements FirebaseAnalytics {
  @override
  dynamic noSuchMethod(Invocation invocation) => Future<void>.value();
}
