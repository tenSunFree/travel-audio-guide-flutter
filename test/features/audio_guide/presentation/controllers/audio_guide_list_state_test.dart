import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/controllers/audio_guide_list_controller.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/presentation/enums/sort_filter_enums.dart';
import 'package:flutter_travel_audio_guide/core/nearby/nearby_models.dart';

// Helper
AudioGuide _guide({
  required int id,
  required String title,
  required String modified,
  bool isDownloaded = false,
}) {
  return AudioGuide(
    id: id,
    title: title,
    summary: null,
    url: 'https://example.com/$id.mp3',
    fileExt: 'mp3',
    modified: modified,
    isDownloaded: isDownloaded,
    localFilePath: isDownloaded ? '/audio/$id.mp3' : null,
  );
}

// Tests
void main() {
  group('AudioGuideListState', () {
    // initial()
    group('initial()', () {
      test('has correct default values', () {
        final state = AudioGuideListState.initial();
        expect(state.allItems, isEmpty);
        expect(state.items, isEmpty);
        expect(state.currentPage, 0);
        expect(state.total, 0);
        expect(state.hasMore, isTrue);
        expect(state.isInitialLoading, isFalse);
        expect(state.isLoadingMore, isFalse);
        expect(state.downloadingIds, isEmpty);
        expect(state.errorMessage, isNull);
        expect(state.sortOrder, SortOrder.dateNewest);
        expect(state.filterType, FilterType.all);
        expect(state.isSyncing, isTrue);
        expect(state.isDefaultFilter, isTrue);
        expect(state.distanceFilter, DistanceFilter.unlimited);
        expect(state.attractions, isEmpty);
      });
    });
    // computeDisplayItems sort
    group('computeDisplayItems — sorting', () {
      test('sorts by newest modified date by default', () {
        final result = AudioGuideListState.computeDisplayItems(
          [
            _guide(id: 1, title: 'B', modified: '2026-01-01'),
            _guide(id: 2, title: 'A', modified: '2026-05-01'),
          ],
          SortOrder.dateNewest,
          FilterType.all,
          distanceFilter: DistanceFilter.unlimited,
          attractions: const [],
        );
        expect(result.map((e) => e.id), <int>[2, 1]);
      });
      test('sorts oldest first', () {
        final result = AudioGuideListState.computeDisplayItems(
          [
            _guide(id: 1, title: 'B', modified: '2026-01-01'),
            _guide(id: 2, title: 'A', modified: '2026-05-01'),
          ],
          SortOrder.dateOldest,
          FilterType.all,
          distanceFilter: DistanceFilter.unlimited,
          attractions: const [],
        );
        expect(result.map((e) => e.id), <int>[1, 2]);
      });
      test('sorts alphabetically by name A-Z', () {
        final result = AudioGuideListState.computeDisplayItems(
          [
            _guide(id: 1, title: 'B', modified: '2026-01-01'),
            _guide(id: 2, title: 'A', modified: '2026-05-01'),
          ],
          SortOrder.nameAZ,
          FilterType.all,
          distanceFilter: DistanceFilter.unlimited,
          attractions: const [],
        );
        expect(result.map((e) => e.id), <int>[2, 1]);
      });
      test('sorts downloaded items first', () {
        final result = AudioGuideListState.computeDisplayItems(
          [
            _guide(id: 1, title: 'B', modified: '2026-01-01'),
            _guide(
              id: 2,
              title: 'A',
              modified: '2026-05-01',
              isDownloaded: true,
            ),
          ],
          SortOrder.downloadedFirst,
          FilterType.all,
          distanceFilter: DistanceFilter.unlimited,
          attractions: const [],
        );
        expect(result.first.id, 2);
        expect(result.first.isDownloaded, isTrue);
      });
      test('does not mutate the original list', () {
        final original = [
          _guide(id: 3, title: 'C', modified: '2026-03-01'),
          _guide(id: 1, title: 'A', modified: '2026-01-01'),
          _guide(id: 2, title: 'B', modified: '2026-02-01'),
        ];
        final before = original.map((g) => g.id).toList();
        AudioGuideListState.computeDisplayItems(
          original,
          SortOrder.dateNewest,
          FilterType.all,
          distanceFilter: DistanceFilter.unlimited,
          attractions: const [],
        );
        expect(original.map((g) => g.id).toList(), before);
      });
    });
    // computeDisplayItems filter
    group('computeDisplayItems — filtering', () {
      final guides = [
        _guide(id: 1, title: 'A', modified: '2026-01-01'),
        _guide(id: 2, title: 'B', modified: '2026-01-02', isDownloaded: true),
      ];
      test('FilterType.all returns all items', () {
        final result = AudioGuideListState.computeDisplayItems(
          guides,
          SortOrder.dateNewest,
          FilterType.all,
          distanceFilter: DistanceFilter.unlimited,
          attractions: const [],
        );
        expect(result.length, 2);
      });
      test('FilterType.downloaded returns only downloaded items', () {
        final result = AudioGuideListState.computeDisplayItems(
          guides,
          SortOrder.dateNewest,
          FilterType.downloaded,
          distanceFilter: DistanceFilter.unlimited,
          attractions: const [],
        );
        expect(result.map((e) => e.id), <int>[2]);
      });
      test('FilterType.notDownloaded returns only undownloaded items', () {
        final result = AudioGuideListState.computeDisplayItems(
          guides,
          SortOrder.dateNewest,
          FilterType.notDownloaded,
          distanceFilter: DistanceFilter.unlimited,
          attractions: const [],
        );
        expect(result.map((e) => e.id), <int>[1]);
      });
      test('empty list returns empty for any filter', () {
        for (final filter in FilterType.values) {
          final result = AudioGuideListState.computeDisplayItems(
            [],
            SortOrder.dateNewest,
            filter,
            distanceFilter: DistanceFilter.unlimited,
            attractions: const [],
          );
          expect(result, isEmpty, reason: 'filter=$filter should return empty');
        }
      });
    });
    // computeDisplayItems filter + sort combined
    group('computeDisplayItems — filter + sort combined', () {
      test('downloaded filter + dateNewest sort works together', () {
        final guides = [
          _guide(id: 1, title: 'A', modified: '2026-03-01', isDownloaded: true),
          _guide(
            id: 2,
            title: 'B',
            modified: '2026-01-01',
            isDownloaded: false,
          ),
          _guide(id: 3, title: 'C', modified: '2026-05-01', isDownloaded: true),
        ];
        final result = AudioGuideListState.computeDisplayItems(
          guides,
          SortOrder.dateNewest,
          FilterType.downloaded,
          distanceFilter: DistanceFilter.unlimited,
          attractions: const [],
        );
        expect(result.every((g) => g.isDownloaded), isTrue);
        expect(result.map((g) => g.modified).toList(), [
          '2026-05-01',
          '2026-03-01',
        ]);
      });
    });
    // copyWith
    group('copyWith', () {
      test('updates values and can clear errorMessage', () {
        final state = AudioGuideListState.initial().copyWith(
          errorMessage: 'failed',
          downloadingIds: {1},
        );
        final updated = state.copyWith(
          isInitialLoading: true,
          clearErrorMessage: true,
        );
        expect(updated.isInitialLoading, isTrue);
        expect(updated.downloadingIds, {1});
        expect(updated.errorMessage, isNull);
      });
      test('preserves existing values when not overridden', () {
        final state = AudioGuideListState.initial().copyWith(
          total: 42,
          currentPage: 3,
        );
        final copy = state.copyWith(isInitialLoading: true);
        expect(copy.total, 42);
        expect(copy.currentPage, 3);
        expect(copy.isInitialLoading, isTrue);
      });
      test('updates isSyncing', () {
        final state = AudioGuideListState.initial().copyWith(isSyncing: false);
        expect(state.isSyncing, isFalse);
      });
      test('updates downloadingIds as Set', () {
        final state = AudioGuideListState.initial().copyWith(
          downloadingIds: {3, 7, 99},
        );
        expect(state.downloadingIds, {3, 7, 99});
      });
      test('updates distanceFilter', () {
        final state = AudioGuideListState.initial().copyWith(
          distanceFilter: DistanceFilter.km3,
        );
        expect(state.distanceFilter, DistanceFilter.km3);
      });
    });
    // isDefaultFilter
    group('isDefaultFilter', () {
      test('true when dateNewest + all + unlimited distance', () {
        final state = AudioGuideListState.initial();
        expect(state.isDefaultFilter, isTrue);
      });
      test('false when sort is not dateNewest', () {
        final state = AudioGuideListState.initial().copyWith(
          sortOrder: SortOrder.nameAZ,
        );
        expect(state.isDefaultFilter, isFalse);
      });
      test('false when filter is not all', () {
        final state = AudioGuideListState.initial().copyWith(
          filterType: FilterType.downloaded,
        );
        expect(state.isDefaultFilter, isFalse);
      });
      test('false when distanceFilter is not unlimited', () {
        final state = AudioGuideListState.initial().copyWith(
          distanceFilter: DistanceFilter.km1,
        );
        expect(state.isDefaultFilter, isFalse);
      });
    });
  });
}
