import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_cached_network_image.dart';
import '../../domain/entities/home_state.dart';
import '../constants/home_ui_colors.dart';
import 'home_fallback_image.dart';

class RecommendListTile extends StatelessWidget {
  const RecommendListTile({super.key, required this.card, this.onTap});

  final HomeRecommendCard card;
  final VoidCallback? onTap;

  // status chip style
  static ({Color bg, Color fg, IconData icon}) _statusStyle(
    RecommendStatus status,
  ) {
    return switch (status) {
      RecommendStatus.ongoing => (
        bg: const Color(0xFFE8F5E9),
        fg: const Color(0xFF2E7D32),
        icon: Icons.play_circle_outline,
      ),
      RecommendStatus.comingSoon => (
        bg: const Color(0xFFE3F2FD),
        fg: const Color(0xFF1565C0),
        icon: Icons.event_outlined,
      ),
      RecommendStatus.openNow || RecommendStatus.alwaysOpen => (
        bg: const Color(0xFFE8F5E9),
        fg: const Color(0xFF2E7D32),
        icon: Icons.check_circle_outline,
      ),
      RecommendStatus.openUntil => (
        bg: const Color(0xFFFFF8E1),
        fg: const Color(0xFFF57F17),
        icon: Icons.schedule,
      ),
      RecommendStatus.closingSoon => (
        bg: const Color(0xFFFFF8E1),
        fg: const Color(0xFFF57F17),
        icon: Icons.hourglass_bottom_outlined,
      ),
      RecommendStatus.uncertain => (
        bg: AppColors.surfaceMuted,
        fg: AppColors.textHint,
        icon: Icons.help_outline,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final isActivity = card.type == HomeRecommendType.activity;
    final style = _statusStyle(card.status);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.07),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left thumbnail / date badge
                isActivity
                    ? _DateBadge(emoji: card.emoji)
                    : _ImageThumb(card: card),
                const SizedBox(width: 14),
                // Main content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Type label (tiny, above title)
                      _TypeLabel(type: card.type),
                      const SizedBox(height: 4),
                      // Title
                      Text(
                        card.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Subtitle (district / category)
                      if (card.subtitle.isNotEmpty)
                        Text(
                          card.subtitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textCaption,
                          ),
                        ),
                      const SizedBox(height: 8),
                      // Bottom row: status chip + reason text
                      Row(
                        children: [
                          // Status chip
                          _StatusChip(
                            label: card.badgeText,
                            bg: style.bg,
                            fg: style.fg,
                            icon: style.icon,
                          ),
                          if (card.reasonText != null &&
                              card.reasonText!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                card.reasonText!,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textCaption,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                // Trailing arrow
                const Padding(
                  padding: EdgeInsets.only(top: 2, left: 4),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Sub-widgets
/// Activity card: emoji date badge (no photo available)
class _DateBadge extends StatelessWidget {
  const _DateBadge({required this.emoji});

  final String emoji;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: AppColors.scaffoldBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
          height: 1.2,
        ),
      ),
    );
  }
}

/// Attraction / audio guide card: real photo thumbnail
class _ImageThumb extends StatelessWidget {
  const _ImageThumb({required this.card});

  final HomeRecommendCard card;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        height: 64,
        child: card.imageUrl != null
            ? AppCachedNetworkImage(
                imageUrl: card.imageUrl!,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
                errorWidget: HomeFallbackImage(card.emoji),
              )
            : HomeFallbackImage(card.emoji),
      ),
    );
  }
}

/// Tiny type labels, e.g., "Activities" / "Attractions" / "Audio Guides"
class _TypeLabel extends StatelessWidget {
  const _TypeLabel({required this.type});

  final HomeRecommendType type;

  static String _label(HomeRecommendType t) => switch (t) {
    HomeRecommendType.activity => '活動',
    HomeRecommendType.attraction => '景點',
    HomeRecommendType.audioGuide => '語音導覽',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: HomeUiColors.typeBadgeBg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        _label(type),
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: HomeUiColors.typeBadgeText,
        ),
      ),
    );
  }
}

/// Coloured status chip: icon + label
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.bg,
    required this.fg,
    required this.icon,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: fg),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
