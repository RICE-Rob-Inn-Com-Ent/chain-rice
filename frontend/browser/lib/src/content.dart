import 'package:flutter/material.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';

/// Легкий перегляд HTML без повного WebView (документація, статті).
class RiceHtmlDocument extends StatelessWidget {
  const RiceHtmlDocument({
    super.key,
    required this.html,
    this.baseUrl,
  });

  final String html;
  final Uri? baseUrl;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12),
      child: HtmlWidget(
        html,
        baseUrl: baseUrl,
        enableCaching: true,
        renderMode: RenderMode.column,
      ),
    );
  }
}
