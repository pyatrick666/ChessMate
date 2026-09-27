import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_settings.dart';
import '../providers/settings_provider.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChessMate', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'Theme',
            onPressed: settings.toggleTheme,
            icon: Icon(settings.darkMode ? Icons.light_mode : Icons.dark_mode),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const SizedBox(height: 24),
                Container(
                  width: 100,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
                  ),
                  child: const Text('♞', style: TextStyle(fontSize: 62, color: Colors.white)),
                ),
                const SizedBox(height: 22),
                Text('Play smarter.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('A clean Flutter chess experience with a built-in minimax AI.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 36),
                FilledButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GameScreen())),
                  icon: const Icon(Icons.play_arrow),
                  label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('Start Game', style: TextStyle(fontSize: 16))),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const HowToPlayScreen())),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Text('How to Play')),
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: Color(0xFF6366F1)),
                        const SizedBox(width: 12),
                        Expanded(child: Text('${settings.settings.mode == GameMode.humanVsAi ? 'Human vs AI' : 'Human vs Human'} • ${settings.settings.difficulty.name[0].toUpperCase()}${settings.settings.difficulty.name.substring(1)} difficulty')),
                      ],
                    ),
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
