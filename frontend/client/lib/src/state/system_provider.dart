import 'dart:convert';

import 'package:model/lib.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'system_provider.g.dart';

/// Мінімальний валідний [SystemAtlas] до приходу реального скану Inventory.
SystemAtlas ricePlaceholderAtlas() {
  return SystemAtlas(
    timestamp: DateTime.now().toUtc(),
    cpu: const CpuInfo(
      model: 'unknown',
      architecture: 'unknown',
      vendor: 'unknown',
      logicalCores: 0,
      physicalPackages: 0,
    ),
  );
}

/// Глобальний стан тіла системи (.rice): [SystemAtlas] з модулю `model`.
///
/// Оновлення з сокетів / фонових задач: викличте [applyAtlas] або [applyFromJson].
@Riverpod(keepAlive: true)
class SystemState extends _$SystemState {
  @override
  Future<SystemAtlas?> build() async {
    await Future<void>.delayed(Duration.zero);
    return null;
  }

  Future<void> applyAtlas(SystemAtlas atlas) async {
    state = AsyncData(atlas);
  }

  Future<void> applyFromJson(String json) async {
    state = await AsyncValue.guard<SystemAtlas?>(() async {
      final map = jsonDecode(json) as Map<String, dynamic>;
      return SystemAtlas.fromJson(map);
    });
  }

  Future<void> clearToBoot() async {
    state = const AsyncData<SystemAtlas?>(null);
  }

  void reportError(Object error, StackTrace stack) {
    state = AsyncError<SystemAtlas?>(error, stack);
  }
}
