import 'package:client/client.dart';
import 'package:flutter/material.dart';

import 'generated/rice_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await bootstrapRiceClient(
    posthogApiKey: null,
    posthogHost: null,
  );
  runApp(const ProviderScope(child: CodeRiceApp()));
}

class CodeRiceApp extends ConsumerWidget {
  const CodeRiceApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: RiceSiteConfig.siteTitle,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(RiceSiteConfig.seedColor),
        ),
        useMaterial3: true,
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const CodeRiceHomePage(),
    ),
    GoRoute(
      path: '/app',
      builder: (context, state) => const RiceClientRoot(title: RiceSiteConfig.siteTitle),
    ),
  ],
);

class CodeRiceHomePage extends StatelessWidget {
  const CodeRiceHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(RiceSiteConfig.siteTitle)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              RiceSiteConfig.siteTitle,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 16),
            Text('API: ${RiceSiteConfig.apiBaseUrl}'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/app'),
              child: const Text('Open BARD client'),
            ),
            if (RiceSiteConfig.moduleBrowser)
              TextButton(
                onPressed: () {},
                child: const Text('Browser module enabled'),
              ),
          ],
        ),
      ),
    );
  }
}
