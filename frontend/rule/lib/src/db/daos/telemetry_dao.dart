import 'package:drift/drift.dart';

import '../database.dart';
import '../tables.dart';

part 'telemetry_dao.g.dart';

@DriftAccessor(tables: [TelemetrySamples])
class TelemetryDao extends DatabaseAccessor<RiceRuleDatabase> with _$TelemetryDaoMixin {
  TelemetryDao(super.db);

  Future<int> insertSample(TelemetrySamplesCompanion row) =>
      into(telemetrySamples).insert(row);

  Stream<List<TelemetrySample>> watchRecent({String? deviceId, int limit = 200}) {
    var q = select(telemetrySamples);
    if (deviceId != null) {
      q = q..where((t) => t.deviceId.equals(deviceId));
    }
    return (q
          ..orderBy([(t) => OrderingTerm.desc(t.recordedAt)])
          ..limit(limit))
        .watch();
  }

  Future<int> deleteOlderThan(DateTime cutoff) {
    return (delete(telemetrySamples)
          ..where((t) => t.recordedAt.isSmallerThanValue(cutoff)))
        .go();
  }
}
