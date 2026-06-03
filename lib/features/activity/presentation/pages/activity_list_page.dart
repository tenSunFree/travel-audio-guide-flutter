import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/list_skeleton.dart';
import '../../../../core/widgets/common_app_bar.dart';
import '../../di/activity_providers.dart';
import '../../domain/entities/activity.dart';
import '../controllers/activity_list_controller.dart';
import '../enums/activity_sort_filter_enums.dart';
import '../widgets/activity_condition_summary_bar.dart';
import '../widgets/activity_sort_filter_bottom_sheet.dart';
import '../widgets/activity_tile.dart';

class ActivityListPage extends ConsumerStatefulWidget {
  const ActivityListPage({super.key, this.initialStatus});

  /// Query value (ongoing/upcoming) from the "Event Recommendations" section on the homepage
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
    // Initial filter brought in on the homepage
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

  Future<void> _openSortFilter(BuildContext context) async {
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
        availableDistrics: state.availableDistrics,
      ),
    );
    if (result != null) {
      final (sort, status, fee, distric) = result;
      ref
          .read(activityListControllerProvider.notifier)
          .applySortFilter(
            sortOrder: sort,
            statusFilter: status,
            feeFilter: fee,
            distric: distric,
          );
    }
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
                onPressed: () => _openSortFilter(context),
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
          if (state.allItems.isEmpty && state.isSyncing) {
            return const ListSkeleton(
              itemCount: 7,
              itemHeight: 100,
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
          if (!state.isInitialLoading &&
              state.allItems.isNotEmpty &&
              state.items.isEmpty) {
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
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: ListView.separated(
                      key: ValueKey(
                        '${state.sortOrder.name}_'
                        '${state.statusFilter.name}_'
                        '${state.feeFilter.name}_'
                        '${state.distric}',
                      ),
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
                          onTap: () => _openDetail(item),
                        );
                      },
                    ),
                  ),
                ),
                if (state.errorMessage != null && state.allItems.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: AppColors.errorSurface,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: AppColors.textError),
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
