import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database_provider.dart';
import '../../widgets/route_error_page.dart';
import '../../../features/activity/domain/entities/activity.dart';
import '../../../features/activity/presentation/pages/activity_detail_page.dart';

class ActivityDetailLoader extends ConsumerWidget {
  const ActivityDetailLoader({
    super.key,
    required this.idText,
    required this.initialActivity,
  });

  final String? idText;
  final Activity? initialActivity;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // When navigating from the list page, if the complete item is available, it will be displayed directly (zero delay).
    if (initialActivity != null) {
      return ActivityDetailPage(activity: initialActivity!);
    }
    // Jump from alert/notification/deep link, only ID is available
    // query from local database.
    final id = int.tryParse(idText ?? '');
    if (id == null) {
      return const RouteErrorPage(message: '活動 ID 格式錯誤');
    }
    return FutureBuilder<Activity?>(
      future: ref.read(appDatabaseProvider).activityDao.findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('活動詳細')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return RouteErrorPage(message: '讀取活動資料失敗：${snapshot.error}');
        }
        final activity = snapshot.data;
        if (activity == null) {
          return const RouteErrorPage(message: '找不到活動詳細資料\n（資料尚未同步，請稍後再試）');
        }
        return ActivityDetailPage(activity: activity);
      },
    );
  }
}
