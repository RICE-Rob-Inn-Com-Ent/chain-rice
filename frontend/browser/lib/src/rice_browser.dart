import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'bridge/i_rice_js_bridge.dart';

/// Thin, testable host around [InAppWebView] with a typed JS bridge.
class RiceBrowser extends StatefulWidget {
  const RiceBrowser({
    super.key,
    required this.initialUrl,
    this.onReady,
    this.injectOsShim = true,
  });

  final Uri initialUrl;
  final void Function(InAppWebViewController controller, IRiceJsBridge bridge)?
      onReady;
  final bool injectOsShim;

  @override
  State<RiceBrowser> createState() => _RiceBrowserState();
}

class _RiceBrowserState extends State<RiceBrowser> {
  final RiceInAppJsBridge _bridge = RiceInAppJsBridge();

  @override
  Widget build(BuildContext context) {
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl.toString())),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        allowsInlineMediaPlayback: true,
        mediaPlaybackRequiresUserGesture: false,
      ),
      onWebViewCreated: (controller) async {
        _bridge.attach(controller);
        if (widget.injectOsShim) {
          await RiceInAppJsBridge.injectOsShim(controller);
        }
        widget.onReady?.call(controller, _bridge);
      },
    );
  }
}
