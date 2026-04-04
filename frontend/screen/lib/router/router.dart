import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../components/layout/shell.dart';
import '../store/auth.dart';
import 'routes.dart';

// TODO:
// [ ] GoRouter redirect auth; errorBuilder 404; debugLogDiagnostics from ENV — https://pub.dev/documentation/go_router/latest/go_router/GoRouter-class.html
// [ ] deep link DEEP_LINK_URL; rice://{project}
//
Provider<GoRouter> Provider<GoRouter> goRouterProvider = Provider<GoRouter>((ProviderRef<GoRouter> ProviderRef<GoRouter> ref) {
  final AuthState AuthState auth = ref.watch(authStoreProvider);

  return GoRouter(
    initialLocation: Routes.home,
    redirect: (BuildContext context, GoRouterState state) {
      final String String loc = state.matchedLocation;
      if (loc.startsWith('/admin') && !auth.isAuthenticated) {
        return Routes.home;
      }
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: Routes.home,
        builder: (BuildContext context, GoRouterState state) => RiceShell(
            body: Center(
              child: Text(
                'Rice',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
            ),
          ),
      ),
      GoRoute(
        path: Routes.error,
        builder: (BuildContext context, GoRouterState state) => const Scaffold(
            body: Center(child: Text('Error')),
          ),
      ),
    ],
  );
});
