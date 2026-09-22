import 'package:drift/native.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/analytics/analytics_service.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/sync/app_sync_service.dart';
import 'package:flutter_travel_audio_guide/core/sync/sync_providers.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/di/audio_guide_providers.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/pages/audio_guide_detail_page.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/widgets/playback_card.dart';
import 'package:mocktail/mocktail.dart';
import '../../../../test_helpers/audio_playback_service_fake.dart';

/// Mock (mocktail) of AppSyncService — avoids real network calls when
/// attractionsStreamProvider kicks off its background sync.
class MockAppSyncService extends Mock implements AppSyncService {}

/// Mock (mocktail) of FirebaseAnalytics — AudioGuideDetailPage logs a
/// "viewed" event in initState, which would otherwise throw
/// `[core/no-app]` in a plain unit-test environment.
class MockFirebaseAnalytics extends Mock implements FirebaseAnalytics {}

AudioGuide _buildGuide({
  int id = 1,
  String title = '故宮語音導覽',
  String? localFilePath = '/tmp/audio/1.mp3',
}) {
  return AudioGuide(
    id: id,
    title: title,
    url: 'https://example.com/$id.mp3',
    modified: '2026-05-19',
    isDownloaded: localFilePath != null,
    localFilePath: localFilePath,
  );
}

Widget _buildTestApp({required AppDatabase db, required AudioGuide guide}) {
  final syncService = MockAppSyncService();
  when(syncService.syncAllIfNeeded).thenAnswer((_) async {});
  when(() => syncService.forceSync(any())).thenAnswer((_) async {});
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWith((ref) => db),
      appSyncServiceProvider.overrideWith((ref) => syncService),
      // Family override: any audio path resolves to the same in-memory fake,
      // so the real just_audio plugin is never touched in this test.
      audioPlaybackServiceProvider.overrideWith(
        (ref, path) => FakeAudioPlaybackService(),
      ),
    ],
    child: MaterialApp(home: AudioGuideDetailPage(guide: guide)),
  );
}

Future<void> _disposeWidgetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // Gives zero-duration timers from Drift's watch stream a chance to run out.
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  setUpAll(() {
    // mocktail: any() must be registered with a fallback value before use.
    registerFallbackValue(SyncTarget.audioGuides);
  });

  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final analytics = MockFirebaseAnalytics();
    when(
      () => analytics.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
    AnalyticsService.debugSetInstance(analytics);
  });

  tearDown(() async {
    await db.close();
    AnalyticsService.debugResetInstance();
  });

  group('沒有本地音訊檔', () {
    testWidgets('顯示「找不到本地音訊檔」', (tester) async {
      final guide = _buildGuide(localFilePath: null);
      await tester.pumpWidget(_buildTestApp(db: db, guide: guide));
      expect(find.text('找不到本地音訊檔'), findsOneWidget);
      await _disposeWidgetTree(tester);
    });
  });

  group('有本地音訊檔', () {
    testWidgets(
      '在 attractionsStreamProvider 尚未發出資料前（AsyncLoading）也能正常建立畫面，此時 pageTitle 會 fallback 使用 guide.title',
      (tester) async {
        final guide = _buildGuide();
        // Deliberately pump only once (no pumpAndSettle) so the very first
        // build happens while attractionsStreamProvider is still
        // AsyncLoading — this exercises the `async.value ?? const []`
        // fallback branch inside _resolveAttraction.
        await tester.pumpWidget(_buildTestApp(db: db, guide: guide));
        expect(find.text(guide.title), findsWidgets);
        expect(find.text('找不到本地音訊檔'), findsNothing);
        await _disposeWidgetTree(tester);
      },
    );

    testWidgets('attractionsStreamProvider 發出空清單後，畫面仍維持 guide.title', (
      tester,
    ) async {
      final guide = _buildGuide();
      await tester.pumpWidget(_buildTestApp(db: db, guide: guide));
      // Switch to a fixed number of pumps instead of waiting for "complete quiescence"—
      // This page deliberately retains the DB watch stream and the audio player state stream;
      // both are long-lived streams designed not to terminate on their own, which is
      // fundamentally incompatible with the semantics of pumpAndSettle()—
      // specifically, the requirement to wait until there are absolutely no new frames.
      await tester.pump();
      await tester.pump();
      expect(find.text(guide.title), findsWidgets);
      await _disposeWidgetTree(tester);
    });

    testWidgets('顯示 PlaybackCard 播放區塊', (tester) async {
      final guide = _buildGuide();
      await tester.pumpWidget(_buildTestApp(db: db, guide: guide));
      await tester.pump();
      await tester.pump();
      expect(find.byType(PlaybackCard), findsOneWidget);
      await _disposeWidgetTree(tester);
    });
  });
}
