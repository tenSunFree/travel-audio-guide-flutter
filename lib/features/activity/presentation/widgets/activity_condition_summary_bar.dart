import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../enums/activity_sort_filter_enums.dart';

class ActivityConditionSummaryBar extends StatelessWidget {
  const ActivityConditionSummaryBar({
    super.key,
    required this.sortOrder,
    required this.statusFilter,
    required this.feeFilter,
    required this.distric,
    required this.isNonDefault,
    required this.onReset,
  });

  final ActivitySortOrder sortOrder;
  final ActivityStatusFilter statusFilter;
  final ActivityFeeFilter feeFilter;
  final String distric;
  final bool isNonDefault;
  final VoidCallback onReset;

  String _buildLabel() {
    final parts = <String>[];
    // Activity status (shown first if not all activities are active)
    if (statusFilter != ActivityStatusFilter.all) {
      parts.add(statusFilter.label);
    }
    // Sort
    if (sortOrder != ActivitySortOrder.beginAsc) {
      parts.add(sortOrder.label);
    } else {
      parts.add('預設');
    }
    if (feeFilter != ActivityFeeFilter.all) parts.add(feeFilter.label);
    if (distric.isNotEmpty) parts.add(distric);
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
