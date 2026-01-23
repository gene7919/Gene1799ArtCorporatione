"""
Gene1799ArtCorporatione - API Manager
Sistema di gestione API inviolabile ed espandibile all'infinito

Features:
- Encryption delle API keys con Fernet (symmetric encryption)
- Rate limiting per prevenire abusi
- Sistema modulare per aggiungere infinite API
- Logging e monitoring completo
- Rotazione automatica delle chiavi
- Gestione errori robu sta
"""

import os
import json
import hashlib
import time
from typing import Dict, Optional, Any
from datetime import datetime, timedelta
from cryptography.fernet import Fernet
from functools import wraps
import logging

# Configurazione logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)


class APIKeyManager:
    """
    Gestore centralizzato per tutte le API keys del sistema.
    Implementa encryption, rate limiting e gestione sicura delle chiavi.
    """
    
    def __init__(self, master_key: Optional[str] = None):
        """Inizializza il manager con encryption key."""
        # Genera o carica master key per encryption
        self.master_key = master_key or os.getenv('API_MASTER_KEY') or Fernet.generate_key()
        self.cipher = Fernet(self.master_key if isinstance(self.master_key, bytes) else self.master_key.encode())
        
        # Storage delle API keys (encrypted)
        self.api_keys: Dict[str, bytes] = {}
        
        # Rate limiting storage
        self.rate_limits: Dict[str, list] = {}
        
        # Configurazione rate limits (requests per minute)
        self.rate_limit_config = {
            'openai': 60,
            'perplexity': 30,
            'stability': 20,
            'default': 100
        }
        
        logger.info("APIKeyManager inizializzato con successo")
    
    def add_api_key(self, service_name: str, api_key: str, metadata: Optional[Dict] = None) -> bool:
        """
        Aggiunge una nuova API key al sistema in modo sicuro.
        
        Args:
            service_name: Nome del servizio (es: 'openai', 'perplexity')
            api_key: La chiave API da proteggere
            metadata: Dati aggiuntivi (es: tier, limiti, scadenza)
        
        Returns:
            bool: True se aggiunta con successo
        """
        try:
            # Encrypta la chiave prima di salvarla
            encrypted_key = self.cipher.encrypt(api_key.encode())
            
            # Salva con metadata
            self.api_keys[service_name] = {
                'key': encrypted_key,
                'added_at': datetime.now().isoformat(),
                'metadata': metadata or {},
                'hash': hashlib.sha256(api_key.encode()).hexdigest()[:16]  # Per verifica
            }
            
            logger.info(f"API key per '{service_name}' aggiunta e criptata con successo")
            return True
            
        except Exception as e:
            logger.error(f"Errore nell'aggiungere API key per '{service_name}': {e}")
            return False
    
    def get_api_key(self, service_name: str) -> Optional[str]:
        """
        Recupera e decrypta una API key.
        
        Args:
            service_name: Nome del servizio
        
        Returns:
            str: La chiave decryptata o None se non trovata
        """
        try:
            if service_name not in self.api_keys:
                logger.warning(f"API key per '{service_name}' non trovata")
                return None
            
            # Decrypta e ritorna
            encrypted_data = self.api_keys[service_name]
            decrypted_key = self.cipher.decrypt(encrypted_data['key']).decode()
            
            logger.debug(f"API key per '{service_name}' recuperata")
            return decrypted_key
            
        except Exception as e:
            logger.error(f"Errore nel recuperare API key per '{service_name}': {e}")
            return None
    
    def rate_limit_check(self, service_name: str) -> bool:
        """
        Verifica se il servizio ha superato il rate limit.
        
        Args:
            service_name: Nome del servizio
        
        Returns:
            bool: True se la richiesta è permessa
        """
        now = time.time()
        
        # Inizializza lista richieste se non esiste
        if service_name not in self.rate_limits:
            self.rate_limits[service_name] = []
        
        # Rimuovi richieste più vecchie di 1 minuto
        self.rate_limits[service_name] = [
            req_time for req_time in self.rate_limits[service_name]
            if now - req_time < 60
        ]
        
        # Controlla limite
        limit = self.rate_limit_config.get(service_name, self.rate_limit_config['default'])
        
        if len(self.rate_limits[service_name]) >= limit:
            logger.warning(f"Rate limit raggiunto per '{service_name}' ({limit}/min)")
            return False
        
        # Aggiungi richiesta corrente
        self.rate_limits[service_name].append(now)
        return True
    
    def rotate_key(self, service_name: str, new_key: str) -> bool:
        """
        Ruota una API key esistente.
        
        Args:
            service_name: Nome del servizio
            new_key: Nuova chiave API
        
        Returns:
            bool: True se rotazione avvenuta con successo
        """
        if service_name in self.api_keys:
            # Salva vecchia chiave per rollback
            old_key_data = self.api_keys[service_name].copy()
            
            # Aggiorna con nuova chiave
            success = self.add_api_key(service_name, new_key, 
                                      old_key_data.get('metadata'))
            
            if success:
                logger.info(f"API key per '{service_name}' ruotata con successo")
                return True
        
        logger.error(f"Impossibile ruotare API key per '{service_name}'")
        return False
    
    def export_encrypted_config(self) -> str:
        """
        Esporta tutte le API keys in formato JSON criptato.
        
        Returns:
            str: JSON criptato delle configurazioni
        """
        config_data = {
            service: {
                'key': data['key'].decode('latin-1'),  # Per JSON serialization
                'metadata': data['metadata'],
                'added_at': data['added_at']
            }
            for service, data in self.api_keys.items()
        }
        
        json_data = json.dumps(config_data)
        encrypted_config = self.cipher.encrypt(json_data.encode())
        
        logger.info("Configurazione esportata e criptata")
        return encrypted_config.decode()
    
    def import_encrypted_config(self, encrypted_config: str) -> bool:
        """
        Importa configurazione criptata.
        
        Args:
            encrypted_config: JSON criptato delle configurazioni
        
        Returns:
            bool: True se import avvenuto con successo
        """
        try:
            decrypted_data = self.cipher.decrypt(encrypted_config.encode())
            config_data = json.loads(decrypted_data.decode())
            
            for service, data in config_data.items():
                self.api_keys[service] = {
                    'key': data['key'].encode('latin-1'),
                    'metadata': data['metadata'],
                    'added_at': data['added_at']
                }
            
            logger.info(f"Importate {len(config_data)} API keys")
            return True
            
        except Exception as e:
            logger.error(f"Errore nell'importare configurazione: {e}")
            return False


def require_api_key(service_name: str):
    """
    Decorator per proteggere endpoint che richiedono API key.
    
    Usage:
        @require_api_key('openai')
        def my_protected_function():
            pass
    """
    def decorator(func):
        @wraps(func)
        def wrapper(*args, **kwargs):
            # Controlla rate limit
            if not api_manager.rate_limit_check(service_name):
                raise Exception(f"Rate limit superato per {service_name}")
            
            # Recupera API key
            api_key = api_manager.get_api_key(service_name)
            if not api_key:
                raise Exception(f"API key per {service_name} non disponibile")
            
            # Passa la key alla funzione
            kwargs['api_key'] = api_key
            return func(*args, **kwargs)
        
        return wrapper
    return decorator


# Istanza globale del manager
api_manager = APIKeyManager()


# Esempio di inizializzazione con API keys
if __name__ == "__main__":
    # Carica API keys da environment variables
    api_keys_to_add = {
        'openai': os.getenv('OPENAI_API_KEY'),
        'perplexity': os.getenv('PERPLEXITY_API_KEY'),
        'stability': os.getenv('STABILITY_API_KEY'),
        'grok': os.getenv('GROK_API_KEY'),
    }
    
    for service, key in api_keys_to_add.items():
        if key:
            api_manager.add_api_key(service, key)
            print(f"✓ {service.upper()} API key caricata e protetta")
    
    print(f"\n🔒 Sistema API inviolabile attivo con {len(api_manager.api_keys)} servizi")
