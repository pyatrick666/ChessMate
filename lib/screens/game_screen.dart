import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/game_settings.dart';
import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/chess_board.dart';
import '../widgets/interstitial_ad_manager.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameProvider _game;
  final InterstitialAdManager _interstitial = InterstitialAdManager();
  bool _gameOverAdShown = false;
  bool _gameOverDialogShown = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _game = GameProvider(context.read<SettingsProvider>());
    _game.addListener(_onGameChanged);
    _interstitial.load();
  }

  void _onGameChanged() {
    if (!_game.isGameOver || _gameOverDialogShown || !mounted) return;
    _gameOverDialogShown = true;

    // Never make the game-over UI depend on an ad callback.
    // A delayed/failed ad must not prevent the result dialog from appearing.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _showGameOverDialog();
    });
  }

  void _showGameOverDialog() {
    final status = _game.status;
    final isCheckmate = _game.game.in_checkmate;
    final title = isCheckmate ? 'CHECKMATE!' : 'GAME OVER';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: Text(title, textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Text(status, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17)),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _gameOverDialogShown = false;
                _gameOverAdShown = false;
                _game.newGame();
                _interstitial.load();
                // Show an interstitial only after the result dialog has
                // already been dismissed and the new game is responsive.
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && !_gameOverAdShown) {
                    _gameOverAdShown = true;
                    _interstitial.show();
                  }
                });
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Play Again'),
            ),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(dialogContext).pop();
                if (mounted) Navigator.of(context).pop();
              },
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveHistory() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        final moves = _game.history;
        return SafeArea(
          child: SizedBox(
            height: 360,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Move History',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: moves.isEmpty
                        ? const Center(child: Text('No moves yet.'))
                        : ListView.builder(
                            itemCount: (moves.length + 1) ~/ 2,
                            itemBuilder: (_, index) {
                              final white = moves[index * 2];
                              final black = index * 2 + 1 < moves.length
                                  ? moves[index * 2 + 1]
                                  : null;
                              return ListTile(
                                dense: true,
                                leading: CircleAvatar(
                                  radius: 14,
                                  child: Text('${white.number}'),
                                ),
                                title: Text(
                                  black == null
                                      ? '${white.san}  …'
                                      : '${white.san}    ${black.san}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _confirmResign() {
    if (_game.isGameOver || _game.thinking) return;
    final side = _game.game.turn == chess.Color.WHITE ? 'White' : 'Black';

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Resign game?'),
        content: Text('Are you sure ${side} wants to resign?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _game.resign();
            },
            child: const Text('Resign'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _game.dispose();
    _interstitial.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _game,
      child: Consumer<GameProvider>(
        builder: (context, game, _) {
          final settings = context.read<SettingsProvider>().settings;
          final local = settings.mode == GameMode.humanVsHuman;
          final turnIsWhite = game.game.turn == chess.Color.WHITE;

          return PopScope(
            canPop: !game.thinking,
            child: Scaffold(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              appBar: AppBar(
                title: Text(local ? 'Local Multiplayer' : 'ChessMate'),
                centerTitle: true,
                leading: IconButton(
                  tooltip: 'Back',
                  onPressed: game.thinking ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Move history',
                    onPressed: _showMoveHistory,
                    icon: const Icon(Icons.history),
                  ),
                ],
              ),
              body: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxHeight < 700;
                    final reserved = compact ? 150.0 : 190.0;
                    final available = constraints.maxHeight - reserved;
                    final boardSize = [
                      constraints.maxWidth,
                      available,
                    ].reduce((a, b) => a < b ? a : b).clamp(220.0, 720.0).toDouble();

                    return Center(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _PlayerCard(
                              name: local ? 'Black' : 'Computer',
                              piece: '♚',
                              active: !game.isGameOver && !turnIsWhite,
                              isBlack: true,
                            ),
                            const SizedBox(height: 8),
                            SizedBox(
                              width: boardSize,
                              height: boardSize,
                              child: const ChessBoard(),
                            ),
                            const SizedBox(height: 8),
                            _PlayerCard(
                              name: 'White',
                              piece: '♔',
                              active: !game.isGameOver && turnIsWhite,
                              isBlack: false,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              game.status,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: game.game.in_check
                                    ? Theme.of(context).colorScheme.error
                                    : null,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                OutlinedButton.icon(
                                  onPressed: game.isGameOver || game.thinking
                                      ? null
                                      : _confirmResign,
                                  icon: const Icon(Icons.flag_outlined),
                                  label: const Text('Resign'),
                                ),
                                const SizedBox(width: 10),
                                OutlinedButton.icon(
                                  onPressed: game.history.isEmpty || game.thinking
                                      ? null
                                      : game.undo,
                                  icon: const Icon(Icons.undo),
                                  label: const Text('Undo'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.name,
    required this.piece,
    required this.active,
    required this.isBlack,
  });

  final String name;
  final String piece;
  final bool active;
  final bool isBlack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 720),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        color: active
            ? primary.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active ? primary : theme.dividerColor.withValues(alpha: 0.25),
          width: active ? 1.6 : 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: isBlack ? Colors.black87 : Colors.white,
            child: Text(
              piece,
              style: TextStyle(
                fontSize: 25,
                color: isBlack ? Colors.white : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          if (active)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 9, color: primary),
                const SizedBox(width: 5),
                const Text('Your turn'),
              ],
            ),
        ],
      ),
    );
  }
}
