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
  }

  final SettingsProvider settings;
  Chess _game = Chess();
  final List<MoveRecord> _history = [];
  String? _selectedSquare;
  Set<String> _legalTargets = {};
  bool _thinking = false;
  int _moveCounter = 0;
  Color? _resignedBy;

  Chess get game => _game;
  List<MoveRecord> get history => List.unmodifiable(_history);
  String? get selectedSquare => _selectedSquare;
  Set<String> get legalTargets => _legalTargets;
  bool get thinking => _thinking;
  bool get isGameOver => _game.game_over || _resignedBy != null;
  bool get isHumanTurn =>
      settings.settings.mode == GameMode.humanVsHuman || _game.turn == Color.WHITE;

  String get status {
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
    if (_thinking) return 'Computer is thinking…';
    if (_game.in_check) return '${_game.turn == Color.WHITE ? 'White' : 'Black'} is in check';
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
    await Future<void>.delayed(const Duration(milliseconds: 180));
    final depth = switch (settings.settings.difficulty) {
      Difficulty.easy => 1,
      Difficulty.medium => 2,
      Difficulty.hard => 3,
    };
    final ai = ChessAi(depth: depth);
    final move = ai.findBestMove(_game);
    if (move != null && !_game.game_over) {
      final from = move.fromAlgebraic;
      final to = move.toAlgebraic;
      final success = _game.move(move);
      if (success) {
        _moveCounter++;
        _history.add(MoveRecord(
          number: _moveCounter,
          san: (_game.san_moves().last ?? ''),
          from: from,
          to: to,
        ));
      }
    }
    _thinking = false;
    notifyListeners();
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
