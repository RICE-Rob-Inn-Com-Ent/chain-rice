// TODO:
// [ ] String.fromEnvironment API_URL, WS_URL, APP_NAME, ENV — https://dart.dev/libraries/core#string
// [ ] isProduction / isDevelopment
//
/// Compile-time configuration via `--dart-define`. Mirror browser `NEXT_PUBLIC_*` semantics.
///
/// Example: `flutter run --dart-define=RICE_SMITH_URL=http://localhost:3000`
abstract final class RiceEnv {
  static const smithBaseUrl = String.fromEnvironment(
    'RICE_SMITH_URL',
    defaultValue: '',
  );

  static const appTitle = String.fromEnvironment(
    'RICE_APP_TITLE',
    defaultValue: 'Rice',
  );

  static const defaultLocale = String.fromEnvironment(
    'RICE_DEFAULT_LOCALE',
    defaultValue: 'en',
  );

  static const posthogKey = String.fromEnvironment(
    'RICE_POSTHOG_KEY',
    defaultValue: '',
  );

  static const posthogHost = String.fromEnvironment(
    'RICE_POSTHOG_HOST',
    defaultValue: 'https://app.posthog.com',
  );
}

// TODO:
// [ ] Keep keys in sync with [frontend/browser/lib/env.ts] and Cue-generated .env templates.
// [ ] Add drift cache TTL / connect timeout defines when wiring SMITH.
