import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../image/app_image_cache_manager.dart';

/// A globally unified network image element
///
/// Features:
/// - Automatically calculates memCacheWidth / memCacheHeight based on width/height × pixelRatio
/// (Prevents small thumbnails from decoding the entire large image into memory)
/// - Uses AppImageCacheManager (disk cache stalePeriod: 1 hour)
/// - Built-in default placeholder (spinning circle) and errorWidget (broken image icon)
/// - Supports custom placeholder, errorWidget, and borderRadius
///
/// Usage Example:
/// ```dart
/// AppCachedNetworkImage(
///   imageUrl: url,
///   width: 96,
///   height: 96,
///   errorWidget: _Placeholder(),
/// )
/// ```
class AppCachedNetworkImage extends StatelessWidget {
  const AppCachedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholder,
    this.errorWidget,
  });

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  /// Rounded corners, automatically wrapped when passed in ClipRRect
  final BorderRadius? borderRadius;

  /// Widgets displayed during loading; if not provided, use the default spinning circle.
  final Widget? placeholder;

  /// Widget to display if loading fails; otherwise, use the default broken icon.
  final Widget? errorWidget;

  @override
  Widget build(BuildContext context) {
    final pixelRatio = MediaQuery.devicePixelRatioOf(context);
    final image = CachedNetworkImage(
      imageUrl: imageUrl,
      cacheManager: AppImageCacheManager.instance,
      width: width,
      height: height,
      fit: fit,
      // Calculate the decoded size based on logical size × device pixel ratio
      // Do not pass isInfinite / null (let the package decide for itself)
      memCacheWidth: _toMemCache(width, pixelRatio),
      memCacheHeight: _toMemCache(height, pixelRatio),
      placeholder: (_, _) =>
          placeholder ?? _DefaultPlaceholder(width: width, height: height),
      errorWidget: (_, _, _) =>
          errorWidget ?? _DefaultError(width: width, height: height),
    );
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  int? _toMemCache(double? logicalSize, double pixelRatio) {
    if (logicalSize == null || logicalSize.isInfinite) return null;
    return (logicalSize * pixelRatio).round();
  }
}

class _DefaultPlaceholder extends StatelessWidget {
  const _DefaultPlaceholder({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

class _DefaultError extends StatelessWidget {
  const _DefaultError({this.width, this.height});

  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: AppColors.surfaceMuted,
      alignment: Alignment.center,
      child: const Icon(Icons.broken_image_outlined, color: AppColors.textHint),
    );
  }
}
