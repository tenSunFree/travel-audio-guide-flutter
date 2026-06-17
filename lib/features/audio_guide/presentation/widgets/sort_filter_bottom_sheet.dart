import 'package:flutter/material.dart';
import '../../../../core/nearby/nearby_models.dart';
import '../enums/sort_filter_enums.dart';

class SortFilterBottomSheet extends StatefulWidget {
  const SortFilterBottomSheet({
    super.key,
    required this.initialSortOrder,
    required this.initialFilterType,
    required this.initialDistanceFilter,
  });

  final SortOrder initialSortOrder;
  final FilterType initialFilterType;
  final DistanceFilter initialDistanceFilter;

  @override
  State<SortFilterBottomSheet> createState() => _SortFilterBottomSheetState();
}

class _SortFilterBottomSheetState extends State<SortFilterBottomSheet> {
  late SortOrder _sortOrder;
  late FilterType _filterType;
  late DistanceFilter _distanceFilter;

  @override
  void initState() {
    super.initState();
    _sortOrder = widget.initialSortOrder;
    _filterType = widget.initialFilterType;
    _distanceFilter = widget.initialDistanceFilter;
  }

  void _reset() {
    setState(() {
      _sortOrder = SortOrder.dateNewest;
      _filterType = FilterType.all;
      _distanceFilter = DistanceFilter.unlimited;
    });
  }

  void _apply() {
    Navigator.of(context).pop((_sortOrder, _filterType, _distanceFilter));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '排序與篩選',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const Divider(height: 1),
          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Download filter
                  _SectionLabel(label: '下載狀態'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: FilterType.values.map((f) {
                        return ChoiceChip(
                          label: Text(f.label),
                          selected: _filterType == f,
                          onSelected: (_) => setState(() => _filterType = f),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  // Distance
                  _SectionLabel(label: '距離範圍'),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: DistanceFilter.values.map((f) {
                        return ChoiceChip(
                          label: Text(f.label),
                          selected: _distanceFilter == f,
                          onSelected: (_) =>
                              setState(() => _distanceFilter = f),
                        );
                      }).toList(),
                    ),
                  ),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  // Sort
                  _SectionLabel(label: '排序'),
                  RadioGroup<SortOrder>(
                    groupValue: _sortOrder,
                    onChanged: (v) => setState(() => _sortOrder = v!),
                    child: Column(
                      children: SortOrder.values
                          .map(
                            (sort) => RadioListTile<SortOrder>(
                              title: Text(sort.label),
                              value: sort,
                              dense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          // Bottom buttons
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _reset,
                    child: const Text('重設'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _apply,
                    child: const Text('套用'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        label,
        style: textTheme.labelLarge?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
