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
  static const attractionDetail = '/attractions/:id';
  static const activityDetail = '/activities/:id';
  static const audioGuideDetail = '/audio-guides/:id';
  static const appLog = '/debug/log';

  static String attractionDetailPath(int id) => '/attractions/$id';

  static String activityDetailPath(int id) => '/activities/$id';

  static String audioGuideDetailPath(int id) => '/audio-guides/$id';
}

final appRouter = GoRouter(
  initialLocation: AppRoutes.home,
  debugLogDiagnostics: kDebugMode,
  observers: [SentryNavigatorObserver()],
  routes: [
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const MainTabPage(),
    ),
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
