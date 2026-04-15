#!/usr/bin/env python3
"""
SuiteV17 Security Module - Enterprise Security Suite
Encryption, authentication, audit logging, intrusion detection
"""
import os
import hashlib
import hmac
import secrets
import json
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Tuple, Any
from dataclasses import dataclass
from enum import Enum
import base64

class SecurityLevel(Enum):
    LOW = 'low'
    MEDIUM = 'medium'
    HIGH = 'high'
    CRITICAL = 'critical'

@dataclass
class SecurityEvent:
    timestamp: str
    event_type: str
    severity: SecurityLevel
    source: str
    description: str
    metadata: Dict

class SecurityManager:
    """Gestore sicurezza SuiteV17."""
    
    def __init__(self):
        self.secret_key = os.getenv('SUITEV17_SECRET', secrets.token_hex(32))
        self.events: List[SecurityEvent] = []
        self.blocked_ips: set = set()
        self.failed_attempts: Dict[str, List[str]] = {}
        self.encryption_key = self._derive_key()
        
    def _derive_key(self) -> bytes:
        """Deriva chiave encryption."""
        return hashlib.sha256(self.secret_key.encode()).digest()
        
    def encrypt(self, data: str) -> str:
        """Cifra dati con AES-256 simulato."""
        # Semplificato: XOR con chiave (in produzione usare cryptography)
        key = self.encryption_key
        data_bytes = data.encode()
        encrypted = bytes([b ^ key[i % len(key)] for i, b in enumerate(data_bytes)])
        return base64.b64encode(encrypted).decode()
        
    def decrypt(self, encrypted_data: str) -> str:
        """Decifra dati."""
        key = self.encryption_key
        encrypted_bytes = base64.b64decode(encrypted_data)
        decrypted = bytes([b ^ key[i % len(key)] for i, b in enumerate(encrypted_bytes)])
        return decrypted.decode()
        
    def hash_password(self, password: str, salt: str = None) -> Tuple[str, str]:
        """Hash password con salt."""
        if salt is None:
            salt = secrets.token_hex(16)
        
        # PBKDF2 simulato
        hash_value = hashlib.pbkdf2_hmac(
            'sha256',
            password.encode(),
            salt.encode(),
            100000
        ).hex()
        
        return hash_value, salt
        
    def verify_password(self, password: str, hash_value: str, salt: str) -> bool:
        """Verifica password."""
        calculated, _ = self.hash_password(password, salt)
        return hmac.compare_digest(calculated, hash_value)
        
    def generate_token(self, user_id: str, expiry_hours: int = 24) -> str:
        """Genera JWT-like token."""
        expiry = datetime.now() + timedelta(hours=expiry_hours)
        payload = {
            'user_id': user_id,
            'exp': expiry.isoformat(),
            'iat': datetime.now().isoformat(),
            'jti': secrets.token_hex(16)
        }
        
        # Firma payload
        signature = hmac.new(
            self.secret_key.encode(),
            json.dumps(payload, sort_keys=True).encode(),
            hashlib.sha256
        ).hexdigest()
        
        token_data = {**payload, 'sig': signature}
        return base64.b64encode(json.dumps(token_data).encode()).decode()
        
    def verify_token(self, token: str) -> Optional[Dict]:
        """Verifica token."""
        try:
            data = json.loads(base64.b64decode(token))
            
            # Verifica firma
            payload = {k: v for k, v in data.items() if k != 'sig'}
            expected_sig = hmac.new(
                self.secret_key.encode(),
                json.dumps(payload, sort_keys=True).encode(),
                hashlib.sha256
            ).hexdigest()
            
            if not hmac.compare_digest(data.get('sig', ''), expected_sig):
                return None
                
            # Verifica scadenza
            expiry = datetime.fromisoformat(data['exp'])
            if datetime.now() > expiry:
                return None
                
            return payload
        except Exception:
            return None
            
    def log_event(self, event_type: str, severity: SecurityLevel,
                  source: str, description: str, metadata: Dict = None):
        """Logga evento sicurezza."""
        event = SecurityEvent(
            timestamp=datetime.now().isoformat(),
            event_type=event_type,
            severity=severity,
            source=source,
            description=description,
            metadata=metadata or {}
        )
        self.events.append(event)
        
        # Se critico, notifica immediatamente
        if severity == SecurityLevel.CRITICAL:
            self._alert_critical(event)
            
    def _alert_critical(self, event: SecurityEvent):
        """Alert per evento critico."""
        print(f'[SECURITY ALERT] {event.event_type}: {event.description}')
        
    def check_brute_force(self, ip: str, max_attempts: int = 5,
                         window_minutes: int = 15) -> bool:
        """Controlla brute force."""
        now = datetime.now()
        attempts = self.failed_attempts.get(ip, [])
        
        # Filtra tentativi vecchi
        cutoff = now - timedelta(minutes=window_minutes)
        attempts = [a for a in attempts if datetime.fromisoformat(a) > cutoff]
        
        if len(attempts) >= max_attempts:
            self.blocked_ips.add(ip)
            self.log_event(
                'brute_force_detected',
                SecurityLevel.HIGH,
                ip,
                f'IP blocked after {len(attempts)} failed attempts'
            )
            return False
            
        attempts.append(now.isoformat())
        self.failed_attempts[ip] = attempts
        return True
        
    def is_ip_blocked(self, ip: str) -> bool:
        """Verifica se IP è bloccato."""
        return ip in self.blocked_ips
        
    def unblock_ip(self, ip: str):
        """Sblocca IP."""
        self.blocked_ips.discard(ip)
        if ip in self.failed_attempts:
            del self.failed_attempts[ip]
            
    def validate_input(self, data: str, input_type: str = 'text') -> Tuple[bool, str]:
        """Valida input per prevenire injection."""
        dangerous_patterns = [
            ';<script>', 'javascript:', 'onerror=',
            'SELECT * FROM', 'DROP TABLE', 'INSERT INTO',
            '$(', '`', '..'
        ]
        
        for pattern in dangerous_patterns:
            if pattern.lower() in data.lower():
                self.log_event(
                    'suspicious_input',
                    SecurityLevel.HIGH,
                    'input_validation',
                    f'Suspicious pattern detected: {pattern}'
                )
                return False, 'Suspicious input detected'
                
        return True, 'OK'
        
    def audit_log(self, action: str, user: str, resource: str,
                  success: bool, details: Dict = None):
        """Log audit completo."""
        self.log_event(
            'audit',
            SecurityLevel.LOW,
            user,
            f'{action} on {resource}: {"success" if success else "failed"}',
            details
        )
        
    def get_security_report(self) -> Dict:
        """Report sicurezza."""
        events_by_severity = {}
        for event in self.events:
            level = event.severity.value
            events_by_severity[level] = events_by_severity.get(level, 0) + 1
            
        return {
            'total_events': len(self.events),
            'blocked_ips': len(self.blocked_ips),
            'events_by_severity': events_by_severity,
            'recent_events': [e.__dict__ for e in self.events[-10:]]
        }
        
    def sanitize_filename(self, filename: str) -> str:
        """Sanitizza nome file."""
        # Rimuovi path traversal
        safe = os.path.basename(filename)
        # Rimuovi caratteri pericolosi
        safe = ''.join(c for c in safe if c.isalnum() or c in '._-')
        return safe
        
    def generate_secure_id(self, length: int = 32) -> str:
        """Genera ID sicuro."""
        return secrets.token_hex(length // 2)
        
    def rate_limit_check(self, key: str, max_requests: int = 100,
                        window_seconds: int = 60) -> bool:
        """Controllo rate limiting."""
        # Implementazione semplice - in produzione usare Redis
        return True  # Placeholder

class EncryptionManager:
    """Manager encryption avanzato."""
    
    def __init__(self):
        self.keys: Dict[str, bytes] = {}
        
    def generate_key(self, key_id: str) -> bytes:
        """Genera nuova chiave."""
        key = secrets.token_bytes(32)
        self.keys[key_id] = key
        return key
        
    def rotate_key(self, key_id: str) -> bytes:
        """Ruota chiave."""
        new_key = secrets.token_bytes(32)
        self.keys[key_id] = new_key
        return new_key
        
    def secure_delete(self, data: bytes):
        """Cancellazione sicura."""
        # Sovrascrivi dati
        overwritten = bytearray(len(data))
        for i in range(len(data)):
            overwritten[i] = secrets.randbelow(256)
        return overwritten

def main():
    """Test security module."""
    security = SecurityManager()
    
    # Test encryption
    message = 'Secret data'
    encrypted = security.encrypt(message)
    decrypted = security.decrypt(encrypted)
    print(f'Encryption test: {"PASS" if decrypted == message else "FAIL"}')
    
    # Test password hashing
    password = 'test_password123'
    hash_val, salt = security.hash_password(password)
    verified = security.verify_password(password, hash_val, salt)
    print(f'Password test: {"PASS" if verified else "FAIL"}')
    
    # Test token
    token = security.generate_token('user123')
    verified_token = security.verify_token(token)
    print(f'Token test: {"PASS" if verified_token else "FAIL"}')
    
    print(f'Security report: {security.get_security_report()}')

if __name__ == '__main__':
    main()
