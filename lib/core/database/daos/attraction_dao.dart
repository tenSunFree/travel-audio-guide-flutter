import 'dart:convert';
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../features/attraction/data/models/attraction_model.dart';
import '../../../features/attraction/domain/entities/attraction.dart';
import '../tables/attraction_table.dart';

part 'attraction_dao.g.dart';

@DriftAccessor(tables: [AttractionTable])
class AttractionDao extends DatabaseAccessor<AppDatabase>
    with _$AttractionDaoMixin {
  AttractionDao(super.db);

  /// The UI listens for this, and the database refreshes automatically when updated.
  Stream<List<Attraction>> watchAll() {
    return (select(attractionTable)..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  Future<List<AttractionTableData>> getAll() {
    return select(attractionTable).get();
  }

  /// Used for name matching during AudioGuide synchronization
  Future<AttractionTableData?> findByName(String name) async {
    final all = await select(attractionTable).get();
    final normalized = _normalize(name);
    try {
      return all.firstWhere((r) => _normalize(r.name) == normalized);
    } catch (_) {
      return null;
    }
  }

  Future<Attraction?> findById(int id) async {
    final row = await (select(
      attractionTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toEntity(row);
  }

  Future<void> upsertAll(List<AttractionModel> models) async {
    final companions = models.map(_toCompanion).toList();
    await batch(
      (b) => b.insertAllOnConflictUpdate(attractionTable, companions),
    );
  }

  static String _normalize(String s) =>
      s.replaceAll('　', '').replaceAll(' ', '').toLowerCase().trim();

  AttractionTableCompanion _toCompanion(AttractionModel m) =>
      AttractionTableCompanion.insert(
        id: Value(m.id),
        name: m.name,
        introduction: m.introduction,
        openTime: m.openTime,
        distric: m.distric,
        address: m.address,
        tel: m.tel,
        officialSite: m.officialSite,
        facebook: m.facebook,
        ticket: m.ticket,
        remind: m.remind,
        url: m.url,
        modified: m.modified,
        nlat: Value(m.nlat),
        elong: Value(m.elong),
        categoriesJson: Value(
          jsonEncode(
            m.categories.map((e) => {'id': e.id, 'name': e.name}).toList(),
          ),
        ),
        imagesJson: Value(
          jsonEncode(m.images.map((e) => {'src': e.src}).toList()),
        ),
        friendliesJson: Value(
          jsonEncode(
            m.friendlies.map((e) => {'id': e.id, 'name': e.name}).toList(),
          ),
        ),
        cachedAt: DateTime.now(),
      );

  Attraction _toEntity(AttractionTableData r) {
    final categories = (jsonDecode(r.categoriesJson) as List)
        .map((e) => AttractionCategory(id: e['id'], name: e['name']))
        .toList();
    final images = (jsonDecode(r.imagesJson) as List)
        .map((e) => AttractionImage(src: e['src'], subject: '', ext: ''))
        .toList();
    final friendlies = (jsonDecode(r.friendliesJson) as List)
        .map((e) => AttractionTag(id: e['id'], name: e['name']))
        .toList();
    return Attraction(
      id: r.id,
      name: r.name,
      introduction: r.introduction,
      openTime: r.openTime,
      distric: r.distric,
      address: r.address,
      tel: r.tel,
      nlat: r.nlat,
      elong: r.elong,
      officialSite: r.officialSite,
      facebook: r.facebook,
      ticket: r.ticket,
      remind: r.remind,
      modified: r.modified,
      url: r.url,
      categories: categories,
      targets: [],
      friendlies: friendlies,
      images: images,
    );
  }
}
