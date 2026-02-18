import 'package:flutter/material.dart';

void main() {
  runApp(const CeramixMobileApp());
}

class CeramixMobileApp extends StatelessWidget {
  const CeramixMobileApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'Ceramix Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('Ceramix Mobile App'),
        ),
      ),
    );
}

