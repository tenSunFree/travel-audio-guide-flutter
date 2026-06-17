import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/nearby/nearby_utils.dart';
import '../../../../core/widgets/app_cached_network_image.dart';
import '../../domain/entities/attraction.dart';

class AttractionTile extends StatelessWidget {
  const AttractionTile({
    super.key,
    required this.attraction,
    required this.onTap,
    this.userLat,
    this.userLng,
  });

  final Attraction attraction;
  final VoidCallback onTap;
  final double? userLat;
  final double? userLng;

  /// Distance label, e.g. "距你 850m". Returns null when location unavailable
  /// or attraction has no valid coordinate.
  String? _distanceLabel() {
    if (userLat == null || userLng == null) return null;
    if (!NearbyUtils.isValidCoordinate(attraction.nlat, attraction.elong)) {
      return null;
    }
    final meters = NearbyUtils.distanceMeters(
      fromLat: userLat!,
      fromLng: userLng!,
      toLat: attraction.nlat!,
      toLng: attraction.elong!,
    );
    return '距你 ${NearbyUtils.formatDistance(meters)}';
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = attraction.firstImageUrl;
    final distanceLabel = _distanceLabel();
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
            // Text area
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
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
                  // Category
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
                  // Distance + district row
                  _MetaRow(
                    distanceLabel: distanceLabel,
                    distric: attraction.distric,
                    address: attraction.address,
                  ),
                  // Opening hours
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

// Distance + district row
class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.distanceLabel,
    required this.distric,
    required this.address,
  });

  final String? distanceLabel;
  final String distric;
  final String address;

  @override
  Widget build(BuildContext context) {
    final location = distric.isNotEmpty ? distric : address;
    final hasLocation = location.isNotEmpty;
    final hasDistance = distanceLabel != null;
    if (!hasDistance && !hasLocation) return const SizedBox.shrink();
    return Row(
      children: [
        const Icon(
          Icons.location_on_outlined,
          size: 13,
          color: AppColors.textHint,
        ),
        const SizedBox(width: 2),
        Expanded(
          child: Text(
            [
              if (hasDistance) distanceLabel!,
              if (hasLocation) location,
            ].join('  ·  '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textCaption),
          ),
        ),
      ],
    );
  }
}

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
