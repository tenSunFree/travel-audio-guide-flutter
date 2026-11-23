import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/reminder/data/services/no_op_notification_service.dart';

void main() {
  const service = NoOpNotificationService();

  test('initialize / schedule / cancel / reschedule 都是安全的 no-op', () async {
    await service.initialize();
    await service.cancelReminder(1);
    await service.reschedulePendingReminders(const []);
  });

  test('requestPermission 不會顯示授權、回傳 false', () async {
    expect(await service.requestPermission(), isFalse);
  });
}
