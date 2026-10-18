import { randomBytes, randomUUID } from 'node:crypto';
import { WebSocketServer } from 'ws';
import { Chess } from 'chess.js';
import { createServer } from 'node:http';

const PORT = Number(process.env.PORT || 8080);
const MAX_CHAT_LENGTH = 280;
const MAX_CHAT_HISTORY = 100;
const CHAT_WINDOW_MS = 10_000;
const CHAT_MAX_PER_WINDOW = 5;
const QUICK_MESSAGES = new Set([
  'good_luck',
  'well_played',
  'nice_move',
  'good_game',
  'thanks',
]);

const httpServer = createServer((req, res) => {
  const path = new URL(req.url || '/', 'http://localhost').pathname;

  if (path === '/' || path === '/health') {
    res.writeHead(200, {
      'content-type': 'application/json',
      'cache-control': 'no-store',
    });
    res.end(JSON.stringify({ status: 'ok', service: 'chessmate-online' }));
    return;
  }

  res.writeHead(404, { 'content-type': 'text/plain' });
  res.end('Not Found');
});

const wss = new WebSocketServer({
  server: httpServer,
  maxPayload: 8 * 1024,
  perMessageDeflate: false,
});

const rooms = new Map();

function roomCode() {
  let code;
  do {
    code = randomBytes(4).toString('base64url').replace(/[^A-Z0-9]/gi, '').toUpperCase().slice(0, 6);
  } while (code.length < 6 || rooms.has(code));
  return code;
}

function send(ws, payload) {
  if (ws.readyState === ws.OPEN) ws.send(JSON.stringify(payload));
}

function broadcast(room, payload, except = null) {
  for (const player of room.players) {
    if (player !== except) send(player.ws, payload);
  }
}

function state(room) {
  return {
    fen: room.chess.fen(),
    turn: room.chess.turn(),
    gameOver: room.chess.isGameOver(),
    checkmate: room.chess.isCheckmate(),
    stalemate: room.chess.isStalemate(),
    draw: room.chess.isDraw(),
  };
}

function cleanup(room) {
  if (room.players.length === 0) rooms.delete(room.code);
}

function chatHistory(room, ws) {
  send(ws, { type: 'chat_history', messages: room.chatHistory });
}

function sendChatError(ws, message) {
  send(ws, { type: 'error', message });
}

httpServer.listen(PORT, () => {
  console.log(`ChessMate multiplayer server listening on port ${PORT}`);
});

wss.on('connection', (ws) => {
  let player = null;

  ws.on('message', (raw, isBinary) => {
    if (isBinary) {
      sendChatError(ws, 'Binary messages are not supported.');
      return;
    }

    let message;
    try {
      message = JSON.parse(raw.toString());
    } catch {
      sendChatError(ws, 'Invalid JSON message.');
      return;
    }

    if (!message || typeof message !== 'object' || Array.isArray(message) || typeof message.type !== 'string') {
      sendChatError(ws, 'Invalid message format.');
      return;
    }

    if (message.type === 'create_room') {
      if (player) return;
      const code = roomCode();
      const room = { code, chess: new Chess(), players: [], rematchVotes: new Set(), drawOffer: null, chatHistory: [] };
      player = {
        ws,
        name: String(message.playerName || 'White').trim().slice(0, 20) || 'White',
        color: 'white',
        reconnectToken: randomUUID(),
        chatTimestamps: [],
        room,
      };
      room.players.push(player);
      rooms.set(code, room);
      send(ws, { type: 'room_created', roomCode: code, color: 'white', reconnectToken: player.reconnectToken, ...state(room) });
      chatHistory(room, ws);
      return;
    }

    if (message.type === 'join_room') {
      if (player) return;
      const code = String(message.roomCode || '').trim().toUpperCase();
      const room = rooms.get(code);
      if (!room) {
        sendChatError(ws, 'Room not found.');
        return;
      }
      if (room.players.length >= 2) {
        sendChatError(ws, 'Room is already full.');
        return;
      }

      player = {
        ws,
        name: String(message.playerName || 'Black').trim().slice(0, 20) || 'Black',
        color: 'black',
        reconnectToken: randomUUID(),
        chatTimestamps: [],
        room,
      };
      room.players.push(player);
      send(ws, {
        type: 'room_joined',
        roomCode: code,
        color: 'black',
        reconnectToken: player.reconnectToken,
        opponentName: room.players[0].name,
        ...state(room),
      });
      chatHistory(room, ws);
      broadcast(room, { type: 'opponent_joined', opponentName: player.name }, ws);
      return;
    }

    if (message.type === 'reconnect_room') {
      if (player) return;
      const code = String(message.roomCode || '').trim().toUpperCase();
      const room = rooms.get(code);
      const token = String(message.reconnectToken || '');
      const existing = room?.players.find((item) => item.reconnectToken === token);
      if (!room || !existing) {
        sendChatError(ws, 'Reconnect session expired. Please create or join a new room.');
        return;
      }

      const previousSocket = existing.ws;
      player = existing;
      player.ws = ws;
      player.disconnectedAt = null;
      if (previousSocket !== ws && previousSocket.readyState === previousSocket.OPEN) previousSocket.close();

      send(ws, {
        type: 'reconnected',
        roomCode: room.code,
        color: player.color,
        opponentName: room.players.find((item) => item !== player)?.name ?? null,
        opponentConnected: room.players.some((item) => item !== player && !item.disconnectedAt),
        ...state(room),
      });
      chatHistory(room, ws);
      return;
    }

    if (!player?.room) {
      sendChatError(ws, 'Create or join a room first.');
      return;
    }

    const room = player.room;

    if (message.type === 'chat_message' || message.type === 'quick_chat') {
      if (room.players.length !== 2 || room.players.some((item) => item.disconnectedAt)) {
        sendChatError(ws, 'Chat is available when both players are connected.');
        return;
      }

      let text;
      let quickId = null;
      if (message.type === 'quick_chat') {
        quickId = typeof message.quickId === 'string' ? message.quickId : '';
        if (!QUICK_MESSAGES.has(quickId)) {
          sendChatError(ws, 'That quick message is not supported.');
          return;
        }
        const quickText = {
          good_luck: 'Good luck!',
          well_played: 'Well played!',
          nice_move: 'Nice move!',
          good_game: 'Good game!',
          thanks: 'Thanks!',
        };
        text = quickText[quickId];
      } else {
        if (typeof message.text !== 'string') {
          sendChatError(ws, 'Chat message must be text.');
          return;
        }
        text = message.text.replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, '').trim();
        if (!text || text.length > MAX_CHAT_LENGTH) {
          sendChatError(ws, `Messages must be between 1 and ${MAX_CHAT_LENGTH} characters.`);
          return;
        }
      }

      const now = Date.now();
      player.chatTimestamps = player.chatTimestamps.filter((stamp) => now - stamp < CHAT_WINDOW_MS);
      if (player.chatTimestamps.length >= CHAT_MAX_PER_WINDOW) {
        sendChatError(ws, 'Please slow down before sending another chat message.');
        return;
      }
      player.chatTimestamps.push(now);

      const chat = {
        type: 'chat_message',
        id: randomUUID(),
        senderName: player.name,
        senderColor: player.color,
        text,
        quickId,
        timestamp: new Date(now).toISOString(),
      };
      room.chatHistory.push(chat);
      if (room.chatHistory.length > MAX_CHAT_HISTORY) room.chatHistory.shift();
      broadcast(room, chat);
      return;
    }

    if (message.type === 'move') {
      if (room.players.length !== 2) {
        sendChatError(ws, 'Waiting for an opponent.');
        return;
      }
      if (room.chess.isGameOver()) {
        sendChatError(ws, 'The game is already over.');
        return;
      }
      const expectedColor = room.chess.turn() === 'w' ? 'white' : 'black';
      if (player.color !== expectedColor) {
        sendChatError(ws, 'It is not your turn.');
        return;
      }
      try {
        const move = room.chess.move({
          from: String(message.from),
          to: String(message.to),
          ...(message.promotion ? { promotion: String(message.promotion) } : {}),
        });
        if (!move) {
          sendChatError(ws, 'Illegal move.');
          return;
        }
        broadcast(room, { type: 'move', from: move.from, to: move.to, san: move.san, ...state(room) });
      } catch {
        sendChatError(ws, 'Illegal move.');
      }
      return;
    }

    if (message.type === 'resign') {
      if (!room.chess.isGameOver()) broadcast(room, { type: 'resigned', color: player.color });
      return;
    }

    if (message.type === 'offer_draw') {
      if (room.chess.isGameOver()) return;
      room.drawOffer = player.color;
      broadcast(room, { type: 'draw_offered', color: player.color }, ws);
      return;
    }

    if (message.type === 'accept_draw') {
      if (room.drawOffer && room.drawOffer !== player.color) {
        room.drawOffer = null;
        broadcast(room, { type: 'draw_accepted' });
      }
      return;
    }

    if (message.type === 'rematch') {
      room.rematchVotes.add(player.color);
      if (room.rematchVotes.size === 2) {
        room.chess.reset();
        room.rematchVotes.clear();
        room.drawOffer = null;
        room.chatHistory = [];
        broadcast(room, { type: 'rematch_started', ...state(room) });
        broadcast(room, { type: 'chat_history', messages: [] });
      } else {
        send(ws, { type: 'rematch_waiting' });
        broadcast(room, { type: 'rematch_requested', color: player.color }, ws);
      }
    }
  });

  ws.on('close', () => {
    if (!player?.room) return;
    const room = player.room;
    const storedPlayer = room.players.find((item) => item.reconnectToken === player.reconnectToken);
    if (storedPlayer && storedPlayer.ws === ws) {
      storedPlayer.disconnectedAt = Date.now();
    }

    broadcast(room, { type: 'opponent_left', message: 'Your opponent disconnected.' });

    setTimeout(() => {
      const current = room.players.find((item) => item.reconnectToken === player.reconnectToken);
      if (current?.disconnectedAt && Date.now() - current.disconnectedAt >= 30000) {
        room.players = room.players.filter((item) => item !== current);
        cleanup(room);
      }
    }, 30000);
  });
});
