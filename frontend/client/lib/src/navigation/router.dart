import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:model/lib.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../state/session_provider.dart';
import '../state/system_provider.dart';

part 'router.g.dart';

final class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(this._ref) {
    _subSystem = _ref.listen(systemStateProvider, (_, __) => notifyListeners());
    _subSession = _ref.listen(userSessionProvider, (_, __) => notifyListeners());
  }

  final Ref _ref;
  late final ProviderSubscription<AsyncValue<SystemAtlas?>> _subSystem;
  late final ProviderSubscription<SessionData> _subSession;

  String? redirect(GoRouterState state) {
    final loc = state.matchedLocation;
    final sys = _ref.read(systemStateProvider);
    final session = _ref.read(userSessionProvider);

    final systemRedirect = sys.when<String?>(
      data: (atlas) {
        if (atlas == null) {
          return (loc == '/boot' || loc == '/failure') ? null : '/boot';
        }
        if (loc == '/boot') {
          return '/home';
        }
        return null;
      },
      loading: () => loc == '/boot' ? null : '/boot',
      error: (_, __) => '/failure',
    );
    if (systemRedirect != null) {
      return systemRedirect;
    }

    if (session.status == AuthStatus.unauthenticated) {
      if (loc.startsWith('/home')) {
        return '/sign-in';
      }
    }
    if (session.status == AuthStatus.authenticated && loc == '/sign-in') {
      return '/home';
    }
    return null;
  }

  @override
  void dispose() {
    _subSystem.close();
    _subSession.close();
    super.dispose();
  }
}

/// GoRouter з [ShellRoute] та реактивними redirect від [systemStateProvider] / [userSessionProvider].
@Riverpod(keepAlive: true)
GoRouter riceRouter(Ref ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/boot',
    refreshListenable: refresh,
    redirect: (context, state) => refresh.redirect(state),
    routes: [
      GoRoute(
        path: '/boot',
        builder: (context, state) => const _BootPage(),
      ),
      GoRoute(
        path: '/failure',
        builder: (context, state) => const _FailurePage(),
      ),
      GoRoute(
        path: '/sign-in',
        builder: (context, state) => const _SignInPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => _RiceShell(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const _HomePage(),
          ),
        ],
      ),
    ],
  );
}

class _BootPage extends StatelessWidget {
  const _BootPage();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

class _FailurePage extends StatelessWidget {
  const _FailurePage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('.rice — збій')),
      body: const Center(
        child: Text('Система у стані failure. Перезапустіть клієнт або Guard.'),
      ),
    );
  }
}

class _SignInPage extends ConsumerWidget {
  const _SignInPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Вхід')),
      body: Center(
        child: FilledButton(
          onPressed: () {
            ref.read(userSessionProvider.notifier).setAuthenticated(
                  userId: 'local-dev',
                );
          },
          child: const Text('Увійти (dev)'),
        ),
      ),
    );
  }
}

class _RiceShell extends StatelessWidget {
  const _RiceShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(child: child),
    );
  }
}

class _HomePage extends StatelessWidget {
  const _HomePage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('.rice — головна (Shell)'),
    );
  }
}
