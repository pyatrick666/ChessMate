import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;

class OnlineChessBoard extends StatelessWidget {
  const OnlineChessBoard({super.key, required this.fen, required this.onMove, this.blackAtBottom = false});
  final String? fen;
  final void Function(String from, String to) onMove;
  final bool blackAtBottom;

  @override
  Widget build(BuildContext context) {
    final game = chess.Chess();
    if (fen != null && fen!.trim().isNotEmpty) {
      try { game.load(fen!); } catch (_) {}
    }
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest.shortestSide;
      return SizedBox(width: size, height: size, child: Column(
        children: List.generate(8, (row) => Expanded(child: Row(
          children: List.generate(8, (col) {
            final boardRow = blackAtBottom ? 7 - row : row;
            final boardCol = blackAtBottom ? 7 - col : col;
            final square = '${String.fromCharCode(97 + boardCol)}${8 - boardRow}';
            final piece = game.get(square);
            final light = (boardRow + boardCol).isEven;
            return Expanded(child: _OnlineSquare(
              square: square, piece: piece, light: light,
              onTap: () => _handleTap(context, game, square),
            ));
          }),
        ))),
      ));
    });
  }

  void _handleTap(BuildContext context, chess.Chess game, String square) {
    final state = _OnlineSelection.of(context);
    if (state == null) return;
    if (state.selected == null) {
      final piece = game.get(square);
      if (piece != null && piece.color == game.turn) {
        state.select(square);
      }
      return;
    }
    if (state.selected == square) { state.clear(); return; }
    final moves = game.generate_moves().where((m) => m.fromAlgebraic == state.selected && m.toAlgebraic == square).toList();
    if (moves.isNotEmpty) {
      onMove(state.selected!, square);
      state.clear();
      return;
    }
    final piece = game.get(square);
    if (piece != null && piece.color == game.turn) state.select(square); else state.clear();
  }
}

class _OnlineSelection extends InheritedWidget {
  const _OnlineSelection({required super.child, required this.selected, required this.select, required this.clear});
  final String? selected;
  final void Function(String) select;
  final VoidCallback clear;
  static _OnlineSelection? of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_OnlineSelection>();
  @override bool updateShouldNotify(_OnlineSelection oldWidget) => oldWidget.selected != selected;
}

class _OnlineSquare extends StatelessWidget {
  const _OnlineSquare({required this.square, required this.piece, required this.light, required this.onTap});
  final String square; final chess.Piece? piece; final bool light; final VoidCallback onTap;
  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(color: light ? const Color(0xfff0d9b5) : const Color(0xffb58863),
      child: Stack(fit: StackFit.expand, children: [
        if (piece != null) Center(child: Text(_piece(piece!), style: const TextStyle(fontSize: 38))),
        if (square[1] == '1') Positioned(right: 2, bottom: 1, child: Text(square[0], style: const TextStyle(fontSize: 8))),
        if (square[0] == 'a') Positioned(left: 2, top: 1, child: Text(square[1], style: const TextStyle(fontSize: 8))),
      ]),
    ),
  );
  String _piece(chess.Piece p) {
    const white = {'p':'♙','n':'♘','b':'♗','r':'♖','q':'♕','k':'♔'};
    const black = {'p':'♟','n':'♞','b':'♝','r':'♜','q':'♛','k':'♚'};
    final key = p.type.toString().split('.').last.substring(0,1).toLowerCase();
    return (p.color == chess.Color.WHITE ? white : black)[key] ?? '';
  }
}