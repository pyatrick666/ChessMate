import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/online_game_service.dart';

enum OnlineConnectionState {
  disconnected,
  connecting,
  connected,
}

class OnlineGameProvider extends ChangeNotifier {
  OnlineGameProvider({OnlineGameService? service})
      : service = service ?? OnlineGameService() {
    _subscription = this.service.events.listen(_handleEvent);
  }

  final OnlineGameService service;
  StreamSubscription<Map<String, dynamic>>? _subscription;

  OnlineConnectionState _connectionState =
      OnlineConnectionState.disconnected;
  String? _roomCode;
  String? _playerName;
  String? _playerColor;
  String? _opponentName;
  String? _errorMessage;
  bool _opponentConnected = false;
  String? _fen;
  String? _lastMoveFrom;
  String? _lastMoveTo;
  String? _gameStatus;
  String? _winner;
  bool _rematchRequested = false;
  bool _drawOffered = false;

  OnlineConnectionState get connectionState => _connectionState;
  String? get roomCode => _roomCode;
  String? get playerName => _playerName;
  String? get playerColor => _playerColor;
  String? get opponentName => _opponentName;
  String? get errorMessage => _errorMessage;
  bool get opponentConnected => _opponentConnected;
  String? get fen => _fen;
  String? get lastMoveFrom => _lastMoveFrom;
  String? get lastMoveTo => _lastMoveTo;
  String? get gameStatus => _gameStatus;
  String? get winner => _winner;
  bool get rematchRequested => _rematchRequested;
  bool get drawOffered => _drawOffered;

  Future<void> connect(Uri serverUri) async {
    _connectionState = OnlineConnectionState.connecting;
    _errorMessage = null;
    notifyListeners();

    try {
      await service.connect(serverUri: serverUri);
      _connectionState = OnlineConnectionState.connected;
    } catch (error) {
      _connectionState = OnlineConnectionState.disconnected;
      _errorMessage = error.toString();
    }

    notifyListeners();
  }

  void createRoom(String playerName) {
    _playerName = playerName.trim();
    _errorMessage = null;
    service.createRoom(playerName: _playerName!);
    notifyListeners();
  }

  void joinRoom(String roomCode, String playerName) {
    _playerName = playerName.trim();
    _errorMessage = null;
    service.joinRoom(
      roomCode: roomCode.trim().toUpperCase(),
      playerName: _playerName!,
    );
    notifyListeners();
  }

  void sendMove({
    required String from,
    required String to,
    String? promotion,
  }) {
    final code = _roomCode;
    if (code == null) return;

    service.sendMove(
      roomCode: code,
      from: from,
      to: to,
      promotion: promotion,
    );
  }

  void resign() {
    final code = _roomCode;
    if (code != null) {
      service.resign(roomCode: code);
    }
  }

  void offerDraw() {
    final code = _roomCode;
    if (code != null) {
      service.offerDraw(roomCode: code);
    }
  }

  void acceptDraw() {
    final code = _roomCode;
    if (code != null) {
      service.acceptDraw(roomCode: code);
    }
  }

  void rematch() {
    final code = _roomCode;
    if (code != null) {
      service.rematch(roomCode: code);
    }
  }

  Future<void> reconnect(Uri serverUri) async {
    await connect(serverUri);
    if (_roomCode != null && _playerName != null) {
      final color = _playerColor;
      if (color == 'white') {
        service.createRoom(playerName: _playerName!);
      } else if (color == 'black') {
        service.joinRoom(roomCode: _roomCode!, playerName: _playerName!);
      }
    }
  }

  void _handleEvent(Map<String, dynamic> event) {
    final type = event['type'];

    switch (type) {
      case 'move':
      case 'rematch_started':
        _fen = event['fen'] as String?;
        _lastMoveFrom = event['from'] as String?;
        _lastMoveTo = event['to'] as String?;
        _winner = event['checkmate'] == true
            ? ((event['turn']?.toString() == 'w') ? 'black' : 'white')
            : null;
        _gameStatus = event['checkmate'] == true
            ? 'checkmate'
            : event['stalemate'] == true
                ? 'stalemate'
                : event['draw'] == true
                    ? 'draw'
                    : null;
        break;
      case 'room_created':
        _roomCode = event['roomCode'] as String?;
        _playerColor = event['color'] as String?;
        _opponentConnected = false;
        break;
      case 'room_joined':
        _roomCode = event['roomCode'] as String?;
        _playerColor = event['color'] as String?;
        _opponentName = event['opponentName'] as String?;
        _opponentConnected = true;
        break;
      case 'opponent_joined':
        _opponentName = event['opponentName'] as String?;
        _opponentConnected = true;
        break;
      case 'opponent_left':
        _opponentConnected = false;
        break;
      case 'resigned':
        final resigned = event['color']?.toString();
        _winner = resigned == 'white' ? 'black' : 'white';
        _gameStatus = '$resigned resigned';
        break;
      case 'draw_offered':
        _drawOffered = true;
        break;
      case 'rematch_requested':
        _rematchRequested = true;
        break;
      case 'rematch_waiting':
        _rematchRequested = false;
        break;
      case 'draw_accepted':
        _drawOffered = false;
        _gameStatus = 'draw';
        break;
      case 'error':
        _errorMessage = event['message']?.toString();
        break;
      case 'disconnected':
        _connectionState = OnlineConnectionState.disconnected;
        _opponentConnected = false;
        break;
    }

    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    service.dispose();
    super.dispose();
  }
}
