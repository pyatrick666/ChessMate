import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/chess_board.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.read<SettingsProvider>();
    return ChangeNotifierProvider(
      create: (_) => GameProvider(settings),
      child: const _GameView(),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView();

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Game'),
        actions: [
          IconButton(tooltip: 'New game', onPressed: game.newGame, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              children: [
                AppCard(
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        child: Icon(game.thinking ? Icons.psychology : Icons.person_outline, size: 21),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(game.status, style: const TextStyle(fontWeight: FontWeight.w700))),
                      if (game.thinking) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const ChessBoard(),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: game.thinking ? null : game.undo, icon: const Icon(Icons.undo), label: const Text('Undo'))),
                    const SizedBox(width: 10),
                    Expanded(child: FilledButton.icon(onPressed: game.newGame, icon: const Icon(Icons.add), label: const Text('New Game'))),
                  ],
                ),
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Moves', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      if (game.history.isEmpty)
                        const Text('No moves yet.')
                      else
                        Wrap(
                          spacing: 8,
                          runSpacing: 5,
                          children: game.history.map((m) => Chip(label: Text('${m.number}. ${m.san}'))).toList(),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
