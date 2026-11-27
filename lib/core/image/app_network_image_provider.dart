import 'package:flutter/painting.dart';
import 'package:flutter_travel_audio_guide/core/platform/platform_support.dart';

/// Shared network image policy for public images, without custom headers.
/// On Web, prefer decoded bytes and fall back to an HTML element on failure.
NetworkImage appNetworkImageProvider(String url, {required bool isWeb}) {
  return NetworkImage(
    PlatformSupport.webSafeUrl(url, isWeb: isWeb),
    webHtmlElementStrategy: isWeb
        ? WebHtmlElementStrategy.fallback
        : WebHtmlElementStrategy.never,
  );
}
