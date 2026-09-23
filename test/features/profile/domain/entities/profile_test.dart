import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/profile/domain/entities/profile.dart';

void main() {
  test('toString 不外洩 email/avatarUrl，只印 id', () {
    final profile = Profile(
      id: 'uid-1',
      email: 'secret@example.com',
      displayName: 'Sun',
      preferredLanguage: 'zh-TW',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
      avatarUrl: 'https://example.com/a.png',
    );
    expect(profile.toString(), 'Profile(id: uid-1)');
    expect(profile.toString(), isNot(contains('secret@example.com')));
  });
}
