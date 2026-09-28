import 'dart:math';

import 'package:flutter/material.dart';

import '../widgets/ad_banner.dart';
import 'online_game_screen.dart';
import '../providers/online_game_provider.dart';

class OnlineLobbyScreen extends StatefulWidget {
  const OnlineLobbyScreen({super.key});

  @override
  State<OnlineLobbyScreen> createState() => _OnlineLobbyScreenState();
}

class _OnlineLobbyScreenState extends State<OnlineLobbyScreen> {
  final _serverController = TextEditingController();
  final _nameController = TextEditingController();
  final _joinController = TextEditingController();
  String? _createdRoom;
  bool _creating = false;
  bool _joining = false;
  bool _showServerSettings = false;
  late final OnlineGameProvider _online;

  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = Random.secure();
    return List.generate(
      6,
      (_) => chars[random.nextInt(chars.length)],
    ).join();
  }

  void _openOnlineGame() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => OnlineGameScreen(online: _online)),
    );
  }

  @override
  void initState() {
    super.initState();
    _online = OnlineGameProvider();
  }

  Future<void> _connectToServer() async {
    final raw = _serverController.text.trim();
    final uri = Uri.tryParse(raw);
    if (uri == null || uri.scheme != 'ws' && uri.scheme != 'wss') {
      throw const FormatException('Enter a valid ws:// or wss:// server URL.');
    }
    await _online.connect(uri);
    if (_online.connectionState != OnlineConnectionState.connected) {
      throw StateError(_online.errorMessage ?? 'Unable to connect to server.');
    }
  }

  Future<void> _createGame() async {
    final name = _nameController.text.trim().isEmpty
        ? 'White'
        : _nameController.text.trim();
    setState(() => _creating = true);
    try {
      await _connectToServer();
      _online.createRoom(name);
      _openOnlineGame();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _joinGame() async {
    final code = _joinController.text.trim().toUpperCase();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a 6-character room code.')),
      );
      return;
    }

    final name = _nameController.text.trim().isEmpty
        ? 'Black'
        : _nameController.text.trim();
    setState(() => _joining = true);
    try {
      await _connectToServer();
      _online.joinRoom(code, name);
      _openOnlineGame();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _joining = false);
    }
  }

  @override
  void dispose() {
    _joinController.dispose();
    _serverController.dispose();
    _nameController.dispose();
    _online.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Online Multiplayer'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Icon(
              Icons.public,
              size: 56,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 10),
            Text(
              'Play Chess Online',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Create a private room or join a friend with a room code.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Player',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _nameController,
                      maxLength: 20,
                      decoration: const InputDecoration(
                        labelText: 'Player name',
                        prefixIcon: Icon(Icons.person_outline),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    ExpansionTile(
                      title: const Text('Server connection'),
                      initiallyExpanded: false,
                      onExpansionChanged: (value) {
                        setState(() => _showServerSettings = value);
                      },
                      children: [
                        TextField(
                          controller: _serverController,
                          keyboardType: TextInputType.url,
                          decoration: const InputDecoration(
                            labelText: 'WebSocket server URL',
                            hintText: 'wss://your-server.example/ws',
                            prefixIcon: Icon(Icons.cloud_outlined),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            'Use your deployed WebSocket server here. The room UI remains usable while the backend is being connected.',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const SizedBox(height: 28),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Create a game',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Generate a room code and share it with your opponent.',
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _creating ? null : _createGame,
                      icon: _creating
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_circle_outline),
                      label: Text(_creating ? 'Creating…' : 'Create Room'),
                    ),
                    if (_createdRoom != null) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: theme.colorScheme.primaryContainer,
                        ),
                        child: Column(
                          children: [
                            const Text('YOUR ROOM CODE'),
                            const SizedBox(height: 6),
                            SelectableText(
                              _createdRoom!,
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.w900,
                                letterSpacing: 5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Share this code with your opponent.',
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Join a game',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text('Enter the room code supplied by your opponent.'),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _joinController,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Room code',
                        hintText: 'ABC123',
                        prefixIcon: Icon(Icons.key_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _joining ? null : _joinGame,
                      icon: _joining
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.login),
                      label: Text(_joining ? 'Joining…' : 'Join Room'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Center(child: AdBanner()),
            const SizedBox(height: 18),
            Card(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.cloud_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Online rooms are prepared in the app UI. The next multiplayer layer connects these rooms to a persistent server so two devices can exchange and validate moves in real time.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
