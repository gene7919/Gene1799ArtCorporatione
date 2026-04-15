#!/usr/bin/env python3
"""
SuiteV17 Resilience Wrapper
Wrapper che aggiunge resilienza a qualsiasi modulo esistente
"""
import functools
import time
from typing import Callable, Any, Optional, Dict
from typing import Callable, Any, Optional
from error_handler import ErrorBoundary, RetryPolicy, CircuitBreaker
from suitev17_logger import get_logger

logger = get_logger('resilience_wrapper')

def resilient_function(max_retries: int = 3, fallback_value: Any = None,
                      circuit_breaker: bool = True, log_errors: bool = True):
    """
    Decorator che rende qualsiasi funzione resilient.
    
    Args:
        max_retries: Numero massimo retry
        fallback_value: Valore di ritorno in caso di fallimento
        circuit_breaker: Abilita circuit breaker
        log_errors: Logga errori
    """
    def decorator(func: Callable) -> Callable:
        # Crea circuit breaker se richiesto
        breaker = CircuitBreaker() if circuit_breaker else None
        retry = RetryPolicy(max_retries=max_retries)
        
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            # Check circuit breaker
            if breaker and not breaker.can_execute():
                logger.warning(f'Circuit breaker OPEN for {func.__name__}')
                return fallback_value
                
            try:
                # Esegui con retry
                result = retry.execute(func, *args, **kwargs)
                
                # Registra successo
                if breaker:
                    breaker.record_success()
                    
                return result
                
            except Exception as e:
                # Registra fallimento
                if breaker:
                    breaker.record_failure()
                    
                if log_errors:
                    logger.error(f'Function {func.__name__} failed after {max_retries} retries: {e}')
                    
                return fallback_value
                
        return wrapper
    return decorator

class ResilientService:
    """Base class per servizi resilienti."""
    
    def __init__(self, name: str):
        self.name = name
        self.logger = get_logger(name)
        self.circuit_breaker = CircuitBreaker()
        self.running = False
        self.error_count = 0
        self.max_errors = 10
        
    def start(self):
        """Avvia servizio con error handling."""
        try:
            self.logger.info(f'Starting service {self.name}')
            self._do_start()
            self.running = True
            self.logger.info(f'Service {self.name} started successfully')
        except Exception as e:
            self.logger.error(f'Failed to start {self.name}: {e}')
            raise
            
    def _do_start(self):
        """Override this in subclass."""
        raise NotImplementedError()
        
    def stop(self):
        """Ferma servizio."""
        try:
            self.logger.info(f'Stopping service {self.name}')
            self._do_stop()
            self.running = False
            self.logger.info(f'Service {self.name} stopped')
        except Exception as e:
            self.logger.error(f'Error stopping {self.name}: {e}')
            
    def _do_stop(self):
        """Override this in subclass."""
        pass
        
    def execute_resilient(self, func: Callable, *args, **kwargs) -> Any:
        """Esegue funzione in modo resiliente."""
        if not self.circuit_breaker.can_execute():
            self.logger.warning(f'Circuit breaker open for {self.name}')
            return None
            
        try:
            result = func(*args, **kwargs)
            self.circuit_breaker.record_success()
            self.error_count = 0
            return result
        except Exception as e:
            self.circuit_breaker.record_failure()
            self.error_count += 1
            self.logger.error(f'Error in {self.name}: {e}')
            
            if self.error_count >= self.max_errors:
                self.logger.critical(f'{self.name} exceeded max errors, stopping')
                self.stop()
                
            return None

def safe_import(module_name: str, fallback_module: str = None):
    """Importa modulo in modo sicuro con fallback."""
    try:
        return __import__(module_name)
    except ImportError as e:
        logger.warning(f'Failed to import {module_name}: {e}')
        if fallback_module:
            try:
                return __import__(fallback_module)
            except ImportError:
                pass
        return None

def safe_api_call(func: Callable, timeout: float = 30.0,
                 max_retries: int = 3) -> Any:
    """Chiama API in modo sicuro con timeout e retry."""
    import concurrent.futures
    
    retry_policy = RetryPolicy(max_retries=max_retries)
    
    def call_with_timeout():
        with concurrent.futures.ThreadPoolExecutor() as executor:
            future = executor.submit(func)
            return future.result(timeout=timeout)
            
    try:
        return retry_policy.execute(call_with_timeout)
    except concurrent.futures.TimeoutError:
        logger.error(f'API call timed out after {timeout}s')
        return None
    except Exception as e:
        logger.error(f'API call failed: {e}')
        return None

def monitor_memory_usage(threshold_mb: float = 1000) -> bool:
    """Monitora uso memoria e ritorna True se sopra threshold."""
    try:
        import psutil
        process = psutil.Process()
        memory_mb = process.memory_info().rss / 1024 / 1024
        
        if memory_mb > threshold_mb:
            logger.warning(f'Memory usage high: {memory_mb:.1f}MB (threshold: {threshold_mb}MB)')
            return True
        return False
    except ImportError:
        return False

def emergency_gc():
    """Emergency garbage collection."""
    import gc
    collected = gc.collect()
    logger.info(f'Emergency GC: {collected} objects collected')

class ServiceRegistry:
    """Registro servizi con monitoring."""
    
    def __init__(self):
        self.services: Dict[str, ResilientService] = {}
        self.health_checks: Dict[str, Callable] = {}
        
    def register(self, service: ResilientService):
        """Registra servizio."""
        self.services[service.name] = service
        logger.info(f'Service registered: {service.name}')
        
    def register_health_check(self, name: str, check_func: Callable):
        """Registra health check."""
        self.health_checks[name] = check_func
        
    def check_all(self) -> Dict[str, bool]:
        """Check tutti i servizi."""
        results = {}
        for name, service in self.services.items():
            results[name] = service.running
        return results
        
    def stop_all(self):
        """Ferma tutti i servizi."""
        for name, service in self.services.items():
            try:
                service.stop()
            except Exception as e:
                logger.error(f'Error stopping {name}: {e}')

# Global registry
_service_registry = ServiceRegistry()

def get_service_registry() -> ServiceRegistry:
    return _service_registry

def main():
    """Test wrapper."""
    print('Resilience Wrapper Test')
    print('=' * 50)
    
    # Test decorator
    @resilient_function(max_retries=3, fallback_value='fallback')
    def unreliable_function():
        import random
        if random.random() < 0.7:
            raise Exception('Random failure')
        return 'success'
    
    print('Testing resilient function:')
    for i in range(10):
        result = unreliable_function()
        print(f'  Call {i+1}: {result}')

if __name__ == '__main__':
    main()
