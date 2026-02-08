"""
Gene1799 Orchestrator Integration System
Connects GUI, Solutions Engine, and Services Management
GPT-powered intelligent orchestration with RTX 4070 acceleration
"""

import asyncio
import json
import time
import subprocess
import os
import sys
from datetime import datetime
from typing import Dict, List, Any, Optional
import psutil

# GPU Support
try:
    import pynvml
    NVIDIA_AVAILABLE = True
    pynvml.nvmlInit()
except ImportError:
    NVIDIA_AVAILABLE = False
    print("[WARN] NVIDIA support not available - using CPU mode")


class ServiceIntegration:
    """Manages service integration and communication"""
    
    def __init__(self):
        self.services = {
            'backend': {'port': 3000, 'name': 'Backend API', 'type': 'express'},
            'frontend': {'port': 5173, 'name': 'Frontend UI', 'type': 'vite'},
            'ai_agent': {'port': 8000, 'name': 'AI Agent', 'type': 'python'},
            'desktop': {'port': None, 'name': 'Desktop App', 'type': 'electron'}
        }
        self.service_processes = {}
    
    def check_service_status(self, service_name: str) -> Dict[str, Any]:
        """Check if a service is running"""
        service = self.services.get(service_name)
        if not service:
            return {'status': 'unknown', 'running': False}
        
        port = service['port']
        if port is None:
            return {'status': 'local', 'port': None}
        
        try:
            for conn in psutil.net_connections():
                if conn.laddr.port == port and conn.status == 'LISTEN':
                    return {
                        'status': 'running',
                        'running': True,
                        'port': port,
                        'name': service['name']
                    }
        except Exception as e:
            return {'status': 'error', 'error': str(e)}
        
        return {'status': 'stopped', 'running': False, 'port': port}
    
    def get_all_services_status(self) -> Dict[str, Any]:
        """Get status of all services"""
        status = {}
        for service_name in self.services:
            status[service_name] = self.check_service_status(service_name)
        return status


class GPUMonitor:
    """Monitors NVIDIA GPU performance"""
    
    def __init__(self):
        self.gpu_available = NVIDIA_AVAILABLE
        
    def get_gpu_info(self) -> Dict[str, Any]:
        """Get GPU information and metrics"""
        if not self.gpu_available:
            return {'available': False, 'mode': 'CPU'}
        
        try:
            gpu_count = pynvml.nvmlDeviceGetCount()
            if gpu_count == 0:
                return {'available': False, 'mode': 'CPU'}
            
            # Get first GPU (RTX 4070)
            handle = pynvml.nvmlDeviceGetHandleByIndex(0)
            
            # Get basic info
            gpu_name = pynvml.nvmlDeviceGetName(handle).decode() if isinstance(
                pynvml.nvmlDeviceGetName(handle), bytes) else pynvml.nvmlDeviceGetName(handle)
            
            # Get memory info
            mem_info = pynvml.nvmlDeviceGetMemoryInfo(handle)
            mem_total_mb = mem_info.total / (1024 * 1024)
            mem_used_mb = mem_info.used / (1024 * 1024)
            mem_util = (mem_info.used / mem_info.total) * 100
            
            # Get utilization
            try:
                util = pynvml.nvmlDeviceGetUtilizationRates(handle)
                gpu_util = util.gpu
                mem_util_alt = util.memory
            except:
                gpu_util = 0
                mem_util_alt = mem_util
            
            # Get temperature
            try:
                temp = pynvml.nvmlDeviceGetTemperature(handle, 0)
            except:
                temp = 0
            
            # Get power usage
            try:
                power_mw = pynvml.nvmlDeviceGetPowerUsage(handle)
                power_w = power_mw / 1000.0
            except:
                power_w = 0
            
            return {
                'available': True,
                'mode': 'GPU',
                'gpu_name': gpu_name,
                'memory': {
                    'total_mb': round(mem_total_mb, 2),
                    'used_mb': round(mem_used_mb, 2),
                    'utilization': round(mem_util, 1)
                },
                'utilization': {
                    'gpu': gpu_util,
                    'memory': round(mem_util_alt, 1)
                },
                'temperature': round(temp, 1) if temp > 0 else None,
                'power_watts': round(power_w, 2) if power_w > 0 else None
            }
        except Exception as e:
            return {'available': False, 'error': str(e), 'mode': 'CPU'}
    
    def get_system_metrics(self) -> Dict[str, Any]:
        """Get system-wide metrics"""
        return {
            'cpu_percent': psutil.cpu_percent(interval=0.1),
            'memory': {
                'percent': psutil.virtual_memory().percent,
                'used_gb': round(psutil.virtual_memory().used / (1024**3), 2),
                'total_gb': round(psutil.virtual_memory().total / (1024**3), 2)
            },
            'disk': {
                'percent': psutil.disk_usage('/').percent,
                'used_gb': round(psutil.disk_usage('/').used / (1024**3), 2),
                'total_gb': round(psutil.disk_usage('/').total / (1024**3), 2)
            },
            'timestamp': datetime.now().isoformat()
        }


class ReportGenerator:
    """Generates comprehensive system reports"""
    
    def __init__(self, service_integration: ServiceIntegration, gpu_monitor: GPUMonitor):
        self.service_integration = service_integration
        self.gpu_monitor = gpu_monitor
    
    def generate_status_report(self) -> Dict[str, Any]:
        """Generate comprehensive system status report"""
        services_status = self.service_integration.get_all_services_status()
        gpu_info = self.gpu_monitor.get_gpu_info()
        system_metrics = self.gpu_monitor.get_system_metrics()
        
        # Count running services
        running_services = sum(1 for s in services_status.values() if s.get('running', False))
        total_services = len(services_status)
        
        report = {
            'timestamp': datetime.now().isoformat(),
            'system_health': {
                'services': f"{running_services}/{total_services} running",
                'services_detail': services_status,
                'gpu_enabled': gpu_info.get('available', False),
                'gpu_info': gpu_info.get('gpu_name', 'NOT AVAILABLE'),
                'execution_mode': gpu_info.get('mode', 'CPU')
            },
            'performance': {
                'cpu': system_metrics['cpu_percent'],
                'memory': system_metrics['memory'],
                'disk': system_metrics['disk'],
                'gpu': gpu_info if 'memory' in gpu_info else None
            },
            'status': 'healthy' if running_services > 0 else 'degraded'
        }
        
        return report
    
    def generate_text_report(self) -> str:
        """Generate human-readable text report"""
        report_data = self.generate_status_report()
        
        text = f"""
╔════════════════════════════════════════════════════════════════╗
║              GENE1799 ORCHESTRATOR - SYSTEM REPORT              ║
╚════════════════════════════════════════════════════════════════╝

Generated: {report_data['timestamp']}
Status: {report_data['status'].upper()}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SYSTEM HEALTH
─────────────
Services Running: {report_data['system_health']['services']}
Execution Mode: {report_data['system_health']['execution_mode']}
GPU Enabled: {'YES' if report_data['system_health']['gpu_enabled'] else 'NO'}
GPU Device: {report_data['system_health']['gpu_info']}

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

SERVICE STATUS
──────────────
"""
        for service_name, status in report_data['system_health']['services_detail'].items():
            running_status = "[RUNNING]" if status.get('running', False) else "[STOPPED]"
            port_info = f" (Port {status['port']})" if status.get('port') else ""
            text += f"{service_name.upper()}: {running_status}{port_info}\n"
        
        text += f"""
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

PERFORMANCE METRICS
──────────────────
CPU Usage: {report_data['performance']['cpu']:.1f}%

Memory:
  Used: {report_data['performance']['memory']['used_gb']} GB / {report_data['performance']['memory']['total_gb']} GB
  Utilization: {report_data['performance']['memory']['percent']:.1f}%

Disk:
  Used: {report_data['performance']['disk']['used_gb']} GB / {report_data['performance']['disk']['total_gb']} GB
  Utilization: {report_data['performance']['disk']['percent']:.1f}%
"""
        
        if report_data['performance']['gpu']:
            gpu = report_data['performance']['gpu']
            if gpu.get('memory'):
                text += f"""
GPU ACCELERATION (RTX 4070)
──────────────────────────
GPU Name: {gpu.get('gpu_name', 'Unknown')}
GPU Utilization: {gpu['utilization'].get('gpu', 0):.1f}%
GPU Memory: {gpu['memory']['used_mb']} MB / {gpu['memory']['total_mb']} MB
Memory Utilization: {gpu['memory']['utilization']:.1f}%
"""
                if gpu.get('temperature'):
                    text += f"Temperature: {gpu['temperature']}°C\n"
                if gpu.get('power_watts'):
                    text += f"Power Draw: {gpu['power_watts']} W\n"
        
        text += """
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

RECOMMENDATIONS
───────────────
"""
        
        # Generate recommendations
        if report_data['performance']['cpu'] > 80:
            text += "⚠️  High CPU usage detected - consider optimizing workloads\n"
        
        if report_data['performance']['memory']['percent'] > 80:
            text += "⚠️  High memory usage detected - consider freeing resources\n"
        
        if report_data['system_health']['gpu_enabled']:
            text += "✓ GPU acceleration: ENABLED and AVAILABLE\n"
        else:
            text += "ℹ️  GPU acceleration: NOT AVAILABLE (CPU mode)\n"
        
        text += """
╚════════════════════════════════════════════════════════════════╝
"""
        
        return text
    
    def save_report(self, filename: Optional[str] = None) -> str:
        """Save report to file"""
        if filename is None:
            filename = f"orchestrator_report_{datetime.now().strftime('%Y%m%d_%H%M%S')}.txt"
        
        filepath = os.path.join(os.getcwd(), filename)
        
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(self.generate_text_report())
        
        return filepath


class OrchestratorIntegration:
    """Master integration layer"""
    
    def __init__(self):
        self.services = ServiceIntegration()
        self.gpu = GPUMonitor()
        self.reporter = ReportGenerator(self.services, self.gpu)
    
    def get_status(self) -> Dict[str, Any]:
        """Get complete system status"""
        return {
            'timestamp': datetime.now().isoformat(),
            'services': self.services.get_all_services_status(),
            'gpu': self.gpu.get_gpu_info(),
            'metrics': self.gpu.get_system_metrics()
        }
    
    def generate_report(self) -> str:
        """Generate and save report"""
        return self.reporter.save_report()
    
    def print_status(self):
        """Print status to console"""
        print(self.reporter.generate_text_report())


# Example usage
if __name__ == "__main__":
    print("Gene1799 Orchestrator Integration System")
    print("=" * 60)
    
    integrator = OrchestratorIntegration()
    
    # Print status
    integrator.print_status()
    
    # Generate report
    report_path = integrator.generate_report()
    print(f"\nReport saved to: {report_path}")
