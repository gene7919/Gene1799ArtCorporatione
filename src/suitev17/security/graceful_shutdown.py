#!/usr/bin/env python3
"""
SuiteV17 Graceful Shutdown - Gestione chiusura graceful con cleanup
"""
import signal
import sys
from typing import List, Callable, Optional, Dict
import threading
import time
from typing import List, Callable, Optional
from datetime import datetime
import logging

logger = logging.getLogger(__name__)

class GracefulShutdown:
    """Gestisce shutdown graceful di tutti i componenti."""
    
    def __init__(self, timeout: int = 30):
        self.timeout = timeout
        self.shutdown_hooks: List[Callable] = []
        self.is_shutting_down = False
        self._shutdown_complete = threading.Event()
        self._registered = False
        
    def register_hook(self, hook: Callable, name: str = None, 
                     priority: int = 100):
        """Registra funzione da chiamare durante shutdown."""
        self.shutdown_hooks.append({
            'func': hook,
            'name': name or hook.__name__,
            'priority': priority
        })
        # Sort by priority
        self.shutdown_hooks.sort(key=lambda x: x['priority'])
        
    def register_signal_handlers(self):
        """Registra signal handlers."""
        if self._registered:
            return
            
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
        
        if sys.platform == 'win32':
            # Windows specific
            try:
                signal.signal(signal.SIGBREAK, self._signal_handler)
            except:
                pass
                
        self._registered = True
        logger.info('Signal handlers registered')
        
    def _signal_handler(self, signum, frame):
        """Handler per segnali."""
        sig_name = signal.Signals(signum).name
        logger.info(f'Received signal {sig_name}, starting graceful shutdown...')
        self.shutdown()
        
    def shutdown(self, force: bool = False):
        """Esegue shutdown graceful."""
        if self.is_shutting_down:
            return
            
        self.is_shutting_down = True
        start_time = time.time()
        
        logger.info('=' * 70)
        logger.info('GRACEFUL SHUTDOWN INITIATED')
        logger.info('=' * 70)
        
        # Esegui hook in ordine di priority
        for hook_info in self.shutdown_hooks:
            try:
                elapsed = time.time() - start_time
                if elapsed > self.timeout and not force:
                    logger.warning(f'Shutdown timeout reached, skipping remaining hooks')
                    break
                    
                logger.info('Executing shutdown hook: ' + hook_info['name'])
                result = hook_info['func']()
                
                # Handle async hooks
                if asyncio.iscoroutine(result):
                    asyncio.run(result)
                    
            except Exception as e:
                logger.error('Error in shutdown hook ' + hook_info['name'] + ': ' + str(e))
                
        elapsed = time.time() - start_time
        logger.info(f'Shutdown completed in {elapsed:.2f}s')
        logger.info('=' * 70)
        
        self._shutdown_complete.set()
        
    def wait_for_shutdown(self):
        """Attende shutdown."""
        self._shutdown_complete.wait()
        
    def is_alive(self) -> bool:
        """Verifica se sistema sta girando."""
        return not self.is_shutting_down

class ProcessGuardian:
    """Guardian processo con auto-restart e monitoring."""
    
    def __init__(self, max_restarts: int = 5, restart_window: int = 300):
        self.max_restarts = max_restarts
        self.restart_window = restart_window
        self.processes: Dict = {}
        self.restart_history: Dict[str, List] = {}
        self.running = False
        self._thread: Optional[threading.Thread] = None
        
    def register_process(self, name: str, start_func: Callable,
                        check_func: Callable = None,
                        restart_delay: int = 5):
        """Registra processo da guardare."""
        self.processes[name] = {
            'start': start_func,
            'check': check_func,
            'restart_delay': restart_delay,
            'status': 'stopped',
            'pid': None,
            'last_restart': None
        }
        self.restart_history[name] = []
        
    def start(self):
        """Avvia guardian."""
        if self.running:
            return
            
        self.running = True
        self._thread = threading.Thread(target=self._guardian_loop, daemon=True)
        self._thread.start()
        logger.info('Process guardian started')
        
    def _guardian_loop(self):
        """Loop guardian."""
        while self.running:
            for name, proc in self.processes.items():
                # Check se processo è vivo
                is_alive = self._is_process_alive(proc)
                
                if not is_alive and proc['status'] == 'running':
                    logger.warning(f'Process {name} died, attempting restart')
                    self._restart_process(name)
                elif is_alive and proc['status'] == 'stopped':
                    proc['status'] = 'running'
                    
            time.sleep(5)
            
    def _is_process_alive(self, proc: Dict) -> bool:
        """Verifica se processo è vivo."""
        if proc['check']:
            try:
                return proc['check']()
            except:
                return False
        return proc['status'] == 'running'
        
    def _can_restart(self, name: str) -> bool:
        """Verifica se possiamo riavviare."""
        now = datetime.now()
        cutoff = now - timedelta(seconds=self.restart_window)
        
        # Cleanup old history
        self.restart_history[name] = [
            t for t in self.restart_history[name] if t > cutoff
        ]
        
        return len(self.restart_history[name]) < self.max_restarts
        
    def _restart_process(self, name: str):
        """Riavvia processo."""
        proc = self.processes[name]
        
        if not self._can_restart(name):
            logger.error(f'Process {name}: max restarts exceeded')
            proc['status'] = 'failed'
            return
            
        proc['status'] = 'restarting'
        self.restart_history[name].append(datetime.now())
        
        # Delay prima restart
        time.sleep(proc['restart_delay'])
        
        try:
            logger.info(f'Restarting process {name}')
            result = proc['start']()
            proc['status'] = 'running'
            proc['last_restart'] = datetime.now().isoformat()
            logger.info(f'Process {name} restarted successfully')
        except Exception as e:
            logger.error(f'Failed to restart {name}: {e}')
            proc['status'] = 'failed'
            
    def stop(self):
        """Ferma guardian."""
        self.running = False
        if self._thread:
            self._thread.join(timeout=5)
            
    def get_status(self) -> Dict:
        """Stato guardian."""
        return {
            name: {
                'status': proc['status'],
                'last_restart': proc['last_restart'],
                'restarts_in_window': len(self.restart_history[name])
            }
            for name, proc in self.processes.items()
        }

# Global instance
_shutdown_manager: Optional[GracefulShutdown] = None

def get_shutdown_manager() -> GracefulShutdown:
    """Ottiene singleton shutdown manager."""
    global _shutdown_manager
    if _shutdown_manager is None:
        _shutdown_manager = GracefulShutdown()
    return _shutdown_manager

def register_shutdown_hook(func: Callable, name: str = None, priority: int = 100):
    """Registra hook shutdown globale."""
    manager = get_shutdown_manager()
    manager.register_hook(func, name, priority)
    manager.register_signal_handlers()

def main():
    """Test graceful shutdown."""
    shutdown = GracefulShutdown()
    
    # Registra hook di esempio
    def cleanup_database():
        print('Closing database connections...')
        
    def cleanup_files():
        print('Cleaning up temp files...')
        
    def save_state():
        print('Saving application state...')
        
    shutdown.register_hook(cleanup_database, 'database', priority=10)
    shutdown.register_hook(save_state, 'state', priority=20)
    shutdown.register_hook(cleanup_files, 'files', priority=100)
    
    shutdown.register_signal_handlers()
    
    print('Running... Press Ctrl+C to test graceful shutdown')
    print()
    
    try:
        while shutdown.is_alive():
            time.sleep(1)
    except:
        pass

if __name__ == '__main__':
    main()
