import 'package:flutter_foreground_task/flutter_foreground_task.dart';

import 'analytics/telemetry.dart';
import 'background/task_manager.dart';
import 'notifications/notifier.dart';

/// Одноразова ініціалізація клієнта .rice перед `runApp`.
///
/// Викликайте після `WidgetsFlutterBinding.ensureInitialized()`.
/// Для foreground task додатково викличте [FlutterForegroundTask.initCommunicationPort]
/// у `main()` до `runApp`, якщо використовуєте [RiceForegroundTaskManager].
Future<void> bootstrapRiceClient({
  bool initNotifications = true,
  bool initForegroundDefaults = false,
  String? posthogApiKey,
  String? posthogHost,
}) async {
  if (initForegroundDefaults) {
    RiceForegroundTaskManager.configure();
  }
  if (initNotifications) {
    await RiceLocalNotifier.init();
  }
  await RiceTelemetry.setup(apiKey: posthogApiKey, host: posthogHost);
}
