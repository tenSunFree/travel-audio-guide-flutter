import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database_provider.dart';
import '../../widgets/route_error_page.dart';
import '../../../features/attraction/domain/entities/attraction.dart';
import '../../../features/attraction/presentation/pages/attraction_detail_page.dart';

class AttractionDetailLoader extends ConsumerWidget {
  const AttractionDetailLoader({
    super.key,
    required this.idText,
    required this.initialAttraction,
  });

  final String? idText;
  final Attraction? initialAttraction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialAttraction != null) {
      return AttractionDetailPage(attraction: initialAttraction!);
    }
    final id = int.tryParse(idText ?? '');
    if (id == null) {
      return const RouteErrorPage(message: '景點 ID 格式錯誤');
    }
    return FutureBuilder<Attraction?>(
      future: ref.read(appDatabaseProvider).attractionDao.findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('景點詳細')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return RouteErrorPage(message: '讀取景點資料失敗：${snapshot.error}');
        }
        final attraction = snapshot.data;
        if (attraction == null) {
          return const RouteErrorPage(message: '找不到景點詳細資料\n（資料尚未同步，請稍後再試）');
        }
        return AttractionDetailPage(attraction: attraction);
      },
    );
  }
}
