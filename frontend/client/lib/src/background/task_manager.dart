import 'package:flutter_foreground_task/flutter_foreground_task.dart';

/// Точка входу для isolate сервісу (має бути top-level / static + vm:entry-point).
@pragma('vm:entry-point')
void riceForegroundStartCallback() {
  FlutterForegroundTask.setTaskHandler(_RiceBardTaskHandler());
}

/// Обробник фонових подій: heartbeat для Inventory / SMITH (розширюйте під ваші порти).
final class _RiceBardTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {}

  @override
  void onRepeatEvent(DateTime timestamp) {
    FlutterForegroundTask.sendDataToMain(<String, Object?>{
      'tick': timestamp.millisecondsSinceEpoch,
    });
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {}
}

/// Конфігурація foreground service для Android / iOS (Linux desktop — no-op / помилка старту).
abstract final class RiceForegroundTaskManager {
  static bool _configured = false;

  /// Викликайте один раз після `WidgetsFlutterBinding.ensureInitialized()`.
  static void configure({
    Duration repeatInterval = const Duration(minutes: 1),
    bool autoRunOnBoot = false,
  }) {
    if (_configured) return;
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'rice_bard_foreground',
        channelName: '.rice BARD',
        channelDescription: 'Фонові служби сканування та мережі',
        channelImportance: NotificationChannelImportance.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(
          repeatInterval.inMilliseconds,
        ),
        autoRunOnBoot: autoRunOnBoot,
        allowWakeLock: true,
      ),
    );
    _configured = true;
  }

  static Future<ServiceRequestResult> start({
    String title = '.rice BARD',
    String text = 'Служба активна',
  }) {
    return FlutterForegroundTask.startService(
      notificationTitle: title,
      notificationText: text,
      callback: riceForegroundStartCallback,
    );
  }

  static Future<ServiceRequestResult> stop() => FlutterForegroundTask.stopService();

  /// Підписка на дані з isolate (tick з [onRepeatEvent]).
  static void addTaskDataListener(void Function(Object data) listener) {
    FlutterForegroundTask.addTaskDataCallback(listener);
  }

  static void removeTaskDataListener(void Function(Object data) listener) {
    FlutterForegroundTask.removeTaskDataCallback(listener);
  }
}
