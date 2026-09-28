import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;
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
    final lastMove = game.history.isEmpty ? null : game.history.last;

    return LayoutBuilder(
      builder: (context, constraints) {
        final boardSize = constraints.biggest.shortestSide;
        final squareSize = boardSize / 8;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: const [BoxShadow(blurRadius: 18, spreadRadius: 2, offset: Offset(0, 8), color: Colors.black38)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: boardSize, height: boardSize,
              child: Column(
                children: List.generate(8, (row) => Expanded(child: Row(
                  children: List.generate(8, (col) {
                    final boardRow = blackAtBottom ? 7 - row : row;
                    final boardCol = blackAtBottom ? 7 - col : col;
                    final square = '${String.fromCharCode(97 + boardCol)}${8 - boardRow}';
                    final piece = game.game.get(square);
                    final isLight = (boardRow + boardCol).isEven;
                    final selected = game.selectedSquare == square;
                    final legal = game.legalTargets.contains(square);
                    final isLastMove = square == lastMove?.from || square == lastMove?.to;
                    final isCheckSquare = game.game.in_check && piece != null && piece.type == chess.Chess.KING && piece.color == game.game.turn;

                    return Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => game.selectSquare(square),
                        child: Stack(fit: StackFit.expand, children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            color: selected ? AppConstants.selectedSquare : isLastMove ? AppConstants.lastMoveSquare : (isLight ? AppConstants.lightSquare : AppConstants.darkSquare),
                          ),
                          if (isCheckSquare) const DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(colors: [Color(0xFFFF5A5F), Color(0x99FF5A5F), Colors.transparent], stops: [0.15, 0.55, 1]))),
                          if (legal) Center(child: Container(
                            width: piece == null ? squareSize * .20 : squareSize * .72,
                            height: piece == null ? squareSize * .20 : squareSize * .72,
                            decoration: BoxDecoration(shape: BoxShape.circle, color: piece == null ? AppConstants.legalMove : Colors.transparent, border: piece != null ? Border.all(color: AppConstants.legalMove, width: 4) : null),
                          )),
                          if (piece != null) ChessPieceWidget(piece: piece, squareSize: squareSize),
                          if (row == 7) Positioned(right: 4, bottom: 2, child: Text(String.fromCharCode(97 + boardCol), style: TextStyle(fontSize: squareSize * .16, fontWeight: FontWeight.w700, color: isLight ? AppConstants.darkSquare : AppConstants.lightSquare))),
                          if (col == 0) Positioned(left: 4, top: 2, child: Text('${8 - boardRow}', style: TextStyle(fontSize: squareSize * .16, fontWeight: FontWeight.w700, color: isLight ? AppConstants.darkSquare : AppConstants.lightSquare))),
                        ]),
                      ),
                    );
                  }),
                ))),
              ),
            ),
          ),
        );
      },
    );
  }
}