#!/usr/bin/env python3
"""
SuiteV17 Resilient Database Manager
Database con connection pooling, retry, backup automatico e failover
"""
import os
import json
import sqlite3
import threading
import time
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any, Union
from dataclasses import dataclass, asdict
from contextlib import contextmanager
import shutil
import queue
import logging

logger = logging.getLogger(__name__)

@dataclass
class ConnectionPoolConfig:
    max_connections: int = 20
    min_connections: int = 5
    connection_timeout: int = 30
    idle_timeout: int = 300
    retry_attempts: int = 3
    retry_delay: float = 1.0

class ConnectionPool:
    """Connection pool per SQLite con retry logic."""
    
    def __init__(self, db_path: str, config: ConnectionPoolConfig = None):
        self.db_path = db_path
        self.config = config or ConnectionPoolConfig()
        self._pool: queue.Queue = queue.Queue(maxsize=self.config.max_connections)
        self._in_use: Dict[int, float] = {}
        self._lock = threading.Lock()
        self._initialized = False
        
    def initialize(self):
        """Inizializza pool."""
        if self._initialized:
            return
            
        for _ in range(self.config.min_connections):
            conn = self._create_connection()
            if conn:
                self._pool.put(conn)
                
        self._initialized = True
        logger.info(f'Connection pool initialized: {self._pool.qsize()} connections')
        
    def _create_connection(self) -> Optional[sqlite3.Connection]:
        """Crea nuova connessione con retry."""
        for attempt in range(self.config.retry_attempts):
            try:
                conn = sqlite3.connect(
                    self.db_path,
                    timeout=self.config.connection_timeout,
                    check_same_thread=False
                )
                conn.row_factory = sqlite3.Row
                conn.execute('PRAGMA journal_mode=WAL')  # Write-ahead logging
                conn.execute('PRAGMA foreign_keys=ON')
                return conn
            except Exception as e:
                logger.warning(f'Connection attempt {attempt + 1} failed: {e}')
                if attempt < self.config.retry_attempts - 1:
                    time.sleep(self.config.retry_delay * (2 ** attempt))
                    
        logger.error('Failed to create database connection after retries')
        return None
        
    @contextmanager
    def get_connection(self):
        """Ottiene connessione dal pool."""
        if not self._initialized:
            self.initialize()
            
        conn = None
        try:
            # Try to get from pool
            try:
                conn = self._pool.get(timeout=5)
            except queue.Empty:
                # Create new connection if pool empty
                conn = self._create_connection()
                
            if conn is None:
                raise Exception('Failed to get database connection')
                
            with self._lock:
                self._in_use[id(conn)] = time.time()
                
            yield conn
            
        finally:
            if conn:
                with self._lock:
                    self._in_use.pop(id(conn), None)
                
                # Return to pool or close
                if self._pool.full():
                    conn.close()
                else:
                    self._pool.put(conn)
                    
    def close_all(self):
        """Chiude tutte le connessioni."""
        while not self._pool.empty():
            try:
                conn = self._pool.get_nowait()
                conn.close()
            except:
                pass
                
class ResilientDatabaseManager:
    """Database manager resiliente con backup e recovery."""
    
    def __init__(self, db_path: str = None, backup_dir: str = 'backups'):
        self.db_path = db_path or os.path.join('data', 'suitev17.db')
        self.backup_dir = Path(backup_dir)
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        
        self.pool = ConnectionPool(self.db_path)
        self._init_tables()
        
        # Backup schedule
        self.last_backup: Optional[datetime] = None
        self.backup_interval = timedelta(hours=1)
        
    def _init_tables(self):
        """Inizializza tabelle."""
        schema = '''
        -- Tabella Agenti
        CREATE TABLE IF NOT EXISTS agents (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL UNIQUE,
            type TEXT NOT NULL,
            status TEXT DEFAULT 'inactive',
            config TEXT DEFAULT '{}',
            last_seen TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            metrics TEXT DEFAULT '{}'
        );
        
        -- Tabella Trades
        CREATE TABLE IF NOT EXISTS trades (
            id TEXT PRIMARY KEY,
            token_symbol TEXT NOT NULL,
            action TEXT NOT NULL,
            amount REAL DEFAULT 0,
            price REAL DEFAULT 0,
            timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
            tx_hash TEXT,
            status TEXT DEFAULT 'pending',
            profit_loss REAL
        );
        
        -- Tabella Logs
        CREATE TABLE IF NOT EXISTS logs (
            id TEXT PRIMARY KEY,
            level TEXT NOT NULL,
            source TEXT NOT NULL,
            message TEXT NOT NULL,
            timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
            metadata TEXT DEFAULT '{}'
        );
        
        -- Tabella Tasks
        CREATE TABLE IF NOT EXISTS tasks (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            status TEXT DEFAULT 'pending',
            scheduled_at TEXT,
            executed_at TEXT,
            result TEXT,
            error TEXT
        );
        
        -- Tabella Configurazioni
        CREATE TABLE IF NOT EXISTS configurations (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Indici
        CREATE INDEX IF NOT EXISTS idx_agents_status ON agents(status);
        CREATE INDEX IF NOT EXISTS idx_trades_timestamp ON trades(timestamp);
        CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs(timestamp);
        CREATE INDEX IF NOT EXISTS idx_logs_level ON logs(level);
        '''
        
        with self.pool.get_connection() as conn:
            conn.executescript(schema)
            conn.commit()
            
    def backup(self, backup_name: str = None) -> str:
        """Crea backup database."""
        if backup_name is None:
            backup_name = 'backup_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.db'
            
        backup_path = self.backup_dir / backup_name
        
        # Chiudi connessioni prima di backup
        self.pool.close_all()
        
        try:
            shutil.copy2(self.db_path, backup_path)
            self.last_backup = datetime.now()
            logger.info(f'Database backed up to {backup_path}')
            return str(backup_path)
        except Exception as e:
            logger.error(f'Backup failed: {e}')
            raise
            
    def restore(self, backup_path: str):
        """Ripristina da backup."""
        if not os.path.exists(backup_path):
            raise FileNotFoundError(f'Backup not found: {backup_path}')
            
        # Chiudi connessioni
        self.pool.close_all()
        
        # Crea backup corrente prima di restore
        if os.path.exists(self.db_path):
            emergency_backup = self.backup_dir / ('pre_restore_' + datetime.now().strftime('%Y%m%d_%H%M%S') + '.db')
            shutil.copy2(self.db_path, emergency_backup)
            
        # Restore
        shutil.copy2(backup_path, self.db_path)
        logger.info(f'Database restored from {backup_path}')
        
    def auto_backup(self) -> Optional[str]:
        """Backup automatico se necessario."""
        if self.last_backup is None or \
           datetime.now() - self.last_backup > self.backup_interval:
            return self.backup()
        return None
        
    def cleanup_old_backups(self, keep_days: int = 7):
        """Pulisce backup vecchi."""
        cutoff = datetime.now() - timedelta(days=keep_days)
        
        for backup in self.backup_dir.glob('*.db'):
            try:
                mtime = datetime.fromtimestamp(backup.stat().st_mtime)
                if mtime < cutoff:
                    backup.unlink()
                    logger.info(f'Deleted old backup: {backup}')
            except Exception as e:
                logger.warning(f'Failed to delete backup {backup}: {e}')
                
    def execute_with_retry(self, query: str, params: tuple = None,
                          max_retries: int = 3) -> Any:
        """Esegue query con retry."""
        for attempt in range(max_retries):
            try:
                with self.pool.get_connection() as conn:
                    if params:
                        result = conn.execute(query, params)
                    else:
                        result = conn.execute(query)
                    conn.commit()
                    return result
            except sqlite3.OperationalError as e:
                if 'database is locked' in str(e) and attempt < max_retries - 1:
                    logger.warning(f'Database locked, retrying ({attempt + 1}/{max_retries})')
                    time.sleep(0.1 * (2 ** attempt))
                else:
                    raise
                    
    def get_stats(self) -> Dict:
        """Statistiche database."""
        with self.pool.get_connection() as conn:
            stats = {}
            for table in ['agents', 'trades', 'logs', 'tasks']:
                count = conn.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0]
                stats[table] = count
                
            stats['last_backup'] = self.last_backup.isoformat() if self.last_backup else None
            stats['backup_dir_size_mb'] = sum(
                f.stat().st_size for f in self.backup_dir.glob('*')
            ) / 1024 / 1024
            
            return stats

# Singleton
_db_manager: Optional[ResilientDatabaseManager] = None

def get_db(db_path: str = None) -> ResilientDatabaseManager:
    """Ottiene singleton database manager."""
    global _db_manager
    if _db_manager is None:
        _db_manager = ResilientDatabaseManager(db_path)
    return _db_manager

def main():
    """Test database manager."""
    db = ResilientDatabaseManager()
    
    print('Database initialized')
    print('Stats:', db.get_stats())
    
    # Test backup
    backup_path = db.backup()
    print(f'Backup created: {backup_path}')
    
    print('Stats after backup:', db.get_stats())

if __name__ == '__main__':
    main()
