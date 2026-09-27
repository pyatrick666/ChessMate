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

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _game = GameProvider(context.read<SettingsProvider>());
    _game.addListener(_onGameChanged);
    _interstitial.load();
  }

  void _onGameChanged() {
    if (_game.isGameOver && !_gameOverAdShown && mounted) {
      _gameOverAdShown = true;
      _interstitial.show(onDismissed: () {});
    }
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
                    final boardSize = constraints.maxWidth < constraints.maxHeight
                        ? constraints.maxWidth
                        : constraints.maxHeight;

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
