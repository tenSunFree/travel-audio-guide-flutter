import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/preferences/shared_preferences_provider.dart';
import 'package:flutter_travel_audio_guide/features/attraction/presentation/widgets/attraction_tile.dart';
import 'package:flutter_travel_audio_guide/features/auth/presentation/pages/login_page.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/fakes.dart';
import 'helpers/fixtures.dart';
import 'helpers/pump_until.dart';
import 'helpers/test_app.dart';

/// Critical journey #1 — Guest-first browse.
///
/// Splash -> Welcome -> Home -> Attractions tab -> Attraction detail -> back
///
/// Verifies the pieces no unit/widget test covers together:
/// splash timing, onboarding redirect, SharedPreferences persistence,
/// background sync (API -> Drift -> DAO stream -> controller -> UI),
/// tab navigation and GoRouter push with `extra`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('首次開啟：Splash → Welcome → 以訪客身分瀏覽景點列表與詳情', (tester) async {
    final app = await pumpTestApp(
      tester,
      hasSeenWelcome: false,
      api: FakeTravelApi(attractions: [attractionJson()]),
    );

    // 1. Splash plays its animation, then routes to Welcome.
    final startButton = find.text('開始探索');
    await tester.pumpUntilFound(startButton);
    // Let the welcome entry animation (fade/slide) finish before tapping.
    await tester.pumpFor(const Duration(milliseconds: 1500));

    // 2. Welcome -> Home. Guest-first: no login gate on the way in.
    await tester.tap(startButton);
    await tester.pumpUntilFound(find.byType(NavigationBar));
    expect(find.byType(LoginPage), findsNothing);
    expect(
      app.prefs.getBool(AppPreferenceKeys.hasSeenWelcome),
      isTrue,
      reason: 'Onboarding completion must be persisted',
    );

    // 3. Switch to the attractions tab. The data arrives via the real
    //    background sync: FakeTravelApi -> AppSyncService -> Drift -> UI.
    await tester.tap(findTab('遊憩景點'));
    final tile = find.widgetWithText(AttractionTile, fixtureAttractionName);
    await tester.pumpUntilFound(tile);
    expect(app.api.requestedPathEndingWith('/Attractions/All'), isTrue);

    // 4. Open the detail page (GoRouter push with `extra`).
    await tester.tap(tile);
    await tester.pumpUntilFound(find.text(fixtureAttractionIntro));
    expect(find.text('景點介紹'), findsOneWidget);

    // 5. Back to the list.
    await tester.pageBack();
    await tester.pumpUntilGone(find.text(fixtureAttractionIntro));
    expect(tile, findsOneWidget);
  });
}
