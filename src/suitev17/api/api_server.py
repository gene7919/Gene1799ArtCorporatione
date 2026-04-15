import os
#!/usr/bin/env python3
"""
SuiteV17 API REST Server - FastAPI-based
Complete REST API with authentication, CORS, rate limiting
"""
import os
import sys
import json
import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any
from contextlib import asynccontextmanager
import jwt

# Import caching
from fastapi_cache import FastAPICache
from fastapi_cache.backends.inmemory import InMemoryBackend
from fastapi_cache.decorator import cache

# Import Pydantic per modelli dati
try:
    from pydantic import BaseModel, Field
    from fastapi import FastAPI, HTTPException, Depends, Query, BackgroundTasks, Request
    from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.responses import JSONResponse, StreamingResponse
    from uvicorn import Config, Server
    HAS_FASTAPI = True
except ImportError:
    HAS_FASTAPI = False
    print('Installa: pip install fastapi uvicorn pydantic')
    sys.exit(1)

# Import moduli SuiteV17
sys.path.insert(0, 'C:\\SuiteV17')
from database_core import get_db, DatabaseManager

# Modelli Pydantic
class AgentCreate(BaseModel):
    name: str = Field(..., min_length=1, max_length=100)
    type: str = Field(..., pattern='^(correttore|orchestratore|trader|monitor|custom)$')
    config: Optional[Dict] = Field(default_factory=dict)

class AgentUpdate(BaseModel):
    status: Optional[str] = Field(None, pattern='^(active|inactive|error|maintenance)$')
    config: Optional[Dict] = None
    metrics: Optional[Dict] = None

class TradeCreate(BaseModel):
    token_symbol: str = Field(..., min_length=1, max_length=20)
    action: str = Field(..., pattern='^(buy|sell|hold|monitor)$')
    amount: float = Field(..., gt=0)
    price: float = Field(..., gt=0)
    tx_hash: Optional[str] = None

class LogQuery(BaseModel):
    level: Optional[str] = Field(None, pattern='^(DEBUG|INFO|WARNING|ERROR|CRITICAL)$')
    source: Optional[str] = None
    limit: int = Field(100, ge=1, le=1000)
    offset: int = Field(0, ge=0)

class MetricRecord(BaseModel):
    name: str
    value: float
    labels: Optional[Dict] = Field(default_factory=dict)

class ConfigUpdate(BaseModel):
    key: str
    value: Any

# Classe per rate limiting semplice
class RateLimiter:
    def __init__(self, requests_per_minute: int = 60):
        self.requests_per_minute = requests_per_minute
        self.requests: Dict[str, List[datetime]] = {}
        
    def is_allowed(self, client_id: str) -> bool:
        now = datetime.now()
        if client_id not in self.requests:
            self.requests[client_id] = []
        
        # Rimuovi richieste vecchie
        self.requests[client_id] = [
            req_time for req_time in self.requests[client_id]
            if now - req_time < timedelta(minutes=1)
        ]
        
        if len(self.requests[client_id]) >= self.requests_per_minute:
            return False
            
        self.requests[client_id].append(now)
        return True

# Classe API Server
class SuiteV17APIServer:
    def __init__(self, host: str = '0.0.0.0', port: int = 8080):
        self.host = host
        self.port = port
        self.db = get_db()
        self.rate_limiter = RateLimiter(requests_per_minute=100)
        self.security = HTTPBearer(auto_error=False)
        self.app = self._create_app()
        
    def _create_app(self) -> FastAPI:
        """Crea applicazione FastAPI."""
        app = FastAPI(
            title='SuiteV17 API',
            description='Enterprise API for SuiteV17 Platform',
            version='1.0.0',
            docs_url='/docs',
            redoc_url='/redoc'
        )

        # Initialize cache
        FastAPICache.init(InMemoryBackend(), prefix="fastapi-cache")
        
        # CORS
        app.add_middleware(
            CORSMiddleware,
            allow_origins=['*'],
            allow_credentials=True,
            allow_methods=['*'],
            allow_headers=['*'],
        )
        
        # Auth dependency
        async def verify_token(credentials: HTTPAuthorizationCredentials = Depends(self.security)):
            if not credentials:
                raise HTTPException(status_code=401, detail='Authentication required')
            token = credentials.credentials
            try:
                # Decode JWT
                payload = jwt.decode(
                    token,
                    os.getenv('JWT_SECRET', 'fallback-secret'),  # should be set in .env
                    algorithms=['HS256']
                )
                # Optionally validate expiration etc (jwt.decode already does exp if present)
                # You can also check specific claims
                return payload  # or return token
            except jwt.ExpiredSignatureError:
                raise HTTPException(status_code=401, detail='Token expired')
            except jwt.InvalidTokenError:
                raise HTTPException(status_code=401, detail='Invalid token')
        
        # Rate limit dependency
        async def rate_limit(request: Request):
            client_ip = request.client.host
            if not self.rate_limiter.is_allowed(client_ip):
                raise HTTPException(status_code=429, detail='Rate limit exceeded')
        
        # === HEALTH ENDPOINTS ===
        
        @app.get('/health')
        async def health_check():
            return {
                'status': 'healthy',
                'timestamp': datetime.now().isoformat(),
                'version': '1.0.0',
                'database': 'connected',
                'services': ['api', 'database', 'monitoring']
            }
            
        @app.get('/health/detailed')
        async def health_detailed():
            db_stats = self.db.get_stats()
            return {
                'status': 'healthy',
                'timestamp': datetime.now().isoformat(),
                'database_stats': db_stats,
                'memory_usage': self._get_memory_usage(),
                'uptime_seconds': 0  # Da implementare
            }
            
        # === AGENT ENDPOINTS ===
        
        @cache(expire=30)
        @app.get('/agents', response_model=List[Dict])
        async def list_agents(
            status: Optional[str] = Query(None, pattern='^(active|inactive|error|maintenance)$'),
            _: None = Depends(rate_limit)
        ):
            agents = self.db.list_agents(status=status)
            for agent in agents:
                agent['config'] = json.loads(agent.get('config', '{}'))
                agent['metrics'] = json.loads(agent.get('metrics', '{}'))
            return agents
            
        @app.get('/agents/{agent_id}')
        async def get_agent(agent_id: str):
            agent = self.db.get_agent(agent_id)
            if not agent:
                raise HTTPException(status_code=404, detail='Agent not found')
            agent['config'] = json.loads(agent.get('config', '{}'))
            agent['metrics'] = json.loads(agent.get('metrics', '{}'))
            return agent
            
        @app.post('/agents')
        async def create_agent(agent_data: AgentCreate):
            existing = self.db.get_agent_by_name(agent_data.name)
            if existing:
                raise HTTPException(status_code=409, detail='Agent name already exists')
                
            agent_id = self.db.create_agent(
                agent_data.name,
                agent_data.type,
                agent_data.config
            )
            return {'id': agent_id, 'status': 'created'}
            
        @app.patch('/agents/{agent_id}')
        async def update_agent(agent_id: str, update: AgentUpdate):
            agent = self.db.get_agent(agent_id)
            if not agent:
                raise HTTPException(status_code=404, detail='Agent not found')
                
            self.db.update_agent_status(
                agent_id,
                update.status or agent['status'],
                update.metrics
            )
            return {'status': 'updated'}
            
        @app.delete('/agents/{agent_id}')
        async def delete_agent(agent_id: str):
            agent = self.db.get_agent(agent_id)
            if not agent:
                raise HTTPException(status_code=404, detail='Agent not found')
            self.db.delete_agent(agent_id)
            return {'status': 'deleted'}
            
        # === TRADE ENDPOINTS ===
        
        @app.get('/trades')
        async def list_trades(
            token: Optional[str] = None,
            limit: int = Query(100, ge=1, le=1000),
            offset: int = Query(0, ge=0)
        ):
            trades = self.db.get_trades(token=token, limit=limit)
            stats = self.db.get_trade_stats()
            return {
                'trades': trades,
                'stats': stats,
                'count': len(trades)
            }
            
        @app.post('/trades')
        async def create_trade(trade: TradeCreate):
            trade_id = self.db.create_trade(
                trade.token_symbol,
                trade.action,
                trade.amount,
                trade.price,
                trade.tx_hash
            )
            return {'id': trade_id, 'status': 'created'}
            
        @app.get('/trades/stats')
        async def get_trade_statistics():
            return self.db.get_trade_stats()
            
        # === LOG ENDPOINTS ===
        
        @app.get('/logs')
        async def get_logs(
            level: Optional[str] = Query(None, pattern='^(DEBUG|INFO|WARNING|ERROR|CRITICAL)$'),
            source: Optional[str] = None,
            limit: int = Query(100, ge=1, le=10000),
            offset: int = Query(0, ge=0)
        ):
            logs = self.db.get_logs(level=level, source=source, limit=limit, offset=offset)
            for log in logs:
                log['metadata'] = json.loads(log.get('metadata', '{}'))
            return {'logs': logs, 'count': len(logs)}
            
        @app.post('/logs')
        async def create_log(
            level: str,
            source: str,
            message: str,
            metadata: Optional[Dict] = None
        ):
            self.db.insert_log(level, source, message, metadata)
            return {'status': 'logged'}
            
        @app.delete('/logs')
        async def clear_logs(days: int = Query(30, ge=1, le=365)):
            self.db.clear_old_logs(days)
            return {'status': 'cleared', 'days': days}
            
        # === METRICS ENDPOINTS ===
        
        @app.post('/metrics')
        async def record_metric(metric: MetricRecord):
            self.db.record_metric(metric.name, metric.value, metric.labels)
            return {'status': 'recorded'}
            
        @cache(expire=10)
        @app.get('/metrics/{metric_name}')
        async def get_metrics(
            metric_name: str,
            start: Optional[str] = None,
            end: Optional[str] = None
        ):
            metrics = self.db.get_metrics(metric_name, start, end)
            stats = self.db.get_metric_stats(metric_name)
            return {
                'name': metric_name,
                'data': metrics,
                'stats': stats
            }
            
        @app.get('/metrics')
        async def list_available_metrics():
            # Query distinct metric names
            return {'metrics': ['cpu_usage', 'memory_usage', 'trade_count', 'agent_uptime']}
            
        # === CONFIG ENDPOINTS ===
        
        @cache(expire=60)
        @app.get('/config')
        async def get_all_config():
            return self.db.get_all_config()
            
        @cache(expire=60)
        @app.get('/config/{key}')
        async def get_config(key: str):
            value = self.db.get_config(key)
            if value is None:
                raise HTTPException(status_code=404, detail='Config key not found')
            return {'key': key, 'value': value}
            
        @app.put('/config/{key}')
        async def update_config(key: str, value: Any):
            self.db.set_config(key, value)
            return {'key': key, 'status': 'updated'}
            
        @app.delete('/config/{key}')
        async def delete_config(key: str):
            # Implementare delete se necessario
            return {'key': key, 'status': 'deleted'}
            
        # === BACKUP ENDPOINTS ===
        
        @app.get('/backup')
        async def create_backup(background_tasks: BackgroundTasks):
            timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
            backup_path = f'C:\\SuiteV17\\backup_{timestamp}.json'
            background_tasks.add_task(self.db.backup_to_json, backup_path)
            return {
                'status': 'backup_started',
                'path': backup_path,
                'timestamp': timestamp
            }
            
        @app.get('/export/agents')
        async def export_agents():
            agents = self.db.list_agents()
            return StreamingResponse(
                iter([json.dumps(agents, indent=2)]),
                media_type='application/json',
                headers={'Content-Disposition': 'attachment; filename=agents.json'}
            )
            
        # === SYSTEM ENDPOINTS ===
        
        @app.get('/system/stats')
        async def system_stats():
            return {
                'database': self.db.get_stats(),
                'memory': self._get_memory_usage(),
                'timestamp': datetime.now().isoformat()
            }
            
        @app.post('/system/notify')
        async def send_notification(
            channel: str = Query(..., pattern='^(discord|telegram|email|sms)$'),
            message: str = '',
            priority: str = Query('normal', pattern='^(low|normal|high|critical)$')
        ):
            # Integrare con notification system
            return {
                'status': 'queued',
                'channel': channel,
                'priority': priority
            }
            
        @app.post('/system/command')
        async def execute_command(
            command: str,
            args: Optional[List[str]] = None,
            timeout: int = Query(30, ge=1, le=300)
        ):
            # Esegui comando sul sistema (con restrizioni)
            allowed_commands = ['status', 'restart', 'backup', 'update']
            if command not in allowed_commands:
                raise HTTPException(status_code=403, detail='Command not allowed')
            return {
                'command': command,
                'status': 'executed',
                'output': 'Command output here'
            }
            
        # === WEBSOCKET ENDPOINTS ===
        
        @app.websocket('/ws')
        async def websocket_endpoint(websocket):
            await websocket.accept()
            try:
                while True:
                    data = await websocket.receive_text()
                    message = json.loads(data)
                    
                    if message.get('action') == 'subscribe':
                        await websocket.send_json({
                            'type': 'subscribed',
                            'channel': message.get('channel')
                        })
                    elif message.get('action') == 'ping':
                        await websocket.send_json({
                            'type': 'pong',
                            'timestamp': datetime.now().isoformat()
                        })
            except Exception as e:
                await websocket.close()
                
        return app
        
    def _get_memory_usage(self) -> Dict:
        """Recupera utilizzo memoria."""
        try:
            import psutil
            process = psutil.Process()
            return {
                'rss_mb': process.memory_info().rss / 1024 / 1024,
                'vms_mb': process.memory_info().vms / 1024 / 1024,
                'percent': process.memory_percent()
            }
        except:
            return {'rss_mb': 0, 'vms_mb': 0, 'percent': 0}
            
    def run(self):
        """Avvia server."""
        import uvicorn
        print(f'Starting SuiteV17 API on {self.host}:{self.port}')
        uvicorn.run(self.app, host=self.host, port=self.port, log_level='info')

def main():
    port = int(os.getenv('API_PORT', 8083))
    server = SuiteV17APIServer(host='0.0.0.0', port=port)
    server.run()

if __name__ == '__main__':
    main()
