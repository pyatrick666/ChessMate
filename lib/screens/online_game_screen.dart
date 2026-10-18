import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/online_game_provider.dart';
import '../widgets/ad_banner.dart';
import '../widgets/online_chess_board.dart';

class OnlineGameScreen extends StatefulWidget {
  const OnlineGameScreen({super.key, required this.online});

  final OnlineGameProvider online;

  @override
  State<OnlineGameScreen> createState() => _OnlineGameScreenState();
}

class _OnlineGameScreenState extends State<OnlineGameScreen> {
  late final OnlineGameProvider _online;
  StreamSubscription<Map<String, dynamic>>? _events;
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  bool _chatExpanded = false;
  int _unreadChatCount = 0;

  @override
  void initState() {
    super.initState();
    _online = widget.online;
    _events = _online.service.events.listen((event) {
      if (!mounted) return;
      if (event['type'] == 'opponent_left') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Your opponent disconnected.')),
        );
      } else if (event['type'] == 'error') {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(event['message']?.toString() ?? 'Server error.'),
          ),
        );
      } else if (event['type'] == 'chat_message') {
        if (!_chatExpanded && event['senderColor'] != _online.playerColor) {
          setState(() => _unreadChatCount++);
        }
        if (_chatExpanded) WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_chatScrollController.hasClients) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _events?.cancel();
    _chatController.dispose();
    _chatScrollController.dispose();
    super.dispose();
  }

  void _sendChat(OnlineGameProvider online) {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;
    online.sendChatMessage(text);
    _chatController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _online,
      child: Consumer<OnlineGameProvider>(
        builder: (context, online, _) {
          final connected = online.opponentConnected;
          final status = online.gameStatus;
          final chatMessages = online.chatMessages;
          return Scaffold(
            appBar: AppBar(
              title: Text(
                online.roomCode == null ? 'Online Chess' : 'Room ${online.roomCode}',
              ),
              centerTitle: true,
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final boardSize = [
                    constraints.maxWidth,
                    constraints.maxHeight - 220,
                  ].reduce((a, b) => a < b ? a : b).clamp(220.0, 720.0).toDouble();

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                    child: Column(
                      children: [
                        _PlayerCard(
                          name: online.opponentName ?? 'Opponent',
                          subtitle: connected ? 'Connected' : 'Waiting for opponent…',
                          icon: Icons.person_outline,
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: boardSize,
                          height: boardSize,
                          child: online.fen == null
                              ? const Center(child: CircularProgressIndicator())
                              : OnlineChessBoard(
                                  fen: online.fen!,
                                  blackAtBottom: online.playerColor == 'black',
                                  onMove: (from, to) =>
                                      online.sendMove(from: from, to: to),
                                ),
                        ),
                        const SizedBox(height: 10),
                        _PlayerCard(
                          name: online.playerName ?? 'You',
                          subtitle: online.playerColor == null
                              ? 'Connecting…'
                              : (online.playerColor == 'white' ? 'White' : 'Black'),
                          icon: Icons.account_circle_outlined,
                        ),
                        const SizedBox(height: 12),
                        Card(
                          child: ListTile(
                            leading: const Icon(Icons.chat_bubble_outline),
                            title: const Text('Match chat', style: TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(connected ? '${chatMessages.length} messages · only visible in this match' : 'Chat becomes available when your opponent joins'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_unreadChatCount > 0)
                                  CircleAvatar(
                                    radius: 11,
                                    child: Text(
                                      _unreadChatCount > 9 ? '9+' : '$_unreadChatCount',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_up),
                              ],
                            ),
                            onTap: connected ? () => _showChatSheet(online) : null,
                          ),
                        ),
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
                                    onPressed:
                                        online.roomCode == null ? null : online.rematch,
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: online.roomCode == null ? null : online.resign,
                              icon: const Icon(Icons.flag_outlined),
                              label: const Text('Resign'),
                            ),
                            const SizedBox(width: 10),
                            OutlinedButton.icon(
                              onPressed:
                                  online.roomCode == null ? null : online.offerDraw,
                              icon: const Icon(Icons.handshake_outlined),
                              label: const Text('Offer Draw'),
                            ),
                          ],
                        ),
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

  Future<void> _showChatSheet(OnlineGameProvider online) async {
    setState(() { _chatExpanded = true; _unreadChatCount = 0; });
    await showModalBottomSheet<void>(
      context: context, isScrollControlled: true, useSafeArea: true, showDragHandle: true,
      builder: (sheetContext) => AnimatedBuilder(
        animation: online,
        builder: (context, _) {
          final messages = online.chatMessages;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 4, 16, MediaQuery.viewInsetsOf(context).bottom + 16),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.68,
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Row(children: [const Icon(Icons.chat_bubble_outline), const SizedBox(width: 8), Expanded(child: Text('Match chat', style: Theme.of(context).textTheme.titleLarge)), Text('${messages.length}/100')]),
                const SizedBox(height: 10),
                Expanded(child: messages.isEmpty
                  ? const Center(child: Text('Say hello to your opponent!'))
                  : ListView.builder(
                      controller: _chatScrollController, padding: const EdgeInsets.all(8), itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final mine = message['senderColor'] == online.playerColor;
                        return Align(
                          alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
                            margin: const EdgeInsets.only(bottom: 8), padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(color: mine ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(12)),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(mine ? 'You' : (message['senderName']?.toString() ?? 'Opponent'), style: Theme.of(context).textTheme.labelSmall),
                              Text(message['text']?.toString() ?? ''),
                              Align(alignment: Alignment.bottomRight, child: Text(_formatTime(message['timestamp']?.toString()), style: Theme.of(context).textTheme.labelSmall)),
                            ]),
                          ),
                        );
                      },
                    )),
                const SizedBox(height: 8),
                Text('Quick messages', style: Theme.of(context).textTheme.labelLarge),
                Wrap(spacing: 6, runSpacing: 4, children: [
                  for (final entry in OnlineGameProvider.quickChatOptions.entries)
                    ActionChip(label: Text(entry.value), onPressed: online.opponentConnected ? () => online.sendQuickChat(entry.key) : null),
                ]),
                const SizedBox(height: 8),
                Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Expanded(child: TextField(controller: _chatController, enabled: online.opponentConnected, maxLength: 280, minLines: 1, maxLines: 3, textCapitalization: TextCapitalization.sentences, decoration: const InputDecoration(hintText: 'Write a message…', counterText: '', border: OutlineInputBorder(), isDense: true), onSubmitted: (_) => _sendChat(online))),
                  const SizedBox(width: 8),
                  IconButton.filled(tooltip: 'Send message', onPressed: online.opponentConnected ? () => _sendChat(online) : null, icon: const Icon(Icons.send)),
                ]),
                Text('Up to 280 characters · history lasts for this match only.', style: Theme.of(context).textTheme.bodySmall),
              ]),
            ),
          );
        },
      ),
    );
    if (mounted) setState(() => _chatExpanded = false);
  }
  String _formatTime(String? value) {
    if (value == null) return '';
    final parsed = DateTime.tryParse(value)?.toLocal();
    if (parsed == null) return '';
    final hour = parsed.hour % 12 == 0 ? 12 : parsed.hour % 12;
    final minute = parsed.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${parsed.hour >= 12 ? 'PM' : 'AM'}';
  }
}

class _PlayerCard extends StatelessWidget {
  const _PlayerCard({
    required this.name,
    required this.subtitle,
    required this.icon,
  });

  final String name;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          leading: CircleAvatar(child: Icon(icon)),
          title: Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
        ),
      );
}
