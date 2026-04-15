#!/usr/bin/env python3
"""
SuiteV17 Master Orchestrator v2.0
Sistema completo di orchestrazione per tutti i servizi SuiteV17
"""
import subprocess
import json
import time
import threading
import os
import sys
import psutil
import requests
from datetime import datetime
from flask import Flask, jsonify, request, render_template_string
from flask_cors import CORS

app = Flask(__name__)
CORS(app)

class SuiteV17Orchestrator:
    """Orchestratore principale per SuiteV17"""
    
    SERVICES = {
        'ai_server': {
            'name': 'AI Server',
            'script': 'ai_server_electron.py',
            'port': 8099,
            'process': None,
            'auto_start': True,
            'color': '#00ff88'
        },
        'api_server': {
            'name': 'API Server',
            'script': 'api_server.py',
            'port': 8083,
            'process': None,
            'auto_start': True,
            'color': '#00ccff'
        },
        'gateway': {
            'name': 'API Gateway',
            'script': 'api_gateway.py',
            'port': 8080,
            'process': None,
            'auto_start': True,
            'color': '#ffaa00'
        },
        'websocket': {
            'name': 'WebSocket Server',
            'script': 'websocket_server.py',
            'port': 8081,
            'process': None,
            'auto_start': False,
            'color': '#ff00ff'
        },
        'social': {
            'name': 'Social Automation',
            'script': 'social_automation.py',
            'port': None,
            'process': None,
            'auto_start': False,
            'color': '#ff5555'
        },
        'orchestrator_agent': {
            'name': 'Agent Orchestrator',
            'script': 'agent_orchestratore.py',
            'port': None,
            'process': None,
            'auto_start': False,
            'color': '#aa66ff'
        }
    }
    
    def __init__(self):
        self.running = False
        self.monitor_thread = None
        self.logs = []
        self.ai_status = {'connected': False, 'last_check': None}
        
    def log(self, message, level='INFO'):
        """Aggiunge log"""
        entry = {
            'timestamp': datetime.now().isoformat(),
            'level': level,
            'message': message
        }
        self.logs.append(entry)
        if len(self.logs) > 1000:
            self.logs = self.logs[-500:]
        print(f"[{level}] {message}")
        
    def start_service(self, service_id):
        """Avvia un servizio"""
        if service_id not in self.SERVICES:
            return {'success': False, 'error': 'Servizio non trovato'}
            
        service = self.SERVICES[service_id]
        
        if service['process'] and service['process'].poll() is None:
            return {'success': False, 'error': 'Servizio gia in esecuzione'}
            
        script_path = os.path.join(r'C:\SuiteV17', service['script'])
        if not os.path.exists(script_path):
            return {'success': False, 'error': f'Script non trovato: {service[script]}'}
            
        try:
            self.log(f'Avvio {service[name]}...')
            service['process'] = subprocess.Popen(
                [sys.executable, script_path],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                creationflags=subprocess.CREATE_NEW_CONSOLE
            )
            service['started_at'] = datetime.now().isoformat()
            self.log(f'{service[name]} avviato con PID {service[process].pid}')
            return {'success': True, 'pid': service['process'].pid}
        except Exception as e:
            self.log(f'Errore avvio {service[name]}: {e}', 'ERROR')
            return {'success': False, 'error': str(e)}
            
    def stop_service(self, service_id):
        """Ferma un servizio"""
        if service_id not in self.SERVICES:
            return {'success': False, 'error': 'Servizio non trovato'}
            
        service = self.SERVICES[service_id]
        
        if not service['process']:
            return {'success': False, 'error': 'Servizio non in esecuzione'}
            
        try:
            self.log(f'Arresto {service[name]}...')
            parent = psutil.Process(service['process'].pid)
            for child in parent.children(recursive=True):
                child.terminate()
            parent.terminate()
            service['process'] = None
            service['started_at'] = None
            self.log(f'{service[name]} arrestato')
            return {'success': True}
        except Exception as e:
            self.log(f'Errore arresto {service[name]}: {e}', 'ERROR')
            return {'success': False, 'error': str(e)}
            
    def get_service_status(self, service_id):
        """Ottiene lo stato di un servizio"""
        if service_id not in self.SERVICES:
            return None
            
        service = self.SERVICES[service_id]
        status = {
            'id': service_id,
            'name': service['name'],
            'port': service['port'],
            'color': service['color'],
            'auto_start': service['auto_start'],
            'running': False
        }
        
        if service['process']:
            status['running'] = service['process'].poll() is None
            status['pid'] = service['process'].pid if status['running'] else None
            status['started_at'] = service.get('started_at')
            
        return status
        
    def get_all_status(self):
        """Ottiene lo stato di tutti i servizi"""
        return {k: self.get_service_status(k) for k in self.SERVICES}
        
    def stop_all(self):
        """Ferma tutti i servizi"""
        results = {}
        for service_id in self.SERVICES:
            results[service_id] = self.stop_service(service_id)
        return results
        
    def start_all(self):
        """Avvia tutti i servizi con auto_start"""
        results = {}
        for service_id, service in self.SERVICES.items():
            if service.get('auto_start', False):
                results[service_id] = self.start_service(service_id)
                time.sleep(1)
        return results

# Istanza globale
orch = SuiteV17Orchestrator()

# API Routes
@app.route('/')
def dashboard():
    return 'Dashboard in sviluppo - Usa /api/status'
    
@app.route('/api/status')
def api_status():
    return jsonify({
        'services': orch.get_all_status(),
        'logs': orch.logs[-50:],
        'timestamp': datetime.now().isoformat()
    })
    
@app.route('/api/service/<service_id>/start', methods=['POST'])
def start_service_api(service_id):
    result = orch.start_service(service_id)
    return jsonify(result)
    
@app.route('/api/service/<service_id>/stop', methods=['POST'])
def stop_service_api(service_id):
    result = orch.stop_service(service_id)
    return jsonify(result)
    
@app.route('/api/services/start-all', methods=['POST'])
def start_all_api():
    results = orch.start_all()
    return jsonify({'success': True, 'results': results})
    
@app.route('/api/services/stop-all', methods=['POST'])
def stop_all_api():
    results = orch.stop_all()
    return jsonify({'success': True, 'results': results})

if __name__ == '__main__':
    print('=' * 60)
    print('SuiteV17 Master Orchestrator v2.0')
    print('=' * 60)
    print('API: http://localhost:9001')
    print('=' * 60)
    app.run(host='0.0.0.0', port=9001, debug=False)
