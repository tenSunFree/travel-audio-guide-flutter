import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_cached_network_image.dart';
import '../../domain/entities/attraction.dart';

class AttractionTile extends StatelessWidget {
  const AttractionTile({
    super.key,
    required this.attraction,
    required this.onTap,
  });

  final Attraction attraction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final imageUrl = attraction.firstImageUrl;
    return InkWell(
      onTap: onTap,
      child: Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: imageUrl.isEmpty
                  ? _Placeholder(categories: attraction.categories)
                  : AppCachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorWidget: _Placeholder(
                        categories: attraction.categories,
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            // Text Area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Attraction Name
                  Text(
                    attraction.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Classification
                  if (attraction.categoryText.isNotEmpty)
                    Text(
                      attraction.categoryText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  const SizedBox(height: 4),
                  // Administrative District + Address
                  if (attraction.distric.isNotEmpty ||
                      attraction.address.isNotEmpty)
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          size: 13,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            attraction.distric.isNotEmpty
                                ? attraction.distric
                                : attraction.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textCaption,
                            ),
                          ),
                        ),
                      ],
                    ),
                  // Opening Hours
                  if (attraction.openTime.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.access_time,
                          size: 13,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            attraction.openTime,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textCaption,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // Arrow
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

/// Category when no image is displayed: Emoji placeholder
class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.categories});

  final List<AttractionCategory> categories;

  static const _emojiMap = {
    12: '🚲',
    13: '🏛️',
    14: '🛕',
    15: '🎨',
    16: '🌿',
    17: '🚤',
    18: '🗿',
    19: '👨‍👩‍👧',
    23: '🏮',
    24: '🛍️',
    25: '♿',
  };

  String get _emoji {
    if (categories.isEmpty) return '📍';
    return _emojiMap[categories.first.id] ?? '📍';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 96,
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: Text(_emoji, style: const TextStyle(fontSize: 32)),
    );
  }
}
