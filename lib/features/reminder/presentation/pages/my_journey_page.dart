import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';
import 'package:flutter_travel_audio_guide/core/router/app_router.dart';
import 'package:flutter_travel_audio_guide/features/auth/di/auth_providers.dart';
import 'package:flutter_travel_audio_guide/features/reminder/di/reminder_providers.dart';
import 'package:flutter_travel_audio_guide/features/reminder/presentation/widgets/reminder_tile.dart';
import 'package:go_router/go_router.dart';

/// MyJourney is a Guest feature: it only reads local Drift reminders and has
/// no auth dependency. The account icon is purely an optional entry point
/// into Login/Account — it does not gate anything on this page.
class MyJourneyPage extends ConsumerWidget {
  const MyJourneyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(reminderListProvider);
    final signedIn = ref.watch(isSignedInProvider);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: AppBar(
        title: const Text('我的旅程'),
        actions: [
          IconButton(
            tooltip: signedIn ? '帳號' : '登入以同步',
            icon: Icon(signedIn ? Icons.person_outline : Icons.login),
            onPressed: () {
              if (signedIn) {
                _showAccountSheet(context, ref);
              } else {
                context.push(AppRoutes.login);
              }
            },
          ),
        ],
      ),
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

  void _showAccountSheet(BuildContext context, WidgetRef ref) {
    final email = ref.read(authRepositoryProvider).currentUser?.email ?? '';
    // Capture the parent page's ScaffoldMessenger before opening the sheet —
    // the sheet's own context is gone once Navigator.pop() runs below.
    final messenger = ScaffoldMessenger.of(context);
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_circle_outlined),
                title: const Text('已登入帳號'),
                subtitle: Text(email),
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('登出'),
                onTap: () async {
                  Navigator.of(sheetContext).pop();
                  try {
                    await ref.read(authRepositoryProvider).signOut();
                  } catch (e) {
                    messenger.showSnackBar(SnackBar(content: Text('登出失敗：$e')));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
