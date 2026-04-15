#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
SuiteV17 Workflow Orchestrator v1.0
Orchestratore aggiuntivo specializzato per:
- Workflow automation & task scheduling
- Event-driven architecture
- Plugin management & hooks
- Social automation integration
- Advanced notification system

Porta: 9002 (complementare al Orchestrator principale su 9001)
"""
import os
import sys
import json
import time
import asyncio
import threading
import schedule
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, asdict
from enum import Enum

from flask import Flask, jsonify, request
from flask_cors import CORS

sys.path.insert(0, r'C:\SuiteV17')

app = Flask(__name__)
CORS(app)

# ============================================================
# WORKFLOW CONFIGURATION
# ============================================================

class WorkflowType(Enum):
    TASK_QUEUE = 'task_queue'
    SOCIAL_POST = 'social_post'
    PLUGIN_EXEC = 'plugin_exec'
    NOTIFICATION = 'notification'
    AI_GENERATION = 'ai_generation'

class WorkflowState(Enum):
    PENDING = 'pending'
    RUNNING = 'running'
    COMPLETED = 'completed'
    FAILED = 'failed'
    CANCELLED = 'cancelled'

@dataclass
class WorkflowStep:
    step_id: str
    name: str
    type: WorkflowType
    config: Dict
    depends_on: List[str] = None
    timeout_seconds: int = 300
    retry_count: int = 0
    max_retries: int = 3
    
    def __post_init__(self):
        if self.depends_on is None:
            self.depends_on = []

@dataclass
class Workflow:
    workflow_id: str
    name: str
    steps: List[WorkflowStep]
    state: WorkflowState = WorkflowState.PENDING
    created_at: str = None
    started_at: Optional[str] = None
    completed_at: Optional[str] = None
    results: Dict = None
    error: Optional[str] = None
    
    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now().isoformat()
        if self.results is None:
            self.results = {}

# ============================================================
# WORKFLOW ORCHESTRATOR CLASS
# ============================================================

class WorkflowOrchestrator:
    """Orchestratore workflow avanzato con event-driven architecture."""
    
    def __init__(self):
        self.workflows: Dict[str, Workflow] = {}
        self.scheduled_jobs: Dict[str, schedule.Job] = {}
        self.event_handlers: Dict[str, List[Callable]] = {}
        self.task_queue = None
        self.plugin_manager = None
        self.notification_service = None
        self.social_automation = None
        self._running = False
        self._scheduler_thread = None
        self._metrics = {
            'workflows_created': 0,
            'workflows_completed': 0,
            'workflows_failed': 0,
            'tasks_executed': 0,
            'events_emitted': 0
        }
        self._init_components()
        self._start_scheduler()
        
    def _init_components(self):
        """Inizializza componenti integrati."""
        # Task Queue
        try:
            from task_queue import TaskQueue, TaskWorker
            self.task_queue = TaskQueue()
            print('[Workflow] Task Queue inizializzata')
        except Exception as e:
            print(f'[Workflow] Task Queue non disponibile: {e}')
            
        # Plugin Manager
        try:
            from plugin_system import PluginManager, HookRegistry
            self.plugin_manager = PluginManager()
            self.hook_registry = HookRegistry()
            print('[Workflow] Plugin Manager inizializzato')
        except Exception as e:
            print(f'[Workflow] Plugin Manager non disponibile: {e}')
            
        # Notification Service
        try:
            from notification_service import NotificationService
            self.notification_service = NotificationService()
            print('[Workflow] Notification Service inizializzato')
        except Exception as e:
            print(f'[Workflow] Notification Service non disponibile: {e}')
            
        # Social Automation
        try:
            from social_automation import SocialAutomation
            self.social_automation = SocialAutomation()
            print('[Workflow] Social Automation inizializzata')
        except Exception as e:
            print(f'[Workflow] Social Automation non disponibile: {e}')
            
    def _start_scheduler(self):
        """Avvia scheduler in background."""
        self._running = True
        self._scheduler_thread = threading.Thread(target=self._scheduler_loop, daemon=True)
        self._scheduler_thread.start()
        
    def _scheduler_loop(self):
        """Loop scheduler per job periodici."""
        while self._running:
            schedule.run_pending()
            time.sleep(1)
            
    def create_workflow(self, name: str, steps: List[Dict]) -> Workflow:
        """Crea nuovo workflow."""
        workflow_id = f'wf_{int(time.time())}_{len(self.workflows)}'
        steps_obj = [WorkflowStep(**s) for s in steps]
        workflow = Workflow(
            workflow_id=workflow_id,
            name=name,
            steps=steps_obj
        )
        self.workflows[workflow_id] = workflow
        self._metrics['workflows_created'] += 1
        return workflow
        
    async def execute_workflow(self, workflow_id: str) -> Dict:
        """Esegue workflow."""
        if workflow_id not in self.workflows:
            return {'error': 'Workflow non trovato'}
            
        workflow = self.workflows[workflow_id]
        workflow.state = WorkflowState.RUNNING
        workflow.started_at = datetime.now().isoformat()
        
        self.emit_event('workflow.started', {'workflow_id': workflow_id, 'name': workflow.name})
        
        try:
            for step in workflow.steps:
                step_result = await self._execute_step(step, workflow)
                workflow.results[step.step_id] = step_result
                
                if not step_result.get('success', False):
                    if step.retry_count < step.max_retries:
                        step.retry_count += 1
                        # Retry logic here
                    else:
                        raise Exception(f'Step {step.name} failed: {step_result.get("error")}')
                        
            workflow.state = WorkflowState.COMPLETED
            workflow.completed_at = datetime.now().isoformat()
            self._metrics['workflows_completed'] += 1
            self.emit_event('workflow.completed', {'workflow_id': workflow_id})
            
            return {'success': True, 'workflow_id': workflow_id, 'results': workflow.results}
            
        except Exception as e:
            workflow.state = WorkflowState.FAILED
            workflow.error = str(e)
            workflow.completed_at = datetime.now().isoformat()
            self._metrics['workflows_failed'] += 1
            self.emit_event('workflow.failed', {'workflow_id': workflow_id, 'error': str(e)})
            return {'success': False, 'error': str(e)}
            
    async def _execute_step(self, step: WorkflowStep, workflow: Workflow) -> Dict:
        """Esegue singolo step."""
        self._metrics['tasks_executed'] += 1
        
        if step.type == WorkflowType.TASK_QUEUE:
            return await self._execute_task_queue(step)
        elif step.type == WorkflowType.SOCIAL_POST:
            return await self._execute_social_post(step)
        elif step.type == WorkflowType.PLUGIN_EXEC:
            return await self._execute_plugin(step)
        elif step.type == WorkflowType.NOTIFICATION:
            return await self._execute_notification(step)
        elif step.type == WorkflowType.AI_GENERATION:
            return await self._execute_ai_generation(step)
        else:
            return {'success': False, 'error': f'Tipo step sconosciuto: {step.type}'}
            
    async def _execute_task_queue(self, step: WorkflowStep) -> Dict:
        """Esegue step su task queue."""
        if not self.task_queue:
            return {'success': False, 'error': 'Task Queue non disponibile'}
        config = step.config
        task_id = self.task_queue.enqueue(
            name=config.get('task_name', 'unnamed'),
            payload=config.get('payload', {}),
            priority=config.get('priority', 'normal')
        )
        return {'success': True, 'task_id': task_id}
        
    async def _execute_social_post(self, step: WorkflowStep) -> Dict:
        """Esegue step su social automation."""
        if not self.social_automation:
            return {'success': False, 'error': 'Social Automation non disponibile'}
        config = step.config
        try:
            content = self.social_automation.generate_post(
                topic=config.get('topic', ''),
                platform=config.get('platform', 'twitter'),
                tone=config.get('tone', 'professional')
            )
            # Qui si invierebbe il post vero
            return {'success': True, 'content': content}
        except Exception as e:
            return {'success': False, 'error': str(e)}
            
    async def _execute_plugin(self, step: WorkflowStep) -> Dict:
        """Esegue step su plugin."""
        if not self.plugin_manager:
            return {'success': False, 'error': 'Plugin Manager non disponibile'}
        config = step.config
        try:
            result = self.hook_registry.emit(
                config.get('hook', 'default'),
                *config.get('args', [])
            )
            return {'success': True, 'result': result}
        except Exception as e:
            return {'success': False, 'error': str(e)}
            
    async def _execute_notification(self, step: WorkflowStep) -> Dict:
        """Esegue step di notifica."""
        if not self.notification_service:
            return {'success': False, 'error': 'Notification Service non disponibile'}
        config = step.config
        try:
            asyncio.create_task(self.notification_service.notify(
                title=config.get('title', ''),
                message=config.get('message', ''),
                priority=config.get('priority', 'normal'),
                channels=config.get('channels', ['webhook'])
            ))
            return {'success': True}
        except Exception as e:
            return {'success': False, 'error': str(e)}
            
    async def _execute_ai_generation(self, step: WorkflowStep) -> Dict:
        """Esegue step di generazione AI."""
        config = step.config
        try:
            # Chiama AI Server su porta 8099
            import requests
            resp = requests.post(
                'http://localhost:8099/api/generate/text',
                json={'prompt': config.get('prompt', ''), 'system': config.get('system')},
                timeout=60
            )
            if resp.status_code == 200:
                return {'success': True, 'content': resp.json().get('result')}
            return {'success': False, 'error': f'HTTP {resp.status_code}'}
        except Exception as e:
            return {'success': False, 'error': str(e)}
            
    def schedule_workflow(self, workflow_id: str, cron: str) -> bool:
        """Schedule workflow con cron expression."""
        try:
            # Semplificazione: schedule ogni X minuti
            if 'min' in cron:
                minutes = int(cron.replace('min', ''))
                job = schedule.every(minutes).minutes.do(
                    lambda: asyncio.create_task(self.execute_workflow(workflow_id))
                )
                self.scheduled_jobs[workflow_id] = job
                return True
        except Exception as e:
            print(f'[Workflow] Errore scheduling: {e}')
            return False
            
    def on_event(self, event: str, handler: Callable):
        """Registra handler per evento."""
        if event not in self.event_handlers:
            self.event_handlers[event] = []
        self.event_handlers[event].append(handler)
        
    def emit_event(self, event: str, data: Dict):
        """Emette evento a tutti i handler."""
        self._metrics['events_emitted'] += 1
        if event in self.event_handlers:
            for handler in self.event_handlers[event]:
                try:
                    handler(data)
                except Exception as e:
                    print(f'[Workflow] Errore handler: {e}')
                    
    def get_status(self) -> Dict:
        """Stato orchestratore."""
        return {
            'workflows': {
                'total': len(self.workflows),
                'pending': len([w for w in self.workflows.values() if w.state == WorkflowState.PENDING]),
                'running': len([w for w in self.workflows.values() if w.state == WorkflowState.RUNNING]),
                'completed': len([w for w in self.workflows.values() if w.state == WorkflowState.COMPLETED]),
                'failed': len([w for w in self.workflows.values() if w.state == WorkflowState.FAILED])
            },
            'scheduled_jobs': len(self.scheduled_jobs),
            'components': {
                'task_queue': self.task_queue is not None,
                'plugin_manager': self.plugin_manager is not None,
                'notification_service': self.notification_service is not None,
                'social_automation': self.social_automation is not None
            },
            'metrics': self._metrics
        }
        
    def get_workflow(self, workflow_id: str) -> Optional[Dict]:
        """Ottiene dettaglio workflow."""
        if workflow_id in self.workflows:
            w = self.workflows[workflow_id]
            return {
                'workflow_id': w.workflow_id,
                'name': w.name,
                'state': w.state.value,
                'steps': len(w.steps),
                'created_at': w.created_at,
                'started_at': w.started_at,
                'completed_at': w.completed_at,
                'results': w.results,
                'error': w.error
            }
        return None

# Istanza globale
workflow_orch = WorkflowOrchestrator()

# ============================================================
# API ROUTES
# ============================================================

@app.route('/api/status')
def api_status():
    return jsonify({
        'orchestrator': 'Workflow Orchestrator v1.0',
        'port': 9002,
        'timestamp': datetime.now().isoformat(),
        'status': workflow_orch.get_status()
    })

@app.route('/api/workflows', methods=['GET'])
def list_workflows():
    workflows = [workflow_orch.get_workflow(wid) for wid in workflow_orch.workflows.keys()]
    return jsonify({'workflows': workflows})

@app.route('/api/workflows', methods=['POST'])
def create_workflow():
    data = request.json or {}
    name = data.get('name', 'Unnamed Workflow')
    steps = data.get('steps', [])
    
    if not steps:
        return jsonify({'error': 'Steps richiesti'}), 400
        
    workflow = workflow_orch.create_workflow(name, steps)
    return jsonify({
        'success': True,
        'workflow_id': workflow.workflow_id,
        'name': workflow.name,
        'state': workflow.state.value
    })

@app.route('/api/workflows/<workflow_id>', methods=['GET'])
def get_workflow(workflow_id):
    wf = workflow_orch.get_workflow(workflow_id)
    if wf:
        return jsonify(wf)
    return jsonify({'error': 'Workflow non trovato'}), 404

@app.route('/api/workflows/<workflow_id>/execute', methods=['POST'])
def execute_workflow(workflow_id):
    loop = asyncio.new_event_loop()
    asyncio.set_event_loop(loop)
    result = loop.run_until_complete(workflow_orch.execute_workflow(workflow_id))
    loop.close()
    return jsonify(result)

@app.route('/api/workflows/<workflow_id>/schedule', methods=['POST'])
def schedule_workflow(workflow_id):
    data = request.json or {}
    cron = data.get('cron', '5min')  # formato semplificato
    success = workflow_orch.schedule_workflow(workflow_id, cron)
    return jsonify({'success': success, 'workflow_id': workflow_id, 'schedule': cron})

@app.route('/api/workflows/<workflow_id>/cancel', methods=['POST'])
def cancel_workflow(workflow_id):
    if workflow_id in workflow_orch.workflows:
        wf = workflow_orch.workflows[workflow_id]
        wf.state = WorkflowState.CANCELLED
        return jsonify({'success': True})
    return jsonify({'error': 'Workflow non trovato'}), 404

@app.route('/api/components/status')
def components_status():
    return jsonify(workflow_orch.get_status()['components'])

@app.route('/api/metrics')
def metrics():
    return jsonify(workflow_orch._metrics)

@app.route('/api/events', methods=['POST'])
def emit_event():
    data = request.json or {}
    event = data.get('event')
    payload = data.get('payload', {})
    if event:
        workflow_orch.emit_event(event, payload)
        return jsonify({'success': True})
    return jsonify({'error': 'Event name required'}), 400

if __name__ == '__main__':
    print('='*70)
    print('  SuiteV17 Workflow Orchestrator v1.0')
    print('  Porta: 9002')
    print('  API: http://localhost:9002/api')
    print('='*70)
    try:
        app.run(host='0.0.0.0', port=9002, debug=False, threaded=True)
    except KeyboardInterrupt:
        print('\n[INFO] Arresto Workflow Orchestrator...')
        workflow_orch._running = False
        print('[OK] Workflow Orchestrator arrestato.')
