#!/usr/bin/env python3
"""
SuiteV17 Performance Optimizer v3.0
Sistema di ottimizzazione fluidità e prestazioni
"""
import os
import psutil
import json
import time
import asyncio
import threading
from typing import Dict, List, Optional, Any
from dataclasses import dataclass
from datetime import datetime, timedelta
from collections import deque
import logging

@dataclass
class PerformanceMetrics:
    """Metriche di performance"""
    cpu_percent: float = 0.0
    memory_percent: float = 0.0
    memory_available_mb: float = 0.0
    disk_io_read: float = 0.0
    disk_io_write: float = 0.0
    network_io_sent: float = 0.0
    network_io_recv: float = 0.0
    process_count: int = 0
    thread_count: int = 0
    timestamp: datetime = None
    
    def __post_init__(self):
        if self.timestamp is None:
            self.timestamp = datetime.now()

class FluidityOptimizer:
    """Ottimizzatore fluidità sistema"""
    
    def __init__(self):
        self.metrics_history = deque(maxlen=1000)
        self.optimization_rules = []
        self.throttle_level = 0  # 0-5, dove 5 è massima limitazione
        self.baseline_metrics = {}
        self.last_optimization = None
        self.optimization_count = 0
        self._running = False
        self._monitor_thread = None
        
        # Soglie ottimizzazione
        self.thresholds = {
            "cpu_warning": 70.0,
            "cpu_critical": 90.0,
            "memory_warning": 80.0,
            "memory_critical": 95.0,
            "process_limit": 200
        }
        
    def start_monitoring(self, interval: float = 1.0):
        """Avvia monitoraggio continuo"""
        self._running = True
        self._monitor_thread = threading.Thread(target=self._monitor_loop, args=(interval,))
        self._monitor_thread.daemon = True
        self._monitor_thread.start()
        
    def stop_monitoring(self):
        """Ferma monitoraggio"""
        self._running = False
        if self._monitor_thread:
            self._monitor_thread.join(timeout=2.0)
            
    def _monitor_loop(self, interval: float):
        """Loop monitoraggio"""
        while self._running:
            try:
                metrics = self.collect_metrics()
                self.metrics_history.append(metrics)
                
                # Controlla necessità ottimizzazione
                self._check_and_optimize(metrics)
                
                time.sleep(interval)
            except Exception as e:
                logging.error(f"Errore monitoraggio: {e}")
                time.sleep(interval)
                
    def collect_metrics(self) -> PerformanceMetrics:
        """Raccoglie metriche sistema"""
        cpu_percent = psutil.cpu_percent(interval=0.1)
        memory = psutil.virtual_memory()
        disk_io = psutil.disk_io_counters()
        net_io = psutil.net_io_counters()
        
        return PerformanceMetrics(
            cpu_percent=cpu_percent,
            memory_percent=memory.percent,
            memory_available_mb=memory.available / 1024 / 1024,
            disk_io_read=disk_io.read_bytes / 1024 / 1024 if disk_io else 0,
            disk_io_write=disk_io.write_bytes / 1024 / 1024 if disk_io else 0,
            network_io_sent=net_io.bytes_sent / 1024 / 1024 if net_io else 0,
            network_io_recv=net_io.bytes_recv / 1024 / 1024 if net_io else 0,
            process_count=len(psutil.pids()),
            thread_count=threading.active_count()
        )
        
    def _check_and_optimize(self, metrics: PerformanceMetrics):
        """Controlla e applica ottimizzazioni"""
        actions = []
        
        # Ottimizzazione CPU
        if metrics.cpu_percent > self.thresholds["cpu_critical"]:
            actions.extend(self._optimize_cpu_critical())
        elif metrics.cpu_percent > self.thresholds["cpu_warning"]:
            actions.extend(self._optimize_cpu_warning())
            
        # Ottimizzazione Memoria
        if metrics.memory_percent > self.thresholds["memory_critical"]:
            actions.extend(self._optimize_memory_critical())
        elif metrics.memory_percent > self.thresholds["memory_warning"]:
            actions.extend(self._optimize_memory_warning())
            
        # Ottimizzazione Processi
        if metrics.process_count > self.thresholds["process_limit"]:
            actions.extend(self._optimize_processes())
            
        if actions:
            self.last_optimization = datetime.now()
            self.optimization_count += 1
            logging.info(f"Ottimizzazioni applicate: {actions}")
            
    def _optimize_cpu_warning(self) -> List[str]:
        """Ottimizzazione CPU livello warning"""
        actions = []
        
        # Riduci priorità processi Python
        for proc in psutil.process_iter(['pid', 'name', 'cpu_percent']):
            try:
                if 'python' in proc.info['name'].lower():
                    p = psutil.Process(proc.info['pid'])
                    p.nice(psutil.BELOW_NORMAL_PRIORITY_CLASS)
                    actions.append(f"Ridotta priorita PID {proc.info['pid']}")
            except:
                pass
                
        return actions
        
    def _optimize_cpu_critical(self) -> List[str]:
        """Ottimizzazione CPU livello critico"""
        actions = self._optimize_cpu_warning()
        
        # Throttling aggiuntivo
        self.throttle_level = min(5, self.throttle_level + 1)
        actions.append(f"Throttle level aumentato a {self.throttle_level}")
        
        return actions
        
    def _optimize_memory_warning(self) -> List[str]:
        """Ottimizzazione memoria warning"""
        actions = []
        
        # Garbage collection
        import gc
        collected = gc.collect()
        actions.append(f"GC: liberati {collected} oggetti")
        
        return actions
        
    def _optimize_memory_critical(self) -> List[str]:
        """Ottimizzazione memoria critica"""
        actions = self._optimize_memory_warning()
        
        # Libera cache Python
        try:
            import sys
            sys.stdout.flush()
            actions.append("Flush stdout buffer")
        except:
            pass
            
        return actions
        
    def _optimize_processes(self) -> List[str]:
        """Ottimizza numero processi"""
        actions = []
        
        # Termina processi zombie
        for proc in psutil.process_iter(['pid', 'status']):
            try:
                if proc.info['status'] == psutil.STATUS_ZOMBIE:
                    psutil.Process(proc.info['pid']).terminate()
                    actions.append(f"Terminato zombie PID {proc.info['pid']}")
            except:
                pass
                
        return actions
        
    def get_fluidity_score(self) -> float:
        """Calcola punteggio fluidità 0-100"""
        if not self.metrics_history:
            return 100.0
            
        recent = list(self.metrics_history)[-10:]
        avg_cpu = sum(m.cpu_percent for m in recent) / len(recent)
        avg_mem = sum(m.memory_percent for m in recent) / len(recent)
        
        # Punteggio basato su risorse disponibili
        cpu_score = max(0, 100 - avg_cpu)
        mem_score = max(0, 100 - avg_mem)
        
        # Penalità per throttling
        throttle_penalty = self.throttle_level * 10
        
        return max(0, (cpu_score + mem_score) / 2 - throttle_penalty)
        
    def get_recommendations(self) -> List[str]:
        """Raccomandazioni ottimizzazione"""
        recs = []
        
        if not self.metrics_history:
            return recs
            
        latest = self.metrics_history[-1]
        
        if latest.cpu_percent > 80:
            recs.append("CPU alta: considerare riduzione carico o upgrade hardware")
        if latest.memory_percent > 85:
            recs.append("Memoria alta: chiudere applicazioni non necessarie")
        if latest.process_count > 150:
            recs.append("Troppi processi: verificare processi in background")
            
        return recs
        
    def get_stats(self) -> Dict:
        """Statistiche ottimizzatore"""
        return {
            "fluidity_score": round(self.get_fluidity_score(), 2),
            "throttle_level": self.throttle_level,
            "optimization_count": self.optimization_count,
            "last_optimization": self.last_optimization.isoformat() if self.last_optimization else None,
            "metrics_history_size": len(self.metrics_history),
            "recommendations": self.get_recommendations(),
            "current_metrics": self.collect_metrics().__dict__ if self.metrics_history else None
        }

class AdaptiveThrottle:
    """Throttle adattivo per richieste AI"""
    
    def __init__(self):
        self.request_times = deque(maxlen=100)
        self.current_delay = 0.0
        self.min_delay = 0.1
        self.max_delay = 5.0
        self.success_rate = 1.0
        
    async def throttle(self):
        """Applica throttling adattivo"""
        if self.current_delay > 0:
            await asyncio.sleep(self.current_delay)
            
    def record_success(self, duration: float):
        """Registra successo"""
        self.request_times.append(duration)
        self.success_rate = min(1.0, self.success_rate + 0.1)
        self._adjust_delay()
        
    def record_failure(self):
        """Registra fallimento"""
        self.success_rate = max(0.0, self.success_rate - 0.2)
        self.current_delay = min(self.max_delay, self.current_delay + 0.5)
        
    def _adjust_delay(self):
        """Aggiusta delay basato su successo"""
        if self.success_rate > 0.8:
            self.current_delay = max(self.min_delay, self.current_delay * 0.9)
        elif self.success_rate < 0.5:
            self.current_delay = min(self.max_delay, self.current_delay * 1.2)

# Singleton
perf_optimizer = FluidityOptimizer()
adaptive_throttle = AdaptiveThrottle()

if __name__ == "__main__":
    print("Testing Performance Optimizer...")
    
    opt = FluidityOptimizer()
    opt.start_monitoring(interval=1.0)
    
    time.sleep(3)
    
    print(f"Stats: {json.dumps(opt.get_stats(), indent=2, default=str)}")
    
    opt.stop_monitoring()
