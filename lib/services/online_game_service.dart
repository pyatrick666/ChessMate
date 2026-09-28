import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

class OnlineGameService {
  OnlineGameService({WebSocketChannel? channel}) : _channel = channel;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;

  final _events = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get events => _events.stream;
  bool get isConnected => _channel != null;

  Future<void> connect({
    required Uri serverUri,
  }) async {
    await disconnect();

    _channel = WebSocketChannel.connect(serverUri);
    await _channel!.ready;

    _subscription = _channel!.stream.listen(
      (message) {
        try {
          final decoded = jsonDecode(message as String);
          if (decoded is Map<String, dynamic>) {
            _events.add(decoded);
          }
        } catch (_) {
          _events.add({
            'type': 'error',
            'message': 'Received an invalid server message.',
          });
        }
      },
      onError: (Object error) {
        _events.add({
          'type': 'error',
          'message': error.toString(),
        });
      },
      onDone: () {
        _events.add({'type': 'disconnected'});
      },
    );
  }

  void send(Map<String, dynamic> message) {
    if (_channel == null) return;
    _channel!.sink.add(jsonEncode(message));
  }

  void createRoom({
    required String playerName,
  }) {
    send({
      'type': 'create_room',
      'playerName': playerName,
    });
  }

  void joinRoom({
    required String roomCode,
    required String playerName,
  }) {
    send({
      'type': 'join_room',
      'roomCode': roomCode,
      'playerName': playerName,
    });
  }

  void sendMove({
    required String roomCode,
    required String from,
    required String to,
    String? promotion,
  }) {
    send({
      'type': 'move',
      'roomCode': roomCode,
      'from': from,
      'to': to,
      if (promotion != null) 'promotion': promotion,
    });
  }

  void resign({required String roomCode}) {
    send({
      'type': 'resign',
      'roomCode': roomCode,
    });
  }

  void offerDraw({required String roomCode}) {
    send({
      'type': 'offer_draw',
      'roomCode': roomCode,
    });
  }

  void acceptDraw({required String roomCode}) {
    send({
      'type': 'accept_draw',
      'roomCode': roomCode,
    });
  }

  void rematch({required String roomCode}) {
    send({
      'type': 'rematch',
      'roomCode': roomCode,
    });
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    await _channel?.sink.close();
    _channel = null;
  }

  Future<void> dispose() async {
    await disconnect();
    await _events.close();
  }
}
