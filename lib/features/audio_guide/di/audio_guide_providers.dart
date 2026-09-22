import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_travel_audio_guide/core/database/database_provider.dart';
import 'package:flutter_travel_audio_guide/core/network/network_providers.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_local_data_source.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/repositories/audio_guide_repository_impl.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/services/audio_playback_service_impl.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/repositories/audio_guide_repository.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/services/audio_playback_service.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/usecases/download_audio_guide_usecase.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/usecases/get_audio_guides_usecase.dart';

final audioGuideRemoteDataSourceProvider = Provider<AudioGuideRemoteDataSource>(
  (ref) => AudioGuideRemoteDataSource(ref.watch(dioProvider)),
);

final audioGuideLocalDataSourceProvider = Provider<AudioGuideLocalDataSource>(
  (ref) => const AudioGuideLocalDataSource(),
);

final audioGuideRepositoryProvider = Provider<AudioGuideRepository>((ref) {
  return AudioGuideRepositoryImpl(
    remoteDataSource: ref.watch(audioGuideRemoteDataSourceProvider),
    localDataSource: ref.watch(audioGuideLocalDataSourceProvider),
  );
});

final getAudioGuidesUseCaseProvider = Provider<GetAudioGuidesUseCase>((ref) {
  return GetAudioGuidesUseCase(ref.watch(audioGuideRepositoryProvider));
});

final downloadAudioGuideUseCaseProvider = Provider<DownloadAudioGuideUseCase>((
  ref,
) {
  return DownloadAudioGuideUseCase(ref.watch(audioGuideRepositoryProvider));
});

final ProviderFamily<AudioPlaybackService, String>
audioPlaybackServiceProvider = Provider.autoDispose
    .family<AudioPlaybackService, String>((ref, path) {
      final service = AudioPlaybackServiceImpl();
      ref.onDispose(service.dispose);
      return service;
    });

final audioGuidesStreamProvider = StreamProvider<List<AudioGuide>>((ref) {
  return ref.watch(appDatabaseProvider).audioGuideDao.watchAll();
});
