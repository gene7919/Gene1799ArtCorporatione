#!/usr/bin/env python3
"""
SuiteV17 Distributed Task Queue
Task queue distribuito con Redis (opzionale) e SQLite fallback
"""
import os
import json
import pickle
import hashlib
import threading
import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Callable, Any, Union
from dataclasses import dataclass, asdict
from enum import Enum
from pathlib import Path
import sqlite3
import uuid
import logging

logger = logging.getLogger(__name__)

class TaskPriority(Enum):
    CRITICAL = 0
    HIGH = 1
    NORMAL = 2
    LOW = 3

class TaskState(Enum):
    PENDING = 'pending'
    QUEUED = 'queued'
    RUNNING = 'running'
    SUCCESS = 'success'
    FAILED = 'failed'
    RETRYING = 'retrying'
    CANCELLED = 'cancelled'

@dataclass
class Task:
    id: str
    name: str
    payload: Dict[str, Any]
    priority: TaskPriority
    state: TaskState
    created_at: str
    scheduled_at: str
    started_at: Optional[str]
    completed_at: Optional[str]
    worker_id: Optional[str]
    result: Optional[Any]
    error: Optional[str]
    retry_count: int
    max_retries: int
    timeout_seconds: int

def generate_task_id() -> str:
    return f'task_{uuid.uuid4().hex[:12]}'

class TaskQueue:
    """Task queue con SQLite backend."""
    
    def __init__(self, db_path: str = 'data/task_queue.db'):
        self.db_path = db_path
        self._local = threading.local()
        self._ensure_db()
    
    def _get_connection(self) -> sqlite3.Connection:
        if not hasattr(self._local, 'conn'):
            self._local.conn = sqlite3.connect(self.db_path, check_same_thread=False)
            self._local.conn.row_factory = sqlite3.Row
        return self._local.conn
    
    def _ensure_db(self):
        Path(self.db_path).parent.mkdir(parents=True, exist_ok=True)
        conn = sqlite3.connect(self.db_path)
        conn.execute('''
            CREATE TABLE IF NOT EXISTS tasks (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                payload BLOB,
                priority INTEGER DEFAULT 2,
                state TEXT DEFAULT 'pending',
                created_at TEXT,
                scheduled_at TEXT,
                started_at TEXT,
                completed_at TEXT,
                worker_id TEXT,
                result BLOB,
                error TEXT,
                retry_count INTEGER DEFAULT 0,
                max_retries INTEGER DEFAULT 3,
                timeout_seconds INTEGER DEFAULT 300
            )
        ''')
        conn.execute('CREATE INDEX IF NOT EXISTS idx_state ON tasks(state)')
        conn.execute('CREATE INDEX IF NOT EXISTS idx_priority ON tasks(priority)')
        conn.execute('CREATE INDEX IF NOT EXISTS idx_scheduled ON tasks(scheduled_at)')
        conn.commit()
        conn.close()
    
    def enqueue(self, name: str, payload: Dict = None, 
                priority: TaskPriority = TaskPriority.NORMAL,
                delay_seconds: int = 0,
                max_retries: int = 3,
                timeout_seconds: int = 300) -> str:
        """Aggiunge task alla coda."""
        task = Task(
            id=generate_task_id(),
            name=name,
            payload=payload or {},
            priority=priority,
            state=TaskState.PENDING,
            created_at=datetime.now().isoformat(),
            scheduled_at=(datetime.now() + timedelta(seconds=delay_seconds)).isoformat(),
            started_at=None,
            completed_at=None,
            worker_id=None,
            result=None,
            error=None,
            retry_count=0,
            max_retries=max_retries,
            timeout_seconds=timeout_seconds
        )
        
        conn = self._get_connection()
        conn.execute('''
            INSERT INTO tasks (id, name, payload, priority, state, created_at, 
                             scheduled_at, max_retries, timeout_seconds)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        ''', (task.id, task.name, pickle.dumps(task.payload), task.priority.value,
               task.state.value, task.created_at, task.scheduled_at,
               task.max_retries, task.timeout_seconds))
        conn.commit()
        
        logger.info(f'Task enqueued: {task.name} ({task.id})')
        return task.id
    
    def dequeue(self, worker_id: str = None, timeout: int = 5) -> Optional[Task]:
        """Prende task dalla coda."""
        conn = self._get_connection()
        
        # Trova task disponibile
        cursor = conn.execute('''
            SELECT * FROM tasks 
            WHERE state = 'pending' 
            AND scheduled_at <= ?
            ORDER BY priority ASC, created_at ASC
            LIMIT 1
        ''', (datetime.now().isoformat(),))
        
        row = cursor.fetchone()
        if not row:
            return None
        
        # Marca come running
        task_id = row['id']
        started_at = datetime.now().isoformat()
        
        conn.execute('''
            UPDATE tasks 
            SET state = 'running', started_at = ?, worker_id = ?
            WHERE id = ?
        ''', (started_at, worker_id, task_id))
        conn.commit()
        
        return self._row_to_task(row)
    
    def complete(self, task_id: str, result: Any = None):
        """Marca task come completato."""
        conn = self._get_connection()
        conn.execute('''
            UPDATE tasks 
            SET state = 'success', completed_at = ?, result = ?
            WHERE id = ?
        ''', (datetime.now().isoformat(), pickle.dumps(result) if result else None, task_id))
        conn.commit()
        logger.info(f'Task completed: {task_id}')
    
    def fail(self, task_id: str, error: str, retry: bool = True):
        """Marca task come fallito."""
        conn = self._get_connection()
        
        cursor = conn.execute('SELECT retry_count, max_retries FROM tasks WHERE id = ?', (task_id,))
        row = cursor.fetchone()
        
        if row and retry and row['retry_count'] < row['max_retries']:
            # Riprova
            new_scheduled = (datetime.now() + timedelta(minutes=2 ** row['retry_count'])).isoformat()
            conn.execute('''
                UPDATE tasks 
                SET state = 'pending', scheduled_at = ?, retry_count = retry_count + 1, error = ?
                WHERE id = ?
            ''', (new_scheduled, error, task_id))
        else:
            # Fail definitivo
            conn.execute('''
                UPDATE tasks 
                SET state = 'failed', completed_at = ?, error = ?
                WHERE id = ?
            ''', (datetime.now().isoformat(), error, task_id))
        
        conn.commit()
        logger.warning(f'Task failed: {task_id} - {error}')
    
    def cancel(self, task_id: str) -> bool:
        """Cancella task pendente."""
        conn = self._get_connection()
        cursor = conn.execute('''
            UPDATE tasks SET state = 'cancelled' 
            WHERE id = ? AND state IN ('pending', 'queued')
        ''', (task_id,))
        conn.commit()
        return cursor.rowcount > 0
    
    def get_task(self, task_id: str) -> Optional[Task]:
        """Ritorna task by ID."""
        conn = self._get_connection()
        cursor = conn.execute('SELECT * FROM tasks WHERE id = ?', (task_id,))
        row = cursor.fetchone()
        return self._row_to_task(row) if row else None
    
    def get_stats(self) -> Dict:
        """Statistiche coda."""
        conn = self._get_connection()
        cursor = conn.execute('''
            SELECT state, COUNT(*) as count FROM tasks GROUP BY state
        ''')
        stats = {row['state']: row['count'] for row in cursor.fetchall()}
        
        # Totale
        cursor = conn.execute('SELECT COUNT(*) FROM tasks')
        total = cursor.fetchone()[0]
        
        return {'total': total, 'by_state': stats}
    
    def cleanup_old(self, days: int = 7):
        """Pulisce task vecchi completati."""
        cutoff = (datetime.now() - timedelta(days=days)).isoformat()
        conn = self._get_connection()
        conn.execute('''
            DELETE FROM tasks 
            WHERE state IN ('success', 'failed', 'cancelled')
            AND completed_at < ?
        ''', (cutoff,))
        conn.commit()
    
    def _row_to_task(self, row: sqlite3.Row) -> Task:
        return Task(
            id=row['id'],
            name=row['name'],
            payload=pickle.loads(row['payload']) if row['payload'] else {},
            priority=TaskPriority(row['priority']),
            state=TaskState(row['state']),
            created_at=row['created_at'],
            scheduled_at=row['scheduled_at'],
            started_at=row['started_at'],
            completed_at=row['completed_at'],
            worker_id=row['worker_id'],
            result=pickle.loads(row['result']) if row['result'] else None,
            error=row['error'],
            retry_count=row['retry_count'],
            max_retries=row['max_retries'],
            timeout_seconds=row['timeout_seconds']
        )

class TaskWorker:
    """Worker che processa task dalla coda."""
    
    def __init__(self, queue: TaskQueue, worker_id: str = None):
        self.queue = queue
        self.worker_id = worker_id or f'worker_{uuid.uuid4().hex[:8]}'
        self.handlers: Dict[str, Callable] = {}
        self.running = False
        self._thread: Optional[threading.Thread] = None
    
    def register_handler(self, task_name: str, handler: Callable):
        """Registra handler per tipo task."""
        self.handlers[task_name] = handler
        logger.info(f'Handler registered: {task_name}')
    
    def start(self):
        """Avvia worker."""
        if self.running:
            return
        
        self.running = True
        self._thread = threading.Thread(target=self._run, daemon=True)
        self._thread.start()
        logger.info(f'Worker {self.worker_id} started')
    
    def stop(self):
        """Ferma worker."""
        self.running = False
        if self._thread:
            self._thread.join(timeout=5)
        logger.info(f'Worker {self.worker_id} stopped')
    
    def _run(self):
        """Loop principale worker."""
        while self.running:
            try:
                task = self.queue.dequeue(self.worker_id, timeout=1)
                if task:
                    self._process_task(task)
                else:
                    # Nessun task, aspetta
                    import time
                    time.sleep(1)
            except Exception as e:
                logger.error(f'Worker error: {e}')
    
    def _process_task(self, task: Task):
        """Processa singolo task."""
        handler = self.handlers.get(task.name)
        
        if not handler:
            self.queue.fail(task.id, f'No handler for {task.name}')
            return
        
        try:
            result = handler(task.payload)
            self.queue.complete(task.id, result)
        except Exception as e:
            self.queue.fail(task.id, str(e), retry=True)

class TaskScheduler:
    """Scheduler per task ricorrenti."""
    
    def __init__(self, queue: TaskQueue):
        self.queue = queue
        self.schedules: List[Dict] = []
        self.running = False
    
    def schedule_recurring(self, name: str, payload: Dict, 
                          interval_seconds: int,
                          priority: TaskPriority = TaskPriority.NORMAL):
        """Schedula task ricorrente."""
        self.schedules.append({
            'name': name,
            'payload': payload,
            'interval': interval_seconds,
            'priority': priority,
            'last_run': None
        })
    
    def start(self):
        """Avvia scheduler."""
        self.running = True
        threading.Thread(target=self._run, daemon=True).start()
    
    def _run(self):
        while self.running:
            now = datetime.now()
            for schedule in self.schedules:
                if schedule['last_run'] is None or \
                   (now - schedule['last_run']).seconds >= schedule['interval']:
                    self.queue.enqueue(
                        schedule['name'],
                        schedule['payload'],
                        schedule['priority']
                    )
                    schedule['last_run'] = now
            import time
            time.sleep(1)

# Singleton
task_queue: Optional[TaskQueue] = None

def get_task_queue(db_path: str = 'data/task_queue.db') -> TaskQueue:
    global task_queue
    if task_queue is None:
        task_queue = TaskQueue(db_path)
    return task_queue

def main():
    print('Task Queue Demo')
    print('=' * 50)
    
    queue = TaskQueue()
    
    # Enqueue tasks
    task1 = queue.enqueue('send_email', {'to': 'user@example.com'}, priority=TaskPriority.HIGH)
    task2 = queue.enqueue('process_data', {'file': 'data.csv'})
    
    print(f'Enqueued: {task1}, {task2}')
    print(f'Stats: {queue.get_stats()}')
    
    # Worker demo
    worker = TaskWorker(queue, 'demo-worker')
    
    def email_handler(payload):
        print('Sending email to ' + payload['to'])
        return {'sent': True}
    
    worker.register_handler('send_email', email_handler)
    
    print('\\nWorker ready (handlers registered)')

if __name__ == '__main__':
    main()
