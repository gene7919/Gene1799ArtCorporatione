#!/usr/bin/env python3
"""
SuiteV17 API Gateway - Gateway unificato con rate limiting, auth e routing
"""
import os
import json
import asyncio
import time
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Callable, Any, Set
from dataclasses import dataclass
from enum import Enum
import hashlib
import hmac
import secrets

# FastAPI imports
try:
    from fastapi import FastAPI, Request, Response, HTTPException, Depends
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.middleware.trustedhost import TrustedHostMiddleware
    from fastapi.responses import JSONResponse
    from fastapi.security import HTTPBearer, HTTPAuthorizationCredentials
    import uvicorn
    HAS_FASTAPI = True
except ImportError:
    HAS_FASTAPI = False
    print('Installa: pip install fastapi uvicorn')

class RateLimitStrategy(Enum):
    FIXED_WINDOW = 'fixed_window'
    SLIDING_WINDOW = 'sliding_window'
    TOKEN_BUCKET = 'token_bucket'

@dataclass
class RateLimitConfig:
    requests_per_minute: int = 60
    burst_size: int = 10
    strategy: RateLimitStrategy = RateLimitStrategy.SLIDING_WINDOW

class RateLimiter:
    """Rate limiter multi-strategy."""
    
    def __init__(self, config: RateLimitConfig = None):
        self.config = config or RateLimitConfig()
        self.requests: Dict[str, List[float]] = {}
        self.tokens: Dict[str, float] = {}
        self.last_update: Dict[str, float] = {}
    
    def is_allowed(self, key: str) -> bool:
        """Verifica se richiesta è permessa."""
        now = time.time()
        
        if self.config.strategy == RateLimitStrategy.SLIDING_WINDOW:
            return self._check_sliding_window(key, now)
        elif self.config.strategy == RateLimitStrategy.FIXED_WINDOW:
            return self._check_fixed_window(key, now)
        else:
            return self._check_token_bucket(key, now)
    
    def _check_sliding_window(self, key: str, now: float) -> bool:
        """Sliding window rate limit."""
        window_start = now - 60  # 1 minuto
        
        if key not in self.requests:
            self.requests[key] = []
        
        # Rimuovi richieste vecchie
        self.requests[key] = [t for t in self.requests[key] if t > window_start]
        
        # Verifica limite
        if len(self.requests[key]) >= self.config.requests_per_minute:
            return False
        
        self.requests[key].append(now)
        return True
    
    def _check_fixed_window(self, key: str, now: float) -> bool:
        """Fixed window rate limit."""
        window_key = f'{key}:{int(now // 60)}'
        
        if window_key not in self.requests:
            self.requests[window_key] = []
        
        if len(self.requests[window_key]) >= self.config.requests_per_minute:
            return False
        
        self.requests[window_key].append(now)
        return True
    
    def _check_token_bucket(self, key: str, now: float) -> bool:
        """Token bucket rate limit."""
        if key not in self.tokens:
            self.tokens[key] = self.config.burst_size
            self.last_update[key] = now
        
        # Aggiungi token
        time_passed = now - self.last_update[key]
        tokens_to_add = time_passed * (self.config.requests_per_minute / 60)
        self.tokens[key] = min(self.config.burst_size, self.tokens[key] + tokens_to_add)
        self.last_update[key] = now
        
        # Consuma token
        if self.tokens[key] >= 1:
            self.tokens[key] -= 1
            return True
        
        return False
    
    def get_remaining(self, key: str) -> int:
        """Ritorna richieste rimanenti."""
        if not self.is_allowed(key):
            return 0
        return self.config.requests_per_minute - len(self.requests.get(key, []))

class APIKeyManager:
    """Gestione API key."""
    
    def __init__(self):
        self.keys: Dict[str, Dict] = {}
        self.key_prefix = 'sv17_'
    
    def generate_key(self, name: str, permissions: List[str] = None, 
                     rate_limit: RateLimitConfig = None) -> str:
        """Genera nuova API key."""
        raw_key = secrets.token_urlsafe(32)
        key_id = self.key_prefix + hashlib.sha256(raw_key.encode()).hexdigest()[:16]
        
        self.keys[key_id] = {
            'name': name,
            'permissions': permissions or [],
            'rate_limit': rate_limit or RateLimitConfig(),
            'created_at': datetime.now().isoformat(),
            'last_used': None,
            'usage_count': 0
        }
        
        return key_id
    
    def validate_key(self, key: str) -> Optional[Dict]:
        """Valida API key."""
        if key not in self.keys:
            return None
        
        self.keys[key]['last_used'] = datetime.now().isoformat()
        self.keys[key]['usage_count'] += 1
        
        return self.keys[key]
    
    def revoke_key(self, key: str) -> bool:
        """Revoca API key."""
        if key in self.keys:
            del self.keys[key]
            return True
        return False

class APIGateway:
    """API Gateway unificato."""
    
    def __init__(self):
        self.app = FastAPI(
            title='SuiteV17 API Gateway',
            description='Unified API Gateway with rate limiting and auth',
            version='2.0.0'
        )
        
        self.rate_limiter = RateLimiter()
        self.api_key_manager = APIKeyManager()
        self.routes: Dict[str, Dict] = {}
        self.middlewares: List[Callable] = []
        
        self._setup_middleware()
        self._setup_routes()
    
    def _setup_middleware(self):
        """Configura middleware."""
        # CORS
        self.app.add_middleware(
            CORSMiddleware,
            allow_origins=['*'],  # Configura in produzione
            allow_credentials=True,
            allow_methods=['*'],
            allow_headers=['*']
        )
        
        # Trusted Hosts
        self.app.add_middleware(
            TrustedHostMiddleware,
            allowed_hosts=['*']  # Configura in produzione
        )
    
    def _setup_routes(self):
        """Configura routes."""
        security = HTTPBearer()
        
        @self.app.middleware('http')
        async def rate_limit_middleware(request: Request, call_next):
            """Middleware rate limiting."""
            client_ip = request.client.host
            
            if not self.rate_limiter.is_allowed(client_ip):
                return JSONResponse(
                    status_code=429,
                    content={'error': 'Rate limit exceeded'}
                )
            
            response = await call_next(request)
            
            # Aggiungi header rate limit
            remaining = self.rate_limiter.get_remaining(client_ip)
            response.headers['X-RateLimit-Remaining'] = str(remaining)
            
            return response
        
        @self.app.get('/health')
        async def health_check():
            return {
                'status': 'healthy',
                'timestamp': datetime.now().isoformat(),
                'gateway': 'SuiteV17 API Gateway',
                'version': '2.0.0'
            }
        
        @self.app.get('/status')
        async def gateway_status():
            return {
                'routes': len(self.routes),
                'active_keys': len(self.api_key_manager.keys),
                'rate_limit_strategy': self.rate_limiter.config.strategy.value
            }
        
        @self.app.post('/auth/key')
        async def create_api_key(name: str, permissions: List[str] = None):
            key = self.api_key_manager.generate_key(name, permissions)
            return {'api_key': key, 'name': name}
        
        @self.app.get('/proxy/{service}/{path:path}')
        async def proxy_request(
            service: str,
            path: str,
            request: Request,
            credentials: HTTPAuthorizationCredentials = Depends(security)
        ):
            """Proxy richiesta a servizio."""
            # Verifica API key
            api_key = credentials.credentials
            key_data = self.api_key_manager.validate_key(api_key)
            
            if not key_data:
                raise HTTPException(status_code=401, detail='Invalid API key')
            
            # Route to service
            return await self._route_to_service(service, path, request)
    
    async def _route_to_service(self, service: str, path: str, request: Request):
        """Inoltra richiesta al servizio."""
        # Implementazione base - in produzione usare aiohttp
        import httpx
        
        service_urls = {
            'api': 'http://localhost:8083',
            'websocket': 'http://localhost:8765',
            'social': 'http://localhost:3007'
        }
        
        if service not in service_urls:
            raise HTTPException(status_code=404, detail=f'Service {service} not found')
        
        try:
            async with httpx.AsyncClient() as client:
                response = await client.request(
                    method=request.method,
                    url=f'{service_urls[service]}/{path}',
                    headers=dict(request.headers),
                    params=dict(request.query_params)
                )
                return JSONResponse(
                    status_code=response.status_code,
                    content=response.json()
                )
        except Exception as e:
            raise HTTPException(status_code=502, detail=f'Proxy error: {str(e)}')
    
    def register_route(self, path: str, handler: Callable, 
                      methods: List[str] = None,
                      auth_required: bool = True):
        """Registra route dinamico."""
        methods = methods or ['GET']
        self.routes[path] = {
            'handler': handler,
            'methods': methods,
            'auth_required': auth_required
        }
    
    def run(self, host: str = '0.0.0.0', port: int = 8080):
        """Avvia gateway."""
        uvicorn.run(self.app, host=host, port=port)

def main():
    if not HAS_FASTAPI:
        print('FastAPI not installed')
        return
    
    gateway = APIGateway()
    print('API Gateway starting...')
    print('Features:')
    print('  - Rate limiting')
    print('  - API key auth')
    print('  - Service routing')
    print('  - Health checks')
    print()
    print('Run: gateway.run()')

if __name__ == '__main__' and HAS_FASTAPI:
    gateway = APIGateway()
    gateway.run()
