#!/usr/bin/env python3
"""
SuiteV17 Message Queue - Distributed Message System
RabbitMQ-style, Redis-compatible, async processing
"""
import asyncio
import json
import pickle
import time
from typing import Dict, List, Optional, Callable, Any, Set
from dataclasses import dataclass, asdict
from datetime import datetime
from collections import deque
import threading
import uuid

@dataclass
class Message:
    id: str
    queue: str
    payload: Any
    priority: int
    timestamp: str
    ttl: Optional[int]  # Time to live in seconds
    delivery_count: int = 0
    max_retries: int = 3

@dataclass
class Queue:
    name: str
    messages: deque
    consumers: Set[str]
    durable: bool
    max_length: Optional[int]
    created_at: str

class MessageQueue:
    """Message Queue SuiteV17."""
    
    def __init__(self, persistence_dir: str = None):
        self.queues: Dict[str, Queue] = {}
        self.consumers: Dict[str, Callable] = {}
        self.processed: Set[str] = set()
        self.running = False
        self.lock = threading.Lock()
        self.persistence_dir = persistence_dir or 'C:\\SuiteV17\\queue_data'
        
    def create_queue(self, name: str, durable: bool = True,
                     max_length: int = None) -> Queue:
        """Crea nuova coda."""
        with self.lock:
            if name not in self.queues:
                self.queues[name] = Queue(
                    name=name,
                    messages=deque(),
                    consumers=set(),
                    durable=durable,
                    max_length=max_length,
                    created_at=datetime.now().isoformat()
                )
            return self.queues[name]
            
    def delete_queue(self, name: str) -> bool:
        """Elimina coda."""
        with self.lock:
            if name in self.queues:
                del self.queues[name]
                return True
            return False
            
    def publish(self, queue_name: str, payload: Any,
                priority: int = 0, ttl: int = None) -> str:
        """Pubblica messaggio."""
        if queue_name not in self.queues:
            self.create_queue(queue_name)
            
        msg_id = str(uuid.uuid4())
        message = Message(
            id=msg_id,
            queue=queue_name,
            payload=payload,
            priority=priority,
            timestamp=datetime.now().isoformat(),
            ttl=ttl,
            delivery_count=0
        )
        
        with self.lock:
            queue = self.queues[queue_name]
            
            # Check max length
            if queue.max_length and len(queue.messages) >= queue.max_length:
                queue.messages.popleft()  # Remove oldest
                
            # Insert by priority
            inserted = False
            for i, existing in enumerate(queue.messages):
                if existing.priority < priority:
                    queue.messages.insert(i, message)
                    inserted = True
                    break
                    
            if not inserted:
                queue.messages.append(message)
                
        return msg_id
        
    def subscribe(self, queue_name: str, consumer_id: str,
                  callback: Callable):
        """Sottoscrive consumatore."""
        if queue_name not in self.queues:
            self.create_queue(queue_name)
            
        with self.lock:
            self.queues[queue_name].consumers.add(consumer_id)
            self.consumers[consumer_id] = callback
            
    def unsubscribe(self, queue_name: str, consumer_id: str):
        """Rimuove sottoscrizione."""
        with self.lock:
            if queue_name in self.queues:
                self.queues[queue_name].consumers.discard(consumer_id)
            if consumer_id in self.consumers:
                del self.consumers[consumer_id]
                
    def consume(self, queue_name: str, consumer_id: str,
                auto_ack: bool = True) -> Optional[Message]:
        """Consuma messaggio."""
        if queue_name not in self.queues:
            return None
            
        with self.lock:
            queue = self.queues[queue_name]
            
            if not queue.messages:
                return None
                
            # Find message not being processed by this consumer
            for i, msg in enumerate(queue.messages):
                if msg.id not in self.processed:
                    if not auto_ack:
                        msg.delivery_count += 1
                        if msg.delivery_count > msg.max_retries:
                            queue.messages.remove(msg)
                            continue
                    else:
                        queue.messages.remove(msg)
                        self.processed.add(msg.id)
                        
                    return msg
                    
        return None
        
    def acknowledge(self, msg_id: str):
        """Acknowledge messaggio."""
        self.processed.add(msg_id)
        
    def reject(self, msg_id: str, requeue: bool = True):
        """Rifiuta messaggio."""
        # In implementation reale, rimetti in coda
        pass
        
    def get_queue_stats(self, queue_name: str) -> Dict:
        """Statistiche coda."""
        if queue_name not in self.queues:
            return {}
            
        queue = self.queues[queue_name]
        return {
            'name': queue.name,
            'message_count': len(queue.messages),
            'consumer_count': len(queue.consumers),
            'durable': queue.durable,
            'created_at': queue.created_at
        }
        
    def list_queues(self) -> List[Dict]:
        """Lista code."""
        return [self.get_queue_stats(name) for name in self.queues.keys()]
        
    def purge_queue(self, queue_name: str) -> int:
        """Svuota coda."""
        if queue_name not in self.queues:
            return 0
            
        with self.lock:
            count = len(self.queues[queue_name].messages)
            self.queues[queue_name].messages.clear()
            return count
            
    def start_processing(self):
        """Avvia processing loop."""
        self.running = True
        threading.Thread(target=self._processing_loop, daemon=True).start()
        
    def _processing_loop(self):
        """Loop di processing."""
        while self.running:
            try:
                for queue_name, queue in self.queues.items():
                    if queue.messages and queue.consumers:
                        # Distribute to consumers
                        for consumer_id in list(queue.consumers):
                            msg = self.consume(queue_name, consumer_id, auto_ack=False)
                            if msg:
                                callback = self.consumers.get(consumer_id)
                                if callback:
                                    try:
                                        callback(msg.payload)
                                        self.acknowledge(msg.id)
                                    except Exception as e:
                                        print(f'Consumer error: {e}')
                                        if msg.delivery_count < msg.max_retries:
                                            # Requeue
                                            pass
                                                
            except Exception as e:
                print(f'Processing error: {e}')
                
            time.sleep(0.1)
            
    def stop(self):
        """Ferma processing."""
        self.running = False
        
    def create_topic_exchange(self, exchange_name: str):
        """Crea topic exchange (pub/sub pattern)."""
        # Implementation pub/sub
        pass
        
    def bind_queue(self, queue_name: str, exchange_name: str,
                   routing_key: str):
        """Binding coda ad exchange."""
        pass

class DistributedTaskQueue:
    """Task queue per distributed computing."""
    
    def __init__(self):
        self.pending = []
        self.running = {}
        self.completed = []
        self.failed = []
        
    def submit_task(self, task_id: str, func: Callable, args: tuple,
                   priority: int = 0) -> str:
        """Sottomette task."""
        task = {
            'id': task_id,
            'func': func,
            'args': args,
            'priority': priority,
            'submitted_at': datetime.now().isoformat(),
            'status': 'pending'
        }
        
        self.pending.append(task)
        self.pending.sort(key=lambda x: x['priority'], reverse=True)
        
        return task_id
        
    def get_task_status(self, task_id: str) -> Optional[str]:
        """Stato task."""
        for task in self.pending:
            if task['id'] == task_id:
                return 'pending'
        if task_id in self.running:
            return 'running'
        for task in self.completed:
            if task['id'] == task_id:
                return 'completed'
        for task in self.failed:
            if task['id'] == task_id:
                return 'failed'
        return None
        
    def process_next(self) -> bool:
        """Processa prossimo task."""
        if not self.pending:
            return False
            
        task = self.pending.pop(0)
        task['status'] = 'running'
        self.running[task['id']] = task
        
        try:
            result = task['func'](*task['args'])
            task['result'] = result
            task['completed_at'] = datetime.now().isoformat()
            task['status'] = 'completed'
            self.completed.append(task)
            del self.running[task['id']]
            return True
        except Exception as e:
            task['error'] = str(e)
            task['status'] = 'failed'
            self.failed.append(task)
            del self.running[task['id']]
            return False
            
    def get_stats(self) -> Dict:
        """Statistiche."""
        return {
            'pending': len(self.pending),
            'running': len(self.running),
            'completed': len(self.completed),
            'failed': len(self.failed)
        }

def main():
    """Test message queue."""
    mq = MessageQueue()
    
    # Test pub/sub
    def callback(payload):
        print(f'Received: {payload}')
        
    mq.create_queue('test_queue')
    mq.subscribe('test_queue', 'consumer1', callback)
    
    msg_id = mq.publish('test_queue', {'data': 'hello'}, priority=5)
    print(f'Published: {msg_id}')
    
    print(f'Queue stats: {mq.get_queue_stats("test_queue")}')

if __name__ == '__main__':
    main()
