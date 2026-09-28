import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/online_game_provider.dart';
import '../widgets/ad_banner.dart';
import '../widgets/online_chess_board.dart';

class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({super.key, required this.online});

  final OnlineGameProvider online;
  @override State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  late final OnlineGameProvider _online;
  StreamSubscription<Map<String, dynamic>>? _events;

  @override
  void initState() {
    super.initState();
    _online = widget.online;
    _events = _online.service.events.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'opponent_left') {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Your opponent disconnected.')));
      } else if (event['type'] == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(event['message']?.toString() ?? 'Server error.')));
      }
    });
  }

  @override
  void dispose() { _events?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _online,
      child: Consumer<OnlineGameProvider>(
        builder: (context, online, _) {
          final connected = online.opponentConnected;
          final status = online.gameStatus;
          return Scaffold(
            appBar: AppBar(
              title: Text(online.roomCode == null ? 'Online Chess' : 'Room ${online.roomCode}'),
              centerTitle: true,
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardSize = [constraints.maxWidth, constraints.maxHeight - 220]
                      .reduce((a, b) => a < b ? a : b).clamp(220.0, 720.0).toDouble();
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      children: [
                        _PlayerCard(name: online.opponentName ?? 'Opponent', subtitle: connected ? 'Connected' : 'Waiting for opponent…', icon: Icons.person_outline),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: boardSize,
                          height: boardSize,
                          child: online.fen == null
                              ? const Center(child: CircularProgressIndicator())
                              : OnlineChessBoard(
                                  fen: online.fen!,
                                  blackAtBottom: online.playerColor == 'black',
                                  onMove: (from, to) => online.sendMove(from: from, to: to),
                                ),
                        ),
                        const SizedBox(height: 10),
                        _PlayerCard(name: online.playerName ?? 'You', subtitle: online.playerColor == null ? 'Connecting…' : (online.playerColor == 'white' ? 'White' : 'Black'), icon: Icons.account_circle_outlined),
                        const SizedBox(height: 12),
                        if (status != null)
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Text(
                                    status == 'checkmate'
                                        ? 'CHECKMATE'
                                        : status == 'draw'
                                            ? 'DRAW'
                                            : status,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  if (online.winner != null) ...[
                                    const SizedBox(height: 4),
                                    Text('Winner: ${online.winner}'),
                                  ],
                                  const SizedBox(height: 10),
                                  FilledButton.icon(
                                    onPressed: online.roomCode == null ? null : online.rematch,
                                    icon: const Icon(Icons.replay),
                                    label: const Text('Play Again'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        if (online.drawOffered)
                          Card(
                            child: ListTile(
                              leading: const Icon(Icons.handshake_outlined),
                              title: const Text('Your opponent offered a draw'),
                              trailing: FilledButton(
                                onPressed: online.acceptDraw,
                                child: const Text('Accept'),
                              ),
                            ),
                          ),
                        const SizedBox(height: 8),
                        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          OutlinedButton.icon(onPressed: online.roomCode == null ? null : online.resign, icon: const Icon(Icons.flag_outlined), label: const Text('Resign')),
                          const SizedBox(width: 10),
                          OutlinedButton.icon(onPressed: online.roomCode == null ? null : online.offerDraw, icon: const Icon(Icons.handshake_outlined), label: const Text('Offer Draw')),
                        ]),
                        const SizedBox(height: 8),
                        const AdBanner(),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({required this.name, required this.subtitle, required this.icon});
  final String name; final String subtitle; final IconData icon;
  @override Widget build(BuildContext context) => Card(child: ListTile(leading: CircleAvatar(child: Icon(icon)), title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(subtitle)));
}