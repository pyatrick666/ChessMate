import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_settings.dart';
import '../providers/settings_provider.dart';
import '../widgets/ad_banner.dart';
import 'game_screen.dart';
import 'how_to_play_screen.dart';
import 'settings_screen.dart';
import 'online_lobby_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _modeLabel(GameMode mode) {
    return switch (mode) {
      GameMode.humanVsAi => 'Vs AI',
      GameMode.humanVsHuman => '2 Players',
      GameMode.online => 'Online',
    };
  }

  String _difficultyLabel(Difficulty difficulty) {
    return switch (difficulty) {
      Difficulty.easy => 'Easy',
      Difficulty.medium => 'Medium',
      Difficulty.hard => 'Hard',
    };
  }

  IconData _difficultyIcon(Difficulty difficulty) {
    return switch (difficulty) {
      Difficulty.easy => Icons.sentiment_satisfied_alt_outlined,
      Difficulty.medium => Icons.bolt_outlined,
      Difficulty.hard => Icons.local_fire_department_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final gameSettings = settings.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'ChessMate',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Theme',
            onPressed: settings.toggleTheme,
            icon: Icon(
              settings.darkMode ? Icons.light_mode : Icons.dark_mode,
            ),
          ),
          IconButton(
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const SettingsScreen(),
              ),
            ),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              children: [
                Row(
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF6366F1),
                            Color(0xFF8B5CF6),
                          ],
                        ),
                      ),
                      child: const Text(
                        '♞',
                        style: TextStyle(
                          fontSize: 36,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ready to play?',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Choose your mode and difficulty.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 26),
                Text(
                  'VS MODE',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<GameMode>(
                  segments: const [
                    ButtonSegment<GameMode>(
                      value: GameMode.humanVsAi,
                      icon: Icon(Icons.smart_toy_outlined),
                      label: Text('Vs AI'),
                    ),
                    ButtonSegment<GameMode>(
                      value: GameMode.humanVsHuman,
                      icon: Icon(Icons.people_outline),
                      label: Text('Local'),
                    ),
                    ButtonSegment<GameMode>(
                      value: GameMode.online,
                      icon: Icon(Icons.public),
                      label: Text('Online'),
                    ),
                  ],
                  selected: {gameSettings.mode},
                  onSelectionChanged: (selection) {
                    settings.setMode(selection.first);
                  },
                ),
                const SizedBox(height: 24),
                Text(
                  'DIFFICULTY',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.1,
                      ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: Difficulty.values.map((difficulty) {
                    final selected = gameSettings.difficulty == difficulty;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: difficulty == Difficulty.hard ? 0 : 8,
                        ),
                        child: _DifficultyCard(
                          label: _difficultyLabel(difficulty),
                          icon: _difficultyIcon(difficulty),
                          selected: selected,
                          enabled: gameSettings.mode == GameMode.humanVsAi,
                          onTap: () => settings.setDifficulty(difficulty),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 26),
                FilledButton.icon(
                  onPressed: () {
                    if (gameSettings.mode == GameMode.online) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const OnlineLobbyScreen(),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const GameScreen(),
                        ),
                      );
                    }
                  },
                  icon: Icon(
                    gameSettings.mode == GameMode.online
                        ? Icons.public
                        : Icons.play_arrow_rounded,
                  ),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      gameSettings.mode == GameMode.online
                          ? 'Online Lobby'
                          : 'Start Game',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HowToPlayScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.menu_book_outlined),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 13),
                    child: Text('How to Play'),
                  ),
                ),
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.tune_outlined),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '${_modeLabel(gameSettings.mode)}'
                            '${gameSettings.mode == GameMode.humanVsAi ? ' • ${_difficultyLabel(gameSettings.difficulty)}' : ''}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.coffee_outlined,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Support the Developer',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Enjoying ChessMate? You can support future updates with eSewa or Khalti.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showSupportDialog(
                                  context,
                                  'eSewa',
                                ),
                                icon: const Icon(Icons.account_balance_wallet_outlined),
                                label: const Text('eSewa'),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _showSupportDialog(
                                  context,
                                  'Khalti',
                                ),
                                icon: const Icon(Icons.payments_outlined),
                                label: const Text('Khalti'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 22),
                const Center(child: AdBanner()),
              ],
            ),
          ),
        ),
      ),
    );
  }
  void _showSupportDialog(BuildContext context, String provider) {
    const walletNumber = '+977 9866805775';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.coffee_outlined),
            SizedBox(width: 10),
            Text('Support with $provider'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thank you for supporting ChessMate!',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 10),
            Text(
              'Send a voluntary donation using your $provider mobile wallet.',
            ),
            SizedBox(height: 16),
            Text('$provider wallet number'),
            SizedBox(height: 4),
            SelectableText(
              walletNumber,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(text: walletNumber),
              );
              if (dialogContext.mounted) {
                ScaffoldMessenger.of(dialogContext).showSnackBar(
                  const SnackBar(content: Text('Wallet number copied.')),
                );
              }
            },
            child: const Text('Copy Number'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

}

class _DifficultyCard extends StatelessWidget {
  const _DifficultyCard({
    required this.label,
    required this.icon,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Opacity(
      opacity: enabled ? 1 : 0.45,
      child: Material(
        color: selected
            ? color.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            constraints: const BoxConstraints(minHeight: 92),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? color : Colors.transparent,
                width: selected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: selected ? color : null),
                const SizedBox(height: 7),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.bold : FontWeight.w600,
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
