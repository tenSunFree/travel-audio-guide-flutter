class ApiConstants {
  const ApiConstants._();

  /// Taipei Travel open API root.
  ///
  /// Browsers block this host (no CORS headers), so Web builds point
  /// `TAIPEI_API_BASE_URL` at the CORS proxy in `infra/taipei-api-proxy`
  /// (path must end with `/open-api`). Mobile keeps the direct URL.
  static const String baseUrl = String.fromEnvironment(
    'TAIPEI_API_BASE_URL',
    defaultValue: 'https://www.travel.taipei/open-api',
  );
  static const String defaultLang = 'zh-tw';
  static const int defaultPage = 1;
  static const int pageSize = 30;
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const Map<String, String> defaultHeaders = {
    'accept': 'application/json',
  };
}
