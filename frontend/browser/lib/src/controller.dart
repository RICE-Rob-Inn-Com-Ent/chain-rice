import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'errors.dart';

/// Контекст сторінки для SAGE / SMITH (мета + основний текст).
class PageContext {
  const PageContext({
    required this.href,
    required this.title,
    required this.description,
    required this.lang,
    required this.mainText,
    required this.meta,
  });

  final String href;
  final String title;
  final String description;
  final String lang;
  final String mainText;
  final Map<String, String> meta;

  Map<String, dynamic> toJson() => {
        'href': href,
        'title': title,
        'description': description,
        'lang': lang,
        'mainText': mainText,
        'meta': meta,
      };
}

/// Обгортка над [InAppWebViewController]: навігація, JS, пошук, куки.
class RiceWebController {
  InAppWebViewController? _engine;

  InAppWebViewController? get engine => _engine;

  bool get isReady => _engine != null;

  void bind(InAppWebViewController controller) {
    _engine = controller;
  }

  void unbind() {
    _engine = null;
  }

  Future<void> loadUrl(Uri uri) async {
    final c = _engine;
    if (c == null) {
      throw RiceBrowserException('WebView ще не готовий (bind не викликано).');
    }
    try {
      await c.loadUrl(
        urlRequest: URLRequest(url: WebUri.uri(uri)),
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        RiceBrowserException('Помилка завантаження URL.', cause: e),
        st,
      );
    }
  }

  Future<void> reload() async {
    final c = _engine;
    if (c == null) {
      throw RiceBrowserException('WebView ще не готовий.');
    }
    try {
      await c.reload();
    } catch (e, st) {
      Error.throwWithStackTrace(
        RiceBrowserException('Не вдалося оновити сторінку.', cause: e),
        st,
      );
    }
  }

  Future<void> goBack() async {
    final c = _engine;
    if (c == null) return;
    if (await c.canGoBack()) {
      await c.goBack();
    }
  }

  Future<void> goForward() async {
    final c = _engine;
    if (c == null) return;
    if (await c.canGoForward()) {
      await c.goForward();
    }
  }

  Future<void> runJavaScript(String source) async {
    final c = _engine;
    if (c == null) {
      throw RiceBrowserException('WebView ще не готовий.');
    }
    try {
      await c.evaluateJavascript(source: source);
    } catch (e, st) {
      Error.throwWithStackTrace(
        RiceBrowserException('Помилка виконання JavaScript.', cause: e),
        st,
      );
    }
  }

  /// Пошук тексту у WebView (нативний find-in-page).
  Future<void> findOnPage(String query) async {
    final c = _engine;
    if (c == null) {
      throw RiceBrowserException('WebView ще не готовий.');
    }
    if (query.isEmpty) return;
    try {
      // ignore: deprecated_member_use
      await c.findAllAsync(find: query);
    } catch (e, st) {
      Error.throwWithStackTrace(
        RiceBrowserException('Пошук на сторінці не вдався.', cause: e),
        st,
      );
    }
  }

  Future<void> clearFindMatches() async {
    final c = _engine;
    if (c == null) return;
    try {
      // ignore: deprecated_member_use
      await c.clearMatches();
    } catch (_) {/* noop */}
  }

  Future<List<Cookie>> readCookiesFor(Uri page) async {
    final c = _engine;
    if (c == null) {
      throw RiceBrowserException('WebView ще не готовий.');
    }
    try {
      return CookieManager.instance().getCookies(
        url: WebUri.uri(page),
        webViewController: c,
      );
    } catch (e, st) {
      Error.throwWithStackTrace(
        RiceBrowserException('Не вдалося прочитати куки.', cause: e),
        st,
      );
    }
  }

  static const String _extractPageContextJs = r'''
(function() {
  function textOf(el) {
    if (!el) return '';
    return (el.innerText || '').replace(/\s+/g, ' ').trim().slice(0, 80000);
  }
  var metas = {};
  var nodes = document.querySelectorAll('meta');
  for (var i = 0; i < nodes.length; i++) {
    var m = nodes[i];
    var name = m.getAttribute('name') || m.getAttribute('property') || m.getAttribute('itemprop');
    var content = m.getAttribute('content');
    if (name && content) metas[name] = content;
  }
  var main = document.querySelector('main') || document.querySelector('article') || document.body;
  return JSON.stringify({
    href: String(location.href),
    title: String(document.title || ''),
    description: String(metas['description'] || metas['og:description'] || ''),
    lang: String(document.documentElement.lang || ''),
    mainText: textOf(main),
    meta: metas
  });
})()
''';

  /// Витягує метадані та основний текст через JS для подальшого аналізу AI.
  Future<PageContext?> extractPageContext() async {
    final c = _engine;
    if (c == null) {
      throw RiceBrowserException('WebView ще не готовий.');
    }
    try {
      final raw = await c.evaluateJavascript(source: _extractPageContextJs);
      final text = _stringifyJsResult(raw);
      if (text == null || text.isEmpty) {
        return null;
      }
      final map = jsonDecode(text) as Map<String, dynamic>;
      final meta = <String, String>{};
      final metaRaw = map['meta'];
      if (metaRaw is Map) {
        metaRaw.forEach((k, v) {
          if (k != null && v != null) {
            meta['$k'] = '$v';
          }
        });
      }
      return PageContext(
        href: '${map['href'] ?? ''}',
        title: '${map['title'] ?? ''}',
        description: '${map['description'] ?? ''}',
        lang: '${map['lang'] ?? ''}',
        mainText: '${map['mainText'] ?? ''}',
        meta: meta,
      );
    } catch (e, st) {
      if (e is RiceBrowserException) rethrow;
      Error.throwWithStackTrace(
        RiceBrowserException('extractPageContext: збій парсингу або JS.', cause: e),
        st,
      );
    }
  }

  /// PNG з нативного WebView (краще за RepaintBoundary для PlatformView).
  Future<Uint8List?> captureNativeViewportPng({
    ScreenshotConfiguration? screenshotConfiguration,
  }) async {
    final c = _engine;
    if (c == null) {
      throw RiceBrowserException('WebView ще не готовий.');
    }
    try {
      return c.takeScreenshot(screenshotConfiguration: screenshotConfiguration);
    } catch (e, st) {
      Error.throwWithStackTrace(
        RiceBrowserException('Нативний знімок WebView не вдався.', cause: e),
        st,
      );
    }
  }

  static String? _stringifyJsResult(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      final s = value.trim();
      if (s.startsWith('"') && s.endsWith('"') && s.length >= 2) {
        try {
          final inner = jsonDecode(s);
          if (inner is String) return inner;
        } catch (_) {/* keep original */}
      }
      return s;
    }
    return value.toString();
  }
}
