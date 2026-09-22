/// Network settings dedicated to the Go backend (/api/v1/*).
/// Intentionally separated from ApiConstants (travel.taipei open-api)
/// to avoid sharing the same configuration between two APIs with
/// different origins and authentication methods.
class BackendApiConstants {
  const BackendApiConstants._();

  static const String baseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'http://localhost:8080',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);

  static const Map<String, String> defaultHeaders = {
    'accept': 'application/json',
    'content-type': 'application/json',
  };
}
