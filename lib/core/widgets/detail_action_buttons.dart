import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../features/home/presentation/utils/home_navigation_launcher.dart';
import '../constants/app_colors.dart';

/// Detail page action buttons.
class DetailActionButtons extends StatefulWidget {
  const DetailActionButtons({
    super.key,
    required this.navigateName,
    this.navigateLat,
    this.navigateLng,
    required this.shareText,
    this.shareLabel = '分享',
    this.onReminderPressed,
    this.reminderLabel = '設定提醒',
    this.onCalendarPressed,
    this.calendarLabel = '行事曆',
    this.onSharePressed,
    this.onNavigatePressed,
  });

  final String navigateName;
  final double? navigateLat;
  final double? navigateLng;
  final String shareText;
  final String shareLabel;
  final VoidCallback? onReminderPressed;
  final String reminderLabel;
  final VoidCallback? onCalendarPressed;
  final String calendarLabel;

  /// Callback after sharing (for Analytics tracking)
  final VoidCallback? onSharePressed;

  /// Callback triggered by navigation (used for Analytics tracking)
  final VoidCallback? onNavigatePressed;

  @override
  State<DetailActionButtons> createState() => _DetailActionButtonsState();
}

class _DetailActionButtonsState extends State<DetailActionButtons> {
  bool _navigating = false;

  Future<void> _onNavigate() async {
    if (_navigating) return;
    setState(() => _navigating = true);
    try {
      await HomeNavigationLauncher.openBest(
        context,
        name: widget.navigateName,
        lat: widget.navigateLat,
        lng: widget.navigateLng,
      );
      // Notify external systems (for tracking) after successful navigation startup.
      widget.onNavigatePressed?.call();
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  Future<void> _onShare() async {
    await SharePlus.instance.share(ShareParams(text: widget.shareText));
    // Share sheet and notify external parties after closing (for tracking purposes)
    widget.onSharePressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final secondaryActions = <Widget>[
      if (widget.onReminderPressed != null)
        _DetailIconAction(
          icon: Icons.notifications_outlined,
          label: widget.reminderLabel,
          onPressed: widget.onReminderPressed,
        ),
      if (widget.onCalendarPressed != null)
        _DetailIconAction(
          icon: Icons.calendar_month_outlined,
          label: widget.calendarLabel,
          onPressed: widget.onCalendarPressed,
        ),
      _DetailIconAction(
        icon: Icons.share_outlined,
        label: widget.shareLabel,
        onPressed: _onShare,
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            for (var i = 0; i < secondaryActions.length; i++) ...[
              Expanded(child: secondaryActions[i]),
              if (i != secondaryActions.length - 1) const SizedBox(width: 10),
            ],
          ],
        ),
        const SizedBox(height: 12),
        FilledButton.icon(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          onPressed: _navigating ? null : _onNavigate,
          icon: _navigating
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.navigation_outlined, size: 20),
          label: const Text(
            '開始導航',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _DetailIconAction extends StatelessWidget {
  const _DetailIconAction({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.divider),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onPressed,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 19),
          const SizedBox(height: 4),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
