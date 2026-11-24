import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
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
import 'package:flutter_travel_audio_guide/core/utils/app_logger.dart';

part 'app_database.g.dart';

/// Handles the result of Drift Web's storage detection and logs a warning
/// when the browser lacked features, forcing a fallback implementation.
///
/// [result] is Drift's `WasmDatabaseResult`. It is typed `dynamic` so the
/// handler can be unit tested on the VM without constructing that class.
@visibleForTesting
void handleDriftWebResult(dynamic result) {
  // Dynamic access allows VM tests to supply a fake WasmDatabaseResult.
  // ignore: avoid_dynamic_calls
  final missing = result.missingFeatures as Iterable<Object>;
  if (missing.isEmpty) return;
  // Dynamic access avoids requiring the concrete Drift Web result in VM tests.
  // ignore: avoid_dynamic_calls
  final chosen = result.chosenImplementation as Object;
  AppLogger.warning(
    'Drift Web using $chosen due to missing browser features: $missing',
  );
}

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
            onResult: handleDriftWebResult,
          ),
        ),
      );

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;
}
