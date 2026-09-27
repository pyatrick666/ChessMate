import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('About ChessMate')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('ChessMate', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Text('A Flutter chess application demonstrating mobile UI development, state management, legal chess rules, move history and a minimax AI with alpha-beta pruning.'),
          SizedBox(height: 20),
          Text('Technology', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Flutter • Dart • Provider • chess 0.8.1'),
        ]),
      ),
    );
  }
}
