#!/usr/bin/env python3
"""
Agente Orchestratore - Gestione Processi e Health Check SuiteV17
"""
import os
import sys
import json
import time
import subprocess
import psutil
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any
from dataclasses import dataclass, asdict, field
import threading
import signal

@dataclass
class ProcessInfo:
    name: str
    pid: int
    status: str
    cpu_percent: float
    memory_mb: float
    uptime_seconds: int
    port: Optional[int] = None
    health: str = 'unknown'
    last_check: str = ''
    
@dataclass
class SystemStatus:
    timestamp: str
    cpu_total: float
    memory_total_mb: float
    memory_used_mb: float
    disk_used_percent: float
    processes: List[ProcessInfo] = field(default_factory=list)
    alerts: List[str] = field(default_factory=list)

class PM2Manager:
    """Gestore processi PM2."""
    
    def __init__(self):
        self.processes: Dict[str, Dict] = {}
        
    def _run_pm2(self, args: List[str]) -> tuple:
        """Esegue comando PM2."""
        try:
            result = subprocess.run(
                ['pm2'] + args,
                capture_output=True,
                text=True,
                timeout=30
            )
            return result.returncode == 0, result.stdout, result.stderr
        except Exception as e:
            return False, '', str(e)
            
    def list_processes(self) -> List[Dict]:
        """Lista processi PM2."""
        success, stdout, stderr = self._run_pm2(['jlist'])
        if success and stdout:
            try:
                return json.loads(stdout)
            except json.JSONDecodeError:
                pass
        return []
        
    def start_process(self, script_path: str, name: str) -> bool:
        """Avvia un processo."""
        success, stdout, stderr = self._run_pm2([
            'start', script_path,
            '--name', name,
            '--log-date-format', 'YYYY-MM-DD HH:mm:ss'
        ])
        return success
        
    def stop_process(self, name: str) -> bool:
        """Ferma un processo."""
        success, _, _ = self._run_pm2(['stop', name])
        return success
        
    def restart_process(self, name: str) -> bool:
        """Riavvia un processo."""
        success, _, _ = self._run_pm2(['restart', name])
        return success
        
    def delete_process(self, name: str) -> bool:
        """Elimina un processo da PM2."""
        success, _, _ = self._run_pm2(['delete', name])
        return success
        
    def flush_logs(self, name: str = None) -> bool:
        """Pulisce log."""
        args = ['flush']
        if name:
            args.append(name)
        success, _, _ = self._run_pm2(args)
        return success
        
    def get_logs(self, name: str, lines: int = 50) -> str:
        """Recupera log di un processo."""
        log_file = os.path.expanduser(f'~/.pm2/logs/{name}-out.log')
        err_file = os.path.expanduser(f'~/.pm2/logs/{name}-error.log')
        
        logs = []
        
        for log_path in [log_file, err_file]:
            if os.path.exists(log_path):
                try:
                    with open(log_path, 'r', encoding='utf-8', errors='ignore') as f:
                        lines_content = f.readlines()[-lines:]
                        logs.append(f'=== {log_path} ===')
                        logs.extend(lines_content)
                except Exception as e:
                    logs.append(f'Errore lettura {log_path}: {e}')
                    
        return '\n'.join(logs) if logs else 'Nessun log disponibile'

class HealthChecker:
    """Health checker per servizi."""
    
    def __init__(self):
        self.endpoints = {
            'gateway': 'http://localhost:8080/health',
            'rag_bridge': 'http://localhost:8091/health',
            'macae': 'http://localhost:3000/health',
        }
        
    def check_http(self, url: str, timeout: int = 5) -> tuple:
        """Check HTTP endpoint."""
        try:
            import urllib.request
            req = urllib.request.Request(url, method='GET')
            req.add_header('User-Agent', 'SuiteV17-HealthCheck/1.0')
            
            with urllib.request.urlopen(req, timeout=timeout) as response:
                return True, response.status, response.read().decode('utf-8')[:500]
        except Exception as e:
            return False, 0, str(e)
            
    def check_tcp(self, host: str, port: int, timeout: int = 3) -> bool:
        """Check TCP port."""
        import socket
        try:
            with socket.create_connection((host, port), timeout=timeout):
                return True
        except:
            return False
            
    def check_process(self, name: str) -> Dict:
        """Check stato processo."""
        for proc in psutil.process_iter(['pid', 'name', 'cmdline']):
            try:
                if name in ' '.join(proc.info['cmdline'] or []):
                    p = psutil.Process(proc.info['pid'])
                    return {
                        'running': True,
                        'pid': p.pid,
                        'cpu': p.cpu_percent(interval=0.5),
                        'memory_mb': p.memory_info().rss / 1024 / 1024,
                        'status': p.status()
                    }
            except (psutil.NoSuchProcess, psutil.AccessDenied):
                pass
        return {'running': False}

class AgenteOrchestratore:
    """Orchestratore principale SuiteV17."""
    
    KNOWN_SERVICES = {
        'gateway': {'script': 'gateway.js', 'port': 8080},
        'rag_bridge': {'script': 'rag_bridge.js', 'port': 8091},
        'macae': {'script': 'macae.js', 'port': 3000},
        'server': {'script': 'server.js', 'port': 8093},
    }
    
    def __init__(self, root_path: str = 'C:\\SuiteV17'):
        self.root_path = Path(root_path)
        self.pm2 = PM2Manager()
        self.health = HealthChecker()
        self.running = False
        self.monitor_thread: Optional[threading.Thread] = None
        self.log_entries: List[str] = []
        
    def log(self, message: str, level: str = 'INFO'):
        """Log con timestamp."""
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        entry = f'[{timestamp}] [{level}] ORCHESTRATORE: {message}'
        self.log_entries.append(entry)
        print(entry)
        
    def get_system_metrics(self) -> Dict[str, Any]:
        """Recupera metriche sistema."""
        cpu = psutil.cpu_percent(interval=1)
        memory = psutil.virtual_memory()
        disk = psutil.disk_usage('/')
        
        return {
            'cpu_total': cpu,
            'memory_total_mb': memory.total / 1024 / 1024,
            'memory_used_mb': memory.used / 1024 / 1024,
            'memory_percent': memory.percent,
            'disk_used_percent': disk.percent,
            'load_avg': os.getloadavg() if hasattr(os, 'getloadavg') else [0, 0, 0]
        }
        
    def get_all_processes(self) -> List[ProcessInfo]:
        """Recupera stato di tutti i processi conosciuti."""
        processes = []
        
        # Processi PM2
        pm2_procs = self.pm2.list_processes()
        for proc in pm2_procs:
            name = proc.get('name', 'unknown')
            pm_id = proc.get('pm_id', 0)
            pid = proc.get('pid', 0)
            
            # Ottieni metriche aggiuntive
            cpu = 0.0
            memory = 0.0
            status = proc.get('pm2_env', {}).get('status', 'unknown')
            
            if pid and psutil.pid_exists(pid):
                try:
                    p = psutil.Process(pid)
                    cpu = p.cpu_percent(interval=0.1)
                    memory = p.memory_info().rss / 1024 / 1024
                except:
                    pass
                    
            # Health check
            port = self.KNOWN_SERVICES.get(name, {}).get('port')
            health = 'unknown'
            if port:
                health = 'healthy' if self.health.check_tcp('localhost', port) else 'unhealthy'
                
            uptime = int(time.time() - proc.get('pm2_env', {}).get('pm_uptime', time.time()) / 1000)
            
            processes.append(ProcessInfo(
                name=name,
                pid=pid,
                status=status,
                cpu_percent=round(cpu, 2),
                memory_mb=round(memory, 2),
                uptime_seconds=uptime,
                port=port,
                health=health,
                last_check=datetime.now().isoformat()
            ))
            
        return processes
        
    def orchestrate(self, folder_path: str = None) -> str:
        """Esegue orchestrazione completa."""
        folder = folder_path or str(self.root_path)
        self.log(f'Avvio orchestrazione: {folder}')
        
        # Rileva servizi disponibili
        services = self.detect_services()
        
        report = f'''
=== ORCHESTRAZIONE SUITEV17 ===
Cartella: {folder}
Timestamp: {datetime.now().isoformat()}

Servizi rilevati:
'''
        for name, info in services.items():
            status = 'OK' if info['exists'] else 'KO'
            running = 'ON' if info['running'] else 'OFF'
            report += f'{status} {running} {name}: {info["script"]} (porta {info["port"]})\n'
            
        # Avvia servizi non running
        started = []
        for name, info in services.items():
            if info['exists'] and not info['running']:
                self.log(f'Avvio {name}...')
                script_path = str(self.root_path / info['script'])
                if self.pm2.start_process(script_path, name):
                    started.append(name)
                    self.log(f'  OK {name} avviato')
                else:
                    self.log(f'  ERROR {name} fallito', 'ERROR')
                    
        if started:
            started_str = ', '.join(started)
            report += f'\nServizi avviati: {started_str}\n'
            
        # Stato sistema
        metrics = self.get_system_metrics()
        report += f'''
Metriche Sistema:
  CPU: {metrics['cpu_total']}%
  Memoria: {metrics['memory_used_mb']:.0f}/{metrics['memory_total_mb']:.0f} MB ({metrics['memory_percent']}%)
  Disco: {metrics['disk_used_percent']}%
'''
        
        self.log('Orchestrazione completata')
        return report
        
    def detect_services(self) -> Dict[str, Dict]:
        """Rileva quali servizi sono disponibili e in esecuzione."""
        pm2_procs = {p.get('name'): p for p in self.pm2.list_processes()}
        services = {}
        
        for name, config in self.KNOWN_SERVICES.items():
            script_path = self.root_path / config['script']
            exists = script_path.exists()
            running = name in pm2_procs and pm2_procs[name].get('pm2_env', {}).get('status') == 'online'
            
            services[name] = {
                'script': config['script'],
                'port': config['port'],
                'exists': exists,
                'running': running,
                'pm2_status': pm2_procs.get(name, {}).get('pm2_env', {}).get('status', 'not_registered')
            }
            
        return services
        
    def start_monitoring(self, interval: int = 30):
        """Avvia monitoraggio continuo in thread separato."""
        self.running = True
        
        def monitor():
            while self.running:
                try:
                    processes = self.get_all_processes()
                    alerts = []
                    
                    for proc in processes:
                        if proc.health == 'unhealthy':
                            alerts.append(f'Servizio {proc.name} non risponde')
                            self.log(f'ALERT: {proc.name} unhealthy, tentativo restart...', 'WARN')
                            self.pm2.restart_process(proc.name)
                            
                        if proc.cpu_percent > 90:
                            alerts.append(f'CPU alto su {proc.name}: {proc.cpu_percent}%')
                            
                        if proc.memory_mb > 1024:  # >1GB
                            alerts.append(f'Memoria alta su {proc.name}: {proc.memory_mb:.0f}MB')
                            
                    if alerts:
                        self.log(f'Alert attivi: {len(alerts)}', 'WARN')
                        
                except Exception as e:
                    self.log(f'Errore monitoraggio: {e}', 'ERROR')
                    
                time.sleep(interval)
                
        self.monitor_thread = threading.Thread(target=monitor, daemon=True)
        self.monitor_thread.start()
        self.log(f'Monitoraggio avviato (intervallo: {interval}s)')
        
    def stop_monitoring(self):
        """Ferma monitoraggio."""
        self.running = False
        if self.monitor_thread:
            self.monitor_thread.join(timeout=5)
        self.log('Monitoraggio fermato')
        
    def get_status(self) -> SystemStatus:
        """Restituisce stato completo sistema."""
        metrics = self.get_system_metrics()
        processes = self.get_all_processes()
        
        alerts = []
        for proc in processes:
            if proc.health == 'unhealthy':
                alerts.append(f'{proc.name}: servizio non risponde')
            if proc.cpu_percent > 90:
                alerts.append(f'{proc.name}: CPU {proc.cpu_percent}%')
                
        if metrics['memory_percent'] > 90:
            alerts.append(f'Memoria sistema critica: {metrics["memory_percent"]}%')
            
        return SystemStatus(
            timestamp=datetime.now().isoformat(),
            cpu_total=metrics['cpu_total'],
            memory_total_mb=round(metrics['memory_total_mb'], 2),
            memory_used_mb=round(metrics['memory_used_mb'], 2),
            disk_used_percent=metrics['disk_used_percent'],
            processes=processes,
            alerts=alerts
        )
        
    def generate_report(self, format: str = 'text') -> str:
        """Genera report stato."""
        status = self.get_status()
        
        if format == 'json':
            return json.dumps(asdict(status), indent=2, default=str)
            
        report = f'''
═══════════════════════════════════════════════════════
           SUITEV17 STATUS REPORT
═══════════════════════════════════════════════════════
Generato: {status.timestamp}

METRICHE SISTEMA
   CPU: {status.cpu_total}%
   Memoria: {status.memory_used_mb:.0f}/{status.memory_total_mb:.0f} MB
   Disco: {status.disk_used_percent}%

PROCESSI ({len(status.processes)})
'''
        for proc in status.processes:
            health_icon = 'OK' if proc.health == 'healthy' else 'KO' if proc.health == 'unhealthy' else '--'
            status_icon = 'ON' if proc.status == 'online' else 'OFF'
            uptime_str = f'{proc.uptime_seconds//3600}h{(proc.uptime_seconds%3600)//60}m'
            report += f'   {health_icon} {status_icon} {proc.name:15} PID:{proc.pid:6} CPU:{proc.cpu_percent:5.1f}% MEM:{proc.memory_mb:6.1f}MB {uptime_str}\n'
            
        if status.alerts:
            report += f'\nALERT ATTIVI ({len(status.alerts)})\n'
            for alert in status.alerts:
                report += f'   * {alert}\n'
        else:
            report += '\nNessun alert attivo\n'
            
        return report

def main():
    """Entry point."""
    if len(sys.argv) < 2:
        print('''Uso: python agent_orchestratore.py <comando> [opzioni]

Comandi:
  orchestrate [cartella]     - Esegue orchestrazione completa
  status                     - Mostra stato sistema
  start <nome>               - Avvia servizio
  stop <nome>                - Ferma servizio
  restart <nome>             - Riavvia servizio
  logs <nome> [righe]        - Mostra log servizio
  monitor [intervallo]       - Avvia monitoraggio continuo
  report [--json]            - Genera report
''')
        sys.exit(1)
        
    command = sys.argv[1]
    agente = AgenteOrchestratore()
    
    if command == 'orchestrate':
        folder = sys.argv[2] if len(sys.argv) > 2 else None
        print(agente.orchestrate(folder))
        
    elif command == 'status':
        print(agente.generate_report())
        
    elif command == 'start':
        if len(sys.argv) < 3:
            print('Errore: specificare nome servizio')
            sys.exit(1)
        name = sys.argv[2]
        script = agente.KNOWN_SERVICES.get(name, {}).get('script', f'{name}.js')
        success = agente.pm2.start_process(str(agente.root_path / script), name)
        print(f'{"OK" if success else "FAIL"} {name}')
        
    elif command == 'stop':
        if len(sys.argv) < 3:
            print('Errore: specificare nome servizio')
            sys.exit(1)
        success = agente.pm2.stop_process(sys.argv[2])
        print(f'{"OK" if success else "FAIL"} {sys.argv[2]}')
        
    elif command == 'restart':
        if len(sys.argv) < 3:
            print('Errore: specificare nome servizio')
            sys.exit(1)
        success = agente.pm2.restart_process(sys.argv[2])
        print(f'{"OK" if success else "FAIL"} {sys.argv[2]}')
        
    elif command == 'logs':
        if len(sys.argv) < 3:
            print('Errore: specificare nome servizio')
            sys.exit(1)
        lines = int(sys.argv[3]) if len(sys.argv) > 3 else 50
        print(agente.pm2.get_logs(sys.argv[2], lines))
        
    elif command == 'monitor':
        interval = int(sys.argv[2]) if len(sys.argv) > 2 else 30
        agente.start_monitoring(interval)
        print(f'Monitoraggio avviato. Ctrl+C per uscire.')
        try:
            while True:
                time.sleep(1)
        except KeyboardInterrupt:
            agente.stop_monitoring()
            
    elif command == 'report':
        format = 'json' if '--json' in sys.argv else 'text'
        print(agente.generate_report(format))
        
    else:
        print(f'Comando sconosciuto: {command}')
        sys.exit(1)

if __name__ == '__main__':
    main()
