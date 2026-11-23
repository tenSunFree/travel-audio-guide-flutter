import 'package:flutter/foundation.dart';

/// Single place that answers "what can this platform do?".
///
/// Never use `dart:io` `Platform` in shared code: it throws on Flutter Web.
/// Branch on these flags (or `kIsWeb` / `defaultTargetPlatform`) instead.
class PlatformSupport {
  const PlatformSupport._();

  /// Running as a Flutter Web app.
  static bool get isWeb => kIsWeb;

  /// Local notifications (flutter_local_notifications) are available.
  static bool get supportsLocalNotifications => !kIsWeb;

  /// Native calendar insertion (add_2_calendar) is available.
  static bool get supportsNativeCalendar => !kIsWeb;

  /// Audio files can be downloaded to the device file system.
  static bool get supportsAudioDownload => !kIsWeb;

  /// Returns [url] unchanged on mobile; on Web promotes HTTP to HTTPS for
  /// hosts known to support it (see [upgradeKnownHttpsHost]).
  static String webSafeUrl(String url) =>
      kIsWeb ? upgradeKnownHttpsHost(url) : url;

  /// Promote HTTP only for hosts known to offer HTTPS. Do NOT rewrite
  /// arbitrary media URLs: a server may not support TLS on the same host.
  /// On HTTPS sites, all other HTTP resources must use a trusted proxy or
  /// provide their own working HTTPS URL (otherwise mixed-content may fail).
  ///
  /// Pure function with no platform check so it can be unit-tested on the VM.
  /// App code should call [webSafeUrl] instead.
  @visibleForTesting
  static String upgradeKnownHttpsHost(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'http') return url;
    const confirmedHttpsHosts = {'travel.taipei', 'www.travel.taipei'};
    if (!confirmedHttpsHosts.contains(uri.host.toLowerCase())) return url;
    return uri.replace(scheme: 'https').toString();
  }
}
