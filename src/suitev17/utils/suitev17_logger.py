#!/usr/bin/env python3
"""
SuiteV17 Logger - Sistema logging professionale con rotazione, alert e monitoraggio
"""
import logging
import logging.handlers
import os
import sys
import json
from datetime import datetime
from pathlib import Path
from typing import Dict, Optional, Any, List
import queue
import threading

class ColoredFormatter(logging.Formatter):
    """Formatter con colori per console."""
    
    COLORS = {
        'DEBUG': '\\033[36m',     # Cyan
        'INFO': '\\033[32m',      # Green
        'WARNING': '\\033[33m',   # Yellow
        'ERROR': '\\033[31m',     # Red
        'CRITICAL': '\\033[35m',  # Magenta
        'RESET': '\\033[0m'
    }
    
    def format(self, record):
        log_color = self.COLORS.get(record.levelname, self.COLORS['RESET'])
        reset = self.COLORS['RESET']
        
        # Add color to levelname
        record.levelname = f'{log_color}{record.levelname}{reset}'
        return super().format(record)

class MemoryLogHandler(logging.Handler):
    """Handler che mantiene log in memoria per accesso rapido."""
    
    def __init__(self, max_entries: int = 10000):
        super().__init__()
        self.max_entries = max_entries
        self.logs: List[Dict] = []
        self._lock = threading.Lock()
        
    def emit(self, record):
        with self._lock:
            entry = {
                'timestamp': datetime.fromtimestamp(record.created).isoformat(),
                'level': record.levelname,
                'logger': record.name,
                'message': record.getMessage(),
                'module': record.module,
                'line': record.lineno
            }
            self.logs.append(entry)
            
            if len(self.logs) > self.max_entries:
                self.logs.pop(0)
    
    def get_logs(self, level: str = None, limit: int = 100) -> List[Dict]:
        """Recupera log filtrati."""
        with self._lock:
            logs = self.logs
            if level:
                logs = [l for l in logs if l['level'] == level]
            return logs[-limit:]
    
    def clear(self):
        """Pulisce log in memoria."""
        with self._lock:
            self.logs.clear()

class AlertHandler(logging.Handler):
    """Handler che invia alert per log critici."""
    
    def __init__(self, webhook_url: str = None, alert_level: int = logging.ERROR):
        super().__init__(level=alert_level)
        self.webhook_url = webhook_url
        self.alert_cooldown = {}  # Per evitare spam
        self.cooldown_seconds = 300  # 5 minuti
        
    def emit(self, record):
        # Check cooldown
        key = f'{record.name}:{record.levelname}'
        now = datetime.now().timestamp()
        
        if key in self.alert_cooldown:
            if now - self.alert_cooldown[key] < self.cooldown_seconds:
                return
        
        self.alert_cooldown[key] = now
        
        # In produzione qui invieresti webhook/email
        print(f'[ALERT] {record.levelname}: {record.getMessage()}')

class SuiteV17Logger:
    """Logger unificato per SuiteV17."""
    
    def __init__(self, name: str = 'SuiteV17', log_dir: str = 'logs',
                 log_level: int = logging.INFO, 
                 max_bytes: int = 10 * 1024 * 1024,  # 10MB
                 backup_count: int = 5):
        self.name = name
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(exist_ok=True)
        
        # Crea logger
        self.logger = logging.getLogger(name)
        self.logger.setLevel(log_level)
        self.logger.propagate = False
        
        # Rimuovi handler esistenti
        self.logger.handlers.clear()
        
        # Formatter
        file_formatter = logging.Formatter(
            '%(asctime)s | %(levelname)-8s | %(name)s | %(message)s | %(filename)s:%(lineno)d',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        console_formatter = ColoredFormatter(
            '%(asctime)s | %(levelname)-8s | %(name)s | %(message)s',
            datefmt='%H:%M:%S'
        )
        
        # File handler con rotazione
        file_handler = logging.handlers.RotatingFileHandler(
            self.log_dir / 'suitev17.log',
            maxBytes=max_bytes,
            backupCount=backup_count,
            encoding='utf-8'
        )
        file_handler.setFormatter(file_formatter)
        self.logger.addHandler(file_handler)
        
        # Error file separato
        error_handler = logging.handlers.RotatingFileHandler(
            self.log_dir / 'error.log',
            maxBytes=max_bytes,
            backupCount=backup_count,
            encoding='utf-8'
        )
        error_handler.setLevel(logging.ERROR)
        error_handler.setFormatter(file_formatter)
        self.logger.addHandler(error_handler)
        
        # Console handler
        console_handler = logging.StreamHandler(sys.stdout)
        console_handler.setFormatter(console_formatter)
        self.logger.addHandler(console_handler)
        
        # Memory handler per accesso rapido
        self.memory_handler = MemoryLogHandler(max_entries=10000)
        self.memory_handler.setFormatter(file_formatter)
        self.logger.addHandler(self.memory_handler)
        
        # Alert handler
        alert_handler = AlertHandler(alert_level=logging.ERROR)
        self.logger.addHandler(alert_handler)
        
    def debug(self, message: str, extra: Dict = None):
        self.logger.debug(message, extra=extra)
        
    def info(self, message: str, extra: Dict = None):
        self.logger.info(message, extra=extra)
        
    def warning(self, message: str, extra: Dict = None):
        self.logger.warning(message, extra=extra)
        
    def error(self, message: str, extra: Dict = None, exc_info: bool = True):
        self.logger.error(message, extra=extra, exc_info=exc_info)
        
    def critical(self, message: str, extra: Dict = None, exc_info: bool = True):
        self.logger.critical(message, extra=extra, exc_info=exc_info)
        
    def get_recent_logs(self, level: str = None, limit: int = 100) -> List[Dict]:
        """Recupera log recenti dalla memoria."""
        return self.memory_handler.get_logs(level, limit)
    
    def export_logs(self, output_file: str, level: str = None, 
                    start_time: str = None, end_time: str = None):
        """Esporta log in JSON."""
        logs = self.get_recent_logs(level, limit=10000)
        
        if start_time:
            logs = [l for l in logs if l['timestamp'] >= start_time]
        if end_time:
            logs = [l for l in logs if l['timestamp'] <= end_time]
            
        with open(output_file, 'w', encoding='utf-8') as f:
            json.dump(logs, f, indent=2)
            
    def get_stats(self) -> Dict:
        """Statistiche logging."""
        logs = self.memory_handler.logs
        
        by_level = {}
        for log in logs:
            level = log['level']
            by_level[level] = by_level.get(level, 0) + 1
            
        return {
            'total_logs': len(logs),
            'by_level': by_level,
            'log_files': [
                str(f) for f in self.log_dir.glob('*.log')
            ]
        }

# Global logger instance
_global_logger: Optional[SuiteV17Logger] = None

def setup_logging(name: str = 'SuiteV17', log_dir: str = 'logs',
                  level: int = logging.INFO) -> SuiteV17Logger:
    """Setup logging globale."""
    global _global_logger
    _global_logger = SuiteV17Logger(name, log_dir, level)
    return _global_logger

def get_logger(name: str = None) -> logging.Logger:
    """Ottiene logger - usa quello globale o crea nuovo."""
    if _global_logger:
        if name:
            return logging.getLogger(f'{_global_logger.name}.{name}')
        return _global_logger.logger
    return logging.getLogger(name)

def log_system_info():
    """Log informazioni sistema all'avvio."""
    import platform
    import psutil
    
    logger = get_logger('system')
    logger.info('=' * 70)
    logger.info('SUITEV17 STARTING')
    logger.info('=' * 70)
    logger.info(f'Python: {platform.python_version()}')
    logger.info(f'Platform: {platform.platform()}')
    logger.info(f'CPU: {psutil.cpu_count()} cores')
    logger.info(f'Memory: {psutil.virtual_memory().total / 1024**3:.1f} GB')
    logger.info(f'Disk: {psutil.disk_usage("/").free / 1024**3:.1f} GB free')
    logger.info('=' * 70)

def main():
    """Test del sistema logging."""
    logger = setup_logging(level=logging.DEBUG)
    
    print('Logger test:')
    logger.debug('Debug message')
    logger.info('Info message')
    logger.warning('Warning message')
    logger.error('Error message')
    
    print('Recent logs:')
    for log in logger.get_recent_logs(limit=5):
        print('  ' + log['timestamp'] + ' | ' + log['level'] + ' | ' + log['message'])
    
    print('Stats:', logger.get_stats())

if __name__ == '__main__':
    main()
