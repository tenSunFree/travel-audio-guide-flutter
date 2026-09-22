import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/constants/backend_api_constants.dart';

void main() {
  test('沒有帶 --dart-define 時，baseUrl 預設為 http://localhost:8080', () {
    expect(BackendApiConstants.baseUrl, 'http://localhost:8080');
  });

  test('defaultHeaders 帶正確的 accept / content-type', () {
    expect(BackendApiConstants.defaultHeaders['accept'], 'application/json');
    expect(
      BackendApiConstants.defaultHeaders['content-type'],
      'application/json',
    );
  });

  test('timeout 設定符合預期', () {
    expect(BackendApiConstants.connectTimeout, const Duration(seconds: 15));
    expect(BackendApiConstants.receiveTimeout, const Duration(seconds: 30));
    expect(BackendApiConstants.sendTimeout, const Duration(seconds: 30));
  });
}
