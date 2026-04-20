import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lang/unit.dart';

import '../providers/rice_state_provider.dart';

/// Root widget — composes localization, theming, and package boundaries.
class MainRiceApp extends ConsumerWidget {
  const MainRiceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(riceSessionStateProvider);

    return TranslationProvider(
      child: Builder(
        builder: (ctx) {
          final t = ctx.t;
          return MaterialApp(
            locale: TranslationProvider.of(ctx).flutterLocale,
            supportedLocales: AppLocaleUtils.supportedLocales,
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            onGenerateTitle: (c) => t.appTitle,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
              useMaterial3: true,
            ),
            home: Scaffold(
              appBar: AppBar(
                title: Text(t.appTitle),
              ),
              body: Center(
                child: Text(
                  '${t.statusOk} · ${session.sessionId.isEmpty ? 'no-session' : session.sessionId}',
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
