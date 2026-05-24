import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../navigation/router.dart';

/// Готовий `MaterialApp.router` поверх [riceRouterProvider].
class RiceClientRoot extends ConsumerWidget {
  const RiceClientRoot({super.key, this.title = '.rice'});

  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(riceRouterProvider);
    return MaterialApp.router(
      title: title,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2D6A4F)),
        useMaterial3: true,
      ),
    );
  }
}
