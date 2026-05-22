import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../database/database_provider.dart';
import '../../widgets/route_error_page.dart';
import '../../../features/audio_guide/domain/entities/audio_guide.dart';
import '../../../features/audio_guide/presentation/pages/audio_guide_detail_page.dart';

class AudioGuideDetailLoader extends ConsumerWidget {
  const AudioGuideDetailLoader({
    super.key,
    required this.idText,
    required this.initialGuide,
  });

  final String? idText;
  final AudioGuide? initialGuide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (initialGuide != null) {
      return AudioGuideDetailPage(guide: initialGuide!);
    }
    final id = int.tryParse(idText ?? '');
    if (id == null) {
      return const RouteErrorPage(message: '語音導覽 ID 格式錯誤');
    }
    return FutureBuilder<AudioGuide?>(
      future: ref.read(appDatabaseProvider).audioGuideDao.findById(id),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return Scaffold(
            appBar: AppBar(title: const Text('語音導覽詳細')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return RouteErrorPage(message: '讀取語音導覽資料失敗：${snapshot.error}');
        }
        final guide = snapshot.data;
        if (guide == null) {
          return const RouteErrorPage(message: '找不到語音導覽詳細資料\n（資料尚未同步，請稍後再試）');
        }
        return AudioGuideDetailPage(guide: guide);
      },
    );
  }
}
