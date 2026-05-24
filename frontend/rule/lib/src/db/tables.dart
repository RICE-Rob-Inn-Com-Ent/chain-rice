import 'package:drift/drift.dart';

/// Automation rule: when [metricKey] [compareOp] [threshold], emit [action].
class Rules extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get name => text().withLength(min: 1, max: 256)();

  /// Atlas / sensor fact key, e.g. `cpu.temp_c` or `rail12v`.
  TextColumn get metricKey => text().withLength(min: 1, max: 128)();

  /// One of: `gt`, `ge`, `lt`, `le`, `eq`.
  TextColumn get compareOp => text().withLength(min: 2, max: 2)();

  RealColumn get threshold => real()();

  /// Command / payload for the shell (client) to execute.
  TextColumn get action => text().withLength(min: 1, max: 2048)();

  IntColumn get priority => integer().withDefault(const Constant(0))();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// Structured log line (Guard, Smith, evaluator, …).
class SystemEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();

  TextColumn get severity => text().withLength(min: 1, max: 32)();

  TextColumn get source => text().withLength(min: 1, max: 128)();

  TextColumn get message => text().withLength(min: 1, max: 4096)();

  TextColumn get contextJson => text().nullable()();
}

/// Key–value configuration persisted per hardware id from Inventory.
class DeviceConfigs extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get deviceId => text().withLength(min: 1, max: 128)();

  TextColumn get configKey => text().withLength(min: 1, max: 256)();

  TextColumn get configValue => text().withLength(min: 1, max: 8192)();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column<Object>>>? get uniqueKeys => [
        {deviceId, configKey},
      ];
}

/// High-frequency numeric samples (sensors / streams).
class TelemetrySamples extends Table {
  IntColumn get id => integer().autoIncrement()();

  TextColumn get deviceId => text().withLength(min: 1, max: 128)();

  TextColumn get metric => text().withLength(min: 1, max: 128)();

  RealColumn get value => real()();

  DateTimeColumn get recordedAt => dateTime().withDefault(currentDateAndTime)();
}
