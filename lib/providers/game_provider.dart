import 'dart:async';

import 'package:chess/chess.dart';
import 'package:flutter/foundation.dart';

import '../engines/stockfish_ai.dart';
import '../models/game_settings.dart';
import 'settings_provider.dart';
import '../models/move_record.dart';

class GameProvider extends ChangeNotifier {
  GameProvider(this.settings) {
    _newGame();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickClock());
  }

  final SettingsProvider settings;
  final StockfishAi _stockfishAi = StockfishAi();

  Chess _game = Chess();
  final List<MoveRecord> _history = [];
  String? _selectedSquare;
  Set<String> _legalTargets = {};
  bool _thinking = false;
  int _moveCounter = 0;
  int _aiGeneration = 0;
  Color? _resignedBy;
  Color? _timedOutBy;
  Timer? _clockTimer;
  int _whiteSeconds = 10 * 60;
  int _blackSeconds = 10 * 60;

  Chess get game => _game;
  List<MoveRecord> get history => List.unmodifiable(_history);
  String? get selectedSquare => _selectedSquare;
  Set<String> get legalTargets => _legalTargets;
  bool get thinking => _thinking;
  bool get isGameOver => _game.game_over || _resignedBy != null || _timedOutBy != null;
  int get whiteSeconds => _whiteSeconds;
  int get blackSeconds => _blackSeconds;
  bool get isHumanTurn =>
      settings.settings.mode == GameMode.humanVsHuman || _game.turn == Color.WHITE;

  String get status {
    if (_timedOutBy != null) {
      return _timedOutBy == Color.WHITE
          ? 'Time expired — Black wins'
          : 'Time expired — White wins';
    }
    if (_resignedBy != null) {
      return _resignedBy == Color.WHITE
          ? 'White resigned — Black wins'
          : 'Black resigned — White wins';
    }
    if (_game.in_checkmate) {
      return _game.turn == Color.WHITE
          ? 'Checkmate — Black wins'
          : 'Checkmate — White wins';
    }
    if (_game.in_stalemate) return 'Draw — stalemate';
    if (_game.insufficient_material) return 'Draw — insufficient material';
    if (_game.in_threefold_repetition) return 'Draw — repetition';
    if (_game.in_draw) return 'Draw';
    if (_game.in_check) {
      return '${_game.turn == Color.WHITE ? 'White' : 'Black'} is in check';
    }
    if (_thinking) return 'Master AI is thinking…';
    return '${_game.turn == Color.WHITE ? 'White' : 'Black'} to move';
  }

  String get gameOverTitle {
    if (_timedOutBy != null) return 'TIME’S UP!';
    if (_resignedBy != null) return 'GAME OVER';
    if (_game.in_checkmate) return 'CHECKMATE!';
    return 'DRAW GAME';
  }

  String get gameOverMessage {
    if (_timedOutBy != null) {
      final winner = _timedOutBy == Color.WHITE ? 'Black' : 'White';
      return '$winner wins on time. Great game!';
    }

    if (_resignedBy != null) {
      final winner = _resignedBy == Color.WHITE ? 'Black' : 'White';
      final loser = _resignedBy == Color.WHITE ? 'White' : 'Black';
      return '$winner wins — $loser resigned.';
    }

    if (_game.in_checkmate) {
      final winner = _game.turn == Color.WHITE ? 'Black' : 'White';
      return '$winner wins by checkmate! Brilliant game!';
    }

    if (_game.in_stalemate) {
      return 'It’s a stalemate. Nobody wins this one.';
    }
    if (_game.insufficient_material) {
      return 'Draw — there is not enough material to checkmate.';
    }
    if (_game.in_threefold_repetition) {
      return 'Draw — the same position occurred three times.';
    }
    return 'It’s a draw. Well played by both sides!';
  }

  void newGame() {
    _newGame();
    notifyListeners();
  }

  void _newGame() {
    _aiGeneration++;
    _game = Chess();
    _history.clear();
    _selectedSquare = null;
    _legalTargets = {};
    _thinking = false;
    _moveCounter = 0;
    _resignedBy = null;
    _timedOutBy = null;
    _whiteSeconds = 10 * 60;
    _blackSeconds = 10 * 60;
  }

  void _tickClock() {
    if (isGameOver) return;
    if (settings.settings.mode == GameMode.online) return;
    if (_game.turn == Color.WHITE) {
      if (_whiteSeconds > 0) _whiteSeconds--;
      if (_whiteSeconds == 0) _timedOutBy = Color.WHITE;
    } else {
      if (_blackSeconds > 0) _blackSeconds--;
      if (_blackSeconds == 0) _timedOutBy = Color.BLACK;
    }
    notifyListeners();
  }

  List<Move> movesFor(String square) {
    return _game.generate_moves().where((m) => m.fromAlgebraic == square).toList();
  }

  void selectSquare(String square) {
    if (_thinking || isGameOver || !isHumanTurn) return;
    final piece = _game.get(square);
    if (_selectedSquare == null) {
      if (piece == null || piece.color != _game.turn) return;
      _selectedSquare = square;
      _legalTargets = movesFor(square).map((m) => m.toAlgebraic).toSet();
      notifyListeners();
      return;
    }

    if (_legalTargets.contains(square)) {
      final candidates = movesFor(_selectedSquare!).where((m) => m.toAlgebraic == square).toList();
      if (candidates.isNotEmpty) {
        playMove(candidates.first);
        return;
      }
    }

    if (piece != null && piece.color == _game.turn) {
      _selectedSquare = square;
      _legalTargets = movesFor(square).map((m) => m.toAlgebraic).toSet();
    } else {
      _selectedSquare = null;
      _legalTargets = {};
    }
    notifyListeners();
  }

  void playMove(Move move) {
    if (_thinking || isGameOver) return;
    final from = move.fromAlgebraic;
    final to = move.toAlgebraic;
    final success = _game.move(move);
    final sanMoves = _game.san_moves();
    final san = success && sanMoves.isNotEmpty ? (sanMoves.last ?? '') : '';
    if (san.isEmpty) return;
    _moveCounter++;
    _history.add(MoveRecord(number: _moveCounter, san: san, from: from, to: to));
    _selectedSquare = null;
    _legalTargets = {};
    notifyListeners();

    if (!_game.game_over &&
        settings.settings.mode == GameMode.humanVsAi &&
        _game.turn == Color.BLACK) {
      unawaited(_makeAiMove());
    }
  }

  int _thinkingTimeForDifficulty() {
    // Keep the AI responsive on phones while still giving harder levels
    // more time to calculate a stronger move.
    return switch (settings.settings.difficulty) {
      Difficulty.easy => 800,
      Difficulty.medium => 1600,
      Difficulty.hard => 2800,
    };
  }

  Move? _moveFromUci(String uci) {
    if (uci.length < 4) return null;
    final from = uci.substring(0, 2);
    final to = uci.substring(2, 4);
    final promotionCode = uci.length >= 5 ? uci[4].toLowerCase() : null;

    final legalMoves = _game.generate_moves();
    for (final move in legalMoves) {
      if (move.fromAlgebraic != from || move.toAlgebraic != to) continue;

      // UCI promotion moves end in q/r/b/n. Match the suffix so Stockfish
      // cannot accidentally select the wrong promotion among four legal moves.
      if (promotionCode != null) {
        final promotion = move.promotion;
        if (promotion == null || promotion.toLowerCase() != promotionCode) {
          continue;
        }
      } else if (move.promotion != null) {
        continue;
      }

      return move;
    }
    return null;
  }

  Future<void> _makeAiMove() async {
    final generation = _aiGeneration;
    _thinking = true;
    notifyListeners();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 180));

      if (generation != _aiGeneration ||
          _game.game_over ||
          settings.settings.mode != GameMode.humanVsAi ||
          _game.turn != Color.BLACK) {
        return;
      }

      final moveUci = await _stockfishAi.findBestMove(
        _game,
        moveTimeMs: _thinkingTimeForDifficulty(),
      );

      if (generation != _aiGeneration ||
          _game.game_over ||
          settings.settings.mode != GameMode.humanVsAi ||
          _game.turn != Color.BLACK) {
        return;
      }

      Move? move;
      if (moveUci != null) {
        move = _moveFromUci(moveUci);
      }

      if (move == null) {
        debugPrint('Stockfish did not return a legal move: $moveUci');
        final legalMoves = _game.generate_moves();
        if (legalMoves.isNotEmpty) {
          move = legalMoves.first;
        }
      }

      if (move != null && !_game.game_over && _game.turn == Color.BLACK) {
        final from = move.fromAlgebraic;
        final to = move.toAlgebraic;
        final success = _game.move(move);

        if (success) {
          final sanMoves = _game.san_moves();
          final san = sanMoves.isNotEmpty ? (sanMoves.last ?? '') : '';

          if (san.isNotEmpty) {
            _moveCounter++;
            _history.add(
              MoveRecord(
                number: _moveCounter,
                san: san,
                from: from,
                to: to,
              ),
            );
          }
        }
      }
    } catch (error, stackTrace) {
      debugPrint('ChessMate Stockfish error: $error');
      debugPrintStack(stackTrace: stackTrace);
    } finally {
      if (generation == _aiGeneration) {
        _thinking = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _aiGeneration++;
    _clockTimer?.cancel();
    _clockTimer = null;
    unawaited(_stockfishAi.dispose());
    super.dispose();
  }

  void resign() {
    if (_thinking || isGameOver) return;
    _resignedBy = _game.turn;
    _selectedSquare = null;
    _legalTargets = {};
    notifyListeners();
  }

  void undo() {
    if (_thinking || _game.history.isEmpty) return;
    _game.undo();
    if (settings.settings.mode == GameMode.humanVsAi && _game.history.isNotEmpty) {
      _game.undo();
    }
    if (_history.isNotEmpty) _history.removeLast();
    if (settings.settings.mode == GameMode.humanVsAi && _history.isNotEmpty) {
      _history.removeLast();
    }
    _moveCounter = _history.length;
    _selectedSquare = null;
    _legalTargets = {};
    notifyListeners();
  }
}
