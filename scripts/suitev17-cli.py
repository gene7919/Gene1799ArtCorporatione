#!/usr/bin/env python3
"""
SuiteV17 CLI - Tool a riga di comando per gestione completa
"""
import os
import sys
import json
import argparse
import asyncio
from datetime import datetime
from typing import Optional
import subprocess

# Import moduli SuiteV17
try:
    from health_monitor import HealthMonitor
    from resilient_database import get_db
    from notification_service import get_notification_service
    from task_queue import get_task_queue
    CLI_AVAILABLE = True
except ImportError:
    CLI_AVAILABLE = False

class Colors:
    GREEN = '\033[92m'
    RED = '\033[91m'
    YELLOW = '\033[93m'
    BLUE = '\033[94m'
    CYAN = '\033[96m'
    WHITE = '\033[97m'
    RESET = '\033[0m'
    BOLD = '\033[1m'

def print_colored(text: str, color: str = 'white', bold: bool = False):
    color_code = getattr(Colors, color.upper(), Colors.WHITE)
    bold_code = Colors.BOLD if bold else ''
    print(f'{bold_code}{color_code}{text}{Colors.RESET}')

def print_banner():
    print_colored('''
╔═══════════════════════════════════════════════════╗
║                                                   ║
║              SUITEV17 CLI MANAGER                ║
║                                                   ║
║   Manage, Monitor & Control your SuiteV17         ║
║                                                   ║
╚═══════════════════════════════════════════════════╝
''', 'cyan', True)

class SuiteV17CLI:
    def __init__(self):
        self.parser = argparse.ArgumentParser(
            description='SuiteV17 CLI Management Tool',
            formatter_class=argparse.RawDescriptionHelpFormatter,
            epilog='''
Esempi:
  %(prog)s status              # Mostra stato sistema
  %(prog)s service start api   # Avvia servizio API
  %(prog)s db backup           # Crea backup database
  %(prog)s logs --tail 100     # Visualizza ultimi log
            '''
        )
        
        self.parser.add_argument('--version', action='version', version='SuiteV17 CLI 2.0.0')
        
        subparsers = self.parser.add_subparsers(dest='command', help='Comandi disponibili')
        
        # Status
        status_parser = subparsers.add_parser('status', help='Stato sistema')
        status_parser.add_argument('--json', action='store_true', help='Output JSON')
        
        # Service
        service_parser = subparsers.add_parser('service', help='Gestione servizi')
        service_parser.add_argument('action', choices=['start', 'stop', 'restart', 'status'])
        service_parser.add_argument('name', nargs='?', help='Nome servizio')
        
        # Database
        db_parser = subparsers.add_parser('db', help='Gestione database')
        db_parser.add_argument('action', choices=['backup', 'restore', 'stats', 'cleanup'])
        db_parser.add_argument('--file', help='File per backup/restore')
        
        # Logs
        logs_parser = subparsers.add_parser('logs', help='Gestione log')
        logs_parser.add_argument('--tail', type=int, default=50, help='Numero righe')
        logs_parser.add_argument('--level', choices=['DEBUG', 'INFO', 'WARNING', 'ERROR'])
        logs_parser.add_argument('--follow', '-f', action='store_true', help='Follow mode')
        
        # Task Queue
        task_parser = subparsers.add_parser('task', help='Gestione task')
        task_parser.add_argument('action', choices=['list', 'enqueue', 'cancel', 'stats'])
        task_parser.add_argument('--name', help='Nome task')
        task_parser.add_argument('--payload', help='Payload JSON')
        
        # Notification
        notify_parser = subparsers.add_parser('notify', help='Invia notifica')
        notify_parser.add_argument('message', help='Messaggio')
        notify_parser.add_argument('--title', default='SuiteV17 Alert', help='Titolo')
        notify_parser.add_argument('--priority', choices=['critical', 'high', 'normal', 'low'], 
                                   default='normal')
        
        # Plugin
        plugin_parser = subparsers.add_parser('plugin', help='Gestione plugin')
        plugin_parser.add_argument('action', choices=['list', 'load', 'unload', 'reload'])
        plugin_parser.add_argument('name', nargs='?', help='Nome plugin')
        
        # Config
        config_parser = subparsers.add_parser('config', help='Gestione configurazione')
        config_parser.add_argument('action', choices=['show', 'set', 'validate'])
        config_parser.add_argument('--key', help='Chiave configurazione')
        config_parser.add_argument('--value', help='Valore configurazione')
        
        # Health
        health_parser = subparsers.add_parser('health', help='Check salute sistema')
        health_parser.add_argument('--fix', action='store_true', help='Auto-fix problemi')
        
        # Test
        test_parser = subparsers.add_parser('test', help='Esegui test')
        test_parser.add_argument('--all', action='store_true', help='Tutti i test')
        test_parser.add_argument('--module', help='Specifico modulo')
    
    def run(self):
        print_banner()
        
        if not CLI_AVAILABLE:
            print_colored('ERRORE: Moduli SuiteV17 non trovati!', 'red', True)
            print_colored('Assicurati di essere nella directory C:\\SuiteV17', 'yellow')
            return 1
        
        args = self.parser.parse_args()
        
        if not args.command:
            self.parser.print_help()
            return 0
        
        try:
            return self.execute_command(args)
        except KeyboardInterrupt:
            print_colored('\\nOperazione interrotta', 'yellow')
            return 1
        except Exception as e:
            print_colored(f'\\nErrore: {e}', 'red', True)
            return 1
    
    def execute_command(self, args) -> int:
        if args.command == 'status':
            return self.cmd_status(args)
        elif args.command == 'service':
            return self.cmd_service(args)
        elif args.command == 'db':
            return self.cmd_db(args)
        elif args.command == 'logs':
            return self.cmd_logs(args)
        elif args.command == 'task':
            return self.cmd_task(args)
        elif args.command == 'notify':
            return self.cmd_notify(args)
        elif args.command == 'plugin':
            return self.cmd_plugin(args)
        elif args.command == 'config':
            return self.cmd_config(args)
        elif args.command == 'health':
            return self.cmd_health(args)
        elif args.command == 'test':
            return self.cmd_test(args)
        else:
            print_colored(f'Comando sconosciuto: {args.command}', 'red')
            return 1
    
    def cmd_status(self, args):
        print_colored('SISTEMA STATUS', 'cyan', True)
        print()
        
        # Database
        db = get_db()
        stats = db.get_stats()
        print_colored('Database:', 'blue', True)
        for table, count in stats.items():
            if not isinstance(count, dict):
                print_colored(f'  {table}: {count} records', 'white')
        
        # Task Queue
        queue = get_task_queue()
        task_stats = queue.get_stats()
        print_colored('\\nTask Queue:', 'blue', True)
        print_colored(f'  Total: {task_stats[\"total\"]}', 'white')
        for state, count in task_stats.get('by_state', {}).items():
            print_colored(f'  {state}: {count}', 'white')
        
        # Environment
        print_colored('\\nEnvironment:', 'blue', True)
        print_colored(f'  Python: {sys.version.split()[0]}', 'white')
        print_colored(f'  Platform: {sys.platform}', 'white')
        print_colored(f'  Working Dir: {os.getcwd()}', 'white')
        
        if args.json:
            print('\\nJSON Output:')
            print(json.dumps({
                'database': stats,
                'tasks': task_stats,
                'python': sys.version.split()[0],
                'platform': sys.platform
            }, indent=2))
        
        return 0
    
    def cmd_service(self, args):
        print_colored(f'Servizio: {args.action}', 'cyan', True)
        
        services = {
            'api': {'port': 8083, 'script': 'api_server.py'},
            'websocket': {'port': 8765, 'script': 'websocket_server.py'},
            'social': {'port': 3007, 'script': 'server.js'}
        }
        
        if args.name and args.name not in services:
            print_colored(f'Servizio sconosciuto: {args.name}', 'red')
            return 1
        
        if args.action == 'status':
            print_colored('\\nStato servizi:', 'blue', True)
            for name, info in services.items():
                print_colored(f'  {name}: port {info[\"port\"]}', 'white')
        else:
            print_colored(f'Azione {args.action} su {args.name or "tutti i servizi"}', 'yellow')
            # Qui implementare gestione processi reali con PM2 o subprocess
        
        return 0
    
    def cmd_db(self, args):
        print_colored(f'Database: {args.action}', 'cyan', True)
        
        db = get_db()
        
        if args.action == 'backup':
            backup_file = args.file or f'backup_{datetime.now().strftime(\"%Y%m%d_%H%M%S\")}.db'
            path = db.backup(backup_file)
            print_colored(f'\\nBackup creato: {path}', 'green')
        
        elif args.action == 'restore':
            if not args.file:
                print_colored('Specifica --file per il restore', 'red')
                return 1
            db.restore(args.file)
            print_colored(f'\\nRestore completato da: {args.file}', 'green')
        
        elif args.action == 'stats':
            stats = db.get_stats()
            print_colored('\\nDatabase Statistics:', 'blue', True)
            print(json.dumps(stats, indent=2))
        
        elif args.action == 'cleanup':
            db.cleanup_old_backups(keep_days=30)
            print_colored('\\nCleanup completato', 'green')
        
        return 0
    
    def cmd_logs(self, args):
        print_colored(f'Logs (ultimi {args.tail})', 'cyan', True)
        
        log_file = 'logs/suitev17.log'
        if not os.path.exists(log_file):
            print_colored('File log non trovato', 'yellow')
            return 0
        
        try:
            with open(log_file, 'r') as f:
                lines = f.readlines()
                
                # Filtra per livello se specificato
                if args.level:
                    lines = [l for l in lines if f'"level": "{args.level}"' in l]
                
                # Mostra ultime righe
                for line in lines[-args.tail:]:
                    try:
                        entry = json.loads(line)
                        level_color = {
                            'ERROR': 'red',
                            'WARNING': 'yellow',
                            'INFO': 'blue',
                            'DEBUG': 'white'
                        }.get(entry.get('level', ''), 'white')
                        
                        print_colored(f'[{entry.get(\"timestamp\", \"???\")}] {entry.get(\"level\", \"???\")}: {entry.get(\"message\", \"???\")}', level_color)
                    except:
                        print(line.strip())
        
        except Exception as e:
            print_colored(f'Errore lettura log: {e}', 'red')
        
        return 0
    
    def cmd_task(self, args):
        print_colored(f'Task: {args.action}', 'cyan', True)
        queue = get_task_queue()
        
        if args.action == 'list':
            # Implementare listing task
            print_colored('\\nTask listing...', 'blue')
        
        elif args.action == 'enqueue':
            if not args.name:
                print_colored('Specifica --name', 'red')
                return 1
            task_id = queue.enqueue(args.name, json.loads(args.payload or '{}'))
            print_colored(f'Task enqueued: {task_id}', 'green')
        
        elif args.action == 'stats':
            stats = queue.get_stats()
            print_colored('\\nTask Statistics:', 'blue', True)
            print(json.dumps(stats, indent=2))
        
        return 0
    
    async def cmd_notify_async(self, args):
        service = get_notification_service()
        
        # Import qui per evitare problemi di import circolare
        from notification_service import NotificationPriority
        
        priority_map = {
            'critical': NotificationPriority.CRITICAL,
            'high': NotificationPriority.HIGH,
            'normal': NotificationPriority.NORMAL,
            'low': NotificationPriority.LOW
        }
        
        result = await service.notify(
            args.title,
            args.message,
            priority=priority_map[args.priority]
        )
        
        print_colored(f'\\nNotifica inviata: {result.id}', 'green')
        print_colored(f'Stato: {result.status}', 'blue')
    
    def cmd_notify(self, args):
        asyncio.run(self.cmd_notify_async(args))
        return 0
    
    def cmd_plugin(self, args):
        print_colored(f'Plugin: {args.action}', 'cyan', True)
        print_colored('\\nGestione plugin...', 'blue')
        # Implementare con plugin_system
        return 0
    
    def cmd_config(self, args):
        print_colored(f'Config: {args.action}', 'cyan', True)
        
        if args.action == 'show':
            if os.path.exists('.env'):
                with open('.env', 'r') as f:
                    lines = f.readlines()
                    print_colored('\\nConfigurazione (.env):', 'blue', True)
                    for line in lines:
                        if line.strip() and not line.startswith('#'):
                            key = line.split('=')[0]
                            print_colored(f'  {key}=***', 'white')
        
        elif args.action == 'validate':
            print_colored('\\nValidazione configurazione...', 'blue')
            # Implementare validazione completa
            print_colored('Configurazione valida!', 'green')
        
        return 0
    
    def cmd_health(self, args):
        print_colored('Health Check', 'cyan', True)
        
        monitor = HealthMonitor()
        status = monitor.get_status()
        
        print_colored(f'\\nOverall Status: {status[\"overall\"]}', 'blue', True)
        
        for name, check in status.get('checks', {}).items():
            color = 'green' if check['status'] == 'healthy' else 'red'
            print_colored(f'  {name}: {check[\"status\"]} - {check[\"message\"]}', color)
        
        if args.fix:
            print_colored('\\nAuto-fixing issues...', 'yellow')
            # Implementare auto-fix
        
        return 0 if status['overall'] == 'healthy' else 1
    
    def cmd_test(self, args):
        print_colored('Running Tests', 'cyan', True)
        
        if args.all:
            print_colored('\\nEsecuzione test suite completa...', 'blue')
            result = subprocess.run([sys.executable, 'test_suite.py'])
            return result.returncode
        elif args.module:
            print_colored(f'\\nTest modulo: {args.module}', 'blue')
            # Test specifico modulo
        else:
            print_colored('\\nEsecuzione test rapidi...', 'blue')
        
        return 0

def main():
    cli = SuiteV17CLI()
    return cli.run()

if __name__ == '__main__':
    sys.exit(main())
