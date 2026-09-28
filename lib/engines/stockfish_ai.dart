import 'dart:async';
import 'dart:io';

import 'package:chess/chess.dart';
import 'package:stockfish_flutter_plus/stockfish_flutter_plus.dart';

/// On-device Stockfish engine wrapper.
///
/// Stockfish is initialized only after its native state reaches `ready`.
/// This is important on Android because the plugin starts the native engine
/// asynchronously and UCI commands should not be sent during startup.
class StockfishAi {
  Stockfish? _engine;
  Future<void>? _readyFuture;
  StreamSubscription<String>? _stdoutSubscription;
  Completer<String?>? _bestMoveCompleter;
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

    // The plugin starts the native engine asynchronously. Only send UCI
    // options after it reports ready.
    engine.stdin = 'setoption name Threads value ${_recommendedThreads()}';
    engine.stdin = 'setoption name Hash value 64';
    engine.stdin = 'setoption name Skill Level value 20';
    engine.stdin = 'setoption name MultiPV value 1';
    engine.stdin = 'isready';

    // Keep one stdout listener for the lifetime of the engine. Listening only
    // when a search starts can miss output from a native stream implementation.
    _stdoutSubscription = engine.stdout.listen(_handleEngineOutput);

    // Give the UCI initialization command a moment to be processed.
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }

  void _handleEngineOutput(String line) {
    final trimmed = line.trim();
    if (!trimmed.startsWith('bestmove ')) return;

    final parts = trimmed.split(RegExp(r'\\s+'));
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
      // Reset the UCI game state before loading the current board position.
      engine.stdin = 'stop';
      engine.stdin = 'ucinewgame';
      engine.stdin = 'isready';
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
