import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'rules_dao.g.dart';

@DriftAccessor(tables: [Rules])
class RulesDao extends DatabaseAccessor<RiceRuleDatabase> with _$RulesDaoMixin {
  RulesDao(super.db);

  Stream<List<Rule>> watchAllRules() {
    return (select(rules)..orderBy([(t) => OrderingTerm.desc(t.priority)])).watch();
  }

  Stream<List<Rule>> watchEnabledRules() {
    return (select(rules)
          ..where((t) => t.enabled.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.priority)]))
        .watch();
  }

  Future<List<Rule>> listEnabledRules() {
    return (select(rules)
          ..where((t) => t.enabled.equals(true))
          ..orderBy([(t) => OrderingTerm.desc(t.priority)]))
        .get();
  }

  Future<int> insertRule(RulesCompanion row) => into(rules).insert(row);

  Future<bool> saveRule(Rule entity) => update(rules).replace(entity);

  Future<int> deleteRule(int id) =>
      (delete(rules)..where((t) => t.id.equals(id))).go();
}
