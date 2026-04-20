import 'package:flutter/widgets.dart';
import 'package:media_kit/media_kit.dart';

/// One-shot init for heavyweight media stacks (MediaKit, etc.).
class ContentBootstrap {
  static Future<void> ensureInitialized() async {
    WidgetsFlutterBinding.ensureInitialized();
    MediaKit.ensureInitialized();
  }
}
