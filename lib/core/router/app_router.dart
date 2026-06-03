import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import '../../features/activity/domain/entities/activity.dart';
import '../../features/attraction/domain/entities/attraction.dart';
import '../../features/audio_guide/domain/entities/audio_guide.dart';
import '../../features/home/presentation/pages/main_tab_page.dart';
import '../utils/app_log_page.dart';
import '../widgets/route_error_page.dart';
import 'loaders/activity_detail_loader.dart';
import 'loaders/attraction_detail_loader.dart';
import 'loaders/audio_guide_detail_loader.dart';

class AppRoutes {
  const AppRoutes._();

  static const home = '/';

  // List page (with filter parameters)
  static const attractions = '/attractions';
  static const activities = '/activities';

  // Details Page
  static const attractionDetail = '/attractions/:id';
  static const activityDetail = '/activities/:id';
  static const audioGuideDetail = '/audio-guides/:id';
  static const appLog = '/debug/log';

  /// Path to the list of recreational attractions page (can include timeSlot/openNow filters)
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

  /// Path to the event showcase list page (can include activityStatus filter)
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

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: kDebugMode,
  observers: [SentryNavigatorObserver()],
  routes: [
    // Homepage (Tab root page)
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const MainTabPage(),
    ),
    // List of recreational attractions (jump to the link from the homepage with parameters)
    // Note: Must be placed before /attractions/:id
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
    // List of events and performances (jump to the link from the homepage with parameters)
    // Note: Must be placed before /activities/:id
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
    // Details Page
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
    GoRoute(
      path: AppRoutes.appLog,
      builder: (context, state) => const AppLogPage(),
    ),
  ],
  errorBuilder: (context, state) =>
      RouteErrorPage(message: '找不到頁面：${state.uri}'),
);
