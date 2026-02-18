import 'package:flutter/material.dart';

void main() {
  runApp(const MeoWTopiaDesktopApp());
}

class MeoWTopiaDesktopApp extends StatelessWidget {
  const MeoWTopiaDesktopApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'MeoWTopia Desktop',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('MeoWTopia Desktop App'),
        ),
      ),
    );
}

