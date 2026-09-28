# ChessMate Online Server

## Local
npm install
npm start

Default port: 8080.

## Docker
docker build -t chessmate-server .
docker run --rm -p 8080:8080 chessmate-server

For production, deploy this container to a host that supports persistent WebSocket connections and TLS. Configure the Flutter app with the resulting wss:// endpoint.