import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/router/app_router.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/entities/app_user.dart';
import 'package:flutter_travel_audio_guide/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_travel_audio_guide/features/reminder/di/reminder_providers.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:flutter_travel_audio_guide/features/reminder/presentation/pages/my_journey_page.dart';
import 'package:go_router/go_router.dart';

Reminder _buildReminder(int id) {
  final future = DateTime.now().add(const Duration(days: 30));
  return Reminder(
    id: id,
    sourceType: 'attraction',
    sourceId: '$id',
    title: '提醒 $id',
    targetTime: future,
    remindBeforeSeconds: 0,
    notifyTime: future,
    notificationId: id,
    routePath: '/attraction/$id',
    payloadJson: '{}',
    isEnabled: true,
    isDone: false,
    createdAt: DateTime.now(),
  );
}

/// MyJourneyPage's account entry point reads currentUser / calls signOut()
/// directly through authRepositoryProvider (see _showAccountSheet), so a
/// fake repository is needed on top of overriding isSignedInProvider.
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.isSignedIn = false, this.currentUser});

  @override
  final bool isSignedIn;

  @override
  final AppUser? currentUser;

  int signOutCallCount = 0;

  @override
  Stream<bool> get authStateChanges => const Stream.empty();

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {}

  @override
  Future<bool> signUpWithPassword({
    required String email,
    required String password,
  }) async => true;

  @override
  Future<void> signOut() async {
    signOutCallCount++;
  }
}

class ThrowingSignOutAuthRepository extends FakeAuthRepository {
  ThrowingSignOutAuthRepository({super.isSignedIn, super.currentUser});

  @override
  Future<void> signOut() async {
    throw Exception('network error');
  }
}

/// Widget under test wrapped with the providers MyJourneyPage now depends
/// on. `isSignedInProvider` is overridden directly (it's a plain Provider,
/// cheap to fix in place); `authRepositoryProvider` is overridden with the
/// same fake so `_showAccountSheet` reads a consistent currentUser/signOut.
Widget buildSubject({
  required FakeAuthRepository authRepository,
  Stream<List<Reminder>>? reminders,
}) {
  return ProviderScope(
    overrides: [
      isSignedInProvider.overrideWithValue(authRepository.isSignedIn),
      authRepositoryProvider.overrideWithValue(authRepository),
      reminderListProvider.overrideWith(
        (ref) => reminders ?? Stream.value(const []),
      ),
    ],
    child: const MaterialApp(home: MyJourneyPage()),
  );
}

/// Variant with a real GoRouter, needed for tests that actually navigate
/// (guest tapping the account icon pushes /login).
Widget buildSubjectWithRouter({required FakeAuthRepository authRepository}) {
  final router = GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      GoRoute(path: AppRoutes.home, builder: (_, _) => const MyJourneyPage()),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, _) => const Scaffold(body: Text('LOGIN')),
      ),
    ],
  );
  return ProviderScope(
    overrides: [
      isSignedInProvider.overrideWithValue(authRepository.isSignedIn),
      authRepositoryProvider.overrideWithValue(authRepository),
      reminderListProvider.overrideWith((ref) => Stream.value(const [])),
    ],
    child: MaterialApp.router(routerConfig: router),
  );
}

void main() {
  group('提醒清單（Guest 可用，不受登入狀態影響）', () {
    testWidgets('清單為空時顯示提示文字', (tester) async {
      await tester.pumpWidget(
        buildSubject(authRepository: FakeAuthRepository()),
      );
      await tester.pumpAndSettle();
      expect(find.text('我的旅程'), findsOneWidget);
      expect(find.text('尚未加入任何提醒'), findsOneWidget);
    });

    testWidgets('有資料時顯示提醒清單', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          authRepository: FakeAuthRepository(),
          reminders: Stream.value([_buildReminder(1), _buildReminder(2)]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('提醒 1'), findsOneWidget);
      expect(find.text('提醒 2'), findsOneWidget);
    });

    testWidgets('讀取錯誤時顯示錯誤訊息', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          authRepository: FakeAuthRepository(),
          reminders: Stream<List<Reminder>>.error('DB 壞了'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('讀取失敗'), findsOneWidget);
    });

    testWidgets('已登入時提醒清單一樣正常顯示（帳號不影響本地功能）', (tester) async {
      await tester.pumpWidget(
        buildSubject(
          authRepository: FakeAuthRepository(isSignedIn: true),
          reminders: Stream.value([_buildReminder(1)]),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('提醒 1'), findsOneWidget);
    });
  });

  group('帳號入口', () {
    testWidgets('Guest 顯示「登入以同步」圖示', (tester) async {
      await tester.pumpWidget(
        buildSubject(authRepository: FakeAuthRepository()),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('登入以同步'), findsOneWidget);
      expect(find.byIcon(Icons.login), findsOneWidget);
      expect(find.byTooltip('帳號'), findsNothing);
    });

    testWidgets('已登入時顯示「帳號」圖示', (tester) async {
      await tester.pumpWidget(
        buildSubject(authRepository: FakeAuthRepository(isSignedIn: true)),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('帳號'), findsOneWidget);
      expect(find.byIcon(Icons.person_outline), findsOneWidget);
      expect(find.byTooltip('登入以同步'), findsNothing);
    });

    testWidgets('Guest 點擊帳號圖示會前往 /login', (tester) async {
      await tester.pumpWidget(
        buildSubjectWithRouter(
          authRepository: FakeAuthRepository(),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('登入以同步'));
      await tester.pumpAndSettle();
      expect(find.text('LOGIN'), findsOneWidget);
    });

    testWidgets('已登入點擊帳號圖示會打開帳號選單，顯示 email', (tester) async {
      final repository = FakeAuthRepository(
        isSignedIn: true,
        currentUser: const AppUser(id: 'u1', email: 'a@b.com'),
      );
      await tester.pumpWidget(buildSubject(authRepository: repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('帳號'));
      await tester.pumpAndSettle();
      expect(find.text('已登入帳號'), findsOneWidget);
      expect(find.text('a@b.com'), findsOneWidget);
      expect(find.text('登出'), findsOneWidget);
    });

    testWidgets('在帳號選單點擊登出會呼叫 signOut', (tester) async {
      final repository = FakeAuthRepository(isSignedIn: true);
      await tester.pumpWidget(buildSubject(authRepository: repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('帳號'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('登出'));
      await tester.pumpAndSettle();
      expect(repository.signOutCallCount, 1);
    });

    testWidgets('signOut 失敗時顯示錯誤 SnackBar，不讓整個 sheet 崩潰', (tester) async {
      final repository = ThrowingSignOutAuthRepository(isSignedIn: true);
      await tester.pumpWidget(buildSubject(authRepository: repository));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('帳號'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('登出'));
      await tester.pumpAndSettle();
      expect(find.textContaining('登出失敗'), findsOneWidget);
    });
  });
}
