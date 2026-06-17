import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/nearby/location_controller.dart';
import '../../../../core/nearby/nearby_models.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/common_app_bar.dart';
import '../../../../core/widgets/list_skeleton.dart';
import '../../di/attraction_providers.dart';
import '../../domain/entities/attraction.dart';
import '../controllers/attraction_list_controller.dart';
import '../enums/attraction_sort_filter_enums.dart';
import '../widgets/attraction_condition_summary_bar.dart';
import '../widgets/attraction_sort_filter_bottom_sheet.dart';
import '../widgets/attraction_tile.dart';

class AttractionListPage extends ConsumerStatefulWidget {
  const AttractionListPage({
    super.key,
    this.initialTimeSlot,
    this.initialOpenNow = false,
  });

  final String? initialTimeSlot;
  final bool initialOpenNow;

  @override
  ConsumerState<AttractionListPage> createState() => _AttractionListPageState();
}

class _AttractionListPageState extends ConsumerState<AttractionListPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final timeSlot = AttractionTimeSlotFilter.fromQuery(
        widget.initialTimeSlot,
      );
      if (widget.initialOpenNow || timeSlot != AttractionTimeSlotFilter.all) {
        ref
            .read(attractionListControllerProvider.notifier)
            .applyHomeEntryFilter(
              openNowOnly: widget.initialOpenNow,
              timeSlotFilter: timeSlot,
            );
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    const threshold = 240.0;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      unawaited(ref.read(attractionListControllerProvider.notifier).loadMore());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // Sort / filter sheet — requests location when needed
  Future<void> _openSortFilter() async {
    final state = ref.read(attractionListControllerProvider);
    final result = await showModalBottomSheet<AttractionFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AttractionSortFilterBottomSheet(
        initialSortOrder: state.sortOrder,
        initialCategoryIds: state.selectedCategoryIds,
        initialDistric: state.distric,
        initialTargets: state.selectedTargets,
        initialFacilities: state.selectedFacilities,
        initialOpenNowOnly: state.openNowOnly,
        initialTimeSlotFilter: state.timeSlotFilter,
        initialDistanceFilter: state.distanceFilter,
        availableCategories: state.availableCategories,
        availableDistrics: state.availableDistrics,
      ),
    );
    if (result == null || !mounted) return;
    final needLocation =
        result.sortOrder == AttractionSortOrder.distanceAsc ||
        result.distanceFilter != DistanceFilter.unlimited;
    if (needLocation) {
      final point = await ref
          .read(locationControllerProvider.notifier)
          .getCurrentLocation();
      if (!mounted) return;
      if (point == null) {
        // Location failed — apply without distance
        ref
            .read(attractionListControllerProvider.notifier)
            .applySortFilter(
              sortOrder: AttractionSortOrder.apiOrder,
              categoryIds: result.categoryIds,
              distric: result.distric,
              targets: result.targets,
              facilities: result.facilities,
              openNowOnly: result.openNowOnly,
              timeSlotFilter: result.timeSlotFilter,
              distanceFilter: DistanceFilter.unlimited,
            );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('無法取得位置，已回復預設排序。')));
        return;
      }
      ref
          .read(attractionListControllerProvider.notifier)
          .applyLocation(point.latitude, point.longitude);
    }
    ref
        .read(attractionListControllerProvider.notifier)
        .applySortFilter(
          sortOrder: result.sortOrder,
          categoryIds: result.categoryIds,
          distric: result.distric,
          targets: result.targets,
          facilities: result.facilities,
          openNowOnly: result.openNowOnly,
          timeSlotFilter: result.timeSlotFilter,
          distanceFilter: result.distanceFilter,
        );
  }

  void _openDetail(Attraction attraction) {
    context.push(
      AppRoutes.attractionDetailPath(attraction.id),
      extra: attraction,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(attractionListControllerProvider);
    final controller = ref.read(attractionListControllerProvider.notifier);
    final isNonDefault = !state.isDefaultFilter;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: CommonAppBar(
        title: '遊憩景點',
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: Icon(
                  Icons.tune,
                  color: isNonDefault ? primaryColor : null,
                ),
                tooltip: '排序與篩選',
                onPressed: _openSortFilter,
              ),
              if (isNonDefault)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          if (state.allItems.isEmpty && (state.isSyncing ?? true)) {
            return const ListSkeleton(
              itemCount: 7,
              itemHeight: 100,
              hasLeadingBox: true,
            );
          }
          if (state.allItems.isEmpty && !(state.isSyncing ?? true)) {
            return RefreshIndicator(
              onRefresh: controller.refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('暫無景點資料')),
                ],
              ),
            );
          }
          if (state.errorMessage != null && state.allItems.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: controller.loadInitial,
                      child: const Text('重新載入'),
                    ),
                  ],
                ),
              ),
            );
          }
          if (!state.isLoading &&
              state.allItems.isNotEmpty &&
              state.items.isEmpty) {
            return Column(
              children: [
                _buildSummaryBar(state, controller),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.refresh,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 160),
                        Center(child: Text('目前沒有符合條件的景點')),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: controller.refresh,
            child: Column(
              children: [
                _buildSummaryBar(state, controller),
                Expanded(
                  child: ListView.separated(
                    controller: _scrollController,
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount:
                        state.items.length + (state.isLoadingMore ? 1 : 0),
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.divider),
                    itemBuilder: (context, index) {
                      if (index >= state.items.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(child: CircularProgressIndicator()),
                        );
                      }
                      final item = state.items[index];
                      return AttractionTile(
                        attraction: item,
                        userLat: state.userLat,
                        userLng: state.userLng,
                        onTap: () => _openDetail(item),
                      );
                    },
                  ),
                ),
                if (state.errorMessage != null && state.items.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: AppColors.errorSurface,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: AppColors.textError),
                      textAlign: TextAlign.center,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryBar(
    AttractionListState state,
    AttractionListController controller,
  ) {
    return AttractionConditionSummaryBar(
      sortOrder: state.sortOrder,
      categoryIds: state.selectedCategoryIds,
      distric: state.distric,
      targets: state.selectedTargets,
      facilities: state.selectedFacilities,
      openNowOnly: state.openNowOnly,
      timeSlotFilter: state.timeSlotFilter,
      availableCategories: state.availableCategories,
      isNonDefault: !state.isDefaultFilter,
      onReset: controller.resetFilter,
    );
  }
}
