import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:rule/unit.dart';

part 'rule_database.g.dart';

/// Single shared Drift database for the shell — override in tests.
@Riverpod(keepAlive: true)
RiceDatabase ruleDatabase(Ref ref) {
  final db = RiceDatabase();
  ref.onDispose(db.close);
  return db;
}
