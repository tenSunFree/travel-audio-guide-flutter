import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/attraction.dart';
import '../enums/attraction_sort_filter_enums.dart';

/// Top filter summary column of the recreation attractions page
/// Displays the currently active criteria
/// allowing users to clearly understand the conditions under which the list is filtered.
class AttractionConditionSummaryBar extends StatelessWidget {
  const AttractionConditionSummaryBar({
    super.key,
    required this.sortOrder,
    required this.categoryIds,
    required this.distric,
    required this.targets,
    required this.facilities,
    required this.openNowOnly,
    required this.timeSlotFilter,
    required this.availableCategories,
    required this.isNonDefault,
    required this.onReset,
  });

  final AttractionSortOrder sortOrder;
  final Set<int> categoryIds;
  final String distric;
  final Set<AttractionTargetFilter> targets;
  final Set<AttractionFacilityFilter> facilities;
  final bool openNowOnly;
  final AttractionTimeSlotFilter timeSlotFilter;
  final List<AttractionCategory> availableCategories;
  final bool isNonDefault;
  final VoidCallback onReset;

  String _buildLabel() {
    final parts = <String>[];
    // Prioritize displaying quick filters from the homepage
    if (openNowOnly) parts.add('現在可去');
    if (timeSlotFilter != AttractionTimeSlotFilter.all) {
      parts.add(timeSlotFilter.label);
    }
    // Sort
    if (sortOrder != AttractionSortOrder.apiOrder) {
      parts.add(sortOrder.label);
    } else {
      parts.add('預設');
    }
    // Category name (lookup from id)
    final catNames = availableCategories
        .where((c) => categoryIds.contains(c.id))
        .map((c) => c.name);
    parts.addAll(catNames);
    if (distric.isNotEmpty) parts.add(distric);
    parts.addAll(targets.map((t) => t.label));
    parts.addAll(facilities.map((f) => f.label));
    return parts.join('・');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      color: isNonDefault
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : colorScheme.surfaceContainerLowest,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Row(
        children: [
          Icon(
            Icons.tune,
            size: 14,
            color: isNonDefault ? colorScheme.primary : AppColors.textHint,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              _buildLabel(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                color: isNonDefault ? colorScheme.primary : AppColors.textHint,
              ),
            ),
          ),
          if (isNonDefault)
            GestureDetector(
              onTap: onReset,
              child: Text(
                '重設',
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
