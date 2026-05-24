import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_widget_from_html_core/flutter_widget_from_html_core.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../reminder/presentation/utils/detail_schedule_actions.dart';
import '../../domain/entities/activity.dart';
import '../../../../core/widgets/detail_action_buttons.dart';

class ActivityDetailPage extends ConsumerStatefulWidget {
  const ActivityDetailPage({super.key, required this.activity});

  final Activity activity;

  @override
  ConsumerState<ActivityDetailPage> createState() => _ActivityDetailPageState();
}

class _ActivityDetailPageState extends ConsumerState<ActivityDetailPage> {
  // First, temporarily save the page; the official version will then integrate Drift.
  bool _isFavorite = false;

  Activity get activity => widget.activity;

  static const String _siteBaseUrl = 'https://www.travel.taipei';

  // Assemble the scheduling data for this page
  // (_parseDate is already defined in the page and can be reused directly)
  DetailScheduleItem get _scheduleItem => DetailScheduleItem(
    sourceType: 'activity',
    sourceId: activity.id.toString(),
    title: activity.title,
    subtitle: activity.address,
    imageUrl: null,
    address: activity.address,
    description: activity.description,
    location: activity.address.isNotEmpty
        ? activity.address
        : activity.organizer,
    startDate: _parseDate(activity.begin),
    endDate: _parseDate(activity.end),
    allDay: true,
  );

  Future<void> _addToCalendar() => DetailScheduleActions.addToCalendar(
    context: context,
    item: _scheduleItem,
  );

  Future<void> _addReminder() => DetailScheduleActions.addReminder(
    context: context,
    ref: ref,
    item: _scheduleItem,
  );

  /// Date utility
  /// "2026-03-26 00:00:00 +08:00" → DateTime, returns null on failure
  static DateTime? _parseDate(String raw) {
    if (raw.trim().isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }

  /// "2026-03-26 00:00:00 +08:00" → "2026/03/26"
  static String _formatDate(String raw) {
    if (raw.isEmpty) return '';
    try {
      final dt = DateTime.parse(raw);
      return '${dt.year}/'
          '${dt.month.toString().padLeft(2, '0')}/'
          '${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.split(' ').first;
    }
  }

  /// URL tools
  static String _toAbsoluteUrl(String url) {
    final t = url.trim();
    if (t.isEmpty) return t;
    if (t.startsWith('http://') || t.startsWith('https://')) return t;
    if (t.startsWith('//')) return 'https:$t';
    if (t.startsWith('/')) return '$_siteBaseUrl$t';
    return '$_siteBaseUrl/$t';
  }

  // HTML preprocessing
  // Simultaneously correct the relative paths of <img src> and <a href>,
  // To prevent images from failing to display and links from becoming unclickable.
  static String _normalizeHtml(String html) {
    if (html.isEmpty) return html;
    // Correct src="..." or src='...'
    var result = html.replaceAllMapped(
      RegExp("\\bsrc=([\"'])([^\"']+)\\1", caseSensitive: false),
      (m) {
        final quote = m.group(1)!;
        final url = m.group(2)!;
        return 'src=$quote${_toAbsoluteUrl(url)}$quote';
      },
    );
    // Correct href="..." or href='...'
    result = result.replaceAllMapped(
      RegExp("\\bhref=([\"'])([^\"']+)\\1", caseSensitive: false),
      (m) {
        final quote = m.group(1)!;
        final url = m.group(2)!;
        if (url.startsWith('#') ||
            url.startsWith('mailto:') ||
            url.startsWith('tel:')) {
          return m.group(0)!;
        }
        return 'href=$quote${_toAbsoluteUrl(url)}$quote';
      },
    );
    return result;
  }

  // The activity coordinates are of type String and need to be converted.
  static double? _parseCoord(String value) {
    final v = double.tryParse(value.trim());
    return (v == null || v == 0.0) ? null : v;
  }

  String _buildActivityShareText() {
    final beginStr = _formatDate(activity.begin);
    final endStr = _formatDate(activity.end);
    final url = _toAbsoluteUrl(activity.url);
    return [
      activity.title,
      if (beginStr.isNotEmpty || endStr.isNotEmpty) '展期：$beginStr ～ $endStr',
      if (activity.address.isNotEmpty) '地點：${activity.address}',
      if (url.isNotEmpty) url,
    ].join('\n');
  }

  Future<void> _callPhone() async {
    final phone = activity.tel.trim();
    if (phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    final success = await launchUrl(uri);
    if (!mounted) return;
    if (!success) _showSnackBar('無法開啟撥號功能');
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(_toAbsoluteUrl(url));
    if (uri == null) {
      _showSnackBar('連結格式異常');
      return;
    }
    final success = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!mounted) return;
    if (!success) _showSnackBar('無法開啟連結');
  }

  void _toggleFavorite() {
    setState(() => _isFavorite = !_isFavorite);
    _showSnackBar(_isFavorite ? '已加入收藏' : '已取消收藏');
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final beginStr = _formatDate(activity.begin);
    final endStr = _formatDate(activity.end);
    final normalizedDescription = _normalizeHtml(activity.description);
    // Meta information column, only display columns with values.
    final infoRows = <_InfoRowData>[
      if (beginStr.isNotEmpty || endStr.isNotEmpty)
        _InfoRowData(
          icon: Icons.calendar_today_outlined,
          label: '展期',
          value: '$beginStr ～ $endStr',
        ),
      if (activity.organizer.isNotEmpty)
        _InfoRowData(
          icon: Icons.business_outlined,
          label: '主辦',
          value: activity.organizer,
        ),
      if (activity.address.isNotEmpty)
        _InfoRowData(
          icon: Icons.location_on_outlined,
          label: '地點',
          value: activity.address,
        ),
      if (activity.tel.isNotEmpty)
        _InfoRowData(
          icon: Icons.phone_outlined,
          label: '電話',
          value: activity.tel,
          isTappable: true,
          onTap: _callPhone,
        ),
      if (activity.ticket.isNotEmpty)
        _InfoRowData(
          icon: Icons.confirmation_number_outlined,
          label: '票價',
          value: activity.ticket,
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '活動展演',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: false,
        // Collect hearts
        actions: [
          IconButton(
            tooltip: _isFavorite ? '取消收藏' : '加入收藏',
            onPressed: _toggleFavorite,
            icon: Icon(
              _isFavorite ? Icons.favorite : Icons.favorite_border,
              color: _isFavorite ? Colors.redAccent : null,
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.divider),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              activity.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            if (infoRows.isNotEmpty)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.scaffoldBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < infoRows.length; i++) ...[
                      _InfoRow(data: infoRows[i]),
                      if (i < infoRows.length - 1)
                        Divider(
                          height: 1,
                          thickness: 1,
                          color: AppColors.divider,
                          indent: 14,
                          endIndent: 14,
                        ),
                    ],
                  ],
                ),
              ),
            const SizedBox(height: 16),
            // Calendar + Share side by side (below meta tag, above body text)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DetailActionButtons(
                  navigateName: activity.address.isNotEmpty
                      ? activity.address
                      : activity.title,
                  navigateLat: _parseCoord(activity.nlat),
                  navigateLng: _parseCoord(activity.elong),
                  shareText: _buildActivityShareText(),
                  shareLabel: '分享活動',
                  onReminderPressed: _addReminder,
                  onCalendarPressed: _addToCalendar,
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(color: AppColors.divider),
            const SizedBox(height: 16),
            // Event Introduction (HTML Rendering)
            const Text(
              '活動介紹',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            HtmlWidget(
              normalizedDescription,
              textStyle: const TextStyle(
                fontSize: 15,
                height: 1.8,
                color: AppColors.textPrimary,
              ),
            ),
            // Related Links
            if (activity.links.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Divider(color: AppColors.divider),
              const SizedBox(height: 12),
              const Text(
                '相關連結',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...activity.links.map(
                (link) =>
                    _LinkRow(link: link, onTap: () => _openLink(link.src)),
              ),
            ],
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _InfoRowData {
  const _InfoRowData({
    required this.icon,
    required this.label,
    required this.value,
    this.isTappable = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isTappable;
  final VoidCallback? onTap;
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.data});

  final _InfoRowData data;

  @override
  Widget build(BuildContext context) {
    final textColor = data.isTappable
        ? Theme.of(context).colorScheme.primary
        : AppColors.textPrimary;
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(data.icon, size: 16, color: AppColors.textCaption),
          const SizedBox(width: 8),
          SizedBox(
            width: 40,
            child: Text(
              data.label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textCaption,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              data.value,
              style: TextStyle(
                fontSize: 13,
                color: textColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (data.isTappable)
            Icon(Icons.chevron_right, size: 16, color: AppColors.textCaption),
        ],
      ),
    );
    if (data.onTap != null) {
      return InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(10),
        child: content,
      );
    }
    return content;
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.link, required this.onTap});

  final ActivityLink link;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = link.subject.isNotEmpty ? link.subject : link.src;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            Icon(Icons.link, size: 16, color: AppColors.textCaption),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
