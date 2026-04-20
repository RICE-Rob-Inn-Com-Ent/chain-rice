import 'package:flutter/material.dart';

import 'main_rice_app.dart';

/// Thin shell so `main.dart` stays free of presentation imports.
class MainRiceAppShell extends StatelessWidget {
  const MainRiceAppShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainRiceApp();
  }
}
