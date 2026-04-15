#!/usr/bin/env python3
"""
SuiteV17 Unified Launcher
Avvia tutti i servizi coordinati: API, WebSocket, Scheduler, Agenti
"""
import os
import sys
import asyncio
import subprocess
import json
from datetime import datetime
from typing import Dict, List
import signal

class Service:
    """Rappresenta un servizio da avviare."""
    def __init__(self, name: str, command: str, port: int, 
                 env_vars: Dict = None, cwd: str = None):
        self.name = name
        self.command = command
        self.port = port
        self.env_vars = env_vars or {}
        self.cwd = cwd or os.getcwd()
        self.process = None
        self.status = 'stopped'
        
class SuiteV17Launcher:
    """Launcher unificato per SuiteV17."""
    
    def __init__(self):
        self.services: Dict[str, Service] = {}
        self.setup_services()
        
    def setup_services(self):
        """Configura i servizi da avviare."""
        # Python API Server
        self.services['api'] = Service(
            name='API Server',
            command='python api_server.py',
            port=8083,
            env_vars={'PORT': '8083'}
        )
        
        # WebSocket Server
        self.services['websocket'] = Service(
            name='WebSocket Server',
            command='python websocket_server.py',
            port=8765
        )
        
        # Master Orchestrator
        self.services['master'] = Service(
            name='SuiteV17 Master',
            command='python suitev17_master.py',
            port=None
        )
        
        # Social Server (Node.js)
        self.services['social'] = Service(
            name='Social Server',
            command='node server.js',
            port=3007
        )
        
        # Gateway (Node.js)
        self.services['gateway'] = Service(
            name='Gateway',
            command='node gateway.js',
            port=8080
        )
        
    async def check_port(self, port: int) -> bool:
        """Verifica se una porta è disponibile."""
        import socket
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as s:
                s.settimeout(1)
                result = s.connect_ex(('localhost', port))
                return result != 0  # True se porta libera
        except:
            return False
            
    async def start_service(self, service: Service) -> bool:
        """Avvia un singolo servizio."""
        try:
            # Verifica porta
            if service.port:
                if not await self.check_port(service.port):
                    print(f'[WARNING] Port {service.port} for {service.name} is already in use')
                    return False
            
            # Prepara environment
            env = os.environ.copy()
            env.update(service.env_vars)
            
            # Avvia processo
            if sys.platform == 'win32':
                service.process = subprocess.Popen(
                    service.command,
                    shell=True,
                    env=env,
                    cwd=service.cwd,
                    creationflags=subprocess.CREATE_NEW_CONSOLE
                )
            else:
                service.process = subprocess.Popen(
                    service.command.split(),
                    env=env,
                    cwd=service.cwd
                )
            
            service.status = 'running'
            print(f'[STARTED] {service.name} (PID: {service.process.pid})')
            return True
            
        except Exception as e:
            print(f'[ERROR] Failed to start {service.name}: {e}')
            service.status = 'failed'
            return False
            
    async def start_all(self):
        """Avvia tutti i servizi."""
        print('=' * 70)
        print('SUITEV17 UNIFIED LAUNCHER')
        print('=' * 70)
        print(f'Started at: {datetime.now().isoformat()}')
        print()
        
        # Start in order
        order = ['gateway', 'api', 'websocket', 'social', 'master']
        
        for name in order:
            if name in self.services:
                service = self.services[name]
                print(f'\nStarting {service.name}...')
                await self.start_service(service)
                await asyncio.sleep(2)  # Delay tra i servizi
        
        print()
        print('=' * 70)
        print('SERVICES STATUS')
        print('=' * 70)
        
        for name, service in self.services.items():
            status_icon = '?' if service.status == 'running' else '?'
            print(f'{status_icon} {service.name:20} {service.status:10} Port: {service.port or \"N/A\"}')
        
        print()
        print('Press Ctrl+C to stop all services')
        
        # Keep running
        try:
            while True:
                await asyncio.sleep(5)
                # Check health
                for name, service in self.services.items():
                    if service.process and service.status == 'running':
                        if service.process.poll() is not None:
                            print(f'[WARNING] {service.name} stopped unexpectedly')
                            service.status = 'stopped'
        except KeyboardInterrupt:
            await self.stop_all()
            
    async def stop_all(self):
        """Ferma tutti i servizi."""
        print()
        print('=' * 70)
        print('STOPPING ALL SERVICES')
        print('=' * 70)
        
        for name, service in self.services.items():
            if service.process and service.status == 'running':
                try:
                    if sys.platform == 'win32':
                        subprocess.run(f'taskkill /F /PID {service.process.pid} /T', 
                                     shell=True, check=False)
                    else:
                        service.process.terminate()
                        service.process.wait(timeout=5)
                    service.status = 'stopped'
                    print(f'[STOPPED] {service.name}')
                except Exception as e:
                    print(f'[ERROR] Failed to stop {service.name}: {e}')
        
        print()
        print('All services stopped. Goodbye!')

def main():
    launcher = SuiteV17Launcher()
    
    # Handle signals
    def signal_handler(sig, frame):
        print('\\nReceived shutdown signal...')
        asyncio.get_event_loop().stop()
    
    signal.signal(signal.SIGINT, signal_handler)
    signal.signal(signal.SIGTERM, signal_handler)
    
    # Run
    try:
        asyncio.run(launcher.start_all())
    except KeyboardInterrupt:
        print('\\nShutdown complete')

if __name__ == '__main__':
    main()
