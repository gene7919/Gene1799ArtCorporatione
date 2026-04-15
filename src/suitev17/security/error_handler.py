#!/usr/bin/env python3
"""
SuiteV17 Error Handler - Gestione errori centralizzata e resilient
Circuit breaker, retry logic, graceful degradation
"""
import functools
import time
import logging
import traceback
from typing import Callable, Any, Optional, Dict, List
from enum import Enum
from datetime import datetime, timedelta
import threading

logger = logging.getLogger(__name__)

class CircuitState(Enum):
    CLOSED = 'closed'      # Normale
    OPEN = 'open'         # Errore, non chiamare
    HALF_OPEN = 'half_open'  # Test recovery

class CircuitBreaker:
    """Circuit breaker per prevenire cascade failures."""
    
    def __init__(self, failure_threshold: int = 5, recovery_timeout: int = 60,
                 expected_exception: type = Exception):
        self.failure_threshold = failure_threshold
        self.recovery_timeout = recovery_timeout
        self.expected_exception = expected_exception
        
        self.failure_count = 0
        self.last_failure_time = None
        self.state = CircuitState.CLOSED
        self._lock = threading.Lock()
        
    def can_execute(self) -> bool:
        """Verifica se possiamo eseguire."""
        with self._lock:
            if self.state == CircuitState.OPEN:
                if self._should_attempt_reset():
                    self.state = CircuitState.HALF_OPEN
                    logger.info('Circuit breaker entering HALF_OPEN state')
                    return True
                return False
            return True
    
    def _should_attempt_reset(self) -> bool:
        """Verifica se possiamo tentare recovery."""
        if self.last_failure_time is None:
            return True
        return (datetime.now() - self.last_failure_time).seconds >= self.recovery_timeout
    
    def record_success(self):
        """Registra successo."""
        with self._lock:
            self.failure_count = 0
            self.state = CircuitState.CLOSED
            
    def record_failure(self):
        """Registra fallimento."""
        with self._lock:
            self.failure_count += 1
            self.last_failure_time = datetime.now()
            
            if self.failure_count >= self.failure_threshold:
                self.state = CircuitState.OPEN
                logger.error(f'Circuit breaker OPEN after {self.failure_count} failures')

class RetryPolicy:
    """Policy di retry con exponential backoff."""
    
    def __init__(self, max_retries: int = 3, base_delay: float = 1.0,
                 max_delay: float = 60.0, exponential: bool = True,
                 exceptions: tuple = (Exception,)):
        self.max_retries = max_retries
        self.base_delay = base_delay
        self.max_delay = max_delay
        self.exponential = exponential
        self.exceptions = exceptions
        
    def execute(self, func: Callable, *args, **kwargs) -> Any:
        """Esegue funzione con retry."""
        last_exception = None
        
        for attempt in range(self.max_retries + 1):
            try:
                return func(*args, **kwargs)
            except self.exceptions as e:
                last_exception = e
                if attempt == self.max_retries:
                    break
                    
                delay = self._calculate_delay(attempt)
                logger.warning(f'Attempt {attempt + 1} failed: {e}. Retrying in {delay}s...')
                time.sleep(delay)
                
        raise last_exception
    
    async def execute_async(self, func: Callable, *args, **kwargs) -> Any:
        """Esegue funzione async con retry."""
        import asyncio
        last_exception = None
        
        for attempt in range(self.max_retries + 1):
            try:
                return await func(*args, **kwargs)
            except self.exceptions as e:
                last_exception = e
                if attempt == self.max_retries:
                    break
                    
                delay = self._calculate_delay(attempt)
                logger.warning(f'Attempt {attempt + 1} failed: {e}. Retrying in {delay}s...')
                await asyncio.sleep(delay)
                
        raise last_exception
    
    def _calculate_delay(self, attempt: int) -> float:
        """Calcola delay con exponential backoff."""
        if self.exponential:
            delay = self.base_delay * (2 ** attempt)
        else:
            delay = self.base_delay
        return min(delay, self.max_delay)

class ErrorBoundary:
    """Boundary per isolare errori e garantire graceful degradation."""
    
    def __init__(self, fallback_value: Any = None, 
                 on_error: Callable = None,
                 log_level: int = logging.ERROR):
        self.fallback_value = fallback_value
        self.on_error = on_error
        self.log_level = log_level
        
    def __call__(self, func: Callable) -> Callable:
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            try:
                return func(*args, **kwargs)
            except Exception as e:
                logger.log(self.log_level, f'Error in {func.__name__}: {e}')
                logger.debug(traceback.format_exc())
                
                if self.on_error:
                    try:
                        self.on_error(e)
                    except:
                        pass
                        
                return self.fallback_value
        return wrapper

class ResilientClient:
    """Client HTTP resiliente con circuit breaker e retry."""
    
    def __init__(self, name: str = 'client'):
        self.name = name
        self.circuit_breaker = CircuitBreaker()
        self.retry_policy = RetryPolicy()
        self.logger = logging.getLogger(f'{__name__}.{name}')
        
    def call(self, func: Callable, *args, **kwargs) -> Any:
        """Chiama funzione con circuit breaker e retry."""
        if not self.circuit_breaker.can_execute():
            raise Exception(f'Circuit breaker OPEN for {self.name}')
            
        try:
            result = self.retry_policy.execute(func, *args, **kwargs)
            self.circuit_breaker.record_success()
            return result
        except Exception as e:
            self.circuit_breaker.record_failure()
            raise

def safe_execute(func: Callable, fallback: Any = None, 
                 log_errors: bool = True) -> Any:
    """Esegue funzione in modo sicuro con fallback."""
    try:
        return func()
    except Exception as e:
        if log_errors:
            logger.error(f'Error executing {func.__name__}: {e}')
        return fallback

class ErrorAggregator:
    """Aggrega errori per analisi e alerting."""
    
    def __init__(self, window_minutes: int = 60):
        self.errors: List[Dict] = []
        self.window_minutes = window_minutes
        self._lock = threading.Lock()
        
    def record_error(self, error: Exception, context: str = '', 
                     severity: str = 'error'):
        """Registra un errore."""
        with self._lock:
            self.errors.append({
                'timestamp': datetime.now().isoformat(),
                'type': type(error).__name__,
                'message': str(error),
                'context': context,
                'severity': severity,
                'traceback': traceback.format_exc()
            })
            
            # Cleanup old errors
            cutoff = datetime.now() - timedelta(minutes=self.window_minutes)
            self.errors = [e for e in self.errors 
                          if datetime.fromisoformat(e['timestamp']) > cutoff]
    
    def get_error_stats(self) -> Dict:
        """Statistiche errori."""
        with self._lock:
            by_type = {}
            by_severity = {}
            
            for error in self.errors:
                by_type[error['type']] = by_type.get(error['type'], 0) + 1
                by_severity[error['severity']] = by_severity.get(error['severity'], 0) + 1
                
            return {
                'total': len(self.errors),
                'by_type': by_type,
                'by_severity': by_severity,
                'window_minutes': self.window_minutes
            }

# Global error aggregator
error_aggregator = ErrorAggregator()

def with_retry(max_retries: int = 3, delay: float = 1.0):
    """Decorator per retry automatico."""
    def decorator(func: Callable) -> Callable:
        policy = RetryPolicy(max_retries=max_retries, base_delay=delay)
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            return policy.execute(func, *args, **kwargs)
        return wrapper
    return decorator

def with_circuit_breaker(threshold: int = 5, timeout: int = 60):
    """Decorator per circuit breaker."""
    def decorator(func: Callable) -> Callable:
        breaker = CircuitBreaker(failure_threshold=threshold, 
                                recovery_timeout=timeout)
        @functools.wraps(func)
        def wrapper(*args, **kwargs):
            if not breaker.can_execute():
                raise Exception(f'Circuit breaker OPEN for {func.__name__}')
            try:
                result = func(*args, **kwargs)
                breaker.record_success()
                return result
            except Exception as e:
                breaker.record_failure()
                raise
        return wrapper
    return decorator

def main():
    """Test del sistema error handling."""
    print('Error Handler System Test')
    print('=' * 50)
    
    # Test circuit breaker
    breaker = CircuitBreaker(failure_threshold=3, recovery_timeout=5)
    
    @with_circuit_breaker(threshold=3)
    def flaky_function():
        import random
        if random.random() < 0.7:
            raise Exception('Random failure')
        return 'Success'
    
    print('Circuit breaker test:')
    for i in range(10):
        try:
            result = flaky_function()
            print(f'  Call {i+1}: {result}')
        except Exception as e:
            print(f'  Call {i+1}: Failed - {e}')
    
    print('\\nRetry policy test:')
    @with_retry(max_retries=3, delay=0.5)
    def always_fails():
        raise Exception('Always fails')
    
    try:
        always_fails()
    except:
        print('  Retry exhausted as expected')

if __name__ == '__main__':
    main()
