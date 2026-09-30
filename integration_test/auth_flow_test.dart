import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/pages/main_tab_page.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/fixtures.dart';
import 'helpers/pump_until.dart';
import 'helpers/test_app.dart';

/// Critical journey #4 — Optional auth in a guest-first app.
///
/// Guest -> Login -> Session -> Account -> Logout -> back to Guest
///
/// Logout must NOT force the user to /login: the app stays usable.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('登入 → 帳號資訊 → 登出後回到訪客狀態（不強制登入）', (tester) async {
    final app = await pumpTestApp(tester);

    // Guest by default.
    await tester.pumpUntilFound(find.byType(NavigationBar));
    await tester.tap(findTab('我的旅程'));
    final guestButton = find.byTooltip('登入以同步');
    await tester.pumpUntilFound(guestButton);

    // Login is an optional page, opened from My Journey.
    await tester.tap(guestButton);
    await tester.pumpUntilFound(find.byType(LoginPage));
    await _submitLogin(tester, email: fixtureEmail, password: fixturePassword);

    // Session established -> LoginPage pops itself -> account icon shows.
    final accountButton = find.byTooltip('帳號');
    await tester.pumpUntilFound(accountButton);
    expect(find.byType(LoginPage), findsNothing);
    expect(app.auth.signInEmails, [fixtureEmail]);

    // Account sheet shows the signed-in email.
    await tester.tap(accountButton);
    await tester.pumpUntilFound(find.text('已登入帳號'));
    expect(find.text(fixtureEmail), findsOneWidget);

    // Logout -> back to guest, still on the main tabs.
    await tester.tap(find.text('登出'));
    await tester.pumpUntilFound(guestButton);
    expect(app.auth.signOutCount, 1);
    expect(find.byType(LoginPage), findsNothing);
    expect(find.byType(MainTabPage), findsOneWidget);
  });

  testWidgets('登入失敗顯示錯誤；按「先逛逛」仍可以訪客身分繼續使用', (tester) async {
    await pumpTestApp(tester);

    await tester.pumpUntilFound(find.byType(NavigationBar));
    await tester.tap(findTab('我的旅程'));
    await tester.pumpUntilFound(find.byTooltip('登入以同步'));
    await tester.tap(find.byTooltip('登入以同步'));
    await tester.pumpUntilFound(find.byType(LoginPage));

    await _submitLogin(tester, email: fixtureEmail, password: 'wrong-password');
    await tester.pumpUntilFound(find.text('帳號或密碼錯誤'));
    expect(find.byType(LoginPage), findsOneWidget);

    await tester.tap(find.text('先逛逛'));
    await tester.pumpUntilGone(find.byType(LoginPage));
    expect(find.byTooltip('登入以同步'), findsOneWidget);
  });
}

Future<void> _submitLogin(
  WidgetTester tester, {
  required String email,
  required String password,
}) async {
  await tester.enterText(find.widgetWithText(TextFormField, 'Email'), email);
  await tester.enterText(find.widgetWithText(TextFormField, '密碼'), password);
  // Hide the soft keyboard so the submit button is laid out normally.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pump(const Duration(milliseconds: 300));

  final submit = find.widgetWithText(FilledButton, '登入');
  await tester.ensureVisible(submit);
  await tester.tap(submit);
}
