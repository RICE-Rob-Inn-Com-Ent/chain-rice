import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'daos/rules_dao.dart';
import 'daos/telemetry_dao.dart';
import 'tables.dart';

part 'database.g.dart';

@DriftDatabase(
  tables: [Rules, SystemEvents, DeviceConfigs, TelemetrySamples],
  daos: [RulesDao, TelemetryDao],
)
class RiceRuleDatabase extends _$RiceRuleDatabase {
  RiceRuleDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Bump [schemaVersion] and migrate here when the schema evolves.
        },
      );

  /// Opens SQLite under app support (sandboxed). Call from a Flutter entrypoint
  /// after `WidgetsFlutterBinding.ensureInitialized()`.
  static Future<RiceRuleDatabase> open({bool logStatements = false}) async {
    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'rice_rule.sqlite'));
    final executor = LazyDatabase(() async {
      return NativeDatabase(file, logStatements: logStatements);
    });
    return RiceRuleDatabase(executor);
  }
}
