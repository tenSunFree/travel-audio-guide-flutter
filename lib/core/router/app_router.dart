import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/core/analytics/analytics_service.dart';
import 'package:flutter_travel_audio_guide/core/router/auth_redirect.dart';
import 'package:flutter_travel_audio_guide/core/router/loaders/activity_detail_loader.dart';
import 'package:flutter_travel_audio_guide/core/router/loaders/attraction_detail_loader.dart';
import 'package:flutter_travel_audio_guide/core/router/loaders/audio_guide_detail_loader.dart';
import 'package:flutter_travel_audio_guide/core/utils/app_log_page.dart';
import 'package:flutter_travel_audio_guide/core/widgets/route_error_page.dart';
import 'package:flutter_travel_audio_guide/features/activity/domain/entities/activity.dart';
import 'package:flutter_travel_audio_guide/features/attraction/domain/entities/attraction.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_travel_audio_guide/features/home/presentation/pages/main_tab_page.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/di/onboarding_providers.dart';
import 'package:flutter_travel_audio_guide/features/onboarding/presentation/pages/welcome_page.dart';
import 'package:flutter_travel_audio_guide/features/splash/presentation/pages/splash_page.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class AppRoutes {
  const AppRoutes._();

  // Splash / Onboarding
  static const splash = '/splash';
  static const welcome = '/welcome';

  // Auth
  static const login = '/login';

  // Homepage (Tab root page)
  static const home = '/';

  // List pages
  static const attractions = '/attractions';
  static const activities = '/activities';
  static const audioGuides = '/audio-guides';

  // Detail pages
  static const attractionDetail = '/attractions/:id';
  static const activityDetail = '/activities/:id';
  static const audioGuideDetail = '/audio-guides/:id';

  // Debug
  static const appLog = '/debug/log';

  /// Attractions list — supports timeSlot / openNow filters
  static String attractionsPath({String? timeSlot, bool openNow = false}) {
    final query = <String, String>{
      if (timeSlot != null && timeSlot.isNotEmpty) 'timeSlot': timeSlot,
      if (openNow) 'openNow': 'true',
    };
    return Uri(
      path: attractions,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  /// Activities list — supports activityStatus filter
  static String activitiesPath({String? activityStatus}) {
    final query = <String, String>{
      if (activityStatus != null && activityStatus.isNotEmpty)
        'activityStatus': activityStatus,
    };
    return Uri(
      path: activities,
      queryParameters: query.isEmpty ? null : query,
    ).toString();
  }

  /// Audio guides list — switches to the audio guide tab
  static String audioGuidesPath() => audioGuides;

  static String attractionDetailPath(int id) => '/attractions/$id';

  static String activityDetailPath(int id) => '/activities/$id';

  static String audioGuideDetailPath(int id) => '/audio-guides/$id';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // Whether the welcome page has been seen
  final hasSeenNotifier = ValueNotifier<bool>(ref.read(onboardingProvider));
  ref.listen<bool>(
    onboardingProvider,
    (_, next) => hasSeenNotifier.value = next,
  );
  ref.onDispose(hasSeenNotifier.dispose);
  // Whether the user is signed in with Supabase
  final signedInNotifier = ValueNotifier<bool>(
    ref.read(authStateChangesProvider).value ?? false,
  );
  ref.listen(authStateChangesProvider, (_, next) {
    next.whenData((signedIn) => signedInNotifier.value = signedIn);
  });
  ref.onDispose(signedInNotifier.dispose);
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    observers: [SentryNavigatorObserver(), AnalyticsService.observer],
    refreshListenable: Listenable.merge([hasSeenNotifier, signedInNotifier]),
    redirect: (context, state) {
      return resolveAuthRedirect(
        hasSeenWelcome: hasSeenNotifier.value,
        signedIn: signedInNotifier.value,
        location: state.matchedLocation,
        requestedLocation: state.uri.toString(),
      );
    },
    routes: [
      // Splash / Onboarding
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.welcome,
        builder: (context, state) => const WelcomePage(),
      ),
      // Auth
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginPage(),
      ),
      // Home
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const MainTabPage(),
      ),
      // Attractions list
      // Must be placed before /attractions/:id
      GoRoute(
        path: AppRoutes.attractions,
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return MainTabPage(
            initialIndex: 3,
            attractionInitialTimeSlot: query['timeSlot'],
            attractionInitialOpenNow: query['openNow'] == 'true',
          );
        },
      ),
      // Activities list
      // Must be placed before /activities/:id
      GoRoute(
        path: AppRoutes.activities,
        builder: (context, state) {
          final query = state.uri.queryParameters;
          return MainTabPage(
            initialIndex: 2,
            activityInitialStatus: query['activityStatus'],
          );
        },
      ),
      // Audio guides list
      // Must be placed before /audio-guides/:id
      GoRoute(
        path: AppRoutes.audioGuides,
        builder: (context, state) {
          return const MainTabPage(initialIndex: 1);
        },
      ),
      // Detail pages
      GoRoute(
        path: AppRoutes.attractionDetail,
        builder: (context, state) => AttractionDetailLoader(
          idText: state.pathParameters['id'],
          initialAttraction: state.extra is Attraction
              ? state.extra! as Attraction
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.activityDetail,
        builder: (context, state) => ActivityDetailLoader(
          idText: state.pathParameters['id'],
          initialActivity: state.extra is Activity
              ? state.extra! as Activity
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.audioGuideDetail,
        builder: (context, state) => AudioGuideDetailLoader(
          idText: state.pathParameters['id'],
          initialGuide: state.extra is AudioGuide
              ? state.extra! as AudioGuide
              : null,
        ),
      ),
      // Debug
      GoRoute(
        path: AppRoutes.appLog,
        builder: (context, state) => const AppLogPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        RouteErrorPage(message: '找不到頁面：${state.uri}'),
  );
});
