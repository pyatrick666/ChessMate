import 'package:flutter/material.dart';

class HowToPlayScreen extends StatelessWidget {
  const HowToPlayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Select a piece', 'Tap one of your pieces to see its legal destination squares.'),
      ('Make a move', 'Tap a highlighted destination. ChessMate validates the move using the chess rules engine.'),
      ('Watch the AI', 'In Human vs AI mode, the computer replies automatically as Black.'),
      ('Win the game', 'Checkmate wins the game. Stalemate, repetition and insufficient material can result in a draw.'),
    ];
    return Scaffold(
      appBar: AppBar(title: const Text('How to Play')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => Card(child: ListTile(leading: CircleAvatar(child: Text('${i + 1}')), title: Text(items[i].$1, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Padding(padding: const EdgeInsets.only(top: 5), child: Text(items[i].$2)))),
      ),
    );
  }
}
