import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/features/profile/data/models/profile_model.dart';

void main() {
  const raw = {
    'id': 'uid-1',
    'email': 'a@b.com',
    'display_name': 'Sun',
    'avatar_url': 'https://example.com/a.png',
    'preferred_language': 'en',
    'created_at': '2026-01-02T03:04:05.000Z',
    'updated_at': '2026-01-03T03:04:05.000Z',
  };

  group('ProfileModel.fromJson', () {
    test('解析後端 /api/v1/me 的 data 物件', () {
      final model = ProfileModel.fromJson(raw);
      expect(model.id, 'uid-1');
      expect(model.email, 'a@b.com');
      expect(model.displayName, 'Sun');
      expect(model.avatarUrl, 'https://example.com/a.png');
      expect(model.preferredLanguage, 'en');
      expect(model.createdAt.toUtc(), DateTime.utc(2026, 1, 2, 3, 4, 5));
      expect(model.updatedAt.toUtc(), DateTime.utc(2026, 1, 3, 3, 4, 5));
    });

    test('缺少選填欄位時使用預設值', () {
      final model = ProfileModel.fromJson({
        'id': 'uid-1',
        'email': 'a@b.com',
        'created_at': '2026-01-02T03:04:05.000Z',
        'updated_at': '2026-01-03T03:04:05.000Z',
      });
      expect(model.displayName, '');
      expect(model.avatarUrl, isNull);
      expect(model.preferredLanguage, 'zh-TW');
    });
  });

  group('ProfileModel.toEntity', () {
    test('欄位完整對應到 Profile entity', () {
      final entity = ProfileModel.fromJson(raw).toEntity();
      expect(entity.id, 'uid-1');
      expect(entity.email, 'a@b.com');
      expect(entity.displayName, 'Sun');
      expect(entity.avatarUrl, 'https://example.com/a.png');
      expect(entity.preferredLanguage, 'en');
      expect(entity.createdAt.toUtc(), DateTime.utc(2026, 1, 2, 3, 4, 5));
      expect(entity.updatedAt.toUtc(), DateTime.utc(2026, 1, 3, 3, 4, 5));
    });
  });

  group('ProfileModel.toString', () {
    test('不外洩 email/avatarUrl，只印 id', () {
      final model = ProfileModel.fromJson(raw);
      expect(model.toString(), 'ProfileModel(id: uid-1)');
      expect(model.toString(), isNot(contains(raw['email'])));
    });
  });
}
