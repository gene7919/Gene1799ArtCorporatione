#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SuiteV17 Unified Orchestrator v4.1 - Agent Integration Edition
Con endpoint per tutti gli agenti:
- AI Server (ai_server_electron.py)
- Zora Agent (Solana operations)
- Agente Correttore (code analysis)
- Synaptic Agent System
- Performance Optimizer
"""
import subprocess
import json
import time
import asyncio
import threading
import os
import sys
import psutil
import socket
import requests
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any

from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS

SUITE_DIR = Path(r'C:\SuiteV17')
sys.path.insert(0, str(SUITE_DIR))

app = Flask(__name__, static_folder=str(SUITE_DIR))
CORS(app)

SERVICES_CONFIG = {
    'ai_server': {'name': 'AI Server', 'script': 'ai_server_electron.py', 'port': 8099, 'auto_start': True, 'color': '#00ff88', 'description': 'AI Text/Audio/Image/Voice Generation'},
    'api_server': {'name': 'API Server', 'script': 'api_server.py', 'port': 8083, 'auto_start': True, 'color': '#00ccff', 'description': 'API REST SuiteV17'},
    'gateway': {'name': 'API Gateway', 'script': 'api_gateway.py', 'port': 8080, 'auto_start': True, 'color': '#ffaa00', 'description': 'Gateway per routing richieste'},
    'websocket': {'name': 'WebSocket', 'script': 'websocket_server.py', 'port': 8081, 'auto_start': False, 'color': '#ff00ff', 'description': 'Server WebSocket realtime'},
    'social': {'name': 'Social', 'script': 'social_automation.py', 'port': None, 'auto_start': False, 'color': '#ff5555', 'description': 'Automazione social media'}
}

# Configurazione agenti
AGENTS_CONFIG = {
    'zora': {'name': 'Zora Agent', 'port': 3010, 'script': 'zora_agent.py', 'enabled': True},
    'correttore': {'name': 'Agente Correttore', 'port': 3020, 'script': 'agent_correttore.py', 'enabled': True}
}

class UnifiedOrchestrator:
    def __init__(self):
        self.services = {k: {**v, 'process': None, 'started_at': None} for k, v in SERVICES_CONFIG.items()}
        self.agents = {}
        self.logs = []
        self.ai_cloud = None
        self.synaptic_swarm = None
        self.perf_optimizer = None
        self._running = False
        self.ai_stats = {'cloud_connected': False, 'agents_active': 0, 'total_requests': 0, 'avg_latency': 0.0}
        self._init_ai_systems()
        self._start_monitoring()
        
    def _init_ai_systems(self):
        try:
            from ai_cloud_connector import ai_cloud
            self.ai_cloud = ai_cloud
            self.ai_stats['cloud_connected'] = any(s.available for s in self.ai_cloud.providers.values())
            self.log('AI Cloud Connector pronto', 'SUCCESS')
        except Exception as e:
            self.log(f'AI Cloud non disponibile: {e}', 'WARNING')
        try:
            from synaptic_agent_system import synaptic_swarm
            self.synaptic_swarm = synaptic_swarm
            self.log('Synaptic Agent System pronto', 'SUCCESS')
        except Exception as e:
            self.log(f'Synaptic System non disponibile: {e}', 'WARNING')
        try:
            from performance_optimizer import perf_optimizer
            self.perf_optimizer = perf_optimizer
            self.perf_optimizer.start_monitoring(interval=2.0)
            self.log('Performance Optimizer avviato', 'SUCCESS')
        except Exception as e:
            self.log(f'Performance Optimizer non disponibile: {e}', 'WARNING')
            
    def _start_monitoring(self):
        self._running = True
        threading.Thread(target=self._monitor_loop, daemon=True).start()
        
    def _monitor_loop(self):
        while self._running:
            try:
                for service_id, service in self.services.items():
                    if service['process'] and service['process'].poll() is not None:
                        self.log(f'Servizio {service["name"]} arrestato', 'WARNING')
                        service['process'] = None
                        service['started_at'] = None
                time.sleep(5)
            except:
                time.sleep(5)
                
    def log(self, message: str, level: str = 'INFO'):
        entry = {'timestamp': datetime.now().isoformat(), 'level': level, 'message': message}
        self.logs.append(entry)
        if len(self.logs) > 2000:
            self.logs = self.logs[-1000:]
        print(f'[{level}] {message}')
        
    def start_service(self, service_id: str) -> Dict:
        if service_id not in self.services:
            return {'success': False, 'error': 'Servizio non trovato'}
        service = self.services[service_id]
        if service['process'] and service['process'].poll() is None:
            return {'success': False, 'error': f\"{service['name']} gia in esecuzione\"}
        script_path = SUITE_DIR / service['script']
        if not script_path.exists():
            return {'success': False, 'error': f\"Script non trovato: {service['script']}\"}
        try:
            self.log(f\"Avvio {service['name']}...\")
            service['process'] = subprocess.Popen(
                [sys.executable, str(script_path)],
                stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                creationflags=subprocess.CREATE_NO_WINDOW, cwd=str(SUITE_DIR)
            )
            service['started_at'] = datetime.now().isoformat()
            self.log(f\"{service['name']} avviato (PID: {service['process'].pid})\", 'SUCCESS')
            if service['port']:
                time.sleep(2)
            return {'success': True, 'pid': service['process'].pid, 'port': service['port'], 'name': service['name']}
        except Exception as e:
            self.log(f\"Errore avvio {service['name']}: {e}\", 'ERROR')
            return {'success': False, 'error': str(e)}
            
    def stop_service(self, service_id: str) -> Dict:
        if service_id not in self.services:
            return {'success': False, 'error': 'Servizio non trovato'}
        service = self.services[service_id]
        if not service['process']:
            return {'success': False, 'error': f\"{service['name']} non in esecuzione\"}
        try:
            self.log(f\"Arresto {service['name']}...\")
            parent = psutil.Process(service['process'].pid)
            for child in parent.children(recursive=True):
                try: child.terminate()
                except: pass
            parent.terminate()
            gone, alive = psutil.wait_procs([parent], timeout=3)
            for p in alive:
                try: p.kill()
                except: pass
            service['process'] = None
            service['started_at'] = None
            self.log(f\"{service['name']} arrestato\", 'SUCCESS')
            return {'success': True}
        except Exception as e:
            self.log(f\"Errore arresto {service['name']}: {e}\", 'ERROR')
            return {'success': False, 'error': str(e)}
            
    def get_service_status(self, service_id: str) -> Dict:
        if service_id not in self.services:
            return None
        service = self.services[service_id]
        status = {'id': service_id, 'name': service['name'], 'port': service['port'], 'color': service['color'], 'auto_start': service['auto_start'], 'description': service.get('description', ''), 'running': False}
        if service['process']:
            status['running'] = service['process'].poll() is None
            status['pid'] = service['process'].pid if status['running'] else None
            status['started_at'] = service.get('started_at')
        return status
        
    def get_all_status(self) -> Dict:
        return {k: self.get_service_status(k) for k in self.services}
        
    def start_all(self) -> Dict:
        results = {}
        for service_id, service in self.services.items():
            if service.get('auto_start', False):
                results[service_id] = self.start_service(service_id)
                time.sleep(1.5)
        return results
        
    def stop_all(self) -> Dict:
        results = {}
        for service_id in self.services:
            if self.services[service_id]['process']:
                results[service_id] = self.stop_service(service_id)
        return results
        
    async def ai_generate(self, prompt: str, system: str = None) -> Dict:
        if not self.ai_cloud:
            return {'error': 'AI Cloud non disponibile'}
        start_time = time.time()
        result = await self.ai_cloud.generate_text(prompt, system)
        self.ai_stats['total_requests'] += 1
        latency = (time.time() - start_time) * 1000
        self.ai_stats['avg_latency'] = (self.ai_stats['avg_latency'] * 0.9 + latency * 0.1)
        return result
        
    def create_synaptic_agent(self, name: str, specialization: str = 'general') -> Dict:
        if not self.synaptic_swarm:
            return {'error': 'Synaptic System non disponibile'}
        agent = self.synaptic_swarm.create_agent(name, specialization)
        self.ai_stats['agents_active'] = len(self.synaptic_swarm.agents)
        return {'success': True, 'agent_id': agent.agent_id, 'name': agent.name, 'specialization': agent.specialization}
        
    def get_performance_stats(self) -> Dict:
        if self.perf_optimizer:
            return self.perf_optimizer.get_stats()
        return {'error': 'Performance Optimizer non disponibile'}
        
    # === PROXY PER AGENTI ===
    def proxy_ai_server(self, endpoint: str, data: Dict = None) -> Dict:
        try:
            if data:
                resp = requests.post(f'http://localhost:8099{endpoint}', json=data, timeout=30)
            else:
                resp = requests.get(f'http://localhost:8099{endpoint}', timeout=5)
            return resp.json() if resp.status_code == 200 else {'error': f'HTTP {resp.status_code}'}
        except Exception as e:
            return {'error': str(e)}

orchestrator = UnifiedOrchestrator()

@app.route('/')
def index():
    return send_from_directory(str(SUITE_DIR), 'dashboard.html')

@app.route('/api/status')
def api_status():
    return jsonify({
        'orchestrator': {'version': '4.1', 'name': 'SuiteV17 Unified Orchestrator', 'timestamp': datetime.now().isoformat()},
        'services': orchestrator.get_all_status(),
        'ai_stats': orchestrator.ai_stats,
        'performance': orchestrator.get_performance_stats(),
        'logs': orchestrator.logs[-100:],
        'agents': AGENTS_CONFIG
    })

@app.route('/api/services')
def list_services():
    status = orchestrator.get_all_status()
    result = {}
    for sid, s in status.items():
        result[sid] = {'running': s['running'], 'info': {'name': s['name'], 'port': s['port'], 'desc': s.get('description', '')}}
    return jsonify(result)

@app.route('/api/service/<service_id>/start', methods=['POST'])
def start_service_api(service_id):
    return jsonify(orchestrator.start_service(service_id))

@app.route('/api/service/<service_id>/stop', methods=['POST'])
def stop_service_api(service_id):
    return jsonify(orchestrator.stop_service(service_id))

@app.route('/api/services/start-all', methods=['POST'])
def start_all_api():
    return jsonify({'success': True, 'results': orchestrator.start_all()})

@app.route('/api/services/stop-all', methods=['POST'])
def stop_all_api():
    return jsonify({'success': True, 'results': orchestrator.stop_all()})

# === AI ENDPOINTS ===
@app.route('/api/ai/generate', methods=['POST'])
def ai_generate_api():
    data = request.json or {}
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    result = loop.run_until_complete(orchestrator.ai_generate(data.get('prompt', ''), data.get('system')))
    loop.close()
    return jsonify(result)

@app.route('/api/ai/create-agent', methods=['POST'])
def create_agent_api():
    data = request.json or {}
    return jsonify(orchestrator.create_synaptic_agent(data.get('name', 'Agent'), data.get('specialization', 'general')))

@app.route('/api/ai/agents')
def list_agents_api():
    if orchestrator.synaptic_swarm:
        return jsonify(orchestrator.synaptic_swarm.get_swarm_stats())
    return jsonify({'error': 'Synaptic System non disponibile'})

@app.route('/api/performance')
def performance_api():
    return jsonify(orchestrator.get_performance_stats())

@app.route('/api/logs')
def logs_api():
    return jsonify({'logs': orchestrator.logs[-200:]})

# === AGENT PROXY ENDPOINTS ===
@app.route('/api/agent/ai/status')
def ai_server_status():
    return jsonify(orchestrator.proxy_ai_server('/api/status'))

@app.route('/api/agent/ai/generate', methods=['POST'])
def ai_server_generate():
    return jsonify(orchestrator.proxy_ai_server('/api/generate', request.json or {}))

@app.route('/api/agent/ai/metrics')
def ai_server_metrics():
    return jsonify(orchestrator.proxy_ai_server('/api/metrics'))

if __name__ == '__main__':
    print('='*70)
    print('  SuiteV17 Unified Orchestrator v4.1')
    print('  Dashboard: http://localhost:9001')
    print('  API:       http://localhost:9001/api')
    print('='*70)
    try:
        app.run(host='0.0.0.0', port=9001, debug=False, threaded=True)
    except KeyboardInterrupt:
        print('\\n[INFO] Arresto orchestratore...')
        orchestrator._running = False
        orchestrator.stop_all()
        if orchestrator.perf_optimizer:
            orchestrator.perf_optimizer.stop_monitoring()
        print('[OK] Orchestrator arrestato.')
