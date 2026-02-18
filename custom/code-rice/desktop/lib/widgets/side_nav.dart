import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SideNav extends StatelessWidget {
  const SideNav({super.key});

  @override
  Widget build(BuildContext context) {
    final String String currentPath = GoRouterState.of(context).uri.path;

    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          right: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Column(
        children: <Widget>[
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            child: const Text(
              'GiPT-1',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.purple,
              ),
            ),
          ),
          const Divider(color: Colors.grey),

          // Navigation Links
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: <Widget>[
                _NavItem(
                  icon: Icons.dashboard,
                  label: 'Dashboard',
                  path: '/dashboard',
                  isActive: currentPath == '/dashboard',
                ),
                _NavItem(
                  icon: Icons.science,
                  label: 'Geny',
                  path: '/training',
                  isActive: currentPath == '/training',
                ),
                _NavItem(
                  icon: Icons.bar_chart,
                  label: 'Benchmark',
                  path: '/benchmark',
                  isActive: currentPath == '/benchmark',
                ),
                const Divider(color: Colors.grey, height: 32),
                _NavItem(
                  icon: Icons.storage,
                  label: 'Data Manager',
                  path: '/interfaces/data-manager',
                  isActive: currentPath == '/interfaces/data-manager',
                ),
                _NavItem(
                  icon: Icons.library_books,
                  label: 'Knowledge Base',
                  path: '/interfaces/knowledge-base',
                  isActive: currentPath == '/interfaces/knowledge-base',
                ),
                _NavItem(
                  icon: Icons.cloud,
                  label: 'Cloud Manager',
                  path: '/interfaces/cloud-manager',
                  isActive: currentPath == '/interfaces/cloud-manager',
                ),
              ],
            ),
          ),

          // Footer
          const Divider(color: Colors.grey),
          Container(
            padding: const EdgeInsets.all(16),
            child: const Column(
              children: <Widget>[
                Text(
                  '© 2025 Code-Rice',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                SizedBox(height: 4),
                Text(
                  'GiPT-1 AGI System',
                  style: TextStyle(fontSize: 8, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {

  const _NavItem({
    required this.icon,
    required this.label,
    required this.path,
    required this.isActive,
  });
  final IconData icon;
  final String label;
  final String path;
  final bool isActive;

  @override
  Widget build(BuildContext context) => Tooltip(
      message: label,
      child: InkWell(
        onTap: () => context.go(path),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? Colors.purple.withOpacity(0.2) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? Border.all(color: Colors.purple, width: 2)
                : null,
          ),
          child: Icon(
            icon,
            color: isActive ? Colors.purple : Colors.grey[400],
            size: 24,
          ),
        ),
      ),
    );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<IconData>('icon', icon));
    properties.add(StringProperty('label', label));
    properties.add(StringProperty('path', path));
    properties.add(DiagnosticsProperty<bool>('isActive', isActive));
  }
}

