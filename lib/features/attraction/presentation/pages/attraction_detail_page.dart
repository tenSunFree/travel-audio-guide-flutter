import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/analytics/analytics_service.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_cached_network_image.dart';
import '../../../reminder/presentation/utils/detail_schedule_actions.dart';
import '../../domain/entities/attraction.dart';
import '../../../../core/widgets/detail_action_buttons.dart';

class AttractionDetailPage extends ConsumerStatefulWidget {
  const AttractionDetailPage({super.key, required this.attraction});

  final Attraction attraction;

  @override
  ConsumerState<AttractionDetailPage> createState() =>
      _AttractionDetailPageState();
}

class _AttractionDetailPageState extends ConsumerState<AttractionDetailPage> {
  @override
  void initState() {
    super.initState();
    // Tracking: User enters attraction details page
    AnalyticsService.logAttractionViewed(
      id: widget.attraction.id,
      name: widget.attraction.name,
    );
  }

  static String _buildAttractionShareText(Attraction attraction) {
    return [
      attraction.name,
      if (attraction.address.isNotEmpty) '地址：${attraction.address}',
      if (attraction.openTime.isNotEmpty) '開放時間：${attraction.openTime}',
      if (attraction.officialSite.isNotEmpty) attraction.officialSite,
    ].join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final attraction = widget.attraction;
    // Assembly scheduling data
    final scheduleItem = DetailScheduleItem(
      sourceType: 'attraction',
      sourceId: attraction.id.toString(),
      title: attraction.name,
      subtitle: attraction.address,
      imageUrl: attraction.firstImageUrl.isNotEmpty
          ? attraction.firstImageUrl
          : null,
      address: attraction.address,
      description: attraction.introduction,
      location: attraction.address,
      allDay: false,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          attraction.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: AppColors.divider),
        ),
      ),
      body: ListView(
        children: [
          // Image Area
          _ImageSection(attraction: attraction),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  attraction.name,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                // Category chips
                if (attraction.categories.isNotEmpty) ...[
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: attraction.categories
                        .map((c) => _CategoryChip(category: c))
                        .toList(),
                  ),
                  const SizedBox(height: 14),
                ],
                // Basic Information
                _InfoRow(
                  icon: Icons.location_on_outlined,
                  text: attraction.address.isNotEmpty
                      ? attraction.address
                      : '未提供地址',
                ),
                if (attraction.openTime.isNotEmpty)
                  _InfoRow(icon: Icons.access_time, text: attraction.openTime),
                if (attraction.tel.isNotEmpty)
                  _InfoRow(icon: Icons.phone_outlined, text: attraction.tel),
                if (attraction.ticket.isNotEmpty)
                  _InfoRow(
                    icon: Icons.confirmation_number_outlined,
                    text: attraction.ticket,
                  ),
                if (attraction.remind.isNotEmpty)
                  _InfoRow(icon: Icons.info_outline, text: attraction.remind),
                const SizedBox(height: 20),
                DetailActionButtons(
                  navigateName: attraction.name,
                  navigateLat: attraction.nlat,
                  navigateLng: attraction.elong,
                  shareText: _buildAttractionShareText(attraction),
                  shareLabel: '分享景點',
                  onReminderPressed: () => DetailScheduleActions.addReminder(
                    context: context,
                    ref: ref,
                    item: scheduleItem,
                  ),
                  onCalendarPressed: () => DetailScheduleActions.addToCalendar(
                    context: context,
                    item: scheduleItem,
                  ),
                  // Tracking: Sharing attractions
                  onSharePressed: () => AnalyticsService.logAttractionShared(
                    id: attraction.id,
                    name: attraction.name,
                  ),
                  // Tracking: Navigation
                  onNavigatePressed: () =>
                      AnalyticsService.logNavigationRequested(
                        id: attraction.id,
                        name: attraction.name,
                        sourceType: 'attraction',
                      ),
                ),
                const SizedBox(height: 20),
                const Divider(color: AppColors.divider),
                const SizedBox(height: 16),
                // Attraction Introduction
                const Text(
                  '景點介紹',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  attraction.introduction.isNotEmpty
                      ? attraction.introduction
                      : '目前沒有景點介紹',
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.8,
                    color: AppColors.textPrimary,
                  ),
                ),
                // External links
                if (attraction.officialSite.isNotEmpty ||
                    attraction.facebook.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  const Divider(color: AppColors.divider),
                  const SizedBox(height: 12),
                  if (attraction.officialSite.isNotEmpty)
                    _LinkRow(
                      icon: Icons.language_outlined,
                      label: '官方網站',
                      url: attraction.officialSite,
                    ),
                  if (attraction.facebook.isNotEmpty)
                    _LinkRow(
                      icon: Icons.link,
                      label: 'Facebook',
                      url: attraction.facebook,
                    ),
                ],
                // Source
                const SizedBox(height: 24),
                const Text(
                  '資料來源：台北旅遊網',
                  style: TextStyle(fontSize: 12, color: AppColors.textHint),
                ),
                if (attraction.modified.isNotEmpty)
                  Text(
                    '最後更新：${attraction.modified.split(' ').first}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textHint,
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Image Section (Supports multiple images in PageView)
class _ImageSection extends StatefulWidget {
  const _ImageSection({required this.attraction});

  final Attraction attraction;

  @override
  State<_ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends State<_ImageSection> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.attraction.images;
    if (images.isEmpty) {
      return Container(
        height: 220,
        color: AppColors.surfaceMuted,
        alignment: Alignment.center,
        child: const Icon(
          Icons.image_not_supported_outlined,
          size: 48,
          color: AppColors.textHint,
        ),
      );
    }
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemBuilder: (_, i) {
              return LayoutBuilder(
                builder: (context, constraints) {
                  return AppCachedNetworkImage(
                    imageUrl: images[i].src,
                    width: constraints.maxWidth,
                    height: 220,
                    fit: BoxFit.cover,
                    errorWidget: Container(
                      color: AppColors.surfaceMuted,
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.broken_image_outlined,
                        size: 48,
                        color: AppColors.textHint,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
        if (images.length > 1)
          Padding(
            padding: const EdgeInsets.all(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${_currentIndex + 1} / ${images.length}',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.category});

  final AttractionCategory category;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        category.name,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onPrimaryContainer,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _LinkRow extends StatelessWidget {
  const _LinkRow({required this.icon, required this.label, required this.url});

  final IconData icon;
  final String label;
  final String url;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: colorScheme.primary,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
