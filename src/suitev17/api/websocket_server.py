#!/usr/bin/env python3
"""
SuiteV17 WebSocket Server - Real-time Communication
Supporta live updates, broadcasting, room management
"""
import asyncio
import websockets
import json
import logging
from datetime import datetime
from typing import Dict, Set, Optional, Callable, Any
from dataclasses import dataclass

@dataclass
class WSClient:
    websocket: Any
    client_id: str
    subscribed_channels: Set[str]
    connected_at: str
    last_ping: str

class WebSocketServer:
    """WebSocket server per SuiteV17 con gestione avanzata."""
    
    def __init__(self, host: str = 'localhost', port: int = 8765):
        self.host = host
        self.port = port
        self.clients: Dict[str, WSClient] = {}
        self.channels: Dict[str, Set[str]] = {}  # channel -> set(client_ids)
        self.message_handlers: Dict[str, Callable] = {}
        self.running = False
        self.logger = logging.getLogger('WebSocketServer')
        
        # Register default handlers
        self.register_handler('ping', self._handle_ping)
        self.register_handler('subscribe', self._handle_subscribe)
        self.register_handler('unsubscribe', self._handle_unsubscribe)
        self.register_handler('broadcast', self._handle_broadcast)
        self.register_handler('agent_status', self._handle_agent_status)
        self.register_handler('trade_update', self._handle_trade_update)
        
    def register_handler(self, message_type: str, handler: Callable):
        """Registra handler per tipo messaggio."""
        self.message_handlers[message_type] = handler
        
    async def handler(self, websocket, path):
        """Gestisce connessione WebSocket."""
        client_id = f"client_{len(self.clients)}_{datetime.now().timestamp()}"
        
        client = WSClient(
            websocket=websocket,
            client_id=client_id,
            subscribed_channels=set(),
            connected_at=datetime.now().isoformat(),
            last_ping=datetime.now().isoformat()
        )
        
        self.clients[client_id] = client
        self.logger.info(f'Client {client_id} connected. Total: {len(self.clients)}')
        
        try:
            # Send welcome
            await websocket.send(json.dumps({
                'type': 'connected',
                'client_id': client_id,
                'timestamp': datetime.now().isoformat()
            }))
            
            async for message in websocket:
                try:
                    data = json.loads(message)
                    await self._process_message(client_id, data)
                except json.JSONDecodeError:
                    await self.send_to_client(client_id, {
                        'type': 'error',
                        'message': 'Invalid JSON'
                    })
                except Exception as e:
                    self.logger.error(f'Error processing message: {e}')
                    await self.send_to_client(client_id, {
                        'type': 'error',
                        'message': str(e)
                    })
                    
        except websockets.exceptions.ConnectionClosed:
            self.logger.info(f'Client {client_id} disconnected')
        finally:
            await self._cleanup_client(client_id)
            
    async def _process_message(self, client_id: str, data: Dict):
        """Processa messaggio in arrivo."""
        msg_type = data.get('type', 'unknown')
        handler = self.message_handlers.get(msg_type)
        
        if handler:
            await handler(client_id, data)
        else:
            await self.send_to_client(client_id, {
                'type': 'error',
                'message': f'Unknown message type: {msg_type}'
            })
            
    # === HANDLERS ===
    
    async def _handle_ping(self, client_id: str, data: Dict):
        """Handler ping/pong."""
        self.clients[client_id].last_ping = datetime.now().isoformat()
        await self.send_to_client(client_id, {
            'type': 'pong',
            'timestamp': datetime.now().isoformat(),
            'latency_ms': data.get('timestamp', 0)
        })
        
    async def _handle_subscribe(self, client_id: str, data: Dict):
        """Handler subscription."""
        channel = data.get('channel')
        if not channel:
            await self.send_to_client(client_id, {'type': 'error', 'message': 'Channel required'})
            return
            
        self.clients[client_id].subscribed_channels.add(channel)
        
        if channel not in self.channels:
            self.channels[channel] = set()
        self.channels[channel].add(client_id)
        
        await self.send_to_client(client_id, {
            'type': 'subscribed',
            'channel': channel,
            'client_count': len(self.channels[channel])
        })
        
    async def _handle_unsubscribe(self, client_id: str, data: Dict):
        """Handler unsubscription."""
        channel = data.get('channel')
        if channel and channel in self.channels:
            self.channels[channel].discard(client_id)
            self.clients[client_id].subscribed_channels.discard(channel)
            
    async def _handle_broadcast(self, client_id: str, data: Dict):
        """Handler broadcast."""
        message = data.get('message', {})
        channel = data.get('channel', 'global')
        await self.broadcast_to_channel(channel, {
            'type': 'broadcast',
            'from': client_id,
            'message': message,
            'timestamp': datetime.now().isoformat()
        })
        
    async def _handle_agent_status(self, client_id: str, data: Dict):
        """Handler aggiornamento stato agente."""
        # Broadcast a tutti i client sui canali subscribed
        await self.broadcast_to_channel('agents', {
            'type': 'agent_status_update',
            'data': data.get('status', {}),
            'timestamp': datetime.now().isoformat()
        })
        
    async def _handle_trade_update(self, client_id: str, data: Dict):
        """Handler aggiornamento trade."""
        await self.broadcast_to_channel('trades', {
            'type': 'trade_update',
            'data': data.get('trade', {}),
            'timestamp': datetime.now().isoformat()
        })
        
    async def _cleanup_client(self, client_id: str):
        """Pulisce risorse client disconnesso."""
        if client_id in self.clients:
            client = self.clients[client_id]
            for channel in client.subscribed_channels:
                if channel in self.channels:
                    self.channels[channel].discard(client_id)
            del self.clients[client_id]
            
    # === UTILITIES ===
    
    async def send_to_client(self, client_id: str, message: Dict):
        """Invia messaggio a client specifico."""
        if client_id in self.clients:
            try:
                await self.clients[client_id].websocket.send(json.dumps(message))
            except Exception as e:
                self.logger.error(f'Error sending to {client_id}: {e}')
                await self._cleanup_client(client_id)
                
    async def broadcast_to_channel(self, channel: str, message: Dict):
        """Broadcast a tutti i client su un canale."""
        if channel not in self.channels:
            return
            
        disconnected = []
        for client_id in list(self.channels[channel]):
            if client_id in self.clients:
                try:
                    await self.clients[client_id].websocket.send(json.dumps(message))
                except:
                    disconnected.append(client_id)
            else:
                disconnected.append(client_id)
                
        # Cleanup disconnected
        for client_id in disconnected:
            await self._cleanup_client(client_id)
            self.channels[channel].discard(client_id)
            
    async def broadcast_to_all(self, message: Dict):
        """Broadcast a tutti i client."""
        for client_id in list(self.clients.keys()):
            await self.send_to_client(client_id, message)
            
    # === PUBLISH METHODS ===
    
    async def publish_agent_update(self, agent_data: Dict):
        """Pubblica aggiornamento agente."""
        await self.broadcast_to_channel('agents', {
            'type': 'agent_update',
            'data': agent_data,
            'timestamp': datetime.now().isoformat()
        })
        
    async def publish_trade(self, trade_data: Dict):
        """Pubblica nuovo trade."""
        await self.broadcast_to_channel('trades', {
            'type': 'new_trade',
            'data': trade_data,
            'timestamp': datetime.now().isoformat()
        })
        
    async def publish_log(self, log_data: Dict):
        """Pubblica log in real-time."""
        await self.broadcast_to_channel('logs', {
            'type': 'log_entry',
            'data': log_data,
            'timestamp': datetime.now().isoformat()
        })
        
    async def publish_system_metrics(self, metrics: Dict):
        """Pubblica metriche sistema."""
        await self.broadcast_to_channel('metrics', {
            'type': 'system_metrics',
            'data': metrics,
            'timestamp': datetime.now().isoformat()
        })
        
    async def publish_alert(self, alert: Dict):
        """Pubblica alert."""
        await self.broadcast_to_channel('alerts', {
            'type': 'alert',
            'data': alert,
            'priority': alert.get('priority', 'normal'),
            'timestamp': datetime.now().isoformat()
        })
        
    # === SERVER LIFECYCLE ===
    
    async def run(self):
        """Avvia server."""
        self.running = True
        print(f'WebSocket server starting on ws://{self.host}:{self.port}')
        
        async with websockets.serve(self.handler, self.host, self.port):
            while self.running:
                await asyncio.sleep(1)
                
    def stop(self):
        """Ferma server."""
        self.running = False
        
    async def get_stats(self) -> Dict:
        """Statistiche server."""
        return {
            'connected_clients': len(self.clients),
            'active_channels': {k: len(v) for k, v in self.channels.items()},
            'uptime': 'running'
        }

def main():
    """Entry point."""
    logging.basicConfig(level=logging.INFO)
    server = WebSocketServer()
    
    try:
        asyncio.run(server.run())
    except KeyboardInterrupt:
        print('Shutting down...')
        server.stop()

if __name__ == '__main__':
    main()
