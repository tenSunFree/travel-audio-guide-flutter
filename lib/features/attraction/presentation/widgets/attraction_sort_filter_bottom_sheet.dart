import 'package:flutter/material.dart';
import '../../domain/entities/attraction.dart';
import '../enums/attraction_sort_filter_enums.dart';

typedef AttractionFilterResult = ({
  AttractionSortOrder sortOrder,
  Set<int> categoryIds,
  String distric,
  Set<AttractionTargetFilter> targets,
  Set<AttractionFacilityFilter> facilities,
  bool openNowOnly,
  AttractionTimeSlotFilter timeSlotFilter,
});

class AttractionSortFilterBottomSheet extends StatefulWidget {
  const AttractionSortFilterBottomSheet({
    super.key,
    required this.initialSortOrder,
    required this.initialCategoryIds,
    required this.initialDistric,
    required this.initialTargets,
    required this.initialFacilities,
    required this.initialOpenNowOnly,
    required this.initialTimeSlotFilter,
    required this.availableCategories,
    required this.availableDistrics,
  });

  final AttractionSortOrder initialSortOrder;
  final Set<int> initialCategoryIds;
  final String initialDistric;
  final Set<AttractionTargetFilter> initialTargets;
  final Set<AttractionFacilityFilter> initialFacilities;
  final bool initialOpenNowOnly;
  final AttractionTimeSlotFilter initialTimeSlotFilter;
  final List<AttractionCategory> availableCategories;
  final List<String> availableDistrics;

  @override
  State<AttractionSortFilterBottomSheet> createState() =>
      _AttractionSortFilterBottomSheetState();
}

class _AttractionSortFilterBottomSheetState
    extends State<AttractionSortFilterBottomSheet> {
  late AttractionSortOrder _sortOrder;
  late Set<int> _categoryIds;
  late String _distric;
  late Set<AttractionTargetFilter> _targets;
  late Set<AttractionFacilityFilter> _facilities;
  late bool _openNowOnly;
  late AttractionTimeSlotFilter _timeSlotFilter;

  @override
  void initState() {
    super.initState();
    _sortOrder = widget.initialSortOrder;
    _categoryIds = {...widget.initialCategoryIds};
    _distric = widget.initialDistric;
    _targets = {...widget.initialTargets};
    _facilities = {...widget.initialFacilities};
    _openNowOnly = widget.initialOpenNowOnly;
    _timeSlotFilter = widget.initialTimeSlotFilter;
  }

  void _reset() {
    setState(() {
      _sortOrder = AttractionSortOrder.apiOrder;
      _categoryIds.clear();
      _distric = '';
      _targets.clear();
      _facilities.clear();
      _openNowOnly = false;
      _timeSlotFilter = AttractionTimeSlotFilter.all;
    });
  }

  void _apply() {
    Navigator.of(context).pop<AttractionFilterResult>((
      sortOrder: _sortOrder,
      categoryIds: Set.unmodifiable(_categoryIds),
      distric: _distric,
      targets: Set.unmodifiable(_targets),
      facilities: Set.unmodifiable(_facilities),
      openNowOnly: _openNowOnly,
      timeSlotFilter: _timeSlotFilter,
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
                  _SectionLabel(label: '開放狀態'),
                  SwitchListTile(
                    title: const Text('只看現在可去'),
                    subtitle: const Text('只顯示此刻正在開放的景點'),
                    value: _openNowOnly,
                    dense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    onChanged: (v) => setState(() => _openNowOnly = v),
                  ),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  _SectionLabel(label: '推薦時段'),
                  RadioGroup<AttractionTimeSlotFilter>(
                    groupValue: _timeSlotFilter,
                    onChanged: (v) => setState(() => _timeSlotFilter = v!),
                    child: Column(
                      children: AttractionTimeSlotFilter.values
                          .map(
                            (slot) => RadioListTile<AttractionTimeSlotFilter>(
                              title: Text(slot.label),
                              value: slot,
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
                  _SectionLabel(label: '排序'),
                  RadioGroup<AttractionSortOrder>(
                    groupValue: _sortOrder,
                    onChanged: (v) => setState(() => _sortOrder = v!),
                    child: Column(
                      children: AttractionSortOrder.values
                          .map(
                            (sort) => RadioListTile<AttractionSortOrder>(
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
                  if (widget.availableCategories.isNotEmpty) ...[
                    _SectionLabel(label: '分類'),
                    _ChipWrap(
                      children: widget.availableCategories
                          .map(
                            (cat) => FilterChip(
                              label: Text(cat.name),
                              selected: _categoryIds.contains(cat.id),
                              onSelected: (_) => setState(() {
                                if (_categoryIds.contains(cat.id)) {
                                  _categoryIds.remove(cat.id);
                                } else {
                                  _categoryIds.add(cat.id);
                                }
                              }),
                            ),
                          )
                          .toList(),
                    ),
                    const Divider(height: 24, indent: 16, endIndent: 16),
                  ],
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
                    const Divider(height: 24, indent: 16, endIndent: 16),
                  ],
                  _SectionLabel(label: '適合族群'),
                  _ChipWrap(
                    children: AttractionTargetFilter.values
                        .map(
                          (f) => FilterChip(
                            label: Text(f.label),
                            selected: _targets.contains(f),
                            onSelected: (_) => setState(() {
                              if (_targets.contains(f)) {
                                _targets.remove(f);
                              } else {
                                _targets.add(f);
                              }
                            }),
                          ),
                        )
                        .toList(),
                  ),
                  const Divider(height: 24, indent: 16, endIndent: 16),
                  _SectionLabel(label: '友善設施'),
                  _ChipWrap(
                    children: AttractionFacilityFilter.values
                        .map(
                          (f) => FilterChip(
                            label: Text(f.label),
                            selected: _facilities.contains(f),
                            onSelected: (_) => setState(() {
                              if (_facilities.contains(f)) {
                                _facilities.remove(f);
                              } else {
                                _facilities.add(f);
                              }
                            }),
                          ),
                        )
                        .toList(),
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

// Shared small components
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
