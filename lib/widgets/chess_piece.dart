import 'package:chess/chess.dart';
import 'package:flutter/material.dart';

class ChessPieceWidget extends StatelessWidget {
  const ChessPieceWidget({super.key, required this.piece});

  final Piece piece;

  @override
  Widget build(BuildContext context) {
    const glyphs = <String, String>{
      'p': '♟', 'n': '♞', 'b': '♝', 'r': '♜', 'q': '♛', 'k': '♚',
      'P': '♙', 'N': '♘', 'B': '♗', 'R': '♖', 'Q': '♕', 'K': '♔',
    };
    final symbol = piece.color == WHITE ? piece.type.toUpperCase() : piece.type.toLowerCase();
    return Center(
      child: Text(
        glyphs[symbol] ?? '?',
        style: TextStyle(
          fontSize: 36,
          height: 1,
          color: piece.color == WHITE ? Colors.white : const Color(0xFF1A1A1A),
          shadows: const [Shadow(offset: Offset(1, 2), blurRadius: 2, color: Colors.black54)],
        ),
      ),
    );
  }
}
