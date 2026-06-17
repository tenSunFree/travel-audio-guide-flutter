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
import '../../di/activity_providers.dart';
import '../../domain/entities/activity.dart';
import '../controllers/activity_list_controller.dart';
import '../enums/activity_sort_filter_enums.dart';
import '../widgets/activity_condition_summary_bar.dart';
import '../widgets/activity_sort_filter_bottom_sheet.dart';
import '../widgets/activity_tile.dart';

class ActivityListPage extends ConsumerStatefulWidget {
  const ActivityListPage({super.key, this.initialStatus});

  final String? initialStatus;

  @override
  ConsumerState<ActivityListPage> createState() => _ActivityListPageState();
}

class _ActivityListPageState extends ConsumerState<ActivityListPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final status = ActivityStatusFilter.fromQuery(widget.initialStatus);
      if (status != ActivityStatusFilter.all) {
        ref
            .read(activityListControllerProvider.notifier)
            .applySortFilter(
              sortOrder: ActivitySortOrder.beginAsc,
              statusFilter: status,
              feeFilter: ActivityFeeFilter.all,
              distric: '',
              distanceFilter: DistanceFilter.unlimited,
            );
      }
    });
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    const threshold = 240.0;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      unawaited(ref.read(activityListControllerProvider.notifier).loadMore());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _openSortFilter() async {
    final state = ref.read(activityListControllerProvider);
    final result = await showModalBottomSheet<ActivityFilterResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => ActivitySortFilterBottomSheet(
        initialSortOrder: state.sortOrder,
        initialStatusFilter: state.statusFilter,
        initialFeeFilter: state.feeFilter,
        initialDistric: state.distric,
        initialDistanceFilter: state.distanceFilter,
        availableDistrics: state.availableDistrics,
      ),
    );
    if (result == null || !mounted) return;
    final needLocation =
        result.sortOrder == ActivitySortOrder.distanceAsc ||
        result.distanceFilter != DistanceFilter.unlimited;
    if (needLocation) {
      final point = await ref
          .read(locationControllerProvider.notifier)
          .getCurrentLocation();
      if (!mounted) return;
      if (point == null) {
        ref
            .read(activityListControllerProvider.notifier)
            .applySortFilter(
              sortOrder: ActivitySortOrder.beginAsc,
              statusFilter: result.statusFilter,
              feeFilter: result.feeFilter,
              distric: result.distric,
              distanceFilter: DistanceFilter.unlimited,
            );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('無法取得位置，已回復預設排序。')));
        return;
      }
      ref
          .read(activityListControllerProvider.notifier)
          .applyLocation(point.latitude, point.longitude);
    }
    ref
        .read(activityListControllerProvider.notifier)
        .applySortFilter(
          sortOrder: result.sortOrder,
          statusFilter: result.statusFilter,
          feeFilter: result.feeFilter,
          distric: result.distric,
          distanceFilter: result.distanceFilter,
        );
  }

  void _openDetail(Activity activity) {
    context.push(AppRoutes.activityDetailPath(activity.id), extra: activity);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(activityListControllerProvider);
    final controller = ref.read(activityListControllerProvider.notifier);
    final isNonDefault = !state.isDefaultFilter;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: CommonAppBar(
        title: '活動展演',
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
          if (state.isInitialLoading && state.allItems.isEmpty) {
            return const ListSkeleton(
              itemCount: 6,
              itemHeight: 88,
              hasLeadingBox: true,
            );
          }
          if (state.allItems.isEmpty && !state.isSyncing) {
            return RefreshIndicator(
              onRefresh: controller.loadInitial,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('暫無活動資料')),
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
          if (state.allItems.isNotEmpty && state.items.isEmpty) {
            return Column(
              children: [
                _buildSummaryBar(state, controller),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.loadInitial,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 160),
                        Center(child: Text('目前沒有符合條件的活動')),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return RefreshIndicator(
            onRefresh: controller.loadInitial,
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
                      return ActivityTile(
                        activity: item,
                        userLat: state.userLat,
                        userLng: state.userLng,
                        onTap: () => _openDetail(item),
                      );
                    },
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
    ActivityListState state,
    ActivityListController controller,
  ) {
    return ActivityConditionSummaryBar(
      sortOrder: state.sortOrder,
      statusFilter: state.statusFilter,
      feeFilter: state.feeFilter,
      distric: state.distric,
      isNonDefault: !state.isDefaultFilter,
      onReset: controller.resetSortFilter,
    );
  }
}
