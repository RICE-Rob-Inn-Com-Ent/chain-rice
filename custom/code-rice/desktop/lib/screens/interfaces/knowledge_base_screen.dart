import 'package:flutter/material.dart';

class KnowledgeBaseScreen extends StatelessWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.black,
              Colors.grey[900]!,
              Colors.black,
            ],
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.library_books,
                size: 64,
                color: Colors.green,
              ),
              SizedBox(height: 16),
              Text(
                'Knowledge Base',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Knowledge Management System',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

