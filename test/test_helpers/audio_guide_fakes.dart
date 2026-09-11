import 'package:dio/dio.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/datasources/activity_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/activity/data/models/activity_page_model.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/datasources/attraction_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/attraction/data/models/attraction_page_model.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/datasources/audio_guide_remote_data_source.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/data/models/audio_guide_page_model.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/entities/audio_guide_page.dart';
import 'package:flutter_travel_audio_guide/features/audio_guide/domain/repositories/audio_guide_repository.dart';

typedef GetAudioGuidesHandler =
    Future<AudioGuidePage> Function({required String lang, required int page});
typedef DownloadAudioGuideHandler = Future<String> Function(AudioGuide guide);
typedef IsGuideDownloadedHandler = Future<bool> Function(AudioGuide guide);

class FakeAudioGuideRepository implements AudioGuideRepository {
  FakeAudioGuideRepository({
    required GetAudioGuidesHandler onGet,
    DownloadAudioGuideHandler? onDownload,
    IsGuideDownloadedHandler? onIsDownloaded,
    // ignore: prefer_initializing_formals, public parameter name kept consistent with the other repositories' constructors
  }) : _onGet = onGet,
       _onDownload = onDownload ?? ((_) async => r'C:\audio\default.mp3'),
       _onIsDownloaded = onIsDownloaded ?? ((_) async => false);

  final GetAudioGuidesHandler _onGet;
  final DownloadAudioGuideHandler _onDownload;
  final IsGuideDownloadedHandler _onIsDownloaded;
  final List<int> requestedPages = <int>[];
  final List<String> requestedLangs = <String>[];

  @override
  Future<AudioGuidePage> getAudioGuides({
    required String lang,
    required int page,
  }) {
    requestedLangs.add(lang);
    requestedPages.add(page);
    return _onGet(lang: lang, page: page);
  }

  @override
  Future<String> downloadAudioGuide(AudioGuide guide) {
    return _onDownload(guide);
  }

  @override
  Future<bool> isGuideDownloaded(AudioGuide guide) {
    return _onIsDownloaded(guide);
  }
}

class FakeAttractionRemoteDataSource extends AttractionRemoteDataSource {
  FakeAttractionRemoteDataSource() : super(Dio());

  @override
  Future<AttractionPageModel> getAttractions({
    required String lang,
    required int page,
    String? categoryIds,
    double? nlat,
    double? elong,
  }) async => AttractionPageModel(total: 0, page: page, data: const []);
}

class FakeAudioGuideRemoteDataSource extends AudioGuideRemoteDataSource {
  FakeAudioGuideRemoteDataSource() : super(Dio());

  @override
  Future<AudioGuidePageModel> getAudioGuides({
    required String lang,
    required int page,
  }) async => AudioGuidePageModel(total: 0, page: page, data: const []);
}

class FakeActivityRemoteDataSource extends ActivityRemoteDataSource {
  FakeActivityRemoteDataSource() : super(Dio());

  @override
  Future<ActivityPageModel> getActivities({
    required String lang,
    required int page,
    String? begin,
    String? end,
  }) async => ActivityPageModel(total: 0, page: page, data: const []);
}
