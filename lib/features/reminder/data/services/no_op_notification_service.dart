import 'package:flutter_travel_audio_guide/features/reminder/domain/entities/reminder.dart';
import 'package:flutter_travel_audio_guide/features/reminder/domain/services/notification_service.dart';

/// Notification service for platforms without local notifications (Web).
///
/// Every call is a safe no-op: no plugin is touched and no permission prompt
/// is shown. Reminders can still be stored in the database; they simply do
/// not fire a system notification.
class NoOpNotificationService implements NotificationService {
  const NoOpNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => false;

  @override
  Future<void> scheduleReminder(Reminder reminder) async {}

  @override
  Future<void> cancelReminder(int notificationId) async {}

  @override
  Future<void> reschedulePendingReminders(List<Reminder> reminders) async {}
}
