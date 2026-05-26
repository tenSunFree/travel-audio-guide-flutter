import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/list_skeleton.dart';

/// Homepage skeleton screen
/// Corresponding real-world layout: HeroRecommendCard + HomeSectionTitle + RecommendListTile
/// Shares a single AnimationController to drive all blinking animations
class HomeSkeleton extends StatefulWidget {
  const HomeSkeleton({super.key});

  @override
  State<HomeSkeleton> createState() => _HomeSkeletonState();
}

class _HomeSkeletonState extends State<HomeSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  Widget build(BuildContext context) {
    final baseColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        final color = baseColor.withValues(alpha: _animation.value);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero skeleton, corresponding to HeroRecommendCard
            _HomeHeroSkeleton(color: color),
            const SizedBox(height: 20),
            // "Go Now" section title skeleton
            _HomeSectionTitleSkeleton(color: color),
            const SizedBox(height: 4),
            // "Go Now" list skeleton (4 entries)
            SizedBox(
              height: 96.0 * 4,
              child: ListSkeleton(
                itemCount: 4,
                itemHeight: 96,
                hasLeadingBox: true,
              ),
            ),
            const SizedBox(height: 20),
            // "Recommended Activities" section title skeleton
            _HomeSectionTitleSkeleton(color: color),
            const SizedBox(height: 4),
            // "Recommended Activities" list skeleton (3 entries)
            SizedBox(
              height: 96.0 * 3,
              child: ListSkeleton(
                itemCount: 3,
                itemHeight: 96,
                hasLeadingBox: true,
              ),
            ),
            const SizedBox(height: 120),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

// Hero Card Skeleton
// Corresponding to HeroRecommendCard: Image 170px + badge + title + subtitle + button column
class _HomeHeroSkeleton extends StatelessWidget {
  const _HomeHeroSkeleton({required this.color});

  final Color color;

  Widget _box(double width, double height, {double radius = 8}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );

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
          _box(double.infinity, 170, radius: 0),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _box(64, 24, radius: 12),
                    const SizedBox(width: 8),
                    _box(80, 24, radius: 12),
                  ],
                ),
                const SizedBox(height: 14),
                _box(double.infinity, 26),
                const SizedBox(height: 10),
                _box(double.infinity, 17),
                const SizedBox(height: 6),
                _box(220, 17),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: _box(double.infinity, 50, radius: 12)),
                    const SizedBox(width: 10),
                    _box(50, 50, radius: 12),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Section Title Skeleton
// Corresponding HomeSectionTitle: Left title + Right action text
class _HomeSectionTitleSkeleton extends StatelessWidget {
  const _HomeSectionTitleSkeleton({required this.color});

  final Color color;

  Widget _box(double width, double height, {double radius = 6}) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_box(100, 22), _box(48, 16)],
      ),
    );
  }
}
