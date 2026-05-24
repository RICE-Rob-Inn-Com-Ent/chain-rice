import '../db/daos/rules_dao.dart';
import '../db/database.dart';

/// Fired when a stored [Rule] matches current [facts].
typedef RuleTriggered = void Function(Rule rule);

/// Compares Atlas-style [facts] (metric → value) against persisted [Rule] rows.
final class RuleEvaluator {
  const RuleEvaluator();

  /// Returns rules whose conditions hold for [facts], highest [Rule.priority] first.
  Future<List<Rule>> matchingRules(
    RulesDao dao,
    Map<String, double> facts,
  ) async {
    final rows = await dao.listEnabledRules();
    final out = <Rule>[];
    for (final rule in rows) {
      final v = facts[rule.metricKey];
      if (v == null) {
        continue;
      }
      if (_compare(v, rule.compareOp, rule.threshold)) {
        out.add(rule);
      }
    }
    return out;
  }

  /// Invokes [onTriggered] for every matching rule (client can map [Rule.action] to commands).
  Future<void> evaluateAndDispatch(
    RulesDao dao,
    Map<String, double> facts,
    RuleTriggered onTriggered,
  ) async {
    final hits = await matchingRules(dao, facts);
    for (final rule in hits) {
      onTriggered(rule);
    }
  }

  bool _compare(double value, String op, double threshold) {
    return switch (op) {
      'gt' => value > threshold,
      'ge' => value >= threshold,
      'lt' => value < threshold,
      'le' => value <= threshold,
      'eq' => value == threshold,
      _ => false,
    };
  }
}
