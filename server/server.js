import { randomBytes } from 'node:crypto';
import { WebSocketServer } from 'ws';
import { Chess } from 'chess.js';

const PORT = Number(process.env.PORT || 8080);
const wss = new WebSocketServer({ port: PORT });

const rooms = new Map();

function roomCode() {
  let code;
  do {
    code = randomBytes(4)
      .toString('base64url')
      .replace(/[^A-Z0-9]/gi, '')
      .toUpperCase()
      .slice(0, 6);
  } while (code.length < 6 || rooms.has(code));
  return code;
}

function send(ws, payload) {
  if (ws.readyState === ws.OPEN) {
    ws.send(JSON.stringify(payload));
  }
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
  if (room.players.length === 0) {
    rooms.delete(room.code);
  }
}

wss.on('connection', (ws) => {
  let player = null;

  ws.on('message', (raw) => {
    let message;
    try {
      message = JSON.parse(raw.toString());
    } catch {
      send(ws, { type: 'error', message: 'Invalid JSON message.' });
      return;
    }

    if (message.type === 'create_room') {
      if (player) return;

      const code = roomCode();
      const room = {
        code,
        chess: new Chess(),
        players: [],
        rematchVotes: new Set(),
        drawOffer: null,
      };

      player = {
        ws,
        name: String(message.playerName || 'White').trim().slice(0, 20) || 'White',
        color: 'white',
        room,
      };

      room.players.push(player);
      rooms.set(code, room);

      send(ws, {
        type: 'room_created',
        roomCode: code,
        color: 'white',
        ...state(room),
      });
      return;
    }

    if (message.type === 'join_room') {
      if (player) return;

      const code = String(message.roomCode || '').trim().toUpperCase();
      const room = rooms.get(code);

      if (!room) {
        send(ws, { type: 'error', message: 'Room not found.' });
        return;
      }

      if (room.players.length >= 2) {
        send(ws, { type: 'error', message: 'Room is already full.' });
        return;
      }

      player = {
        ws,
        name: String(message.playerName || 'Black').trim().slice(0, 20) || 'Black',
        color: 'black',
        room,
      };

      room.players.push(player);

      send(ws, {
        type: 'room_joined',
        roomCode: code,
        color: 'black',
        opponentName: room.players[0].name,
        ...state(room),
      });

      broadcast(room, {
        type: 'opponent_joined',
        opponentName: player.name,
      }, ws);
      return;
    }

    if (!player?.room) {
      send(ws, { type: 'error', message: 'Create or join a room first.' });
      return;
    }

    const room = player.room;

    if (message.type === 'move') {
      if (room.players.length !== 2) {
        send(ws, { type: 'error', message: 'Waiting for an opponent.' });
        return;
      }

      if (room.chess.isGameOver()) {
        send(ws, { type: 'error', message: 'The game is already over.' });
        return;
      }

      const expectedColor = room.chess.turn() === 'w' ? 'white' : 'black';
      if (player.color !== expectedColor) {
        send(ws, { type: 'error', message: 'It is not your turn.' });
        return;
      }

      try {
        const move = room.chess.move({
          from: String(message.from),
          to: String(message.to),
          ...(message.promotion ? { promotion: String(message.promotion) } : {}),
        });

        if (!move) {
          send(ws, { type: 'error', message: 'Illegal move.' });
          return;
        }

        const payload = {
          type: 'move',
          from: move.from,
          to: move.to,
          san: move.san,
          ...state(room),
        };

        broadcast(room, payload);
        return;
      } catch {
        send(ws, { type: 'error', message: 'Illegal move.' });
        return;
      }
    }

    if (message.type === 'resign') {
      broadcast(room, {
        type: 'resigned',
        color: player.color,
      });
      return;
    }

    if (message.type === 'offer_draw') {
      room.drawOffer = player.color;
      broadcast(room, {
        type: 'draw_offered',
        color: player.color,
      }, ws);
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
        broadcast(room, {
          type: 'rematch_started',
          ...state(room),
        });
      } else {
        send(ws, { type: 'rematch_waiting' });
        broadcast(room, {
          type: 'rematch_requested',
          color: player.color,
        }, ws);
      }
    }
  });

  ws.on('close', () => {
    if (!player?.room) return;

    const room = player.room;
    room.players = room.players.filter((item) => item !== player);

    broadcast(room, {
      type: 'opponent_left',
    });

    cleanup(room);
  });
});

console.log(`ChessMate multiplayer server listening on port ${PORT}`);
