#!/usr/bin/env python3
"""
SuiteV17 Workflow Engine - Business Process Automation
DAG-based workflows, conditional execution, parallel tasks
"""
import json
import asyncio
from typing import Dict, List, Optional, Callable, Any, Set
from dataclasses import dataclass
from datetime import datetime
from enum import Enum
import uuid
import graphlib

class TaskStatus(Enum):
    PENDING = 'pending'
    RUNNING = 'running'
    COMPLETED = 'completed'
    FAILED = 'failed'
    SKIPPED = 'skipped'

@dataclass
class WorkflowTask:
    id: str
    name: str
    action: Callable
    dependencies: Set[str]
    status: TaskStatus
    result: Any
    error: Optional[str]
    started_at: Optional[str]
    completed_at: Optional[str]
    retries: int
    max_retries: int
    condition: Optional[Callable]  # Function to determine if task should run

class WorkflowEngine:
    """Engine workflow SuiteV17."""
    
    def __init__(self):
        self.workflows: Dict[str, Dict[str, WorkflowTask]] = {}
        self.executions: Dict[str, Dict] = {}
        
    def create_workflow(self, workflow_id: str, tasks: List[Dict]):
        """Crea workflow da definizione."""
        workflow = {}
        
        for task_def in tasks:
            task = WorkflowTask(
                id=task_def['id'],
                name=task_def.get('name', task_def['id']),
                action=task_def['action'],
                dependencies=set(task_def.get('dependencies', [])),
                status=TaskStatus.PENDING,
                result=None,
                error=None,
                started_at=None,
                completed_at=None,
                retries=0,
                max_retries=task_def.get('max_retries', 3),
                condition=task_def.get('condition')
            )
            workflow[task.id] = task
            
        self.workflows[workflow_id] = workflow
        
    def execute_workflow(self, workflow_id: str, context: Dict = None) -> str:
        """Esegue workflow."""
        if workflow_id not in self.workflows:
            raise ValueError(f'Workflow {workflow_id} not found')
            
        execution_id = str(uuid.uuid4())
        workflow = self.workflows[workflow_id]
        
        self.executions[execution_id] = {
            'workflow_id': workflow_id,
            'started_at': datetime.now().isoformat(),
            'status': 'running',
            'context': context or {},
            'results': {}
        }
        
        # Topological sort per ordine esecuzione
        try:
            ts = graphlib.TopologicalSorter({
                task_id: task.dependencies
                for task_id, task in workflow.items()
            })
            execution_order = list(ts.static_order())
        except Exception as e:
            self.executions[execution_id]['status'] = 'failed'
            self.executions[execution_id]['error'] = str(e)
            return execution_id
            
        # Execute tasks
        for task_id in execution_order:
            task = workflow[task_id]
            
            # Check condition
            if task.condition and not task.condition(context):
                task.status = TaskStatus.SKIPPED
                continue
                
            # Check dependencies
            deps_satisfied = all(
                workflow[dep].status == TaskStatus.COMPLETED
                for dep in task.dependencies
            )
            
            if not deps_satisfied:
                task.status = TaskStatus.SKIPPED
                continue
                
            # Execute task
            self._execute_task(task, context)
            
            if task.status == TaskStatus.FAILED:
                self.executions[execution_id]['status'] = 'failed'
                break
                
        # Update execution status
        if self.executions[execution_id]['status'] == 'running':
            self.executions[execution_id]['status'] = 'completed'
            self.executions[execution_id]['completed_at'] = datetime.now().isoformat()
            
        return execution_id
        
    def _execute_task(self, task: WorkflowTask, context: Dict):
        """Esegue singolo task."""
        task.status = TaskStatus.RUNNING
        task.started_at = datetime.now().isoformat()
        
        try:
            # Pass context and previous results
            result = task.action(context)
            task.result = result
            task.status = TaskStatus.COMPLETED
            task.completed_at = datetime.now().isoformat()
            
            # Update context with result
            context[task.id] = result
            
        except Exception as e:
            task.error = str(e)
            task.retries += 1
            
            if task.retries < task.max_retries:
                # Retry
                task.status = TaskStatus.PENDING
            else:
                task.status = TaskStatus.FAILED
                
    def get_execution_status(self, execution_id: str) -> Optional[Dict]:
        """Stato esecuzione workflow."""
        return self.executions.get(execution_id)
        
    def list_workflows(self) -> List[str]:
        """Lista workflow."""
        return list(self.workflows.keys())
        
    def get_workflow_definition(self, workflow_id: str) -> Optional[Dict]:
        """Definizione workflow."""
        if workflow_id not in self.workflows:
            return None
            
        return {
            'id': workflow_id,
            'tasks': [
                {
                    'id': task.id,
                    'name': task.name,
                    'dependencies': list(task.dependencies),
                    'max_retries': task.max_retries
                }
                for task in self.workflows[workflow_id].values()
            ]
        }

class WorkflowBuilder:
    """Builder per workflow."""
    
    def __init__(self, workflow_id: str):
        self.workflow_id = workflow_id
        self.tasks = []
        
    def add_task(self, task_id: str, action: Callable,
                 dependencies: List[str] = None,
                 condition: Callable = None,
                 max_retries: int = 3):
        """Aggiunge task."""
        self.tasks.append({
            'id': task_id,
            'action': action,
            'dependencies': dependencies or [],
            'condition': condition,
            'max_retries': max_retries
        })
        return self
        
    def build(self, engine: WorkflowEngine):
        """Costruisce workflow."""
        engine.create_workflow(self.workflow_id, self.tasks)
        return self.workflow_id

def main():
    """Test workflow engine."""
    engine = WorkflowEngine()
    
    # Define actions
    def fetch_data(ctx):
        return {'data': [1, 2, 3, 4, 5]}
        
    def process_data(ctx):
        data = ctx.get('fetch_data', {}).get('data', [])
        return {'processed': [x * 2 for x in data]}
        
    def save_results(ctx):
        return {'saved': True}
        
    # Build workflow
    builder = WorkflowBuilder('data_pipeline')
    builder.add_task('fetch_data', fetch_data)\
           .add_task('process_data', process_data, ['fetch_data'])\
           .add_task('save_results', save_results, ['process_data'])\
           .build(engine)
           
    # Execute
    execution_id = engine.execute_workflow('data_pipeline')
    print(f'Execution: {execution_id}')
    print(f'Status: {engine.get_execution_status(execution_id)}')

if __name__ == '__main__':
    main()
