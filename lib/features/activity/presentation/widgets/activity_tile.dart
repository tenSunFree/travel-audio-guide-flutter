import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/nearby/nearby_utils.dart';
import '../../domain/entities/activity.dart';
import '../controllers/activity_list_controller.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.activity,
    required this.onTap,
    this.userLat,
    this.userLng,
  });

  final Activity activity;
  final VoidCallback onTap;
  final double? userLat;
  final double? userLng;

  static String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      final y = dt.year;
      final m = dt.month.toString().padLeft(2, '0');
      final d = dt.day.toString().padLeft(2, '0');
      return '$y/$m/$d';
    } catch (_) {
      return raw.split(' ').first;
    }
  }

  static String _htmlToPlainText(String html, {int maxLength = 100}) {
    final text = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&quot;', '"')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\n{2,}'), '\n')
        .trim();
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}…';
  }

  String? _distanceLabel() {
    if (userLat == null || userLng == null) return null;
    final lat = double.tryParse(activity.nlat);
    final lng = double.tryParse(activity.elong);
    if (!NearbyUtils.isValidCoordinate(lat, lng)) return null;
    final meters = NearbyUtils.distanceMeters(
      fromLat: userLat!,
      fromLng: userLng!,
      toLat: lat!,
      toLng: lng!,
    );
    return '距你 ${NearbyUtils.formatDistance(meters)}';
  }

  String? _statusText() {
    return ActivityListState.activityStatusText(activity, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final preview = _htmlToPlainText(activity.description);
    final dateRange =
        '${_formatDate(activity.begin)}  ～  ${_formatDate(activity.end)}';
    final distanceLabel = _distanceLabel();
    final statusText = _statusText();
    // Distance + status form a single line of additional information
    // which is only displayed if there is content.
    final extraParts = <String>[?distanceLabel, ?statusText];
    return InkWell(
      onTap: onTap,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              activity.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            // Date
            if (activity.begin.isNotEmpty || activity.end.isNotEmpty)
              Text(
                dateRange,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textCaption,
                ),
              ),
            // Distance + Activity Status
            // Only displayed when location is available or activity status is active.
            if (extraParts.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                extraParts.join('  ·  '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textCaption,
                ),
              ),
            ],
            // Organizer
            if (activity.organizer.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                activity.organizer,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textCaption,
                ),
              ),
            ],
            // Preview
            if (preview.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                preview,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
