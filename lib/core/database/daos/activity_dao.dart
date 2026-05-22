import 'dart:convert';
import 'package:drift/drift.dart';
import '../app_database.dart';
import '../../../features/activity/data/models/activity_model.dart';
import '../../../features/activity/domain/entities/activity.dart';
import '../tables/activity_table.dart';

part 'activity_dao.g.dart';

@DriftAccessor(tables: [ActivityTable])
class ActivityDao extends DatabaseAccessor<AppDatabase>
    with _$ActivityDaoMixin {
  ActivityDao(super.db);

  Stream<List<Activity>> watchAll() {
    return (select(activityTable)..orderBy([(t) => OrderingTerm.desc(t.begin)]))
        .watch()
        .map((rows) => rows.map(_toEntity).toList());
  }

  Future<List<ActivityTableData>> getAll() {
    return select(activityTable).get();
  }

  // Retrieve a single record from the local database
  Future<Activity?> findById(int id) async {
    final row = await (select(
      activityTable,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (row == null) return null;
    return _toEntity(row);
  }

  Future<void> upsertAll(List<ActivityModel> models) async {
    final companions = models.map(_toCompanion).toList();
    await batch((b) => b.insertAllOnConflictUpdate(activityTable, companions));
  }

  ActivityTableCompanion _toCompanion(ActivityModel m) =>
      ActivityTableCompanion.insert(
        id: Value(m.id),
        title: m.title,
        description: m.description,
        begin: m.begin,
        end: m.end,
        posted: m.posted,
        modified: m.modified,
        url: m.url,
        address: m.address,
        distric: m.distric,
        nlat: m.nlat,
        elong: m.elong,
        organizer: m.organizer,
        coRganizer: m.coRganizer,
        contact: m.contact,
        tel: m.tel,
        ticket: m.ticket,
        traffic: m.traffic,
        parking: m.parking,
        linksJson: Value(
          jsonEncode(
            m.links.map((e) => {'src': e.src, 'subject': e.subject}).toList(),
          ),
        ),
        cachedAt: DateTime.now(),
      );

  Activity _toEntity(ActivityTableData r) {
    final links = (jsonDecode(r.linksJson) as List)
        .map((e) => ActivityLink(src: e['src'], subject: e['subject']))
        .toList();
    return Activity(
      id: r.id,
      title: r.title,
      description: r.description,
      begin: r.begin,
      end: r.end,
      posted: r.posted,
      modified: r.modified,
      url: r.url,
      address: r.address,
      distric: r.distric,
      nlat: r.nlat,
      elong: r.elong,
      organizer: r.organizer,
      coRganizer: r.coRganizer,
      contact: r.contact,
      tel: r.tel,
      ticket: r.ticket,
      traffic: r.traffic,
      parking: r.parking,
      links: links,
    );
  }
}
