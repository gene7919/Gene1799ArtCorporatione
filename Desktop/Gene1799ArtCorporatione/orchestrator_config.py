"""
Gene1799 Orchestrator Configuration Manager
Centralized configuration for all system components
"""

import os
import json
from typing import Dict, Any, Optional
from pathlib import Path
from datetime import datetime


class OrchestratorConfig:
    """Manages all orchestrator configuration"""
    
    DEFAULT_CONFIG = {
        'system': {
            'name': 'Gene1799 Orchestrator',
            'version': '1.0.0',
            'environment': 'production',
            'debug_mode': False,
            'log_level': 'INFO'
        },
        'services': {
            'backend': {
                'name': 'Backend API',
                'type': 'express',
                'port': 3000,
                'host': 'localhost',
                'enabled': True,
                'auto_start': True,
                'restart_on_failure': True
            },
            'frontend': {
                'name': 'Frontend UI',
                'type': 'vite',
                'port': 5173,
                'host': 'localhost',
                'enabled': True,
                'auto_start': True,
                'restart_on_failure': False
            },
            'ai_agent': {
                'name': 'AI Agent',
                'type': 'python',
                'port': 8000,
                'host': 'localhost',
                'enabled': True,
                'auto_start': True,
                'restart_on_failure': True
            },
            'desktop': {
                'name': 'Desktop Application',
                'type': 'electron',
                'port': None,
                'enabled': False,
                'auto_start': False
            }
        },
        'agents': {
            'orchestrator': {
                'enabled': True,
                'capabilities': ['service_management', 'health_monitoring', 'reporting']
            },
            'data_processor': {
                'enabled': True,
                'capabilities': ['data_processing', 'transformation', 'analysis']
            },
            'analytics': {
                'enabled': True,
                'capabilities': ['metrics_collection', 'trend_analysis', 'reporting']
            },
            'communicator': {
                'enabled': True,
                'capabilities': ['messaging', 'notifications', 'logging']
            },
            'learning': {
                'enabled': True,
                'capabilities': ['optimization', 'pattern_detection', 'recommendations']
            }
        },
        'specialized_agents': {
            'anti_cancer': {
                'enabled': True,
                'domain': 'medical_oncology',
                'capabilities': [
                    'tumor_classification',
                    'drug_targeting',
                    'clinical_trials',
                    'prognosis'
                ]
            },
            'drug_discovery': {
                'enabled': True,
                'domain': 'pharmaceutical',
                'capabilities': [
                    'molecular_docking',
                    'compound_screening',
                    'admet_prediction',
                    'lead_optimization'
                ]
            },
            'healthcare': {
                'enabled': True,
                'domain': 'healthcare_integration',
                'capabilities': [
                    'ehr_integration',
                    'patient_analytics',
                    'outcomes_prediction',
                    'care_coordination'
                ]
            },
            'multi_agent': {
                'enabled': True,
                'domain': 'orchestration',
                'capabilities': [
                    'agent_coordination',
                    'workflow_management',
                    'task_distribution',
                    'result_aggregation'
                ]
            }
        },
        'gpu': {
            'enabled': True,
            'device': 'RTX 4070',
            'cuda_compute_capability': 8.9,
            'max_memory_mb': 12000,
            'monitoring': {
                'enabled': True,
                'interval_seconds': 2,
                'temperature_alert_celsius': 85
            }
        },
        'monitoring': {
            'enabled': True,
            'update_interval_seconds': 3,
            'metrics': {
                'cpu': True,
                'memory': True,
                'disk': True,
                'gpu': True,
                'network': False,
                'services': True
            },
            'health_check_interval_seconds': 10,
            'log_metrics': True
        },
        'reporting': {
            'enabled': True,
            'auto_report': True,
            'report_interval_minutes': 60,
            'formats': ['text', 'json', 'html'],
            'storage_path': './reports',
            'retention_days': 30
        },
        'gui': {
            'enabled': True,
            'theme': 'dark',
            'window_size': {
                'width': 1200,
                'height': 800
            },
            'refresh_interval_ms': 1000,
            'colors': {
                'background': '#0a0e27',
                'accent': '#00d4ff',
                'success': '#00ff88',
                'warning': '#ffaa00',
                'error': '#ff4444',
                'text': '#e0e0e0'
            }
        },
        'logging': {
            'enabled': True,
            'level': 'INFO',
            'file_logging': True,
            'log_file': 'orchestrator.log',
            'max_log_size_mb': 10,
            'backup_count': 5,
            'format': '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        },
        'security': {
            'enable_authentication': False,
            'verify_ssl': True,
            'allowed_hosts': ['localhost', '127.0.0.1'],
            'rate_limiting': {
                'enabled': False,
                'requests_per_minute': 100
            }
        },
        'performance': {
            'max_concurrent_tasks': 10,
            'request_timeout_seconds': 30,
            'connection_pool_size': 20,
            'use_async': True
        }
    }
    
    def __init__(self, config_path: Optional[str] = None):
        self.config_path = config_path or os.path.join(os.getcwd(), 'orchestrator_config.json')
        self.config = self.load_config()
    
    def load_config(self) -> Dict[str, Any]:
        """Load configuration from file or use defaults"""
        if os.path.exists(self.config_path):
            try:
                with open(self.config_path, 'r') as f:
                    loaded_config = json.load(f)
                return {**self.DEFAULT_CONFIG, **loaded_config}
            except Exception as e:
                print(f"Warning: Could not load config file: {e}. Using defaults.")
                return self.DEFAULT_CONFIG.copy()
        else:
            return self.DEFAULT_CONFIG.copy()
    
    def save_config(self) -> bool:
        """Save current configuration to file"""
        try:
            os.makedirs(os.path.dirname(self.config_path) or '.', exist_ok=True)
            with open(self.config_path, 'w') as f:
                json.dump(self.config, f, indent=2)
            return True
        except Exception as e:
            print(f"Error saving config: {e}")
            return False
    
    def get(self, key: str, default: Any = None) -> Any:
        """Get configuration value by dot notation (e.g., 'services.backend.port')"""
        keys = key.split('.')
        value = self.config
        
        for k in keys:
            if isinstance(value, dict):
                value = value.get(k)
                if value is None:
                    return default
            else:
                return default
        
        return value
    
    def set(self, key: str, value: Any) -> bool:
        """Set configuration value by dot notation"""
        keys = key.split('.')
        config = self.config
        
        for k in keys[:-1]:
            if k not in config:
                config[k] = {}
            config = config[k]
        
        config[keys[-1]] = value
        return self.save_config()
    
    def get_service_config(self, service_name: str) -> Optional[Dict[str, Any]]:
        """Get specific service configuration"""
        return self.config.get('services', {}).get(service_name)
    
    def get_agent_config(self, agent_name: str) -> Optional[Dict[str, Any]]:
        """Get specific agent configuration"""
        configs = self.config.get('agents', {})
        return configs.get(agent_name) or self.config.get('specialized_agents', {}).get(agent_name)
    
    def is_service_enabled(self, service_name: str) -> bool:
        """Check if service is enabled"""
        service = self.get_service_config(service_name)
        return service.get('enabled', False) if service else False
    
    def is_agent_enabled(self, agent_name: str) -> bool:
        """Check if agent is enabled"""
        agent = self.get_agent_config(agent_name)
        return agent.get('enabled', False) if agent else False
    
    def get_enabled_services(self) -> Dict[str, Dict[str, Any]]:
        """Get all enabled services"""
        return {
            name: config for name, config in self.config.get('services', {}).items()
            if config.get('enabled', False)
        }
    
    def get_enabled_agents(self) -> Dict[str, Dict[str, Any]]:
        """Get all enabled agents (standard + specialized)"""
        enabled = {}
        
        for name, config in self.config.get('agents', {}).items():
            if config.get('enabled', False):
                enabled[name] = config
        
        for name, config in self.config.get('specialized_agents', {}).items():
            if config.get('enabled', False):
                enabled[name] = config
        
        return enabled
    
    def to_json(self) -> str:
        """Export configuration as JSON"""
        return json.dumps(self.config, indent=2)
    
    def print_summary(self):
        """Print configuration summary"""
        print("\n" + "=" * 70)
        print("GENE1799 ORCHESTRATOR - CONFIGURATION SUMMARY")
        print("=" * 70)
        
        print(f"\nSystem:")
        print(f"  Name: {self.get('system.name')}")
        print(f"  Version: {self.get('system.version')}")
        print(f"  Environment: {self.get('system.environment')}")
        print(f"  Debug: {self.get('system.debug_mode')}")
        
        print(f"\nServices (Enabled/Total):")
        for name, config in self.config.get('services', {}).items():
            status = "[ENABLED]" if config.get('enabled') else "[DISABLED]"
            port = f" - Port {config.get('port')}" if config.get('port') else ""
            print(f"  {name}: {status}{port}")
        
        print(f"\nAgents (Enabled/Total):")
        enabled_standard = {name: config for name, config in self.config.get('agents', {}).items()
                          if config.get('enabled')}
        enabled_specialized = {name: config for name, config in self.config.get('specialized_agents', {}).items()
                             if config.get('enabled')}
        
        print(f"  Standard Agents: {len(enabled_standard)}")
        for name in enabled_standard:
            print(f"    - {name}")
        
        print(f"  Specialized Agents: {len(enabled_specialized)}")
        for name in enabled_specialized:
            print(f"    - {name}")
        
        print(f"\nGPU Configuration:")
        print(f"  Enabled: {self.get('gpu.enabled')}")
        print(f"  Device: {self.get('gpu.device')}")
        print(f"  Monitoring: {self.get('gpu.monitoring.enabled')}")
        
        print("\n" + "=" * 70 + "\n")


# Initialize default config if needed
def init_config(config_path: Optional[str] = None) -> OrchestratorConfig:
    """Initialize or load orchestrator configuration"""
    config = OrchestratorConfig(config_path)
    
    # Save default config if it doesn't exist
    if not os.path.exists(config.config_path):
        config.save_config()
    
    return config


# Example usage
if __name__ == "__main__":
    config = init_config()
    config.print_summary()
    
    # Example: Get specific values
    print("Backend port:", config.get('services.backend.port'))
    print("GPU enabled:", config.get('gpu.enabled'))
    print("Enabled services:", list(config.get_enabled_services().keys()))
