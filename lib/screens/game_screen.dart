import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

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

    void showResult() {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showGameOverDialog();
      });
    }

    if (!_gameOverAdShown) {
      _gameOverAdShown = true;
      _interstitial.show(onDismissed: showResult);
    } else {
      showResult();
    }
  }

  void _showGameOverDialog() {
    final status = _game.status;
    final isCheckmate = _game.game.in_checkmate;
    final title = isCheckmate ? 'CHECKMATE!' : 'GAME OVER';

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
            title: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: Text(
              status,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17),
            ),
            actionsAlignment: MainAxisAlignment.center,
            actions: [
              FilledButton.icon(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  _gameOverDialogShown = false;
                  _gameOverAdShown = false;
                  _game.newGame();
                  _interstitial.load();
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
        );
      },
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
          return PopScope(
            canPop: !game.thinking,
            child: Scaffold(
              backgroundColor: Colors.black,
              body: SafeArea(
                top: false,
                bottom: false,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // Always calculate the board from the actual finite
                    // viewport. In portrait the width is the limiting
                    // dimension; in landscape the height is the limiting
                    // dimension. This prevents the 8x8 board from being
                    // clipped on tall/narrow Android screens.
                    final maxWidth = constraints.maxWidth;
                    final maxHeight = constraints.maxHeight;

                    final boardSize = maxHeight.isFinite
                        ? (maxWidth < maxHeight ? maxWidth : maxHeight)
                        : maxWidth;

                    return Center(
                      child: SizedBox(
                        width: boardSize,
                        height: boardSize,
                        child: const ChessBoard(),
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
