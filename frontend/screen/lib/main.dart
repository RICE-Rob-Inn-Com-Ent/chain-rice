import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'analytics.dart';
import 'app.dart';

// TODO:
// [ ] ensureInitialized; ProviderScope + RiceApp — https://docs.flutter.dev/
// [ ] API_URL, WS_URL, APP_NAME, ENV via --dart-define / String.fromEnvironment — https://dart.dev/libraries/core#string
//
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RiceAnalytics.init();
  runApp(const ProviderScope(child: RiceApp()));
}
