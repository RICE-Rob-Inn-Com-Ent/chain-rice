// TODO:
// [ ] const provider name strings; projectKey(id) cache keys — https://riverpod.dev/docs/concepts2/family
//
/// Namespaced Rice keys — same contract as [frontend/browser/lib/riceKeys.ts].

abstract final class RicePrefixes {
  static const db = 'db.';
  static const ai = 'ai.';
  static const ui = 'ui.';
  static const i18n = 'i18n.';
  static const feature = 'feature.';
}

String riceDbKey(String path) => '${RicePrefixes.db}$path';
String riceAiKey(String path) => '${RicePrefixes.ai}$path';
String riceUiKey(String path) => '${RicePrefixes.ui}$path';
String riceI18nKey(String path) => '${RicePrefixes.i18n}$path';
String riceFeatureKey(String path) => '${RicePrefixes.feature}$path';

bool isRemoteRiceKey(String key) =>
    key.startsWith(RicePrefixes.db) || key.startsWith(RicePrefixes.ai);

// TODO:
// [ ] Optional allowlist via dart-define for production key policies.
// [ ] Map keys to generated protos under frontend/gen/ when available.
