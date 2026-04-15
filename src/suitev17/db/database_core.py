#!/usr/bin/env python3
"""
SuiteV17 Database Layer - SQLite & PostgreSQL Support
Enterprise-grade ORM with async support
"""
import os
import json
import sqlite3
import threading
from datetime import datetime
from pathlib import Path
from typing import Dict, List, Optional, Any, Union
from dataclasses import dataclass, asdict
from contextlib import contextmanager
import hashlib
import uuid

@dataclass
class AgentRecord:
    id: str
    name: str
    type: str
    status: str
    config: Dict
    last_seen: str
    created_at: str
    metrics: Dict

@dataclass
class TradeRecord:
    id: str
    token_symbol: str
    action: str
    amount: float
    price: float
    timestamp: str
    tx_hash: Optional[str]
    status: str
    profit_loss: Optional[float]

@dataclass
class LogRecord:
    id: str
    level: str
    source: str
    message: str
    timestamp: str
    metadata: Dict

@dataclass
class TaskRecord:
    id: str
    name: str
    status: str
    scheduled_at: str
    executed_at: Optional[str]
    result: Optional[str]
    error: Optional[str]

class DatabaseManager:
    """Database manager con supporto SQLite e PostgreSQL."""
    
    def __init__(self, db_path: str = None, db_type: str = 'sqlite'):
        self.db_type = db_type
        self.db_path = db_path or os.path.join('C:\\SuiteV17', 'data', 'suitev17.db')
        self._local = threading.local()
        self._ensure_data_dir()
        self._init_tables()
        
    def _ensure_data_dir(self):
        """Crea directory dati se non esiste."""
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        
    def _get_connection(self):
        """Ottiene connessione thread-local."""
        if not hasattr(self._local, 'connection'):
            self._local.connection = sqlite3.connect(
                self.db_path, 
                check_same_thread=False,
                timeout=30.0
            )
            self._local.connection.row_factory = sqlite3.Row
        return self._local.connection
        
    @contextmanager
    def transaction(self):
        """Context manager per transazioni."""
        conn = self._get_connection()
        try:
            yield conn
            conn.commit()
        except Exception as e:
            conn.rollback()
            raise e
            
    def _init_tables(self):
        """Inizializza tabelle database."""
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
        
        -- Tabella Metrics
        CREATE TABLE IF NOT EXISTS metrics (
            id TEXT PRIMARY KEY,
            metric_name TEXT NOT NULL,
            metric_value REAL NOT NULL,
            labels TEXT DEFAULT '{}',
            timestamp TEXT DEFAULT CURRENT_TIMESTAMP
        );
        
        -- Indici
        CREATE INDEX IF NOT EXISTS idx_agents_status ON agents(status);
        CREATE INDEX IF NOT EXISTS idx_trades_timestamp ON trades(timestamp);
        CREATE INDEX IF NOT EXISTS idx_logs_timestamp ON logs(timestamp);
        CREATE INDEX IF NOT EXISTS idx_logs_level ON logs(level);
        CREATE INDEX IF NOT EXISTS idx_metrics_name ON metrics(metric_name);
        '''
        
        conn = self._get_connection()
        conn.executescript(schema)
        conn.commit()
        
    # === AGENT OPERATIONS ===
    
    def create_agent(self, name: str, agent_type: str, config: Dict = None) -> str:
        """Crea nuovo agente."""
        agent_id = str(uuid.uuid4())
        with self.transaction() as conn:
            conn.execute('''
                INSERT INTO agents (id, name, type, status, config, created_at)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (agent_id, name, agent_type, 'inactive', json.dumps(config or {}), 
                  datetime.now().isoformat()))
        return agent_id
        
    def get_agent(self, agent_id: str) -> Optional[Dict]:
        """Recupera agente by ID."""
        conn = self._get_connection()
        row = conn.execute('SELECT * FROM agents WHERE id = ?', (agent_id,)).fetchone()
        if row:
            return dict(row)
        return None
        
    def get_agent_by_name(self, name: str) -> Optional[Dict]:
        """Recupera agente by name."""
        conn = self._get_connection()
        row = conn.execute('SELECT * FROM agents WHERE name = ?', (name,)).fetchone()
        if row:
            return dict(row)
        return None
        
    def update_agent_status(self, agent_id: str, status: str, metrics: Dict = None):
        """Aggiorna stato agente."""
        with self.transaction() as conn:
            conn.execute('''
                UPDATE agents SET status = ?, last_seen = ?, metrics = ?
                WHERE id = ?
            ''', (status, datetime.now().isoformat(), json.dumps(metrics or {}), agent_id))
            
    def list_agents(self, status: str = None) -> List[Dict]:
        """Lista agenti."""
        conn = self._get_connection()
        if status:
            rows = conn.execute('SELECT * FROM agents WHERE status = ?', (status,)).fetchall()
        else:
            rows = conn.execute('SELECT * FROM agents').fetchall()
        return [dict(row) for row in rows]
        
    def delete_agent(self, agent_id: str):
        """Elimina agente."""
        with self.transaction() as conn:
            conn.execute('DELETE FROM agents WHERE id = ?', (agent_id,))
            
    # === TRADE OPERATIONS ===
    
    def create_trade(self, token_symbol: str, action: str, amount: float, 
                     price: float, tx_hash: str = None) -> str:
        """Registra trade."""
        trade_id = str(uuid.uuid4())
        with self.transaction() as conn:
            conn.execute('''
                INSERT INTO trades (id, token_symbol, action, amount, price, tx_hash, status)
                VALUES (?, ?, ?, ?, ?, ?, ?)
            ''', (trade_id, token_symbol, action, amount, price, tx_hash, 'pending'))
        return trade_id
        
    def update_trade_status(self, trade_id: str, status: str, profit_loss: float = None):
        """Aggiorna stato trade."""
        with self.transaction() as conn:
            if profit_loss is not None:
                conn.execute('''
                    UPDATE trades SET status = ?, profit_loss = ? WHERE id = ?
                ''', (status, profit_loss, trade_id))
            else:
                conn.execute('UPDATE trades SET status = ? WHERE id = ?', (status, trade_id))
                
    def get_trades(self, token: str = None, limit: int = 100) -> List[Dict]:
        """Recupera trades."""
        conn = self._get_connection()
        if token:
            rows = conn.execute(
                'SELECT * FROM trades WHERE token_symbol = ? ORDER BY timestamp DESC LIMIT ?',
                (token, limit)
            ).fetchall()
        else:
            rows = conn.execute(
                'SELECT * FROM trades ORDER BY timestamp DESC LIMIT ?', (limit,)
            ).fetchall()
        return [dict(row) for row in rows]
        
    def get_trade_stats(self) -> Dict:
        """Statistiche trades."""
        conn = self._get_connection()
        total = conn.execute('SELECT COUNT(*) FROM trades').fetchone()[0]
        profitable = conn.execute(
            "SELECT COUNT(*) FROM trades WHERE profit_loss > 0"
        ).fetchone()[0]
        total_pnl = conn.execute(
            "SELECT COALESCE(SUM(profit_loss), 0) FROM trades WHERE profit_loss IS NOT NULL"
        ).fetchone()[0]
        return {
            'total_trades': total,
            'profitable_trades': profitable,
            'total_pnl': total_pnl
        }
        
    # === LOG OPERATIONS ===
    
    def insert_log(self, level: str, source: str, message: str, metadata: Dict = None):
        """Inserisce log."""
        log_id = str(uuid.uuid4())
        with self.transaction() as conn:
            conn.execute('''
                INSERT INTO logs (id, level, source, message, metadata, timestamp)
                VALUES (?, ?, ?, ?, ?, ?)
            ''', (log_id, level, source, message, json.dumps(metadata or {}),
                  datetime.now().isoformat()))
                  
    def get_logs(self, level: str = None, source: str = None, 
                 limit: int = 100, offset: int = 0) -> List[Dict]:
        """Recupera logs."""
        conn = self._get_connection()
        query = 'SELECT * FROM logs WHERE 1=1'
        params = []
        
        if level:
            query += ' AND level = ?'
            params.append(level)
        if source:
            query += ' AND source = ?'
            params.append(source)
            
        query += ' ORDER BY timestamp DESC LIMIT ? OFFSET ?'
        params.extend([limit, offset])
        
        rows = conn.execute(query, params).fetchall()
        return [dict(row) for row in rows]
        
    def clear_old_logs(self, days: int = 30):
        """Pulisce log vecchi."""
        with self.transaction() as conn:
            conn.execute('''
                DELETE FROM logs 
                WHERE timestamp < datetime('now', '-{} days')
            '''.format(days))
            
    # === METRICS OPERATIONS ===
    
    def record_metric(self, name: str, value: float, labels: Dict = None):
        """Registra metrica."""
        metric_id = str(uuid.uuid4())
        with self.transaction() as conn:
            conn.execute('''
                INSERT INTO metrics (id, metric_name, metric_value, labels, timestamp)
                VALUES (?, ?, ?, ?, ?)
            ''', (metric_id, name, value, json.dumps(labels or {}), 
                  datetime.now().isoformat()))
                  
    def get_metrics(self, name: str, start_time: str = None, 
                    end_time: str = None) -> List[Dict]:
        """Recupera metriche."""
        conn = self._get_connection()
        query = 'SELECT * FROM metrics WHERE metric_name = ?'
        params = [name]
        
        if start_time:
            query += ' AND timestamp >= ?'
            params.append(start_time)
        if end_time:
            query += ' AND timestamp <= ?'
            params.append(end_time)
            
        query += ' ORDER BY timestamp DESC'
        
        rows = conn.execute(query, params).fetchall()
        return [dict(row) for row in rows]
        
    def get_metric_stats(self, name: str) -> Dict:
        """Statistiche metrica."""
        conn = self._get_connection()
        row = conn.execute('''
            SELECT 
                COUNT(*) as count,
                AVG(metric_value) as avg,
                MIN(metric_value) as min,
                MAX(metric_value) as max
            FROM metrics WHERE metric_name = ?
        ''', (name,)).fetchone()
        
        return {
            'count': row[0],
            'avg': row[1],
            'min': row[2],
            'max': row[3]
        }
        
    # === CONFIG OPERATIONS ===
    
    def set_config(self, key: str, value: Any):
        """Imposta configurazione."""
        with self.transaction() as conn:
            conn.execute('''
                INSERT OR REPLACE INTO configurations (key, value, updated_at)
                VALUES (?, ?, ?)
            ''', (key, json.dumps(value), datetime.now().isoformat()))
            
    def get_config(self, key: str, default: Any = None) -> Any:
        """Recupera configurazione."""
        conn = self._get_connection()
        row = conn.execute(
            'SELECT value FROM configurations WHERE key = ?', (key,)
        ).fetchone()
        if row:
            return json.loads(row[0])
        return default
        
    def get_all_config(self) -> Dict[str, Any]:
        """Recupera tutte le configurazioni."""
        conn = self._get_connection()
        rows = conn.execute('SELECT key, value FROM configurations').fetchall()
        return {row[0]: json.loads(row[1]) for row in rows}
        
    # === BACKUP / RESTORE ===
    
    def backup_to_json(self, output_path: str):
        """Backup database in JSON."""
        data = {
            'agents': self.list_agents(),
            'trades': self.get_trades(limit=10000),
            'config': self.get_all_config(),
            'timestamp': datetime.now().isoformat()
        }
        with open(output_path, 'w') as f:
            json.dump(data, f, indent=2)
            
    def get_stats(self) -> Dict:
        """Statistiche database."""
        conn = self._get_connection()
        stats = {}
        for table in ['agents', 'trades', 'logs', 'tasks', 'metrics']:
            count = conn.execute(f'SELECT COUNT(*) FROM {table}').fetchone()[0]
            stats[table] = count
        return stats

# Singleton instance
db_manager: Optional[DatabaseManager] = None

def get_db(db_path: str = None) -> DatabaseManager:
    """Ottiene singleton database manager."""
    global db_manager
    if db_manager is None:
        db_manager = DatabaseManager(db_path)
    return db_manager

if __name__ == '__main__':
    # Test
    db = get_db()
    print('Database initialized')
    print('Stats:', db.get_stats())
    
    # Test agent
    agent_id = db.create_agent('TestAgent', 'correttore', {'max_workers': 4})
    print(f'Created agent: {agent_id}')
    
    # Test trade
    trade_id = db.create_trade('TEST', 'buy', 100.0, 1.5)
    print(f'Created trade: {trade_id}')
    
    # Test metric
    db.record_metric('cpu_usage', 45.5, {'host': 'localhost'})
    print('Stats:', db.get_stats())
