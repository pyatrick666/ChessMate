import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/game_settings.dart';
import '../providers/game_provider.dart';
import '../utils/constants.dart';
import 'chess_piece.dart';

class ChessBoard extends StatelessWidget {
  const ChessBoard({super.key});

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final blackAtBottom = game.settings.settings.orientation == BoardOrientation.black;
    return AspectRatio(
      aspectRatio: 1,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 64,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 8),
        itemBuilder: (context, index) {
          final row = index ~/ 8;
          final col = index % 8;
          final boardRow = blackAtBottom ? 7 - row : row;
          final boardCol = blackAtBottom ? 7 - col : col;
          final square = '${String.fromCharCode(97 + boardCol)}${8 - boardRow}';
          final piece = game.game.get(square);
          final isLight = (boardRow + boardCol).isEven;
          final selected = game.selectedSquare == square;
          final legal = game.legalTargets.contains(square);
          return GestureDetector(
            onTap: () => game.selectSquare(square),
            child: Container(
              decoration: BoxDecoration(
                color: selected ? AppConstants.selectedSquare : isLight ? AppConstants.lightSquare : AppConstants.darkSquare,
              ),
              child: Stack(
                children: [
                  if (piece != null) ChessPieceWidget(piece: piece),
                  if (legal)
                    Center(
                      child: Container(
                        width: piece == null ? 12 : 44,
                        height: piece == null ? 12 : 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: piece == null ? null : Border.all(color: Colors.black38, width: 3),
                          color: piece == null ? AppConstants.legalMove : Colors.transparent,
                        ),
                      ),
                    ),
                  if (row == 7)
                    Positioned(
                      right: 3,
                      bottom: 1,
                      child: Text(String.fromCharCode(97 + boardCol), style: TextStyle(fontSize: 9, color: isLight ? Colors.black45 : Colors.white70)),
                    ),
                  if (col == 0)
                    Positioned(
                      left: 3,
                      top: 1,
                      child: Text('${8 - boardRow}', style: TextStyle(fontSize: 9, color: isLight ? Colors.black45 : Colors.white70)),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
