import 'dart:async';
import 'dart:io';

import 'package:chess/chess.dart';
import 'package:stockfish/stockfish.dart';

/// On-device Stockfish engine wrapper.
///
/// The native engine starts asynchronously. UCI commands are only sent after
/// the plugin reports ready, and every "isready" command is synchronized with
/// a corresponding "readyok" response before a search begins.
class StockfishAi {
  Stockfish? _engine;
  Future<void>? _readyFuture;
  StreamSubscription<String>? _stdoutSubscription;
  Completer<String?>? _bestMoveCompleter;
  Completer<void>? _readyOkCompleter;
  bool _disposed = false;
  bool _searching = false;

  Future<void> _ensureReady() async {
    if (_disposed) {
      throw StateError('Stockfish AI has been disposed.');
    }

    if (_readyFuture == null) {
      _readyFuture = _startEngine();
    }

    try {
      await _readyFuture;
    } catch (_) {
      _readyFuture = null;
      rethrow;
    }
  }

  int _recommendedThreads() {
    final processors = Platform.numberOfProcessors;
    return processors <= 2 ? 1 : (processors - 1).clamp(1, 8);
  }

  Future<void> _startEngine() async {
    if (_disposed) {
      throw StateError('Stockfish AI has been disposed.');
    }

    final engine = Stockfish();
    _engine = engine;

    final deadline = DateTime.now().add(const Duration(seconds: 12));
    while (!_disposed && engine.state.value != StockfishState.ready) {
      if (DateTime.now().isAfter(deadline)) {
        throw TimeoutException('Stockfish did not become ready in time.');
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }

    if (_disposed) {
      throw StateError('Stockfish AI was disposed while starting.');
    }

    _stdoutSubscription = engine.stdout.listen(_handleEngineOutput);

    engine.stdin = 'setoption name Threads value ${_recommendedThreads()}';
    engine.stdin = 'setoption name Hash value 64';
    engine.stdin = 'setoption name Skill Level value 20';
    engine.stdin = 'setoption name MultiPV value 1';

    await _waitForReadyOk();
  }

  Future<void> _waitForReadyOk() async {
    final engine = _engine;
    if (engine == null || _disposed) {
      throw StateError('Stockfish engine is unavailable.');
    }

    final existing = _readyOkCompleter;
    if (existing != null && !existing.isCompleted) {
      await existing.future;
      return;
    }

    final completer = Completer<void>();
    _readyOkCompleter = completer;

    engine.stdin = 'isready';

    try {
      await completer.future.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw TimeoutException('Stockfish did not respond with readyok.');
        },
      );
    } finally {
      if (identical(_readyOkCompleter, completer)) {
        _readyOkCompleter = null;
      }
    }
  }

  void _handleEngineOutput(String line) {
    final trimmed = line.trim();

    if (trimmed == 'readyok') {
      final completer = _readyOkCompleter;
      if (completer != null && !completer.isCompleted) {
        completer.complete();
      }
      return;
    }

    if (!trimmed.startsWith('bestmove ')) return;

    final parts = trimmed.split(RegExp(r'\s+'));
    final move = parts.length > 1 ? parts[1] : null;
    final completer = _bestMoveCompleter;

    if (completer != null && !completer.isCompleted) {
      completer.complete(move == '0000' ? null : move);
    }
  }

  Future<String?> findBestMove(
    Chess position, {
    required int moveTimeMs,
  }) async {
    await _ensureReady();

    final engine = _engine;
    if (engine == null || _disposed) return null;
    if (_searching) {
      throw StateError('Stockfish search already in progress.');
    }

    _searching = true;
    final completer = Completer<String?>();
    _bestMoveCompleter = completer;

    try {
      engine.stdin = 'stop';
      engine.stdin = 'ucinewgame';

      await _waitForReadyOk();

      engine.stdin = 'position fen ${position.fen}';
      engine.stdin = 'go movetime $moveTimeMs';

      return await completer.future.timeout(
        Duration(milliseconds: moveTimeMs + 4000),
        onTimeout: () {
          try {
            engine.stdin = 'stop';
          } catch (_) {}
          return null;
        },
      );
    } finally {
      if (identical(_bestMoveCompleter, completer)) {
        _bestMoveCompleter = null;
      }
      _searching = false;
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _readyFuture = null;

    final engine = _engine;
    _engine = null;
    _bestMoveCompleter = null;
    _readyOkCompleter = null;
    _searching = false;

    await _stdoutSubscription?.cancel();
    _stdoutSubscription = null;

    if (engine != null) {
      try {
        engine.stdin = 'stop';
        engine.stdin = 'quit';
      } catch (_) {
        // The native engine may already be shutting down.
      }
      engine.dispose();
    }
  }
}
