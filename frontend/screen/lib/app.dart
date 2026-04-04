import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/i18n_provider.dart';
import 'providers/theme_provider.dart';
import 'router/router.dart';

// TODO:
// [ ] MaterialApp.router + GoRouter — https://pub.dev/documentation/go_router/latest/
// [ ] AppLifecycleListener: pause/resume WebSocket — https://api.flutter.dev/flutter/widgets/AppLifecycleListener-class.html
//
/// Root app shell — navigation + theme + locale from providers (no hardcoded copy).
class RiceApp extends ConsumerWidget {
  const RiceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(goRouterProvider);
    final ThemeMode themeMode = ref.watch(themeModeProvider);
    final Locale locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'Rice',
      themeMode: themeMode,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0EA5E9)),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0EA5E9),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      locale: locale,
      routerConfig: router,
    );
  }
}
