import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../features/audio_guide/data/models/audio_guide_model.dart';
import '../../../features/audio_guide/domain/entities/audio_guide.dart';
import '../tables/audio_guide_table.dart';

part 'audio_guide_dao.g.dart';

@DriftAccessor(tables: [AudioGuideTable])
class AudioGuideDao extends DatabaseAccessor<AppDatabase>
    with _$AudioGuideDaoMixin {
  AudioGuideDao(super.db);

  Stream<List<AudioGuide>> watchAll() {
    return (select(audioGuideTable)
          ..orderBy([(t) => OrderingTerm.asc(t.title)]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  Future<List<AudioGuideTableData>> getAll() {
    return select(audioGuideTable).get();
  }

  Future<AudioGuide?> findById(int id) async {
    final row = await (select(
      audioGuideTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toEntity(row);
  }

  Future<void> upsertAll(List<AudioGuideTableCompanion> companions) async {
    await batch(
      (b) => b.insertAllOnConflictUpdate(audioGuideTable, companions),
    );
  }

  /// Update download status
  Future<void> updateDownloadState({
    required int id,
    required bool isDownloaded,
    String? localFilePath,
  }) async {
    await (update(audioGuideTable)..where((t) => t.id.equals(id))).write(
      AudioGuideTableCompanion(
        isDownloaded: Value(isDownloaded),
        localFilePath: Value(localFilePath),
      ),
    );
  }

  AudioGuideTableCompanion toCompanion(
    AudioGuideModel m, {
    int? matchedAttractionId,
    bool isDownloaded = false,
    String? localFilePath,
  }) => AudioGuideTableCompanion.insert(
    id: Value(m.id),
    title: m.title,
    url: m.url,
    modified: m.modified,
    summary: Value(m.summary),
    fileExt: Value(m.fileExt),
    matchedAttractionId: Value(matchedAttractionId),
    isDownloaded: Value(isDownloaded),
    localFilePath: Value(localFilePath),
    cachedAt: DateTime.now(),
  );

  AudioGuide _toEntity(AudioGuideTableData r) => AudioGuide(
    id: r.id,
    title: r.title,
    summary: r.summary,
    url: r.url,
    fileExt: r.fileExt,
    modified: r.modified,
    isDownloaded: r.isDownloaded,
    matchedAttractionId: r.matchedAttractionId,
    localFilePath: r.localFilePath,
  );

  Future<void> markAsDownloaded({
    required int id,
    required String localFilePath,
  }) {
    return (update(audioGuideTable)..where((t) => t.id.equals(id))).write(
      AudioGuideTableCompanion(
        isDownloaded: const Value(true),
        localFilePath: Value(localFilePath),
      ),
    );
  }
}
