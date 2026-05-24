import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'errors.dart';

/// Конфігурація та ініціалізація WebView для .rice BARD.
///
/// Примітка: у `flutter_inappwebview` поле називається [InAppWebViewSettings.hardwareAcceleration],
/// що відповідає намірі «enable hardware acceleration».
abstract final class RiceBrowserSession {
  static const String defaultRiceUserAgentSuffix =
      'RiceBARD/1.0 (Flutter; .rice OS integration)';

  /// Базові налаштування: швидкість, safe browsing, завантаження, JS.
  static InAppWebViewSettings buildSettings({
    bool incognito = false,
    String? userAgent,
    bool safeBrowsingEnabled = true,
  }) {
    return InAppWebViewSettings(
      hardwareAcceleration: true,
      useOnDownloadStart: true,
      safeBrowsingEnabled: safeBrowsingEnabled,
      incognito: incognito,
      userAgent: userAgent ?? '',
      applicationNameForUserAgent: defaultRiceUserAgentSuffix,
      javaScriptEnabled: true,
      domStorageEnabled: true,
      databaseEnabled: true,
      cacheEnabled: !incognito,
      clearSessionCache: incognito,
      thirdPartyCookiesEnabled: !incognito,
      mixedContentMode: MixedContentMode.MIXED_CONTENT_COMPATIBILITY_MODE,
      loadsImagesAutomatically: true,
      blockNetworkImage: false,
      blockNetworkLoads: false,
      useWideViewPort: true,
      loadWithOverviewMode: true,
    );
  }

  /// HTTP(S) / SOCKS проксі для WebView (Android WebView ProxyConfig).
  static Future<void> applyProxy(ProxySettings settings) async {
    try {
      await ProxyController.instance().setProxyOverride(settings: settings);
    } catch (e, st) {
      Error.throwWithStackTrace(
        RiceBrowserException('Не вдалося застосувати проксі.', cause: e),
        st,
      );
    }
  }

  static Future<void> clearProxy() async {
    try {
      await ProxyController.instance().clearProxyOverride();
    } catch (e, st) {
      Error.throwWithStackTrace(
        RiceBrowserException('Не вдалося скинути проксі.', cause: e),
        st,
      );
    }
  }
}
