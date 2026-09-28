import 'package:chess/chess.dart' as chess;
import 'package:flutter/material.dart';

class ChessPieceWidget extends StatelessWidget {
  const ChessPieceWidget({super.key, required this.piece, required this.squareSize});
  final chess.Piece piece;
  final double squareSize;

  @override
  Widget build(BuildContext context) {
    const glyphs = <String, String>{'p':'♟','n':'♞','b':'♝','r':'♜','q':'♛','k':'♚','P':'♙','N':'♘','B':'♗','R':'♖','Q':'♕','K':'♔'};
    final symbol = piece.color == chess.Color.WHITE ? piece.type.toUpperCase() : piece.type.toLowerCase();
    final isWhite = piece.color == chess.Color.WHITE;
    return Center(child: FittedBox(fit: BoxFit.contain, child: Text(
      glyphs[symbol] ?? '?',
      style: TextStyle(fontFamily: 'DejaVu Sans', fontSize: squareSize * .82, height: .95, color: isWhite ? const Color(0xFFF7F7F7) : const Color(0xFF171717),
        shadows: isWhite ? const [Shadow(offset: Offset(0,2), blurRadius: 1, color: Colors.black87), Shadow(offset: Offset(1,3), blurRadius: 4, color: Colors.black45)] : const [Shadow(offset: Offset(0,2), blurRadius: 2, color: Colors.white38), Shadow(offset: Offset(1,3), blurRadius: 4, color: Colors.black54)],
      ),
    )));
  }
}