import 'package:flutter/material.dart';

void main() {
  runApp(const MeoWTopiaMobileApp());
}

class MeoWTopiaMobileApp extends StatelessWidget {
  const MeoWTopiaMobileApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
      title: 'MeoWTopia Mobile',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const Scaffold(
        body: Center(
          child: Text('MeoWTopia Mobile App'),
        ),
      ),
    );
}

