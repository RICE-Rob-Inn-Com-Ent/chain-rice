import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'rice_rules_table.dart';

part 'rice_database.g.dart';

@DriftDatabase(tables: [RiceRules])
class RiceDatabase extends _$RiceDatabase {
  RiceDatabase([QueryExecutor? executor]) : super(executor ?? _openExecutor());

  /// Opens the on-disk rule store (mobile/desktop friendly).
  static QueryExecutor _openExecutor() {
    return LazyDatabase(() async {
      if (Platform.isAndroid) {
        await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
      }
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'rice_rules.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }

  @override
  int get schemaVersion => 1;

  /// Stream of all persisted rules for reactive UIs.
  Stream<List<RiceRuleRow>> watchAllRules() =>
      select(riceRules).watch();

  Future<int> upsertRule({
    required String ruleKey,
    required String definitionJson,
    String metadataJson = '{}',
  }) {
    return into(riceRules).insertOnConflictUpdate(
      RiceRulesCompanion(
        ruleKey: Value(ruleKey),
        definitionJson: Value(definitionJson),
        metadataJson: Value(metadataJson),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteRule(String ruleKey) {
    return (delete(riceRules)..where((t) => t.ruleKey.equals(ruleKey))).go();
  }
}
