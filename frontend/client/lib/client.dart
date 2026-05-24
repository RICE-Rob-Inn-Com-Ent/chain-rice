/// Центральний керуючий шар .rice — маршрути, стан, фон, сховище, телеметрія.
library;

export 'package:flutter_riverpod/flutter_riverpod.dart' show ProviderScope;
export 'package:go_router/go_router.dart';
export 'package:hooks_riverpod/hooks_riverpod.dart';

export 'src/app/rice_root.dart';
export 'src/analytics/telemetry.dart';
export 'src/background/task_manager.dart';
export 'src/bootstrap.dart';
export 'src/device/info_collector.dart';
export 'src/navigation/router.dart';
export 'src/notifications/notifier.dart';
export 'src/state/connectivity_provider.dart';
export 'src/state/session_provider.dart';
export 'src/state/system_provider.dart';
export 'src/storage/settings.dart';
export 'src/storage/vault.dart';
