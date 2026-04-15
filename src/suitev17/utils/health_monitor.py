#!/usr/bin/env python3
"""
SuiteV17 Health Monitor - Health checks, monitoring e self-healing
"""
import asyncio
import aiohttp
import psutil
import os
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Callable, Any
from dataclasses import dataclass
from enum import Enum
import threading
import time

class HealthStatus(Enum):
    HEALTHY = 'healthy'
    DEGRADED = 'degraded'
    UNHEALTHY = 'unhealthy'
    UNKNOWN = 'unknown'

@dataclass
class HealthCheck:
    name: str
    status: HealthStatus
    last_check: str
    response_time_ms: float
    message: str
    metadata: Dict

class HealthMonitor:
    """Monitor health di tutti i componenti SuiteV17."""
    
    def __init__(self, check_interval: int = 30):
        self.check_interval = check_interval
        self.checks: Dict[str, HealthCheck] = {}
        self.services: Dict[str, Dict] = {}
        self.running = False
        self._thread: Optional[threading.Thread] = None
        self._callbacks: List[Callable] = []
        self._lock = threading.Lock()
        
    def register_service(self, name: str, port: int, 
                        health_endpoint: str = '/health',
                        check_type: str = 'http'):
        """Registra un servizio da monitorare."""
        self.services[name] = {
            'port': port,
            'endpoint': health_endpoint,
            'type': check_type,
            'failures': 0,
            'last_success': None
        }
        
    def register_callback(self, callback: Callable):
        """Registra callback per cambio stato."""
        self._callbacks.append(callback)
        
    async def check_http_endpoint(self, name: str, config: Dict) -> HealthCheck:
        """Check HTTP endpoint."""
        start_time = time.time()
        
        try:
            url = 'http://localhost:' + str(config['port']) + config['endpoint']
            
            timeout = aiohttp.ClientTimeout(total=5)
            async with aiohttp.ClientSession(timeout=timeout) as session:
                async with session.get(url) as response:
                    elapsed = (time.time() - start_time) * 1000
                    
                    if response.status == 200:
                        data = await response.json()
                        return HealthCheck(
                            name=name,
                            status=HealthStatus.HEALTHY,
                            last_check=datetime.now().isoformat(),
                            response_time_ms=elapsed,
                            message='OK',
                            metadata=data
                        )
                    else:
                        return HealthCheck(
                            name=name,
                            status=HealthStatus.DEGRADED,
                            last_check=datetime.now().isoformat(),
                            response_time_ms=elapsed,
                            message=f'HTTP {response.status}',
                            metadata={}
                        )
                        
        except Exception as e:
            return HealthCheck(
                name=name,
                status=HealthStatus.UNHEALTHY,
                last_check=datetime.now().isoformat(),
                response_time_ms=(time.time() - start_time) * 1000,
                message=str(e),
                metadata={}
            )
            
    def check_system_resources(self) -> HealthCheck:
        """Check risorse sistema."""
        try:
            cpu_percent = psutil.cpu_percent(interval=1)
            memory = psutil.virtual_memory()
            disk = psutil.disk_usage('/')
            
            status = HealthStatus.HEALTHY
            message = 'System OK'
            
            # Check thresholds
            if cpu_percent > 90:
                status = HealthStatus.DEGRADED
                message = f'High CPU: {cpu_percent}%'
            elif memory.percent > 90:
                status = HealthStatus.DEGRADED
                message = f'High Memory: {memory.percent}%'
            elif disk.percent > 90:
                status = HealthStatus.DEGRADED
                message = f'High Disk: {disk.percent}%'
                
            return HealthCheck(
                name='system_resources',
                status=status,
                last_check=datetime.now().isoformat(),
                response_time_ms=0,
                message=message,
                metadata={
                    'cpu_percent': cpu_percent,
                    'memory_percent': memory.percent,
                    'disk_percent': disk.percent,
                    'memory_available_gb': memory.available / 1024**3
                }
            )
            
        except Exception as e:
            return HealthCheck(
                name='system_resources',
                status=HealthStatus.UNHEALTHY,
                last_check=datetime.now().isoformat(),
                response_time_ms=0,
                message=str(e),
                metadata={}
            )
            
    async def run_checks(self):
        """Esegue tutti i health checks."""
        # Check HTTP services
        for name, config in self.services.items():
            if config['type'] == 'http':
                check = await self.check_http_endpoint(name, config)
                
                with self._lock:
                    old_status = self.checks.get(name)
                    self.checks[name] = check
                    
                    # Update failure tracking
                    if check.status == HealthStatus.UNHEALTHY:
                        config['failures'] += 1
                    else:
                        config['failures'] = 0
                        config['last_success'] = datetime.now().isoformat()
                        
                    # Trigger callbacks on status change
                    if old_status and old_status.status != check.status:
                        for callback in self._callbacks:
                            try:
                                callback(name, old_status.status, check.status)
                            except:
                                pass
                                
        # Check system resources
        system_check = self.check_system_resources()
        with self._lock:
            self.checks['system_resources'] = system_check
            
    def should_restart(self, name: str) -> bool:
        """Verifica se servizio deve essere riavviato."""
        if name not in self.services:
            return False
        return self.services[name]['failures'] >= 3
        
    def start(self):
        """Avvia monitoring in background."""
        if self.running:
            return
            
        self.running = True
        
        def monitor_loop():
            import asyncio
            asyncio.run(self._monitor())
            
        self._thread = threading.Thread(target=monitor_loop, daemon=True)
        self._thread.start()
        
    async def _monitor(self):
        """Loop monitoring."""
        while self.running:
            await self.run_checks()
            await asyncio.sleep(self.check_interval)
            
    def stop(self):
        """Ferma monitoring."""
        self.running = False
        if self._thread:
            self._thread.join(timeout=5)
            
    def get_status(self) -> Dict:
        """Stato completo."""
        with self._lock:
            return {
                'overall': self._calculate_overall_status(),
                'checks': {
                    name: {
                        'status': check.status.value,
                        'last_check': check.last_check,
                        'message': check.message,
                        'response_time_ms': check.response_time_ms
                    }
                    for name, check in self.checks.items()
                },
                'timestamp': datetime.now().isoformat()
            }
            
    def _calculate_overall_status(self) -> str:
        """Calcola stato globale."""
        if not self.checks:
            return HealthStatus.UNKNOWN.value
            
        statuses = [c.status for c in self.checks.values()]
        
        if any(s == HealthStatus.UNHEALTHY for s in statuses):
            return HealthStatus.UNHEALTHY.value
        elif any(s == HealthStatus.DEGRADED for s in statuses):
            return HealthStatus.DEGRADED.value
        else:
            return HealthStatus.HEALTHY.value
            
    def get_unhealthy_services(self) -> List[str]:
        """Servizi non healthy."""
        with self._lock:
            return [
                name for name, check in self.checks.items()
                if check.status in [HealthStatus.UNHEALTHY, HealthStatus.DEGRADED]
            ]

class SelfHealingManager:
    """Gestisce auto-recovery dei servizi."""
    
    def __init__(self, monitor: HealthMonitor):
        self.monitor = monitor
        self.restart_attempts: Dict[str, int] = {}
        self.max_restarts = 5
        self.restart_window = 300  # 5 minuti
        self.restart_history: Dict[str, List] = {}
        
    def register_handlers(self):
        """Registra handlers per auto-healing."""
        self.monitor.register_callback(self._on_status_change)
        
    def _on_status_change(self, service: str, old_status: HealthStatus, 
                         new_status: HealthStatus):
        """Handler cambio stato."""
        if new_status == HealthStatus.UNHEALTHY:
            self._handle_unhealthy(service)
            
    def _handle_unhealthy(self, service: str):
        """Gestisce servizio unhealthy."""
        # Check se possiamo riavviare
        if not self._can_restart(service):
            print(f'[SelfHealing] Service {service}: max restarts exceeded')
            return
            
        print(f'[SelfHealing] Attempting restart of {service}')
        self._restart_service(service)
        
    def _can_restart(self, service: str) -> bool:
        """Verifica se possiamo riavviare."""
        now = datetime.now()
        
        # Cleanup old history
        if service in self.restart_history:
            cutoff = now - timedelta(seconds=self.restart_window)
            self.restart_history[service] = [
                t for t in self.restart_history[service] if t > cutoff
            ]
        else:
            self.restart_history[service] = []
            
        return len(self.restart_history[service]) < self.max_restarts
        
    def _restart_service(self, service: str):
        """Riavvia servizio."""
        self.restart_history[service].append(datetime.now())
        
        # In produzione qui useresti PM2, systemd, o docker
        print(f'[SelfHealing] Restart command would execute for {service}')
        
        # Esempio con PM2
        # subprocess.run(['pm2', 'restart', service])

def main():
    """Test health monitor."""
    monitor = HealthMonitor(check_interval=10)
    
    # Registra servizi
    monitor.register_service('api', 8083, '/health')
    monitor.register_service('websocket', 8765)
    monitor.register_service('social', 3007, '/api/health')
    
    # Registra callback
    def on_change(service, old, new):
        print(f'[{datetime.now().isoformat()}] {service}: {old.value} -> {new.value}')
    
    monitor.register_callback(on_change)
    
    print('Starting health monitor...')
    print('Press Ctrl+C to stop')
    print()
    
    monitor.start()
    
    try:
        while True:
            time.sleep(5)
            status = monitor.get_status()
            print("Overall: " + status["overall"])
            print("Unhealthy: " + str(monitor.get_unhealthy_services()))
            print()
    except KeyboardInterrupt:
        monitor.stop()
        print('Stopped')

if __name__ == '__main__':
    main()
