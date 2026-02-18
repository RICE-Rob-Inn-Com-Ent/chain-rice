import 'package:flutter/material.dart';

class CloudManagerScreen extends StatelessWidget {
  const CloudManagerScreen({super.key});

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
                Icons.cloud,
                size: 64,
                color: Colors.orange,
              ),
              SizedBox(height: 16),
              Text(
                'Cloud Manager',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Cloud Infrastructure Management',
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

