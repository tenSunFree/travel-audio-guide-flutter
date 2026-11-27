import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_travel_audio_guide/core/constants/app_colors.dart';
import 'package:flutter_travel_audio_guide/core/image/app_network_image_provider.dart';

class NearbyAttractionTile extends StatelessWidget {
  const NearbyAttractionTile({
    required this.name,
    required this.distric,
    required this.distanceLabel,
    required this.imageUrl,
    required this.onTap,
    super.key,
    this.isWeb = kIsWeb,
  });

  final String name;
  final String distric;
  final String? distanceLabel;
  final String? imageUrl;
  final VoidCallback onTap;
  final bool isWeb;

  @override
  Widget build(BuildContext context) {
    final meta = <String>[
      ?distanceLabel,
      if (distric.trim().isNotEmpty) distric.trim(),
    ].join('  ·  ');
    return InkWell(
      onTap: onTap,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            // Leading icon / image
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.surfaceMuted,
                borderRadius: BorderRadius.circular(8),
              ),
              clipBehavior: Clip.antiAlias,
              child: imageUrl != null
                  ? Image(
                      image: appNetworkImageProvider(imageUrl!, isWeb: isWeb),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const Icon(
                        Icons.place_outlined,
                        color: AppColors.textHint,
                      ),
                    )
                  : const Icon(Icons.place_outlined, color: AppColors.textHint),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (meta.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      meta,
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
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}
