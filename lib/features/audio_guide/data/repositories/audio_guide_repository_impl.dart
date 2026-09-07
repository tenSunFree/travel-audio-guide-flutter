import 'package:flutter_travel_audio_guide/core/constants/api_constants.dart';
import 'package:flutter_travel_audio_guide/core/error/exceptions.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_local_data_source.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide_page.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/repositories/audio_guide_repository.dart';

class AudioGuideRepositoryImpl implements AudioGuideRepository {
  const AudioGuideRepositoryImpl({
    required this._remoteDataSource,
    required this._localDataSource,
  });

  final AudioGuideRemoteDataSource _remoteDataSource;
  final AudioGuideLocalDataSource _localDataSource;

  @override
  Future<AudioGuidePage> getAudioGuides({
    required String lang,
    required int page,
  }) async {
    final pageModel = await _remoteDataSource.getAudioGuides(
      lang: lang,
      page: page,
    );
    final items = await Future.wait(
      pageModel.data.map((model) async {
        final localPath = await _localDataSource.getAudioFilePath(
          id: model.id,
          title: model.title,
        );
        final exists = await _localDataSource.existsPath(localPath);
        return model.toEntity(
          isDownloaded: exists,
          localFilePath: exists ? localPath : null,
        );
      }),
    );
    final hasMore = page * ApiConstants.pageSize < pageModel.total;
    return AudioGuidePage(
      total: pageModel.total,
      page: pageModel.page,
      items: items,
      hasMore: hasMore,
    );
  }

  @override
  Future<String> downloadAudioGuide(AudioGuide guide) async {
    final targetPath = await _localDataSource.getAudioFilePath(
      id: guide.id,
      title: guide.title,
    );
    if (await _localDataSource.existsPath(targetPath)) {
      return targetPath;
    }
    final result = await _remoteDataSource.downloadAudioBinary(guide.url);
    final looksLikeAudio =
        result.contentType.contains('audio') ||
        result.finalUrl.toLowerCase().endsWith('.mp3') ||
        guide.url.toLowerCase().endsWith('.mp3');
    if (!looksLikeAudio) {
      throw const DownloadException('非音訊檔，請提供MP3下載連結。');
    }
    await _localDataSource.writeBytes(bytes: result.bytes, path: targetPath);
    return targetPath;
  }

  @override
  Future<bool> isGuideDownloaded(AudioGuide guide) async {
    final targetPath = await _localDataSource.getAudioFilePath(
      id: guide.id,
      title: guide.title,
    );
    return _localDataSource.existsPath(targetPath);
  }
}
