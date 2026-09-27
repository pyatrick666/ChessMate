import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/game_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/chess_board.dart';
import '../widgets/interstitial_ad_manager.dart';

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

class _GameView extends StatefulWidget {
  const _GameView();

  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> {
  final InterstitialAdManager _interstitial = InterstitialAdManager();

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _interstitial.load();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _interstitial.dispose();
    super.dispose();
  }

  void _newGame() {
    final game = context.read<GameProvider>();
    _interstitial.show(
      onDismissed: game.newGame,
    );
  }

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();

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
  }
}
