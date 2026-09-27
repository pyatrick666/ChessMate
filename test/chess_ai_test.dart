import 'package:chess/chess.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chessmate/engines/chess_ai.dart';

void main() {
  test('starting position has 20 legal moves', () {
    final game = Chess();
    expect(game.moves().length, 20);
  });

  test('AI returns a legal move from the starting position', () {
    final game = Chess();
    final move = ChessAi(depth: 1).findBestMove(game);
    expect(move, isNotNull);
    expect(game.moves().any((m) => m.fromAlgebraic == move!.fromAlgebraic && m.toAlgebraic == move.toAlgebraic), isTrue);
  });

  test('Fool\'s mate is detected as checkmate', () {
    final game = Chess();
    game.move('f3');
    game.move('e5');
    game.move('g4');
    game.move('Qh4#');
    expect(game.in_checkmate, isTrue);
  });
}
