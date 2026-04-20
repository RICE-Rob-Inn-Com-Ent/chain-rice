import 'package:drift/drift.dart';

/// Persisted AI rule row — JSON blobs stay opaque for versioned evolution.
@DataClassName('RiceRuleRow')
class RiceRules extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get ruleKey => text().withLength(min: 1, max: 256)();

  TextColumn get definitionJson => text()();

  /// Optional provenance / tool metadata (JSON).
  TextColumn get metadataJson => text().withDefault(const Constant('{}'))();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
        {ruleKey},
      ];
}
