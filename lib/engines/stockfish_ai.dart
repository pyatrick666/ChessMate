import 'dart:async';
import 'dart:io';

import 'package:chess/chess.dart';
import 'package:stockfish_flutter_plus/stockfish_flutter_plus.dart';

/// On-device Stockfish engine wrapper.
///
/// The engine runs outside Flutter's UI isolate, so deep searches do not
/// freeze the board. Stockfish is configured at full strength (Skill Level 20)
/// and the difficulty setting controls how long it is allowed to think.
class StockfishAi {
  Stockfish? _engine;
  Future<void>? _readyFuture;
  bool _disposed = false;

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

    engine.stdin = 'setoption name Threads value ${_recommendedThreads()}';
    engine.stdin = 'setoption name Hash value 64';
    engine.stdin = 'setoption name Skill Level value 20';
    engine.stdin = 'setoption name MultiPV value 1';
    engine.stdin = 'isready';

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
  }

  Future<String?> findBestMove(
    Chess position, {
    required int moveTimeMs,
  }) async {
    await _ensureReady();

    final engine = _engine;
    if (engine == null || _disposed) return null;

    final completer = Completer<String?>();

    late final StreamSubscription<String> subscription;
    subscription = engine.stdout.listen((line) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('bestmove ')) return;

      final parts = trimmed.split(RegExp(r'\s+'));
      final move = parts.length > 1 ? parts[1] : null;

      if (!completer.isCompleted) {
        completer.complete(move == '0000' ? null : move);
      }
    });

    try {
      engine.stdin = 'position fen ${position.fen}';
      engine.stdin = 'go movetime $moveTimeMs';

      return await completer.future.timeout(
        Duration(milliseconds: moveTimeMs + 4000),
        onTimeout: () {
          engine.stdin = 'stop';
          return null;
        },
      );
    } finally {
      await subscription.cancel();
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    final engine = _engine;
    _engine = null;

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
