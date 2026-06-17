import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/nearby/location_controller.dart';
import '../../../../core/nearby/nearby_models.dart';
import '../../../../core/nearby/nearby_utils.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/list_skeleton.dart';
import '../../../../core/widgets/common_app_bar.dart';
import '../../domain/entities/audio_guide.dart';
import '../enums/sort_filter_enums.dart';
import '../controllers/audio_guide_list_controller.dart';
import '../widgets/audio_guide_tile.dart';
import '../widgets/condition_summary_bar.dart';
import '../widgets/sort_filter_bottom_sheet.dart';

class AudioGuideListPage extends ConsumerStatefulWidget {
  const AudioGuideListPage({super.key});

  @override
  ConsumerState<AudioGuideListPage> createState() => _AudioGuideListPageState();
}

class _AudioGuideListPageState extends ConsumerState<AudioGuideListPage> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    const threshold = 240.0;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - threshold) {
      unawaited(ref.read(audioGuideListControllerProvider.notifier).loadMore());
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // Sort / filter — Add distance filtering + positioning process
  Future<void> _openSortFilter(BuildContext context) async {
    final state = ref.read(audioGuideListControllerProvider);
    final result =
        await showModalBottomSheet<(SortOrder, FilterType, DistanceFilter)>(
          context: context,
          isScrollControlled: true,
          useSafeArea: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          builder: (_) => SortFilterBottomSheet(
            initialSortOrder: state.sortOrder,
            initialFilterType: state.filterType,
            initialDistanceFilter: state.distanceFilter,
          ),
        );
    // The context is passed in as a parameter, so use context.mounted
    if (result == null || !context.mounted) return;
    final (sort, filter, distanceFilter) = result;
    final needLocation =
        sort == SortOrder.distanceAsc ||
        distanceFilter != DistanceFilter.unlimited;
    if (needLocation) {
      final point = await ref
          .read(locationControllerProvider.notifier)
          .getCurrentLocation();
      if (!context.mounted) return;
      if (point == null) {
        ref
            .read(audioGuideListControllerProvider.notifier)
            .applySortFilter(
              SortOrder.dateNewest,
              FilterType.all,
              distanceFilter: DistanceFilter.unlimited,
            );
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('無法取得位置，已回復預設排序。')));
        return;
      }
      ref
          .read(audioGuideListControllerProvider.notifier)
          .applyLocation(point.latitude, point.longitude);
    }
    ref
        .read(audioGuideListControllerProvider.notifier)
        .applySortFilter(sort, filter, distanceFilter: distanceFilter);
  }

  Future<void> _handleAction(AudioGuide guide) async {
    if (guide.isDownloaded && guide.localFilePath != null) {
      // Using State.context directly before await is fine.
      context.push(AppRoutes.audioGuideDetailPath(guide.id), extra: guide);
      return;
    }
    final error = await ref
        .read(audioGuideListControllerProvider.notifier)
        .downloadGuide(guide);
    // _handleAction uses State.context, so using mounted is sufficient.
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
      return;
    }
    final latestState = ref.read(audioGuideListControllerProvider);
    final latestGuide = latestState.items.firstWhere(
      (item) => item.id == guide.id,
      orElse: () => guide,
    );
    if (latestGuide.localFilePath != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('下載完成')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(audioGuideListControllerProvider);
    final controller = ref.read(audioGuideListControllerProvider.notifier);
    final isNonDefault = !state.isDefaultFilter;
    final primaryColor = Theme.of(context).colorScheme.primary;
    return Scaffold(
      appBar: CommonAppBar(
        title: '語音導覽',
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
                  Center(child: Text('暫無語音導覽資料')),
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
                ConditionSummaryBar(
                  sortOrder: state.sortOrder,
                  filterType: state.filterType,
                  isNonDefault: isNonDefault,
                  onReset: controller.resetSortFilter,
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: controller.loadInitial,
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        SizedBox(height: 160),
                        Center(child: Text('目前沒有符合條件的語音導覽')),
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
                ConditionSummaryBar(
                  sortOrder: state.sortOrder,
                  filterType: state.filterType,
                  isNonDefault: isNonDefault,
                  onReset: controller.resetSortFilter,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: ListView.separated(
                      key: ValueKey(
                        '${state.sortOrder.name}_${state.filterType.name}',
                      ),
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount:
                          state.items.length + (state.isLoadingMore ? 1 : 0),
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        final guide = state.items[index];
                        // Calculate distance label (only if there is a location)
                        final distanceMeters =
                            state.userLat != null && state.userLng != null
                            ? AudioGuideListState.distanceForGuide(
                                guide: guide,
                                attractions: state.attractions,
                                userLat: state.userLat!,
                                userLng: state.userLng!,
                              )
                            : null;
                        final distanceLabel = distanceMeters == null
                            ? null
                            : '距你 ${NearbyUtils.formatDistance(distanceMeters)}';
                        return AudioGuideTile(
                          guide: guide,
                          distanceLabel: distanceLabel,
                          isDownloading: state.downloadingIds.contains(
                            guide.id,
                          ),
                          onActionPressed: () => _handleAction(guide),
                        );
                      },
                    ),
                  ),
                ),
                if (state.errorMessage != null && state.items.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: AppColors.errorSurface,
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      state.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
