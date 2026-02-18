import 'package:flutter/material.dart';

void main() {
  runApp(const CeramixDesktopApp());
}

class CeramixDesktopApp extends StatelessWidget {
  const CeramixDesktopApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Ceramix Desktop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Ceramix Desktop App'),
        ),
      ),
    );
}

