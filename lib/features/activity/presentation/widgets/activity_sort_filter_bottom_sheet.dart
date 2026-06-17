import 'package:flutter/material.dart';
import '../../../../core/nearby/nearby_models.dart';
import '../enums/activity_sort_filter_enums.dart';

typedef ActivityFilterResult = ({
  ActivitySortOrder sortOrder,
  ActivityStatusFilter statusFilter,
  ActivityFeeFilter feeFilter,
  String distric,
  DistanceFilter distanceFilter,
});

class ActivitySortFilterBottomSheet extends StatefulWidget {
  const ActivitySortFilterBottomSheet({
    super.key,
    required this.initialSortOrder,
    required this.initialStatusFilter,
    required this.initialFeeFilter,
    required this.initialDistric,
    required this.initialDistanceFilter,
    required this.availableDistrics,
  });

  final ActivitySortOrder initialSortOrder;
  final ActivityStatusFilter initialStatusFilter;
  final ActivityFeeFilter initialFeeFilter;
  final String initialDistric;
  final DistanceFilter initialDistanceFilter;
  final List<String> availableDistrics;

  @override
  State<ActivitySortFilterBottomSheet> createState() =>
      _ActivitySortFilterBottomSheetState();
}

class _ActivitySortFilterBottomSheetState
    extends State<ActivitySortFilterBottomSheet> {
  late ActivitySortOrder _sortOrder;
  late ActivityStatusFilter _statusFilter;
  late ActivityFeeFilter _feeFilter;
  late String _distric;
  late DistanceFilter _distanceFilter;

  @override
  void initState() {
    super.initState();
    _sortOrder = widget.initialSortOrder;
    _statusFilter = widget.initialStatusFilter;
    _feeFilter = widget.initialFeeFilter;
    _distric = widget.initialDistric;
    _distanceFilter = widget.initialDistanceFilter;
  }

  void _reset() {
    setState(() {
      _sortOrder = ActivitySortOrder.beginAsc;
      _statusFilter = ActivityStatusFilter.all;
      _feeFilter = ActivityFeeFilter.all;
      _distric = '';
      _distanceFilter = DistanceFilter.unlimited;
    });
  }

  void _apply() {
    Navigator.of(context).pop<ActivityFilterResult>((
      sortOrder: _sortOrder,
      statusFilter: _statusFilter,
      feeFilter: _feeFilter,
      distric: _distric,
      distanceFilter: _distanceFilter,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
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
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Activity status
                  _SectionLabel(label: '活動狀態'),
                  _ChipWrap(
                    children: ActivityStatusFilter.values.map((f) {
                      return ChoiceChip(
                        label: Text(f.label),
                        selected: _statusFilter == f,
                        onSelected: (_) => setState(() => _statusFilter = f),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  // Distance
                  _SectionLabel(label: '距離範圍'),
                  _ChipWrap(
                    children: DistanceFilter.values.map((f) {
                      return ChoiceChip(
                        label: Text(f.label),
                        selected: _distanceFilter == f,
                        onSelected: (_) => setState(() => _distanceFilter = f),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  // Sort
                  _SectionLabel(label: '排序'),
                  RadioGroup<ActivitySortOrder>(
                    groupValue: _sortOrder,
                    onChanged: (v) => setState(() => _sortOrder = v!),
                    child: Column(
                      children: ActivitySortOrder.values
                          .map(
                            (sort) => RadioListTile<ActivitySortOrder>(
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
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  // Fee
                  _SectionLabel(label: '費用'),
                  _ChipWrap(
                    children: ActivityFeeFilter.values.map((f) {
                      return ChoiceChip(
                        label: Text(f.label),
                        selected: _feeFilter == f,
                        onSelected: (_) => setState(() => _feeFilter = f),
                      );
                    }).toList(),
                  ),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  // District
                  if (widget.availableDistrics.isNotEmpty) ...[
                    _SectionLabel(label: '行政區'),
                    _ChipWrap(
                      children: [
                        ChoiceChip(
                          label: const Text('全部'),
                          selected: _distric.isEmpty,
                          onSelected: (_) => setState(() => _distric = ''),
                        ),
                        ...widget.availableDistrics.map(
                          (d) => ChoiceChip(
                            label: Text(d),
                            selected: _distric == d,
                            onSelected: (_) => setState(() => _distric = d),
                          ),
                        ),
                      ],
                    ),
                  ] else
                    const SizedBox(height: 16),
                ],
              ),
            ),
          ),
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

class _ChipWrap extends StatelessWidget {
  const _ChipWrap({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Wrap(spacing: 8, runSpacing: 8, children: children),
    );
  }
}
