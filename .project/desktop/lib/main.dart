import 'package:flutter/material.dart';

void main() {
  runApp(const InfiniRApp());
}

class InfiniRApp extends StatelessWidget {
  const InfiniRApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InfiniR Desktop',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF581C87), // purple-900
              Color(0xFF1E3A8A), // blue-900
              Color(0xFF000000), // black
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [
                    Color(0xFFC084FC), // purple-400
                    Color(0xFFEC4899), // pink-500
                    Color(0xFF3B82F6), // blue-500
                  ],
                ).createShader(bounds),
                child: const Text(
                  'InfiniR',
                  style: TextStyle(
                    fontSize: 120,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Infinite Reality Awaits',
                style: TextStyle(
                  fontSize: 24,
                  color: Color(0xFFD1D5DB), // gray-300
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
