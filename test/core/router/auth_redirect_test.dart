import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/router/auth_redirect.dart';

void main() {
  group('resolveAuthRedirect', () {
    test('splash 一律不介入', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: false,
          signedIn: false,
          location: '/splash',
        ),
        isNull,
      );
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: true,
          location: '/splash',
        ),
        isNull,
      );
    });

    test('第一次啟動時非 welcome 頁都導向 welcome', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: false,
          signedIn: false,
          location: '/',
        ),
        '/welcome',
      );
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: false,
          signedIn: false,
          location: '/welcome',
        ),
        isNull,
      );
    });

    test('完成 onboarding 後直接進 Home，不要求登入', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: false,
          location: '/welcome',
        ),
        '/',
      );
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: true,
          location: '/welcome',
        ),
        '/',
      );
    });

    test('Guest 可以直接使用公開頁面', () {
      const publicRoutes = [
        '/',
        '/attractions',
        '/activities',
        '/audio-guides',
        '/attractions/123',
      ];
      for (final route in publicRoutes) {
        expect(
          resolveAuthRedirect(
            hasSeenWelcome: true,
            signedIn: false,
            location: route,
          ),
          isNull,
          reason: '$route 應允許 Guest 存取',
        );
      }
    });

    test('已登入的使用者停在 /login 不會被 router 導走（避免與 LoginPage 導航競爭）', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: true,
          location: '/login',
        ),
        isNull,
      );
    });

    test('Guest 訪問 protected route 時導向 login，並帶上 from', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: false,
          location: '/profile',
          protected: const {'/profile'},
        ),
        '/login?from=%2Fprofile',
      );
    });

    test('protected 子路徑同樣需要登入', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: false,
          location: '/profile/settings',
          protected: const {'/profile'},
        ),
        '/login?from=%2Fprofile%2Fsettings',
      );
    });

    test('已登入可以直接進 protected route', () {
      expect(
        resolveAuthRedirect(
          hasSeenWelcome: true,
          signedIn: true,
          location: '/profile',
          protected: const {'/profile'},
        ),
        isNull,
      );
    });

    test('from 保留完整 requestedLocation（含 query）', () {
      final redirect = resolveAuthRedirect(
        hasSeenWelcome: true,
        signedIn: false,
        location: '/profile',
        requestedLocation: '/profile?tab=sync',
        protected: const {'/profile'},
      );
      final uri = Uri.parse(redirect!);
      expect(uri.path, '/login');
      expect(uri.queryParameters['from'], '/profile?tab=sync');
    });
  });
}
