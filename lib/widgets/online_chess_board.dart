import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

class OnlineChessBoard extends StatefulWidget {
  const OnlineChessBoard({super.key, required this.fen, required this.onMove, this.blackAtBottom = false});
  final String? fen;
  final void Function(String from, String to) onMove;
  final bool blackAtBottom;
  @override State<OnlineChessBoard> createState() => _OnlineChessBoardState();
}

class _OnlineChessBoardState extends State<OnlineChessBoard> {
  String? _selected;

  @override Widget build(BuildContext context) {
    final game = chess.Chess();
    if (widget.fen != null && widget.fen!.trim().isNotEmpty) { try { game.load(widget.fen!); } catch (_) {} }
    return LayoutBuilder(builder: (context, constraints) {
      final size = constraints.biggest.shortestSide;
      return SizedBox(width: size, height: size, child: Column(children: List.generate(8, (row) => Expanded(child: Row(children: List.generate(8, (col) {
        final boardRow = widget.blackAtBottom ? 7 - row : row;
        final boardCol = widget.blackAtBottom ? 7 - col : col;
        final square = '${String.fromCharCode(97 + boardCol)}${8 - boardRow}';
        final piece = game.get(square);
        final light = (boardRow + boardCol).isEven;
        final selected = _selected == square;
        return Expanded(child: GestureDetector(onTap: () => _tap(game, square), child: Container(color: selected ? const Color(0xffd6b656) : (light ? const Color(0xfff0d9b5) : const Color(0xffb58863)), child: Stack(fit: StackFit.expand, children: [
          if (piece != null) Center(child: Text(_piece(piece), style: const TextStyle(fontSize: 38))),
          if (col == 0) Positioned(left: 2, top: 1, child: Text('${8 - boardRow}', style: const TextStyle(fontSize: 8))),
          if (row == 7) Positioned(right: 2, bottom: 1, child: Text(String.fromCharCode(97 + boardCol), style: const TextStyle(fontSize: 8))),
        ]))));
      }))));
    });
  }

  void _tap(chess.Chess game, String square) {
    if (_selected == null) {
      final piece = game.get(square);
      if (piece != null && piece.color == game.turn) setState(() => _selected = square);
      return;
    }
    final moves = game.generate_moves().where((m) => m.fromAlgebraic == _selected && m.toAlgebraic == square).toList();
    if (moves.isNotEmpty) {
      final from = _selected!;
      setState(() => _selected = null);
      widget.onMove(from, square);
      return;
    }
    final piece = game.get(square);
    setState(() => _selected = piece != null && piece.color == game.turn ? square : null);
  }

  String _piece(chess.Piece p) {
    const white = {'p':'♙','n':'♘','b':'♗','r':'♖','q':'♕','k':'♔'};
    const black = {'p':'♟','n':'♞','b':'♝','r':'♜','q':'♛','k':'♚'};
    final key = p.type.toString().split('.').last.substring(0, 1).toLowerCase();
    return (p.color == chess.Color.WHITE ? white : black)[key] ?? '';
  }
}