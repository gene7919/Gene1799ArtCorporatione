# Service Controller SuiteV17
import subprocess
import json
import os
from pathlib import Path

SUITE_DIR = Path(r'C:\SuiteV17')

class ServiceController:
    SERVICES = {
        'ai_server': {'cmd': ['python', 'ai_server_electron.py'], 'port': 8099, 'desc': 'AI Server Flask'},
        'api_server': {'cmd': ['python', 'api_server.py'], 'port': 8080, 'desc': 'API Server FastAPI'},
        'gateway': {'cmd': ['node', 'gateway.js'], 'port': 8080, 'desc': 'Gateway Node.js'},
        'videoworker': {'cmd': ['node', 'VideoWorker/server.js'], 'port': 3002, 'desc': 'Video Worker'},
        'aihub': {'cmd': ['node', 'AIHub/ollama_router.js'], 'port': 3001, 'desc': 'AI Hub Ollama'},
        'tokenmodule': {'cmd': ['node', 'TokenModule/server.js'], 'port': 3003, 'desc': 'Token Monitor'},
        'social': {'cmd': ['python', 'social_automation.py'], 'port': 3004, 'desc': 'Social Automation'},
        'orchestrator': {'cmd': ['python', 'agent_orchestratore.py'], 'port': 3005, 'desc': 'Agent Orchestrator'}
    }

    def __init__(self):
        self.processes = {}

    def is_running(self, name):
        if name in self.processes:
            return self.processes[name].poll() is None
        return False

    def get_status(self):
        result = {}
        for name, info in self.SERVICES.items():
            result[name] = {'running': self.is_running(name), 'info': info}
        return result

    def start(self, name):
        if name not in self.SERVICES:
            return {'error': 'Unknown service'}
        if self.is_running(name):
            return {'status': 'running', 'name': name}
        try:
            cfg = self.SERVICES[name]
            self.processes[name] = subprocess.Popen(cfg['cmd'], cwd=SUITE_DIR, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
            return {'status': 'started', 'name': name}
        except Exception as e:
            return {'error': str(e)}

    def stop(self, name):
        if name not in self.processes:
            return {'status': 'not_running'}
        try:
            self.processes[name].terminate()
            del self.processes[name]
            return {'status': 'stopped', 'name': name}
        except Exception as e:
            return {'error': str(e)}

    def stop_all(self):
        return [self.stop(name) for name in list(self.processes.keys())]

controller = ServiceController()

if __name__ == '__main__':
    import sys
    if len(sys.argv) > 2:
        print(json.dumps(getattr(controller, sys.argv[1])(sys.argv[2])))
    elif len(sys.argv) > 1 and sys.argv[1] == 'status':
        print(json.dumps(controller.get_status(), indent=2))
