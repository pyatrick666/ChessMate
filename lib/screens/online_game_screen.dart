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
      } else if (event['type'] == 'chat_message' && _chatExpanded) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
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
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.chat_bubble_outline),
                                title: const Text(
                                  'Match chat',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Text(
                                  connected
                                      ? '${chatMessages.length} messages · only visible in this match'
                                      : 'Chat becomes available when your opponent joins',
                                ),
                                trailing: Icon(
                                  _chatExpanded
                                      ? Icons.keyboard_arrow_up
                                      : Icons.keyboard_arrow_down,
                                ),
                                onTap: () => setState(
                                  () => _chatExpanded = !_chatExpanded,
                                ),
                              ),
                              AnimatedCrossFade(
                                firstChild: const SizedBox(width: double.infinity),
                                secondChild: Padding(
                                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Container(
                                        height: 190,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .surfaceContainerHighest
                                              .withValues(alpha: 0.45),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: chatMessages.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  'Say hello to your opponent!',
                                                ),
                                              )
                                            : ListView.builder(
                                                controller: _chatScrollController,
                                                padding: const EdgeInsets.all(10),
                                                itemCount: chatMessages.length,
                                                itemBuilder: (context, index) {
                                                  final message = chatMessages[index];
                                                  final mine = message['senderColor'] ==
                                                      online.playerColor;
                                                  final sender =
                                                      message['senderName']?.toString() ??
                                                          'Player';
                                                  final text =
                                                      message['text']?.toString() ?? '';
                                                  final time = _formatTime(
                                                    message['timestamp']?.toString(),
                                                  );
                                                  return Align(
                                                    alignment: mine
                                                        ? Alignment.centerRight
                                                        : Alignment.centerLeft,
                                                    child: Container(
                                                      constraints: BoxConstraints(
                                                        maxWidth:
                                                            MediaQuery.sizeOf(context)
                                                                    .width *
                                                                0.72,
                                                      ),
                                                      margin: const EdgeInsets.only(
                                                        bottom: 8,
                                                      ),
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                        horizontal: 11,
                                                        vertical: 8,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color: mine
                                                            ? Theme.of(context)
                                                                .colorScheme
                                                                .primaryContainer
                                                            : Theme.of(context)
                                                                .colorScheme
                                                                .surface,
                                                        borderRadius:
                                                            BorderRadius.circular(12),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment.start,
                                                        children: [
                                                          Text(
                                                            mine ? 'You' : sender,
                                                            style: Theme.of(context)
                                                                .textTheme
                                                                .labelSmall
                                                                ?.copyWith(
                                                                  fontWeight:
                                                                      FontWeight.bold,
                                                                ),
                                                          ),
                                                          const SizedBox(height: 2),
                                                          Text(text),
                                                          const SizedBox(height: 2),
                                                          Align(
                                                            alignment:
                                                                Alignment.bottomRight,
                                                            child: Text(
                                                              time,
                                                              style: Theme.of(context)
                                                                  .textTheme
                                                                  .labelSmall,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                },
                                              ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'Quick messages',
                                        style: Theme.of(context).textTheme.labelLarge,
                                      ),
                                      const SizedBox(height: 6),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 6,
                                        children: [
                                          for (final entry
                                              in OnlineGameProvider.quickChatOptions.entries)
                                            ActionChip(
                                              label: Text(entry.value),
                                              onPressed: connected
                                                  ? () => online.sendQuickChat(entry.key)
                                                  : null,
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      Row(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _chatController,
                                              enabled: connected,
                                              maxLength: 280,
                                              minLines: 1,
                                              maxLines: 3,
                                              textCapitalization:
                                                  TextCapitalization.sentences,
                                              decoration: const InputDecoration(
                                                hintText: 'Write a message…',
                                                counterText: '',
                                                border: OutlineInputBorder(),
                                                isDense: true,
                                              ),
                                              onSubmitted: (_) => _sendChat(online),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton.filled(
                                            tooltip: 'Send message',
                                            onPressed: connected
                                                ? () => _sendChat(online)
                                                : null,
                                            icon: const Icon(Icons.send),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Messages are limited to 280 characters. Be respectful.',
                                        style: Theme.of(context).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                crossFadeState: _chatExpanded
                                    ? CrossFadeState.showSecond
                                    : CrossFadeState.showFirst,
                                duration: const Duration(milliseconds: 200),
                              ),
                            ],
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
