import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../di/reminder_providers.dart';
import '../../domain/usecases/create_reminder_usecase.dart';
import '../widgets/reminder_bottom_sheet.dart';

/// Pass in the scheduling data for each page.
class DetailScheduleItem {
  const DetailScheduleItem({
    required this.sourceType,
    required this.sourceId,
    required this.title,
    this.subtitle,
    this.imageUrl,
    this.address,
    this.description,
    this.location,
    this.startDate,
    this.endDate,
    this.allDay = false,
  });

  final String sourceType;
  final String sourceId;
  final String title;
  final String? subtitle;
  final String? imageUrl;
  final String? address;
  final String? description;
  final String? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool allDay;
}

/// This is a shared tool for reminders and calendars; all three detail pages call this place.
class DetailScheduleActions {
  const DetailScheduleActions._();

  static Future<void> addToCalendar({
    required BuildContext context,
    required DetailScheduleItem item,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.android) {
      final status = await Permission.calendarWriteOnly.request();
      if (!context.mounted) return;
      if (!status.isGranted) {
        _showSnackBar(context, '請允許行事曆權限才能新增行程');
        return;
      }
    }
    final now = DateTime.now();
    final startDate = item.startDate ?? now;
    final DateTime endDate;
    if (item.endDate != null) {
      endDate = item.allDay
          ? _toExclusiveEndDate(item.endDate!)
          : item.endDate!;
    } else {
      endDate = startDate.add(const Duration(hours: 1));
    }
    final event = Event(
      title: item.title,
      description: item.description ?? '',
      location: item.location ?? item.address ?? '',
      startDate: startDate,
      endDate: endDate,
      allDay: item.allDay,
    );
    final success = await Add2Calendar.addEvent2Cal(event);
    if (!context.mounted) return;
    _showSnackBar(context, success ? '已開啟行事曆新增流程' : '無法加入行事曆');
  }

  static Future<void> addReminder({
    required BuildContext context,
    required WidgetRef ref,
    required DetailScheduleItem item,
  }) async {
    if (_isEnded(item)) {
      _showSnackBar(context, '行程已結束，無法加入提醒');
      return;
    }
    final defaultTargetTime = _getDefaultTargetTime(item);
    final maxTargetTime = item.endDate == null
        ? null
        : _toExclusiveEndDate(
            item.endDate!,
          ).subtract(const Duration(minutes: 1));
    final result = await showModalBottomSheet<ReminderBottomSheetResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ReminderBottomSheet(
        initialTargetTime: defaultTargetTime,
        minTargetTime: DateTime.now(),
        maxTargetTime: maxTargetTime,
      ),
    );
    if (result == null || !context.mounted) return;
    final validationError = _validateReminderTime(
      item: item,
      targetTime: result.targetTime,
      remindBeforeSeconds: result.remindBeforeSeconds,
    );
    if (validationError != null) {
      _showSnackBar(context, validationError);
      return;
    }
    try {
      await ref
          .read(createReminderUseCaseProvider)
          .call(
            CreateReminderParams(
              sourceType: item.sourceType,
              sourceId: item.sourceId,
              title: item.title,
              subtitle: item.subtitle,
              imageUrl: item.imageUrl,
              address: item.address,
              targetTime: result.targetTime,
              remindBeforeSeconds: result.remindBeforeSeconds,
            ),
          );
      // Tracking: Notification of successful setup
      await AnalyticsService.logReminderCreated(
        sourceType: item.sourceType,
        sourceId: item.sourceId,
        title: item.title,
        remindBeforeSeconds: result.remindBeforeSeconds,
      );
      if (!context.mounted) return;
      _showSnackBar(context, '已加入我的旅程提醒');
    } catch (e) {
      if (!context.mounted) return;
      _showSnackBar(context, _toFriendlyError(e));
    }
  }

  static bool _isEnded(DetailScheduleItem item) {
    final end = item.endDate;
    if (end == null) return false;
    return !DateTime.now().isBefore(_toExclusiveEndDate(end));
  }

  static DateTime _getDefaultTargetTime(DetailScheduleItem item) {
    final now = DateTime.now();
    final begin = item.startDate;
    final end = item.endDate;
    if (begin == null || end == null) {
      return now.add(const Duration(hours: 1));
    }
    final exclusiveEnd = _toExclusiveEndDate(end);
    if (now.isBefore(begin)) return begin;
    final candidate = now.add(const Duration(hours: 1));
    if (candidate.isBefore(exclusiveEnd)) return candidate;
    return now;
  }

  static String? _validateReminderTime({
    required DetailScheduleItem item,
    required DateTime targetTime,
    required int remindBeforeSeconds,
  }) {
    final now = DateTime.now();
    final begin = item.startDate;
    final end = item.endDate;
    if (begin != null && end != null) {
      final beginDay = DateTime(begin.year, begin.month, begin.day);
      final exclusiveEnd = _toExclusiveEndDate(end);
      if (targetTime.isBefore(beginDay)) {
        return '提醒時間不能早於開始日期';
      }
      if (!targetTime.isBefore(exclusiveEnd)) {
        return '提醒時間已超過結束日期，請選擇結束前的時間';
      }
    }
    final notifyTime = targetTime.subtract(
      Duration(seconds: remindBeforeSeconds),
    );
    if (notifyTime.isBefore(now)) {
      return '提醒觸發時間已經過了，請重新設定';
    }
    return null;
  }

  static DateTime _toExclusiveEndDate(DateTime end) =>
      DateTime(end.year, end.month, end.day).add(const Duration(days: 1));

  static String _toFriendlyError(Object e) {
    final msg = e.toString();
    if (msg.contains('exact_alarms_not_permitted')) {
      return '無法建立精準提醒，請至設定開啟「精確鬧鐘」權限';
    }
    if (msg.contains('提醒時間已經過了')) {
      return '提醒時間已過，請重新設定';
    }
    return '加入提醒失敗，請稍後再試';
  }

  static void _showSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}
