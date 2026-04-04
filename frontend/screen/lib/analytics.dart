import 'package:posthog_flutter/posthog_flutter.dart';

// TODO:
// [ ] posthog_flutter init POSTHOG_KEY dart-define — https://pub.dev/packages/posthog_flutter
// [ ] track(); GoRouter listener screen views
//
/// PostHog facade — keys from `--dart-define` / native config.
abstract final class RiceAnalytics {
  static Future<void> init() async {
    const String key = String.fromEnvironment('POSTHOG_KEY');
    if (key.isEmpty) {
      return;
    }
    final PostHogConfig cfg = PostHogConfig(key)
      ..host = const String.fromEnvironment(
        'POSTHOG_HOST',
        defaultValue: 'https://us.i.posthog.com',
      );
    await Posthog().setup(cfg);
  }

  static Future<void> track(String event, [Map<String, Object>? props]) async {
    await Posthog().capture(eventName: event, properties: props);
  }

  static Future<void> identify(String userId, [Map<String, Object>? traits]) async {
    await Posthog().identify(userId: userId, userProperties: traits);
  }

  static Future<void> screen(String name, [Map<String, Object>? props]) async {
    await Posthog().screen(screenName: name, properties: props);
  }

  static Future<bool> featureFlag(String key) async => Posthog().isFeatureEnabled(key);
}
