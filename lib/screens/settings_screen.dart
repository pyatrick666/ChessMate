import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_settings.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SettingsProvider>();
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Game mode', style: TextStyle(fontWeight: FontWeight.bold)),
          RadioListTile<GameMode>(value: GameMode.humanVsAi, groupValue: p.settings.mode, onChanged: (v) => p.setMode(v!), title: const Text('Human vs AI'), subtitle: const Text('Play White against ChessMate.')),
          RadioListTile<GameMode>(value: GameMode.humanVsHuman, groupValue: p.settings.mode, onChanged: (v) => p.setMode(v!), title: const Text('Human vs Human'), subtitle: const Text('Two players share the device.')),
          const Divider(height: 28),
          const Text('AI difficulty', style: TextStyle(fontWeight: FontWeight.bold)),
          DropdownButtonFormField<Difficulty>(value: p.settings.difficulty, decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Difficulty'), items: Difficulty.values.map((d) => DropdownMenuItem(value: d, child: Text(d.name[0].toUpperCase() + d.name.substring(1)))).toList(), onChanged: (v) => p.setDifficulty(v!)),
          const SizedBox(height: 24),
          const Text('Board orientation', style: TextStyle(fontWeight: FontWeight.bold)),
          SegmentedButton<BoardOrientation>(segments: const [ButtonSegment(value: BoardOrientation.white, label: Text('White'), icon: Icon(Icons.keyboard_arrow_up)), ButtonSegment(value: BoardOrientation.black, label: Text('Black'), icon: Icon(Icons.keyboard_arrow_down))], selected: {p.settings.orientation}, onSelectionChanged: (v) => p.setOrientation(v.first)),
          const SizedBox(height: 24),
          SwitchListTile(title: const Text('Dark theme'), value: p.darkMode, onChanged: (_) => p.toggleTheme()),
        ],
      ),
    );
  }
}
