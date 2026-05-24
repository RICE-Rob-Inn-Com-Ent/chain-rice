import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:screenshot/screenshot.dart';

import '../src/controller.dart';
import '../src/session.dart';
import '../src/vision.dart';

/// Поверхня браузера .rice: адреса, прогрес, керування, WebView.
class WebViewSurface extends StatefulWidget {
  const WebViewSurface({
    super.key,
    required this.initialUri,
    this.controller,
    this.vision,
    this.incognito = false,
    this.onDownloadStartRequest,
  });

  final Uri initialUri;
  final RiceWebController? controller;
  final WebVision? vision;
  final bool incognito;
  final void Function(InAppWebViewController controller, DownloadStartRequest r)?
      onDownloadStartRequest;

  @override
  State<WebViewSurface> createState() => _WebViewSurfaceState();
}

class _WebViewSurfaceState extends State<WebViewSurface> {
  late final RiceWebController _web;
  late final WebVision _vision;
  late final TextEditingController _address;
  double _progress = 0;

  @override
  void initState() {
    super.initState();
    _web = widget.controller ?? RiceWebController();
    _vision = widget.vision ?? WebVision();
    _address = TextEditingController(text: widget.initialUri.toString());
  }

  @override
  void dispose() {
    _web.unbind();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submitAddress() async {
    final raw = _address.text.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || !uri.hasScheme) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Некоректна адреса')),
        );
      }
      return;
    }
    await _web.loadUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    final settings = RiceBrowserSession.buildSettings(
      incognito: widget.incognito,
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Назад',
                onPressed: () => _web.goBack(),
                icon: const Icon(Icons.arrow_back),
              ),
              IconButton(
                tooltip: 'Вперед',
                onPressed: () => _web.goForward(),
                icon: const Icon(Icons.arrow_forward),
              ),
              IconButton(
                tooltip: 'Оновити',
                onPressed: () => _web.reload(),
                icon: const Icon(Icons.refresh),
              ),
              Expanded(
                child: TextField(
                  controller: _address,
                  decoration: const InputDecoration(
                    hintText: 'https://…',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _submitAddress(),
                ),
              ),
              IconButton(
                tooltip: 'Перейти',
                onPressed: _submitAddress,
                icon: const Icon(Icons.open_in_browser),
              ),
            ],
          ),
        ),
        if (_progress < 1)
          LinearProgressIndicator(
            value: _progress <= 0 ? null : _progress,
            minHeight: 2,
          ),
        Expanded(
          child: Screenshot(
            controller: _vision.screenshot,
            child: InAppWebView(
              initialUrlRequest: URLRequest(url: WebUri.uri(widget.initialUri)),
              initialSettings: settings,
              onWebViewCreated: (c) => _web.bind(c),
              onProgressChanged: (_, p) => setState(() => _progress = p / 100),
              onLoadStop: (_, __) => setState(() => _progress = 1),
              onDownloadStartRequest: widget.onDownloadStartRequest,
            ),
          ),
        ),
      ],
    );
  }
}
