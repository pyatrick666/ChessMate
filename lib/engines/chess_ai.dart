import 'dart:math' as math;

import 'package:chess/chess.dart';

/// Lightweight chess AI using minimax, alpha-beta pruning and piece-square tables.
class ChessAi {
  ChessAi({this.depth = 2});

  final int depth;

  static const Map<PieceType, double> _values = {
    PAWN: 100,
    KNIGHT: 320,
    BISHOP: 330,
    ROOK: 500,
    QUEEN: 900,
    KING: 20000,
  };

  static const List<int> _pawnPst = [
    0,0,0,0,0,0,0,0, 50,50,50,50,50,50,50,50,
    10,10,20,30,30,20,10,10, 5,5,10,25,25,10,5,5,
    0,0,0,20,20,0,0,0, 5,-5,-10,0,0,-10,-5,5,
    5,10,10,-20,-20,10,10,5, 0,0,0,0,0,0,0,0,
  ];
  static const List<int> _knightPst = [
    -50,-40,-30,-30,-30,-30,-40,-50, -40,-20,0,0,0,0,-20,-40,
    -30,0,10,15,15,10,0,-30, -30,5,15,20,20,15,5,-30,
    -30,0,15,20,20,15,0,-30, -30,5,10,15,15,10,5,-30,
    -40,-20,0,5,5,0,-20,-40, -50,-40,-30,-30,-30,-30,-40,-50,
  ];
  static const List<int> _bishopPst = [
    -20,-10,-10,-10,-10,-10,-10,-20, -10,0,0,0,0,0,0,-10,
    -10,0,5,10,10,5,0,-10, -10,5,5,10,10,5,5,-10,
    -10,0,10,10,10,10,0,-10, -10,10,10,10,10,10,10,-10,
    -10,5,0,0,0,0,5,-10, -20,-10,-10,-10,-10,-10,-10,-20,
  ];
  static const List<int> _rookPst = [
    0,0,0,5,5,0,0,0, -5,0,0,0,0,0,0,-5, -5,0,0,0,0,0,0,-5,
    -5,0,0,0,0,0,0,-5, -5,0,0,0,0,0,0,-5, -5,0,0,0,0,0,0,-5,
    5,10,10,10,10,10,10,5, 0,0,0,0,0,0,0,0,
  ];
  static const List<int> _queenPst = [
    -20,-10,-10,0,0,-10,-10,-20, -10,0,0,0,0,0,0,-10,
    -10,0,5,5,5,5,0,-10, 0,0,5,5,5,5,0,-5,
    0,0,5,5,5,5,0,-5, -10,5,5,5,5,5,0,-10,
    -10,0,5,0,0,0,0,-10, -20,-10,-10,0,0,-10,-10,-20,
  ];
  static const List<int> _kingPst = [
    -30,-40,-40,-50,-50,-40,-40,-30, -30,-40,-40,-50,-50,-40,-40,-30,
    -30,-40,-40,-50,-50,-40,-40,-30, -30,-40,-40,-50,-50,-40,-40,-30,
    -20,-30,-30,-40,-40,-30,-30,-20, -10,-20,-20,-20,-20,-20,-20,-10,
    20,20,0,0,0,0,20,20, 20,30,10,0,0,10,30,20,
  ];

  Move? findBestMove(Chess position) {
    final moves = position.generate_moves();
    if (moves.isEmpty) return null;

    final maximizing = position.turn == WHITE;
    Move? bestMove;
    var bestScore = maximizing ? -double.infinity : double.infinity;

    for (final move in moves) {
      final next = position.copy();
      next.make_move(move);
      final score = _minimax(next, math.max(0, depth - 1), -double.infinity,
          double.infinity, !maximizing);
      if ((maximizing && score > bestScore) ||
          (!maximizing && score < bestScore)) {
        bestScore = score;
        bestMove = move;
      }
    }
    return bestMove;
  }

  double _minimax(Chess position, int remaining, double alpha, double beta,
      bool maximizing) {
    if (remaining == 0 || position.game_over) return _evaluate(position);
    final moves = position.generate_moves();
    if (maximizing) {
      var value = -double.infinity;
      for (final move in moves) {
        final next = position.copy()..make_move(move);
        value = math.max(value, _minimax(next, remaining - 1, alpha, beta, false));
        alpha = math.max(alpha, value);
        if (alpha >= beta) break;
      }
      return value;
    }
    var value = double.infinity;
    for (final move in moves) {
      final next = position.copy()..make_move(move);
      value = math.min(value, _minimax(next, remaining - 1, alpha, beta, true));
      beta = math.min(beta, value);
      if (alpha >= beta) break;
    }
    return value;
  }

  double _evaluate(Chess game) {
    if (game.in_checkmate) return game.turn == WHITE ? -100000 : 100000;
    if (game.in_draw || game.in_stalemate || game.insufficient_material) return 0;
    var score = 0.0;
    for (var i = 0; i < game.board.length; i++) {
      final piece = game.board[i];
      if (piece == null || (i & 0x88) != 0) continue;
      final file = i & 7;
      final rank = i >> 4;
      final tableIndex = rank * 8 + file;
      final whiteIndex = 56 - (rank * 8) + file;
      final pstIndex = piece.color == WHITE ? whiteIndex : tableIndex;
      final value = (_values[piece.type] ?? 0) + _tableFor(piece.type)[pstIndex];
      score += piece.color == WHITE ? value : -value;
    }
    return score;
  }

  List<int> _tableFor(PieceType type) {
    if (type == PAWN) return _pawnPst;
    if (type == KNIGHT) return _knightPst;
    if (type == BISHOP) return _bishopPst;
    if (type == ROOK) return _rookPst;
    if (type == QUEEN) return _queenPst;
    return _kingPst;
  }
}
