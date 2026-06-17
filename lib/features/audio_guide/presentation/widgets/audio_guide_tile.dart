import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/entities/audio_guide.dart';

class AudioGuideTile extends StatelessWidget {
  const AudioGuideTile({
    super.key,
    required this.guide,
    required this.isDownloading,
    required this.onActionPressed,
    this.distanceLabel,
  });

  final AudioGuide guide;
  final bool isDownloading;
  final VoidCallback onActionPressed;
  final String? distanceLabel;

  @override
  Widget build(BuildContext context) {
    final showPlay = guide.isDownloaded;
    final VoidCallback? action = isDownloading ? null : onActionPressed;
    return Material(
      color: AppColors.surface,
      child: InkWell(
        onTap: action,
        child: Container(
          height: 84,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      guide.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (distanceLabel != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        distanceLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textCaption,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Right side: Button + Update Date
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 92,
                    height: 34,
                    child: OutlinedButton.icon(
                      onPressed: action,
                      icon: isDownloading
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Icon(
                              showPlay
                                  ? Icons.play_arrow_rounded
                                  : Icons.download_rounded,
                              size: 16,
                            ),
                      label: Text(
                        isDownloading ? '下載中' : (showPlay ? '播放' : '下載'),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        backgroundColor: AppColors.surface,
                        foregroundColor: AppColors.textSecondary,
                        textStyle: const TextStyle(fontSize: 13),
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '更新於 ${guide.modified}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
