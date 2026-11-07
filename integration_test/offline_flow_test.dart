import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/models/attraction_model.dart';
import 'package:flutter_travel_audio_guide/features/attraction/di/attraction_providers.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/widgets/attraction_tile.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/pages/main_tab_page.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/fakes.dart';
import 'helpers/fixtures.dart';
import 'helpers/pump_until.dart';
import 'helpers/test_app.dart';

/// Critical journey #2 — Offline-first.
///
/// Drift already has cached data -> the remote API fails -> the UI keeps
/// showing the cache (and surfaces the error without wiping the list).
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('離線：API 失敗時仍顯示 Drift 快取，且可進入詳情頁', (tester) async {
    final app = await pumpTestApp(
      tester,
      api: FakeTravelApi(offline: true),
      // A previous session already synced this attraction into Drift.
      seed: (db) => db.attractionDao.upsertAll([
        AttractionModel.fromJson(attractionJson()),
      ]),
    );

    await tester.pumpUntilFound(find.byType(NavigationBar));
    await tester.tap(findTab('遊憩景點'));

    // The background sync is attempted and fails...
    await tester.pumpUntil(
      () => app.api.requestedPathEndingWith('/Attractions/All'),
      description: 'a sync attempt against /Attractions/All',
    );

    // ...but the cached row is still rendered, with no empty/error page.
    final tile = find.widgetWithText(AttractionTile, fixtureAttractionName);
    await tester.pumpUntilFound(tile);
    expect(find.text('暫無景點資料'), findsNothing);
    expect(find.text('重新載入'), findsNothing);

    // The detail page works purely from local data.
    await tester.tap(tile);
    await tester.pumpUntilFound(find.text(fixtureAttractionIntro));
    await tester.pageBack();
    await tester.pumpUntilFound(tile);
  });

  testWidgets('離線：下拉重新整理失敗會顯示錯誤，但不清空快取列表', (tester) async {
    await pumpTestApp(
      tester,
      api: FakeTravelApi(offline: true),
      seed: (db) => db.attractionDao.upsertAll([
        AttractionModel.fromJson(attractionJson()),
      ]),
    );

    await tester.pumpUntilFound(find.byType(NavigationBar));
    await tester.tap(findTab('遊憩景點'));
    final tile = find.widgetWithText(AttractionTile, fixtureAttractionName);
    await tester.pumpUntilFound(tile);

    // Pull to refresh -> forceSync -> remote throws -> controller error.
    await tester.fling(tile, const Offset(0, 400), 1000);

    final container = ProviderScope.containerOf(
      tester.element(find.byType(MainTabPage)),
    );
    await tester.pumpUntil(
      () =>
          container.read(attractionListControllerProvider).errorMessage != null,
      description: 'attraction list errorMessage after a failed refresh',
    );

    // Offline-first contract: error is reported, cached data stays.
    expect(tile, findsOneWidget);
    expect(container.read(attractionListControllerProvider).items, isNotEmpty);
  });
}
