import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/nearby/location_controller.dart';
import '../../../../core/nearby/location_fallback_card.dart';
import '../../../../core/nearby/nearby_utils.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/common_app_bar.dart';
import '../../di/home_providers.dart';
import '../../domain/entities/home_state.dart';
import '../controllers/home_controller.dart';
import '../widgets/hero_recommend_card.dart';
import '../widgets/home_empty_card.dart';
import '../widgets/home_section_title.dart';
import '../widgets/home_skeleton.dart';
import '../widgets/home_subtitle.dart';
import '../widgets/period_chips.dart';
import '../widgets/rainy_mode_card.dart';
import '../widgets/recommend_list_tile.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Do not call methods that modify the state of other providers within the provider constructor (synchronous initialization phase).
    //
    // Change it to after the first frame is completed on the HomePage (addPostFrameCallback)
    // Only then is restoreIfPreviouslyEnabled() called. This is the point in time:
    // 1. NearbyHomeController has been fully mounted.
    // 2. LocationController has also been fully mounted.
    // 3. The first build of the entire widget tree has completed.
    // So here we call getCurrentLocation() to modify LocationController.state
    // This completely avoids violating Riverpod's "cannot modify other providers during initialization" rule.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref
          .read(nearbyHomeControllerProvider.notifier)
          .restoreIfPreviouslyEnabled();
    });
  }

  static String _timeSlotValue(HomePeriod period) {
    return switch (period) {
      HomePeriod.morning => 'morning',
      HomePeriod.afternoon => 'afternoon',
      HomePeriod.evening => 'evening',
      HomePeriod.night => 'night',
    };
  }

  static String _heroSectionTitle(HomePeriod period) {
    return switch (period) {
      HomePeriod.morning => '早上推薦',
      HomePeriod.afternoon => '下午推薦',
      HomePeriod.evening => '傍晚推薦',
      HomePeriod.night => '夜間推薦',
    };
  }

  void _openRecommendDetail(BuildContext context, HomeRecommendCard card) {
    switch (card.type) {
      case HomeRecommendType.attraction:
        final attraction = card.attraction;
        if (attraction == null) {
          _showError(context, '找不到景點詳細資料');
          return;
        }
        context.push(
          AppRoutes.attractionDetailPath(attraction.id),
          extra: attraction,
        );
      case HomeRecommendType.activity:
        final activity = card.activity;
        if (activity == null) {
          _showError(context, '找不到活動詳細資料');
          return;
        }
        context.push(
          AppRoutes.activityDetailPath(activity.id),
          extra: activity,
        );
      case HomeRecommendType.audioGuide:
        break;
    }
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    final nearbyState = ref.watch(nearbyHomeControllerProvider);
    final nearbyController = ref.read(nearbyHomeControllerProvider.notifier);
    final locState = ref.watch(locationControllerProvider);
    final locController = ref.read(locationControllerProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: CommonAppBar(
        title: '首頁',
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.tune),
            tooltip: '首頁設定',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          controller.changePeriod(state.selectedPeriod);
          await nearbyController.refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // Subtitle
            SliverToBoxAdapter(
              child: HomeSubtitle(subtitle: '${state.title}・${state.subtitle}'),
            ),
            // Rainy mode toggle
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: RainyModeCard(
                  value: state.isRainyMode,
                  onChanged: controller.toggleRainyMode,
                ),
              ),
            ),
            // Period chips
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: PeriodChips(
                  selected: state.selectedPeriod,
                  onSelected: controller.changePeriod,
                ),
              ),
            ),
            // Main content / skeleton / error
            if (state.isLoading)
              const SliverToBoxAdapter(child: HomeSkeleton())
            else if (state.errorMessage != null)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: HomeEmptyCard(message: '首頁資料讀取失敗'),
                ),
              )
            else ...[
              // Hero section
              SliverToBoxAdapter(
                child: HomeSectionTitle(
                  title: _heroSectionTitle(state.selectedPeriod),
                  action: '查看全部',
                  onActionTap: () {
                    context.push(
                      AppRoutes.attractionsPath(
                        timeSlot: _timeSlotValue(state.selectedPeriod),
                      ),
                    );
                  },
                ),
              ),
              if (state.heroCard != null)
                SliverToBoxAdapter(
                  child: HeroRecommendCard(
                    card: state.heroCard!,
                    onViewDetail: () =>
                        _openRecommendDetail(context, state.heroCard!),
                  ),
                )
              else
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: HomeEmptyCard(message: '目前沒有適合的推薦景點'),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              // Available now section
              SliverToBoxAdapter(
                child: HomeSectionTitle(
                  title: '現在可去',
                  action: '查看全部',
                  onActionTap: () {
                    context.push(AppRoutes.attractionsPath(openNow: true));
                  },
                ),
              ),
              SliverList.builder(
                itemCount: state.availableCards.length,
                itemBuilder: (context, index) {
                  final card = state.availableCards[index];
                  return RecommendListTile(
                    card: card,
                    onTap: () => _openRecommendDetail(context, card),
                  );
                },
              ),
              if (state.availableCards.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: HomeEmptyCard(message: '目前沒有可前往景點'),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              // Activity section
              SliverToBoxAdapter(
                child: HomeSectionTitle(
                  title: '活動推薦',
                  action: '查看全部',
                  onActionTap: () {
                    context.push(
                      AppRoutes.activitiesPath(activityStatus: 'ongoing'),
                    );
                  },
                ),
              ),
              SliverList.builder(
                itemCount: state.activityCards.length,
                itemBuilder: (context, index) {
                  final card = state.activityCards[index];
                  return RecommendListTile(
                    card: card,
                    onTap: () => _openRecommendDetail(context, card),
                  );
                },
              ),
              if (state.activityCards.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: HomeEmptyCard(message: '目前沒有活動推薦'),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              // Nearby section
              if (!nearbyState.hasLocation) ...[
                // Not yet enabled → show the fallback card
                SliverToBoxAdapter(
                  child: LocationFallbackCard(
                    permissionState: locState.permissionState,
                    isLoading: nearbyState.isLoading,
                    onRequestLocation: () => nearbyController.enableNearby(),
                    onOpenSettings: () => locController.openAppSettings(),
                    onOpenLocationService: () =>
                        locController.openLocationSettings(),
                    onBrowseAll: () =>
                        context.push(AppRoutes.attractionsPath()),
                  ),
                ),
              ] else ...[
                // Nearby attractions
                SliverToBoxAdapter(
                  child: HomeSectionTitle(
                    title: '附近景點',
                    action: '查看全部',
                    onActionTap: () =>
                        context.push(AppRoutes.attractionsPath()),
                  ),
                ),
                if (nearbyState.nearbyAttractions.isEmpty)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: HomeEmptyCard(message: '附近沒有找到景點'),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: nearbyState.nearbyAttractions.length,
                    itemBuilder: (context, index) {
                      final item = nearbyState.nearbyAttractions[index];
                      final locPoint = ref
                          .read(locationControllerProvider)
                          .point;
                      // Build distance label for the tile subtitle
                      String? distLabel;
                      if (locPoint != null &&
                          NearbyUtils.isValidCoordinate(
                            item.nlat,
                            item.elong,
                          )) {
                        final m = NearbyUtils.distanceMeters(
                          fromLat: locPoint.latitude,
                          fromLng: locPoint.longitude,
                          toLat: item.nlat!,
                          toLng: item.elong!,
                        );
                        distLabel = NearbyUtils.formatDistance(m);
                      }
                      return _NearbyAttractionTile(
                        name: item.name,
                        distric: item.distric,
                        distanceLabel: distLabel,
                        imageUrl: item.images.isNotEmpty
                            ? item.images.first.src
                            : null,
                        onTap: () => context.push(
                          AppRoutes.attractionDetailPath(item.id),
                          extra: item,
                        ),
                      );
                    },
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ],
        ),
      ),
    );
  }
}

// Private tile widgets — lightweight, home-screen only
class _NearbyAttractionTile extends StatelessWidget {
  const _NearbyAttractionTile({
    required this.name,
    required this.distric,
    required this.distanceLabel,
    required this.imageUrl,
    required this.onTap,
  });

  final String name;
  final String distric;
  final String? distanceLabel;
  final String? imageUrl;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      ?distanceLabel,
      if (distric.trim().isNotEmpty) distric.trim(),
    ].join('  ·  ');
    return InkWell(
      onTap: onTap,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // Leading icon / image
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.place_outlined,
                        color: AppColors.textHint,
                      ),
                    )
                  : const Icon(Icons.place_outlined, color: AppColors.textHint),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textCaption,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
