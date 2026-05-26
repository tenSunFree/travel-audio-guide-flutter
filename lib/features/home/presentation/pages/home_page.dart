import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/common_app_bar.dart';
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

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  // Unified jump logic
  void _openRecommendDetail(BuildContext context, HomeRecommendCard card) {
    switch (card.type) {
      case HomeRecommendType.attraction:
        final attraction = card.attraction;
        if (attraction == null) {
          _showErrorSnackBar(context, '找不到景點詳細資料');
          return;
        }
        context.push(
          AppRoutes.attractionDetailPath(attraction.id),
          extra: attraction,
        );
      case HomeRecommendType.activity:
        final activity = card.activity;
        if (activity == null) {
          _showErrorSnackBar(context, '找不到活動詳細資料');
          return;
        }
        context.push(
          AppRoutes.activityDetailPath(activity.id),
          extra: activity,
        );
      case HomeRecommendType.audioGuide:
        // There are currently no recommended audio guide cards on the homepage; these are reserved for future use.
        break;
    }
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeControllerProvider);
    final controller = ref.read(homeControllerProvider.notifier);
    return Scaffold(
      backgroundColor: AppColors.pageBackground,
      appBar: CommonAppBar(
        title: '首頁',
        actions: [
          IconButton(
            onPressed: () {
              // Homepage Filter Settings
            },
            icon: const Icon(Icons.tune),
            tooltip: '首頁設定',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => controller.changePeriod(state.selectedPeriod),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: HomeSubtitle(subtitle: '${state.title}・${state.subtitle}'),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: RainyModeCard(
                  value: state.isRainyMode,
                  onChanged: controller.toggleRainyMode,
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: PeriodChips(
                  selected: state.selectedPeriod,
                  onSelected: controller.changePeriod,
                ),
              ),
            ),
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
              SliverToBoxAdapter(
                child: HomeSectionTitle(
                  title: _heroSectionTitle(state.selectedPeriod),
                  action: '查看全部',
                  onActionTap: () {
                    // Jump to the full list of attractions
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
              const SliverToBoxAdapter(
                child: HomeSectionTitle(title: '現在可去', action: '排序'),
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
              const SliverToBoxAdapter(
                child: HomeSectionTitle(title: '活動推薦', action: '全部'),
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
              const SliverToBoxAdapter(child: SizedBox(height: 120)),
            ],
          ],
        ),
      ),
    );
  }

  static String _heroSectionTitle(HomePeriod period) {
    return switch (period) {
      HomePeriod.morning => '早晨推薦',
      HomePeriod.afternoon => '午後推薦',
      HomePeriod.evening => '傍晚推薦',
      HomePeriod.night => '夜間推薦',
    };
  }
}
