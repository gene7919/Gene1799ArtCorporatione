"""
Gene1799ArtCorporatione - API Network Scanner
Scansiona la rete per identificare tutte le API attribuite al progetto

Features:
1. Integrazione Supabase per storage persistente
2. REST API endpoints per gestione web
3. Webhook notifications per rate limit alerts
4. Analytics dashboard con metriche real-time
5. Auto-scaling rate limits basato su pattern
6. Network scanner per discovery automatico API
"""

import os
import json
import requests
from typing import Dict, List, Optional
from datetime import datetime
import logging

logger = logging.getLogger(__name__)


class APINetworkScanner:
    """Scanner di rete per identificare API del progetto."""
    
    # Domini e pattern da scansionare
    KNOWN_PROVIDERS = {
        'openai': {'domain': 'api.openai.com', 'check_endpoint': '/v1/models'},
        'perplexity': {'domain': 'api.perplexity.ai', 'check_endpoint': '/'},
        'stability': {'domain': 'api.stability.ai', 'check_endpoint': '/v1/user/account'},
        'grok': {'domain': 'api.x.ai', 'check_endpoint': '/v1/models'},
        'github': {'domain': 'api.github.com', 'check_endpoint': '/user'},
        'supabase': {'domain': '.supabase.co', 'check_endpoint': '/rest/v1/'},
        'render': {'domain': 'api.render.com', 'check_endpoint': '/v1/services'},
    }
    
    def __init__(self):
        self.discovered_apis: Dict = {}
        self.scan_results = []
    
    def scan_environment_variables(self) -> Dict:
        """Scansiona environment variables per API keys."""
        found_keys = {}
        
        api_patterns = [
            'API_KEY', 'APIKEY', 'TOKEN', 'SECRET', 'KEY',
            'OPENAI', 'PERPLEXITY', 'STABILITY', 'GROK',
            'GITHUB', 'SUPABASE', 'RENDER'
        ]
        
        for key, value in os.environ.items():
            for pattern in api_patterns:
                if pattern in key.upper() and value:
                    service = self._identify_service(key)
                    found_keys[service] = {
                        'env_var': key,
                        'key_preview': value[:8] + '...' if len(value) > 8 else '***',
                        'discovered_at': datetime.now().isoformat()
                    }
                    break
        
        logger.info(f"Trovate {len(found_keys)} API keys in environment")
        return found_keys
    
    def _identify_service(self, env_key: str) -> str:
        """Identifica il servizio dall'env variable name."""
        env_upper = env_key.upper()
        
        for service in self.KNOWN_PROVIDERS.keys():
            if service.upper() in env_upper:
                return service
        
        return env_key.lower().replace('_api_key', '').replace('_token', '')
    
    def verify_api_key(self, service: str, api_key: str) -> bool:
        """Verifica se una API key è valida facendo una test request."""
        if service not in self.KNOWN_PROVIDERS:
            return False
        
        config = self.KNOWN_PROVIDERS[service]
        url = f"https://{config['domain']}{config['check_endpoint']}"
        
        headers = {'Authorization': f'Bearer {api_key}'}
        
        try:
            response = requests.get(url, headers=headers, timeout=5)
            is_valid = response.status_code in [200, 401]  # 401 = valido ma no permission
            
            if is_valid:
                logger.info(f"✓ API key per '{service}' verificata")
            
            return is_valid
            
        except Exception as e:
            logger.warning(f"Impossibile verificare '{service}': {e}")
            return False
    
    def scan_project_config_files(self, root_path: str = '.') -> Dict:
        """Scansiona file di configurazione del progetto."""
        config_files = [
            '.env', '.env.local', '.env.production',
            'config.json', 'secrets.json',
            'render.yaml', 'docker-compose.yml'
        ]
        
        found_configs = {}
        
        for config_file in config_files:
            file_path = os.path.join(root_path, config_file)
            if os.path.exists(file_path):
                found_configs[config_file] = {
                    'path': file_path,
                    'found_at': datetime.now().isoformat()
                }
        
        return found_configs
    
    def generate_discovery_report(self) -> Dict:
        """Genera report completo delle API scoperte."""
        env_apis = self.scan_environment_variables()
        config_files = self.scan_project_config_files()
        
        report = {
            'scan_timestamp': datetime.now().isoformat(),
            'project': 'Gene1799ArtCorporatione',
            'discovered_apis': env_apis,
            'config_files_found': list(config_files.keys()),
            'total_api_count': len(env_apis),
            'providers_supported': list(self.KNOWN_PROVIDERS.keys()),
            'scan_summary': {
                'ai_services': sum(1 for s in env_apis if s in ['openai', 'perplexity', 'stability', 'grok']),
                'infrastructure': sum(1 for s in env_apis if s in ['github', 'supabase', 'render']),
                'blockchain': sum(1 for s in env_apis if 'zora' in s or 'metamask' in s)
            }
        }
        
        return report


class SupabaseIntegration:
    """Integrazione con Supabase per storage persistente API keys."""
    
    def __init__(self, supabase_url: str, supabase_key: str):
        self.url = supabase_url
        self.key = supabase_key
        self.headers = {
            'apikey': supabase_key,
            'Authorization': f'Bearer {supabase_key}',
            'Content-Type': 'application/json'
        }
    
    def store_encrypted_keys(self, service: str, encrypted_data: str) -> bool:
        """Salva keys encrypted su Supabase."""
        endpoint = f"{self.url}/rest/v1/api_keys"
        
        data = {
            'service_name': service,
            'encrypted_key': encrypted_data,
            'created_at': datetime.now().isoformat(),
            'project': 'gene1799artcorporatione'
        }
        
        try:
            response = requests.post(endpoint, json=data, headers=self.headers)
            return response.status_code in [200, 201]
        except Exception as e:
            logger.error(f"Errore storage Supabase: {e}")
            return False
    
    def get_api_keys(self, service: Optional[str] = None) -> List[Dict]:
        """Recupera keys da Supabase."""
        endpoint = f"{self.url}/rest/v1/api_keys"
        params = {'select': '*', 'project': 'eq.gene1799artcorporatione'}
        
        if service:
            params['service_name'] = f'eq.{service}'
        
        try:
            response = requests.get(endpoint, params=params, headers=self.headers)
            return response.json() if response.status_code == 200 else []
        except Exception as e:
            logger.error(f"Errore recupero da Supabase: {e}")
            return []


class WebhookNotifier:
    """Sistema webhook per notifiche real-time."""
    
    def __init__(self, webhook_urls: List[str]):
        self.webhook_urls = webhook_urls
    
    def send_rate_limit_alert(self, service: str, current_rate: int, limit: int):
        """Invia alert quando rate limit è raggiunto."""
        payload = {
            'event': 'rate_limit_reached',
            'service': service,
            'current_rate': current_rate,
            'limit': limit,
            'timestamp': datetime.now().isoformat(),
            'severity': 'warning' if current_rate < limit * 0.9 else 'critical'
        }
        
        for webhook_url in self.webhook_urls:
            try:
                requests.post(webhook_url, json=payload, timeout=5)
                logger.info(f"Alert inviato a {webhook_url}")
            except Exception as e:
                logger.error(f"Errore invio webhook: {e}")


class AnalyticsDashboard:
    """Dashboard analytics con metriche real-time."""
    
    def __init__(self):
        self.metrics = {
            'total_requests': 0,
            'requests_by_service': {},
            'rate_limit_hits': 0,
            'avg_response_time': 0
        }
    
    def track_request(self, service: str, response_time: float):
        """Traccia una richiesta API."""
        self.metrics['total_requests'] += 1
        
        if service not in self.metrics['requests_by_service']:
            self.metrics['requests_by_service'][service] = 0
        
        self.metrics['requests_by_service'][service] += 1
        
        # Calcola media response time
        n = self.metrics['total_requests']
        self.metrics['avg_response_time'] = (
            (self.metrics['avg_response_time'] * (n - 1) + response_time) / n
        )
    
    def get_dashboard_data(self) -> Dict:
        """Ritorna dati per dashboard."""
        return {
            'metrics': self.metrics,
            'timestamp': datetime.now().isoformat(),
            'top_services': sorted(
                self.metrics['requests_by_service'].items(),
                key=lambda x: x[1],
                reverse=True
            )[:5]
        }


class AutoScalingRateLimiter:
    """Auto-scaling intelligente dei rate limits."""
    
    def __init__(self):
        self.usage_history = {}
        self.scaling_rules = {
            'scale_up_threshold': 0.8,  # Scala up al 80% usage
            'scale_down_threshold': 0.3,  # Scala down sotto 30% usage
            'max_limit': 1000,
            'min_limit': 10
        }
    
    def analyze_and_adjust(self, service: str, current_usage: int, current_limit: int) -> int:
        """Analizza usage e suggerisce nuovo limite."""
        usage_ratio = current_usage / current_limit if current_limit > 0 else 0
        
        if usage_ratio >= self.scaling_rules['scale_up_threshold']:
            # Scala UP del 50%
            new_limit = min(
                int(current_limit * 1.5),
                self.scaling_rules['max_limit']
            )
            logger.info(f"🔼 Scaling UP {service}: {current_limit} -> {new_limit}")
            return new_limit
        
        elif usage_ratio <= self.scaling_rules['scale_down_threshold']:
            # Scala DOWN del 30%
            new_limit = max(
                int(current_limit * 0.7),
                self.scaling_rules['min_limit']
            )
            logger.info(f"🔽 Scaling DOWN {service}: {current_limit} -> {new_limit}")
            return new_limit
        
        return current_limit


# Funzione main per esecuzione scanner
if __name__ == "__main__":
    print("\n🔍 Gene1799ArtCorporatione - API Network Scanner\n")
    
    scanner = APINetworkScanner()
    report = scanner.generate_discovery_report()
    
    print(json.dumps(report, indent=2))
    print(f"\n✅ Scansione completata: {report['total_api_count']} API scoperte")
    print(f"📊 AI Services: {report['scan_summary']['ai_services']}")
    print(f"🏗️  Infrastructure: {report['scan_summary']['infrastructure']}")
    print(f"⛓️  Blockchain: {report['scan_summary']['blockchain']}")
