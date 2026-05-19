import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_travel_audio_guide/core/database/app_database.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/sync/app_sync_service.dart';
import 'package:flutter_travel_audio_guide/core/sync/sync_providers.dart';
import 'package:flutter_travel_audio_guide/core/widgets/list_skeleton.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/pages/audio_guide_list_page.dart';

/// Mock (mocktail) of AppSyncService
/// Used to control the behavior of syncAllIfNeeded() / forceSync()
class MockAppSyncService extends Mock implements AppSyncService {}

/// [syncService] The default is to complete immediately (without blocking). If mockService is passed in, the behavior can be controlled.
Widget buildTestApp({required AppDatabase db, AppSyncService? syncService}) {
  final fakeSyncService = syncService ?? _buildInstantSyncService(db);
  return ProviderScope(
    overrides: [
      // Use in-memory DB (independent for each test)
      appDatabaseProvider.overrideWith((ref) {
        return db;
      }),
      // Override the sync service to avoid real network calls
      appSyncServiceProvider.overrideWith((ref) => fakeSyncService),
    ],
    child: const MaterialApp(home: AudioGuideListPage()),
  );
}

/// Create a MockAppSyncService that completes sync immediately.
AppSyncService _buildInstantSyncService(AppDatabase db) {
  final mock = MockAppSyncService();
  when(() => mock.syncAllIfNeeded()).thenAnswer((_) async {});
  when(() => mock.forceSync(any())).thenAnswer((_) async {});
  return mock;
}

/// Insert an AudioGuide into the in-memory DB (triggered by watchAll() stream)
Future<void> insertGuide(
  AppDatabase db, {
  int id = 1,
  String title = '故宮語音導覽',
  String modified = '2026-05-19',
  bool isDownloaded = false,
  String? localFilePath,
}) async {
  await db.audioGuideDao.upsertAll([
    AudioGuideTableCompanion.insert(
      id: Value(id),
      title: title,
      url: 'https://example.com/$id.mp3',
      modified: modified,
      summary: const Value('語音導覽說明'),
      fileExt: const Value('mp3'),
      isDownloaded: Value(isDownloaded),
      localFilePath: Value(localFilePath),
      cachedAt: DateTime.now(),
    ),
  ]);
}

Future<void> disposeWidgetTree(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  // This gives the zero-duration timer generated when the Drift watch stream disposes a chance to run out.
  await tester.pump(const Duration(milliseconds: 1));
}

void main() {
  // mocktail: any() must be registered with FallbackValue before using SyncTarget(enum).
  setUpAll(() {
    registerFallbackValue(SyncTarget.audioGuides);
  });
  late AppDatabase db;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });
  // Initial loading state: isSyncing=true, allItems empty → Display ListSkeleton
  group('loading 狀態', () {
    testWidgets('isSyncing=true 且無資料時顯示 ListSkeleton', (tester) async {
      final mockSync = MockAppSyncService();
      when(() => mockSync.syncAllIfNeeded()).thenAnswer((_) async {});
      when(() => mockSync.forceSync(any())).thenAnswer((_) async {});
      await tester.pumpWidget(buildTestApp(db: db, syncService: mockSync));
      expect(find.byType(ListSkeleton), findsOneWidget);
      await disposeWidgetTree(tester);
    });
  });
  // Reference available: insert → watchAll trigger → UI displays list
  group('有語音導覽資料', () {
    testWidgets('DB 有資料時顯示 AudioGuideTile 列表', (tester) async {
      // Insert the data first, then create the widget (sync completes immediately).
      await insertGuide(db, id: 1, title: '故宮語音導覽');
      await insertGuide(db, id: 2, title: '大稻埕語音導覽');
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('故宮語音導覽'), findsOneWidget);
      expect(find.text('大稻埕語音導覽'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
    testWidgets('顯示更新日期文字（更新於）', (tester) async {
      await insertGuide(db, id: 1, modified: '2026-05-19');
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.textContaining('更新於'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
    testWidgets('已下載的 guide 顯示「播放」按鈕', (tester) async {
      await insertGuide(
        db,
        id: 1,
        title: '已下載導覽',
        isDownloaded: true,
        localFilePath: '/tmp/audio.mp3',
      );
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('播放'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
    testWidgets('未下載的 guide 顯示「下載」按鈕', (tester) async {
      await insertGuide(db, id: 1, isDownloaded: false);
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('下載'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
    testWidgets('顯示 ConditionSummaryBar（排序列）', (tester) async {
      await insertGuide(db);
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.textContaining('日期（新→舊）'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
  });
  // No data: sync complete, DB empty → Display empty status text
  group('空狀態', () {
    testWidgets('sync 完成但無資料時顯示「暫無語音導覽資料」', (tester) async {
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('暫無語音導覽資料'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
  });
  // sync failed: errorMessage is displayed in the loadInitial path
  group('錯誤狀態', () {
    testWidgets('errorMessage 在 items 為空時顯示錯誤文字', (tester) async {
      final mockSync = MockAppSyncService();
      when(() => mockSync.syncAllIfNeeded()).thenThrow(Exception('sync 失敗'));
      when(() => mockSync.forceSync(any())).thenAnswer((_) async {});
      await tester.pumpWidget(buildTestApp(db: db, syncService: mockSync));
      await tester.pumpAndSettle();
      expect(find.text('暫無語音導覽資料'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
  });
  group('AppBar', () {
    testWidgets('顯示「語音導覽」標題', (tester) async {
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('語音導覽'), findsOneWidget);
      await disposeWidgetTree(tester);
    });
    testWidgets('顯示 tune（排序）icon 按鈕', (tester) async {
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.tune), findsOneWidget);
      await disposeWidgetTree(tester);
    });
  });
  // Dynamically add data (watchAll stream triggers UI update)
  group('Stream 更新', () {
    testWidgets('初始無資料 → 插入資料後 UI 自動更新', (tester) async {
      await tester.pumpWidget(buildTestApp(db: db));
      await tester.pumpAndSettle();
      expect(find.text('暫無語音導覽資料'), findsOneWidget);
      await insertGuide(db, id: 1, title: '動態新增導覽');
      await tester.pumpAndSettle();
      expect(find.text('動態新增導覽'), findsOneWidget);
      expect(find.text('暫無語音導覽資料'), findsNothing);
      await disposeWidgetTree(tester);
    });
  });
}
