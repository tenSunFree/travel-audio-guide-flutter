import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_travel_audio_guide/core/database/daos/activity_dao.dart';
import 'package:flutter_travel_audio_guide/core/database/daos/attraction_dao.dart';
import 'package:flutter_travel_audio_guide/core/database/daos/audio_guide_dao.dart';
import 'package:flutter_travel_audio_guide/core/database/daos/reminder_dao.dart';
import 'package:flutter_travel_audio_guide/core/database/daos/sync_meta_dao.dart';
import 'package:flutter_travel_audio_guide/core/database/tables/activity_table.dart';
import 'package:flutter_travel_audio_guide/core/database/tables/attraction_table.dart';
import 'package:flutter_travel_audio_guide/core/database/tables/audio_guide_table.dart';
import 'package:flutter_travel_audio_guide/core/database/tables/reminder_table.dart';
import 'package:flutter_travel_audio_guide/core/database/tables/sync_meta_table.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    AttractionTable,
    AudioGuideTable,
    ActivityTable,
    SyncMetaTable,
    ReminderTable,
  ],
  daos: [AttractionDao, AudioGuideDao, ActivityDao, SyncMetaDao, ReminderDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase()
    : super(
        driftDatabase(
          name: 'travel_guide_db',
          // Web: SQLite compiled to WASM, running in a shared/dedicated worker
          // with OPFS/IndexedDB persistence. Both files must be served from
          // the web root (see scripts/fetch_web_sqlite_assets.sh).
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
            onResult: (result) {
              if (result.missingFeatures.isNotEmpty) {
                debugPrint(
                  'Drift Web using ${result.chosenImplementation} due to '
                  'missing browser features: ${result.missingFeatures}',
                );
              }
            },
          ),
        ),
      );

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;
}
