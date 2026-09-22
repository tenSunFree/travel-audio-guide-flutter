import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/profile/data/datasources/profile_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/profile/data/models/profile_model.dart';
import 'package:flutter_travel_audio_guide/features/profile/data/repositories/profile_repository_impl.dart';
import 'package:mocktail/mocktail.dart';

class MockProfileRemoteDataSource extends Mock
    implements ProfileRemoteDataSource {}

void main() {
  late MockProfileRemoteDataSource remote;
  late ProfileRepositoryImpl repository;

  setUp(() {
    remote = MockProfileRemoteDataSource();
    repository = ProfileRepositoryImpl(remote);
  });

  final model = ProfileModel(
    id: 'uid-1',
    email: 'a@b.com',
    displayName: 'Sun',
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026, 1, 2),
  );

  test('getMe 把 Model 轉成 Entity', () async {
    when(() => remote.getMe()).thenAnswer((_) async => model);
    final entity = await repository.getMe();
    expect(entity.id, 'uid-1');
    expect(entity.displayName, 'Sun');
    expect(entity.email, 'a@b.com');
    verify(() => remote.getMe()).called(1);
  });

  test('updateMe 轉發參數並把 Model 轉成 Entity', () async {
    when(
      () => remote.updateMe(
        displayName: 'New',
        preferredLanguage: 'en',
      ),
    ).thenAnswer(
      (_) async => model.copyWith(displayName: 'New', preferredLanguage: 'en'),
    );
    final entity = await repository.updateMe(
      displayName: 'New',
      preferredLanguage: 'en',
    );
    expect(entity.displayName, 'New');
    expect(entity.preferredLanguage, 'en');
  });

  test('getMe 的 ServerException 會往外拋', () async {
    when(() => remote.getMe()).thenThrow(const ServerException('boom'));
    await expectLater(repository.getMe(), throwsA(isA<ServerException>()));
  });
}
