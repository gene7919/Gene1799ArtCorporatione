#!/usr/bin/env python3
"""
SuiteV17 Scheduler - Job Scheduling System
Cron-like scheduling with persistence and retry logic
"""
import os
import sys
import json
import asyncio
import threading
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Callable, Any
from dataclasses import dataclass
from enum import Enum
import time

class JobStatus(Enum):
    PENDING = 'pending'
    RUNNING = 'running'
    COMPLETED = 'completed'
    FAILED = 'failed'
    RETRYING = 'retrying'
    CANCELLED = 'cancelled'

class JobType(Enum):
    ONCE = 'once'
    INTERVAL = 'interval'
    CRON = 'cron'
    DAILY = 'daily'
    WEEKLY = 'weekly'

@dataclass
class Job:
    id: str
    name: str
    job_type: JobType
    status: JobStatus
    scheduled_at: datetime
    last_run: Optional[datetime]
    next_run: Optional[datetime]
    interval_seconds: Optional[int]
    cron_expression: Optional[str]
    payload: Dict[str, Any]
    retry_count: int = 0
    max_retries: int = 3

def generate_job_id():
    """Genera ID univoco per job."""
    return f"job_{int(time.time())}_{os.urandom(4).hex()}"

class TaskScheduler:
    """Scheduler per task SuiteV17."""
    
    def __init__(self, db_path: str = None):
        self.jobs: Dict[str, Job] = {}
        self.handlers: Dict[str, Callable] = {}
        self.running = False
        self.loop: Optional[asyncio.AbstractEventLoop] = None
        self.thread: Optional[threading.Thread] = None
        self._lock = threading.Lock()
        self._task = None
        
        # Register default handlers
        self.register_handler('backup', self._handle_backup)
        self.register_handler('notify', self._handle_notify)
        self.register_handler('cleanup', self._handle_cleanup)
        self.register_handler('report', self._handle_report)
        self.register_handler('trade_scan', self._handle_trade_scan)
        
    def register_handler(self, name: str, handler: Callable):
        """Registra handler per tipo task."""
        self.handlers[name] = handler
        
    # === HANDLERS ===
    
    async def _handle_backup(self, payload: Dict) -> Dict:
        """Handler backup automatico."""
        print(f'[{datetime.now()}] Running backup...')
        return {'status': 'completed', 'files_backed_up': 0}
        
    async def _handle_notify(self, payload: Dict) -> Dict:
        """Handler notifica."""
        message = payload.get('message', 'Scheduled notification')
        print(f'[{datetime.now()}] Notification: {message}')
        return {'status': 'sent', 'message': message}
        
    async def _handle_cleanup(self, payload: Dict) -> Dict:
        """Handler pulizia."""
        days = payload.get('days', 7)
        print(f'[{datetime.now()}] Cleaning up logs older than {days} days')
        return {'status': 'completed', 'deleted_records': 0}
        
    async def _handle_report(self, payload: Dict) -> Dict:
        """Handler generazione report."""
        report_type = payload.get('type', 'daily')
        print(f'[{datetime.now()}] Generating {report_type} report')
        return {'status': 'generated', 'report_path': ''}
        
    async def _handle_trade_scan(self, payload: Dict) -> Dict:
        """Handler scansione trades."""
        tokens = payload.get('tokens', [])
        print(f'[{datetime.now()}] Scanning {len(tokens)} tokens')
        return {'status': 'completed', 'opportunities_found': 0}
        
    # === JOB MANAGEMENT ===
    
    def add_job(self, name: str, handler_name: str, 
                job_type: JobType = JobType.ONCE,
                run_at: datetime = None,
                interval_seconds: int = None,
                payload: Dict = None) -> str:
        """Aggiunge nuovo job."""
        job_id = generate_job_id()
        
        now = datetime.now()
        if run_at is None:
            run_at = now
            
        job = Job(
            id=job_id,
            name=name,
            job_type=job_type,
            status=JobStatus.PENDING,
            scheduled_at=run_at,
            last_run=None,
            next_run=run_at if job_type == JobType.ONCE else now,
            interval_seconds=interval_seconds,
            cron_expression=None,
            payload=payload or {}
        )
        
        with self._lock:
            self.jobs[job_id] = job
            
        print(f'Added job: {name} ({job_id}) - Type: {job_type.value}')
        return job_id
        
    def add_cron_job(self, name: str, handler_name: str, 
                     cron: str, payload: Dict = None) -> str:
        """Aggiunge job con espressione cron."""
        # Semplificato: cron come "*/5 * * * *" (ogni 5 minuti)
        return self.add_job(
            name=name,
            handler_name=handler_name,
            job_type=JobType.CRON,
            payload=payload
        )
        
    def remove_job(self, job_id: str) -> bool:
        """Rimuove job."""
        with self._lock:
            if job_id in self.jobs:
                del self.jobs[job_id]
                return True
        return False
        
    def cancel_job(self, job_id: str) -> bool:
        """Cancella job in esecuzione."""
        with self._lock:
            if job_id in self.jobs:
                self.jobs[job_id].status = JobStatus.CANCELLED
                return True
        return False
        
    def get_job(self, job_id: str) -> Optional[Job]:
        """Recupera job."""
        return self.jobs.get(job_id)
        
    def list_jobs(self, status: JobStatus = None) -> List[Job]:
        """Lista jobs."""
        jobs = list(self.jobs.values())
        if status:
            jobs = [j for j in jobs if j.status == status]
        return sorted(jobs, key=lambda x: x.scheduled_at)
        
    def get_next_run(self, job: Job) -> Optional[datetime]:
        """Calcola prossima esecuzione."""
        if job.job_type == JobType.ONCE:
            return None
        elif job.job_type == JobType.INTERVAL and job.interval_seconds:
            last = job.last_run or datetime.now()
            return last + timedelta(seconds=job.interval_seconds)
        elif job.job_type == JobType.DAILY:
            last = job.last_run or datetime.now()
            return last + timedelta(days=1)
        return None
        
    # === SCHEDULER LOOP ===
    
    async def _run_job(self, job: Job):
        """Esegue singolo job."""
        handler_name = job.payload.get('handler', 'default')
        handler = self.handlers.get(handler_name)
        
        if not handler:
            job.status = JobStatus.FAILED
            return
            
        job.status = JobStatus.RUNNING
        job.last_run = datetime.now()
        
        try:
            result = await handler(job.payload)
            job.status = JobStatus.COMPLETED
            job.retry_count = 0
            print(f'Job {job.name} completed: {result}')
        except Exception as e:
            job.retry_count += 1
            if job.retry_count >= job.max_retries:
                job.status = JobStatus.FAILED
                print(f'Job {job.name} failed after {job.max_retries} retries: {e}')
            else:
                job.status = JobStatus.RETRYING
                print(f'Job {job.name} failed, retry {job.retry_count}/{job.max_retries}')
                
    async def _scheduler_loop(self):
        """Loop principale scheduler."""
        while self.running:
            now = datetime.now()
            
            with self._lock:
                for job in list(self.jobs.values()):
                    # Skip completed/cancelled/failed
                    if job.status in [JobStatus.COMPLETED, JobStatus.CANCELLED, JobStatus.FAILED]:
                        if job.job_type == JobType.ONCE:
                            continue
                        # Reset for recurring jobs
                        if job.next_run and job.next_run <= now:
                            job.status = JobStatus.PENDING
                            
                    # Run pending jobs
                    if job.status == JobStatus.PENDING and job.next_run and job.next_run <= now:
                        await self._run_job(job)
                        
                        # Schedule next run for recurring jobs
                        if job.status == JobStatus.COMPLETED and job.job_type != JobType.ONCE:
                            job.next_run = self.get_next_run(job)
                            job.status = JobStatus.PENDING
                            
            await asyncio.sleep(1)
            
    def start(self):
        """Avvia scheduler in thread separato."""
        if self.running:
            return
            
        self.running = True
        
        def run_loop():
            self.loop = asyncio.new_event_loop()
            asyncio.set_event_loop(self.loop)
            self.loop.run_until_complete(self._scheduler_loop())
            
        self.thread = threading.Thread(target=run_loop, daemon=True)
        self.thread.start()
        print('Scheduler started')
        
    def stop(self):
        """Ferma scheduler."""
        self.running = False
        if self.thread:
            self.thread.join(timeout=5)
        print('Scheduler stopped')
        
    # === CONVENIENCE METHODS ===
    
    def schedule_once(self, name: str, handler: str, 
                      delay_seconds: int, payload: Dict = None) -> str:
        """Schedula job una tantum."""
        run_at = datetime.now() + timedelta(seconds=delay_seconds)
        return self.add_job(name, handler, JobType.ONCE, run_at, payload=payload)
        
    def schedule_interval(self, name: str, handler: str,
                         interval_seconds: int, payload: Dict = None) -> str:
        """Schedula job ricorrente."""
        return self.add_job(
            name, handler, JobType.INTERVAL, 
            interval_seconds=interval_seconds,
            payload=payload
        )
        
    def schedule_daily(self, name: str, handler: str, 
                       hour: int, minute: int, payload: Dict = None) -> str:
        """Schedula job giornaliero."""
        now = datetime.now()
        run_at = now.replace(hour=hour, minute=minute, second=0)
        if run_at < now:
            run_at += timedelta(days=1)
        return self.add_job(name, handler, JobType.DAILY, run_at, payload=payload)
        
    def get_stats(self) -> Dict:
        """Statistiche scheduler."""
        total = len(self.jobs)
        by_status = {}
        for job in self.jobs.values():
            by_status[job.status.value] = by_status.get(job.status.value, 0) + 1
        return {
            'total_jobs': total,
            'by_status': by_status,
            'running': self.running
        }

def main():
    """Test scheduler."""
    scheduler = TaskScheduler()
    
    # Test jobs
    scheduler.schedule_interval('Test Job', 'notify', 10, {'message': 'Test notification'})
    scheduler.schedule_once('One-time', 'backup', 5, {'target': 'logs'})
    
    scheduler.start()
    
    try:
        while True:
            time.sleep(5)
            print(f'Stats: {scheduler.get_stats()}')
    except KeyboardInterrupt:
        scheduler.stop()

if __name__ == '__main__':
    main()
