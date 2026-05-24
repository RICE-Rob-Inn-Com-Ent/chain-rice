import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'connectivity_provider.g.dart';

/// Поточна мережа як стрім (connectivity_plus v6: список інтерфейсів).
@Riverpod(keepAlive: true)
Stream<List<ConnectivityResult>> connectivity(Ref ref) {
  return Connectivity().onConnectivityChanged;
}

/// `true`, якщо є хоча б один не-none канал.
@riverpod
bool isOnline(Ref ref) {
  final async = ref.watch(connectivityProvider);
  return async.maybeWhen(
    data: riceConnectivityIsOnline,
    orElse: () => true,
  );
}

bool riceConnectivityIsOnline(List<ConnectivityResult> results) {
  if (results.isEmpty) return false;
  return results.any((r) => r != ConnectivityResult.none);
}
