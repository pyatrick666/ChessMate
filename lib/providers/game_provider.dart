import 'dart:async';

import 'package:chess/chess.dart';
import 'package:flutter/foundation.dart';

import '../engines/chess_ai.dart';
import '../models/game_settings.dart';
import 'settings_provider.dart';
import '../models/move_record.dart';

class GameProvider extends ChangeNotifier {
  GameProvider(this.settings) {
    _newGame();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) => _tickClock());
  }

  final SettingsProvider settings;
  Chess _game = Chess();
  final List<MoveRecord> _history = [];
  String? _selectedSquare;
  Set<String> _legalTargets = {};
  bool _thinking = false;
  int _moveCounter = 0;
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
      return _timedOutBy == Color.WHITE ? 'Time expired — Black wins' : 'Time expired — White wins';
    }
    if (_resignedBy != null) {
      return _resignedBy == Color.WHITE ? 'White resigned — Black wins' : 'Black resigned — White wins';
    }
    if (_game.in_checkmate) {
      return _game.turn == Color.WHITE ? 'Checkmate — Black wins' : 'Checkmate — White wins';
    }
    if (_game.in_stalemate) return 'Draw — stalemate';
    if (_game.insufficient_material) return 'Draw — insufficient material';
    if (_game.in_threefold_repetition) return 'Draw — repetition';
    if (_game.in_draw) return 'Draw';
    // Keep the check warning visible while the AI is calculating its reply.
    if (_game.in_check) {
      return '${_game.turn == Color.WHITE ? 'White' : 'Black'} is in check';
    }
    if (_thinking) return 'Computer is thinking…';
    return '${_game.turn == Color.WHITE ? 'White' : 'Black'} to move';
  }

  void newGame() {
    _newGame();
    notifyListeners();
  }

  void _newGame() {
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

    if (!_game.game_over && settings.settings.mode == GameMode.humanVsAi && _game.turn == Color.BLACK) {
      unawaited(_makeAiMove());
    }
  }

  Future<void> _makeAiMove() async {
    _thinking = true;
    notifyListeners();

    try {
      // Give Flutter a frame to update the UI before calculating.
      await Future<void>.delayed(const Duration(milliseconds: 180));

      if (_game.game_over || settings.settings.mode != GameMode.humanVsAi) {
        return;
      }

      final depth = switch (settings.settings.difficulty) {
        Difficulty.easy => 1,
        Difficulty.medium => 2,
        Difficulty.hard => 3,
      };

      Move? move;

      try {
        final ai = ChessAi(depth: depth);
        move = ai.findBestMove(_game);
      } catch (error, stackTrace) {
        debugPrint('ChessMate AI error: $error');
        debugPrintStack(stackTrace: stackTrace);
      }

      // Always keep the game playable if the search encounters an
      // unexpected runtime error. A legal move is safer than leaving the
      // game permanently stuck on "Computer is thinking…".
      if (move == null && !_game.game_over) {
        final legalMoves = _game.generate_moves();
        if (legalMoves.isNotEmpty) {
          move = legalMoves.first;
          debugPrint('ChessMate AI fallback move used.');
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
    } finally {
      // This must always run, even if the AI throws an exception.
      _thinking = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _clockTimer = null;
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
