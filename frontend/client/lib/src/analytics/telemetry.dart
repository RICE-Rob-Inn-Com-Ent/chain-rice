import 'package:flutter/foundation.dart';
import 'package:posthog_flutter/posthog_flutter.dart';

/// Телеметрія клієнта (PostHog) — лаги, екрани, збої. Без ключа ініціалізація no-op.
abstract final class RiceTelemetry {
  static bool _ready = false;

  static Future<void> setup({required String? apiKey, String? host}) async {
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('RiceTelemetry: пропуск (немає POSTHOG_API_KEY).');
      return;
    }
    final cfg = PostHogConfig(apiKey);
    if (host != null && host.isNotEmpty) {
      cfg.host = host;
    }
    cfg.captureApplicationLifecycleEvents = true;
    cfg.debug = kDebugMode;
    await Posthog().setup(cfg);
    _ready = true;
  }

  static Future<void> capture(String event, [Map<String, Object>? props]) async {
    if (!_ready) return;
    await Posthog().capture(eventName: event, properties: props);
  }

  static Future<void> screen(String name, [Map<String, Object>? props]) async {
    if (!_ready) return;
    await Posthog().screen(screenName: name, properties: props);
  }

  static Future<void> identify(String userId) async {
    if (!_ready) return;
    await Posthog().identify(userId: userId);
  }
}
