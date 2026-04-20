import 'package:client/unit.dart';
import 'package:content/unit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ContentBootstrap.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MainRiceAppShell(),
    ),
  );
}
