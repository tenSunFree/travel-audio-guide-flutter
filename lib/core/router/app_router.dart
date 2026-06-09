import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../features/activity/domain/entities/activity.dart';
import '../../features/attraction/domain/entities/attraction.dart';
import '../../features/audio_guide/domain/entities/audio_guide.dart';
import '../../features/home/presentation/pages/main_tab_page.dart';
import '../../features/onboarding/di/onboarding_providers.dart';
import '../../features/onboarding/presentation/pages/welcome_page.dart';
import '../../features/splash/presentation/pages/splash_page.dart';
import '../analytics/analytics_service.dart';
import '../utils/app_log_page.dart';
import '../widgets/route_error_page.dart';
import 'loaders/activity_detail_loader.dart';
import 'loaders/attraction_detail_loader.dart';
import 'loaders/audio_guide_detail_loader.dart';

class AppRoutes {
  const AppRoutes._();

  // Splash / Onboarding
  static const splash = '/splash';
  static const welcome = '/welcome';

  // Homepage (Tab root page)
  static const home = '/';

  // List pages (with optional filter parameters)
  static const attractions = '/attractions';
  static const activities = '/activities';

  // Detail pages
  static const attractionDetail = '/attractions/:id';
  static const activityDetail = '/activities/:id';
  static const audioGuideDetail = '/audio-guides/:id';

  // Debug
  static const appLog = '/debug/log';

  /// Path to the attractions list page (supports timeSlot / openNow filters)
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

  /// Path to the activities list page (supports activityStatus filter)
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

  static String attractionDetailPath(int id) => '/attractions/$id';

  static String activityDetailPath(int id) => '/activities/$id';

  static String audioGuideDetailPath(int id) => '/audio-guides/$id';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  // ValueNotifier acts as a bridge to GoRouter's refreshListenable.
  // GoRouter cannot directly listen to Riverpod providers; it connects indirectly through this bridge.
  final notifier = ValueNotifier<bool>(ref.read(onboardingProvider));
  // When the onboardingProvider state changes (after completeOnboarding() is called),
  // Synchronously update the notifier → trigger GoRouter to recalculate the redirect.
  // WelcomePage does not need to call context.go() itself; GoRouter handles it automatically.
  ref.listen<bool>(onboardingProvider, (_, next) => notifier.value = next);
  // Clean up ValueNotifier when Provider disposes to prevent memory leaks.
  ref.onDispose(notifier.dispose);
  return GoRouter(
    // The app always starts from /splash.
    // After the SplashPage animation ends, it will redirect to /welcome or / depending on hasSeenWelcome.
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: kDebugMode,
    // Retain the original Sentry and Analytics observers.
    observers: [SentryNavigatorObserver(), AnalyticsService.observer],
    // refreshListenable makes GoRouter rerun the redirect when the notifier changes.
    refreshListenable: notifier,
    redirect: (context, state) {
      final hasSeen = notifier.value;
      final location = state.matchedLocation;
      // Welcome to view only once, If already seen it, please block it.
      if (hasSeen && location == AppRoutes.welcome) {
        return AppRoutes.home;
      }
      return null;
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
      // Main app
      // Homepage (Tab root page)
      GoRoute(
        path: AppRoutes.home,
        builder: (context, state) => const MainTabPage(),
      ),
      // Attractions list (supports timeSlot / openNow query parameters)
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
      // Activities list (supports activityStatus query parameter)
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
      // Detail pages
      GoRoute(
        path: AppRoutes.attractionDetail,
        builder: (context, state) => AttractionDetailLoader(
          idText: state.pathParameters['id'],
          initialAttraction: state.extra is Attraction
              ? state.extra as Attraction
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.activityDetail,
        builder: (context, state) => ActivityDetailLoader(
          idText: state.pathParameters['id'],
          initialActivity: state.extra is Activity
              ? state.extra as Activity
              : null,
        ),
      ),
      GoRoute(
        path: AppRoutes.audioGuideDetail,
        builder: (context, state) => AudioGuideDetailLoader(
          idText: state.pathParameters['id'],
          initialGuide: state.extra is AudioGuide
              ? state.extra as AudioGuide
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
