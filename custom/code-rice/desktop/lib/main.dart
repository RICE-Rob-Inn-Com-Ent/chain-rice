import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'screens/benchmark/benchmark_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';
import 'screens/interfaces/cloud_manager_screen.dart';
import 'screens/interfaces/data_manager_screen.dart';
import 'screens/interfaces/knowledge_base_screen.dart';
import 'screens/training/training_screen.dart';
import 'widgets/side_nav.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
      title: 'GiPT-1 AGI',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.dark,
        ),
      ),
      routerConfig: _router,
    );
}

final GoRouter _router = GoRouter(
  initialLocation: '/dashboard',
  routes: <RouteBase>[
    ShellRoute(
      builder: (BuildContext context, GoRouterState state, Widget child) => Scaffold(
          body: Row(
            children: <Widget>[
              const SideNav(),
              Expanded(child: child),
            ],
          ),
        ),
      routes: <RouteBase>[
        GoRoute(
          path: '/dashboard',
          builder: (BuildContext context, GoRouterState state) => const DashboardScreen(),
        ),
        GoRoute(
          path: '/training',
          builder: (BuildContext context, GoRouterState state) => const TrainingScreen(),
        ),
        GoRoute(
          path: '/benchmark',
          builder: (BuildContext context, GoRouterState state) => const BenchmarkScreen(),
        ),
        GoRoute(
          path: '/interfaces/data-manager',
          builder: (BuildContext context, GoRouterState state) => const DataManagerScreen(),
        ),
        GoRoute(
          path: '/interfaces/knowledge-base',
          builder: (BuildContext context, GoRouterState state) => const KnowledgeBaseScreen(),
        ),
        GoRoute(
          path: '/interfaces/cloud-manager',
          builder: (BuildContext context, GoRouterState state) => const CloudManagerScreen(),
        ),
      ],
    ),
  ],
);
