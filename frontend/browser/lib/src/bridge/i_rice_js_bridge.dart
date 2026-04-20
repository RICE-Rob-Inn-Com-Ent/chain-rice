import 'dart:convert';

import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Outbound JS contract — page listens via `window` events or polling.
abstract class IRiceJsBridge {
  Future<void> dispatch(String eventName, Map<String, dynamic> payload);

  void registerHandler(
    String name,
    Future<dynamic> Function(List<dynamic> args) handler,
  );
}

/// Bridges Dart ↔ page using `flutter_inappwebview` handlers + `evaluateJavascript`.
class RiceInAppJsBridge implements IRiceJsBridge {
  RiceInAppJsBridge();

  InAppWebViewController? _controller;

  void attach(InAppWebViewController controller) {
    _controller = controller;
  }

  @override
  Future<void> dispatch(String eventName, Map<String, dynamic> payload) async {
    final ctrl = _controller;
    if (ctrl == null) {
      return;
    }
    final b64 = base64Encode(utf8.encode(jsonEncode(payload)));
    await ctrl.evaluateJavascript(source: '''
      (function() {
        var jsonText = decodeURIComponent(escape(atob('$b64')));
        var detail = JSON.parse(jsonText);
        window.dispatchEvent(new CustomEvent('${eventName.replaceAll("'", '')}', { detail: detail }));
      })();
    ''');
  }

  @override
  void registerHandler(
    String name,
    Future<dynamic> Function(List<dynamic> args) handler,
  ) {
    final ctrl = _controller;
    if (ctrl == null) {
      throw StateError('RiceInAppJsBridge.attach must run before registerHandler');
    }
    ctrl.addJavaScriptHandler(
      handlerName: name,
      callback: handler,
    );
  }

  static Future<void> injectOsShim(InAppWebViewController ctrl) {
    return ctrl.evaluateJavascript(source: '''
      window.riceOS = window.riceOS || {};
      window.riceOS.bridge = function(name, payload) {
        return window.flutter_inappwebview.callHandler(name, payload);
      };
    ''');
  }
}
