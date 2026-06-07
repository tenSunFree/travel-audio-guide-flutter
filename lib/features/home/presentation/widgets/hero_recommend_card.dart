import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_cached_network_image.dart';
import '../../domain/entities/home_state.dart';
import '../utils/home_navigation_launcher.dart';
import 'home_badge.dart';
import 'home_fallback_image.dart';
import '../constants/home_ui_colors.dart';

class HeroRecommendCard extends StatelessWidget {
  const HeroRecommendCard({super.key, required this.card, this.onViewDetail});

  final HomeRecommendCard card;

  /// The callback for the "View Details" button is passed in from the HomePage for easy routing later.
  final VoidCallback? onViewDetail;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 170,
            width: double.infinity,
            child: card.imageUrl != null
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      return AppCachedNetworkImage(
                        imageUrl: card.imageUrl!,
                        width: constraints.maxWidth,
                        height: 170,
                        fit: BoxFit.cover,
                        errorWidget: HomeFallbackImage(card.emoji),
                      );
                    },
                  )
                : HomeFallbackImage(card.emoji),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    HomeBadge(
                      text: _typeLabel(card.type),
                      backgroundColor: HomeUiColors.typeBadgeBg,
                      textColor: HomeUiColors.typeBadgeText,
                    ),
                    HomeBadge(
                      text: card.badgeText,
                      backgroundColor: HomeUiColors.recoBadgeBg,
                      textColor: HomeUiColors.recoBadgeText,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  card.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  card.subtitle,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (card.reasonText != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    card.reasonText!,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.textPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: onViewDetail,
                        child: const Text(
                          '查看詳情',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _NavigateButton(card: card),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _typeLabel(HomeRecommendType type) {
    switch (type) {
      case HomeRecommendType.attraction:
        return '景點推薦';
      case HomeRecommendType.activity:
        return '活動展演';
      case HomeRecommendType.audioGuide:
        return '語音導覽';
    }
  }
}

// Navigation buttons (StatefulWidget manages the loading state)
class _NavigateButton extends StatefulWidget {
  const _NavigateButton({required this.card});

  final HomeRecommendCard card;

  @override
  State<_NavigateButton> createState() => _NavigateButtonState();
}

class _NavigateButtonState extends State<_NavigateButton> {
  bool _loading = false;

  Future<void> _handleNavigate() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      await HomeNavigationLauncher.openBest(
        context,
        name: widget.card.title,
        lat: widget.card.lat,
        lng: widget.card.lng,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.divider),
        minimumSize: const Size(86, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: _loading ? null : _handleNavigate,
      child: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation(AppColors.textPrimary),
              ),
            )
          : const Text(
              '導航',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
    );
  }
}
