import 'package:freezed_annotation/freezed_annotation.dart';

part 'audio_guide.freezed.dart';

@freezed
abstract class AudioGuide with _$AudioGuide {
  const factory AudioGuide({
    required int id,
    required String title,
    required String url,
    required String modified,
    required bool isDownloaded,
    int? matchedAttractionId,
    String? summary,
    String? fileExt,
    String? localFilePath,
  }) = _AudioGuide;
}
