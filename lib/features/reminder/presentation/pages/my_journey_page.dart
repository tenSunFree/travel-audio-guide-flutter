import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../di/reminder_providers.dart';
import '../widgets/reminder_tile.dart';

class MyJourneyPage extends ConsumerWidget {
  const MyJourneyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(reminderListProvider);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(title: const Text('我的旅程')),
      body: remindersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('讀取失敗：$error')),
        data: (reminders) {
          if (reminders.isEmpty) {
            return const Center(child: Text('尚未加入任何提醒'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reminders.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              return ReminderTile(reminder: reminders[index]);
            },
          );
        },
      ),
    );
  }
}
