#!/usr/bin/env python3
"""
Gene1799 Crew - AI Agent Swarm Manager
Gestisce un team di agenti AI specializzati che collaborano su task complessi
"""
import os
import json
import asyncio
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, asdict
from datetime import datetime
from enum import Enum
import uuid

class AgentRole(Enum):
    ARCHITECT = 'architect'      # Progetta soluzioni
    DEVELOPER = 'developer'      # Scrive codice
    REVIEWER = 'reviewer'        # Revisiona codice
    TESTER = 'tester'          # Testa e verifica
    DEVOPS = 'devops'          # Gestisce deployment
    ANALYST = 'analyst'        # Analizza dati

class TaskStatus(Enum):
    PENDING = 'pending'
    ASSIGNED = 'assigned'
    IN_PROGRESS = 'in_progress'
    REVIEW = 'review'
    COMPLETED = 'completed'
    FAILED = 'failed'

@dataclass
class CrewAgent:
    id: str
    name: str
    role: AgentRole
    model: str  # e.g., 'ollama/llama3.1', 'openai/gpt-4'
    skills: List[str]
    status: str
    current_task: Optional[str]
    completed_tasks: int
    success_rate: float

@dataclass
class CrewTask:
    id: str
    title: str
    description: str
    role_required: AgentRole
    status: TaskStatus
    assigned_to: Optional[str]
    dependencies: List[str]
    priority: int  # 1-10
    created_at: str
    started_at: Optional[str]
    completed_at: Optional[str]
    result: Optional[Any]
    artifacts: List[str]  # File generati

class Gene1799Crew:
    """
    Gestore di team AI multi-agent per sviluppo software automatizzato.
    
    Esempio:
        crew = Gene1799Crew()
        crew.create_agent('CodeExpert', AgentRole.DEVELOPER, 'ollama/codellama')
        task = crew.create_task('Implementare API', 'Creare endpoint REST', AgentRole.DEVELOPER)
        crew.execute_task(task.id)
    """
    
    def __init__(self, ollama_url: str = None):
        self.agents: Dict[str, CrewAgent] = {}
        self.tasks: Dict[str, CrewTask] = {}
        self.ollama_url = ollama_url or os.getenv('OLLAMA_URL', 'http://localhost:11434/api/generate')
        self.history: List[Dict] = []
        
    def create_agent(self, name: str, role: AgentRole, model: str = 'ollama/llama3.1', 
                     skills: List[str] = None) -> str:
        """Crea un nuovo agente nel crew."""
        agent_id = f"agent_{uuid.uuid4().hex[:8]}"
        agent = CrewAgent(
            id=agent_id,
            name=name,
            role=role,
            model=model,
            skills=skills or [],
            status='idle',
            current_task=None,
            completed_tasks=0,
            success_rate=1.0
        )
        self.agents[agent_id] = agent
        self._log(f'Created agent {name} ({role.value}) with model {model}')
        return agent_id
        
    def create_task(self, title: str, description: str, role_required: AgentRole,
                    dependencies: List[str] = None, priority: int = 5) -> str:
        """Crea un nuovo task da assegnare."""
        task_id = f"task_{uuid.uuid4().hex[:8]}"
        task = CrewTask(
            id=task_id,
            title=title,
            description=description,
            role_required=role_required,
            status=TaskStatus.PENDING,
            assigned_to=None,
            dependencies=dependencies or [],
            priority=priority,
            created_at=datetime.now().isoformat(),
            started_at=None,
            completed_at=None,
            result=None,
            artifacts=[]
        )
        self.tasks[task_id] = task
        self._log(f'Created task: {title} (requires {role_required.value})')
        return task_id
        
    def assign_task(self, task_id: str, agent_id: str) -> bool:
        """Assegna un task a un agente."""
        if task_id not in self.tasks:
            return False
        if agent_id not in self.agents:
            return False
            
        task = self.tasks[task_id]
        agent = self.agents[agent_id]
        
        # Verifica che l'agente abbia il ruolo giusto
        if task.role_required != agent.role:
            self._log(f'Cannot assign: role mismatch {task.role_required.value} vs {agent.role.value}')
            return False
            
        task.assigned_to = agent_id
        task.status = TaskStatus.ASSIGNED
        agent.current_task = task_id
        agent.status = 'busy'
        
        self._log(f'Task {task.title} assigned to {agent.name}')
        return True
        
    async def execute_task(self, task_id: str) -> Dict:
        """Esegue un task usando l'agente assegnato."""
        if task_id not in self.tasks:
            return {'error': 'Task not found'}
            
        task = self.tasks[task_id]
        if not task.assigned_to:
            return {'error': 'No agent assigned'}
            
        agent = self.agents[task.assigned_to]
        task.status = TaskStatus.IN_PROGRESS
        task.started_at = datetime.now().isoformat()
        
        self._log(f'Executing task {task.title} with {agent.name}')
        
        # Simula esecuzione task (qui integreresti Ollama/OpenAI)
        try:
            result = await self._call_llm(agent.model, task.description)
            task.result = result
            task.status = TaskStatus.COMPLETED
            task.completed_at = datetime.now().isoformat()
            
            # Aggiorna statistiche agente
            agent.completed_tasks += 1
            agent.status = 'idle'
            agent.current_task = None
            
            self._log(f'Task {task.title} completed successfully')
            
            return {
                'task_id': task_id,
                'status': 'completed',
                'result': result,
                'agent': agent.name
            }
            
        except Exception as e:
            task.status = TaskStatus.FAILED
            agent.status = 'idle'
            agent.current_task = None
            agent.success_rate = agent.completed_tasks / (agent.completed_tasks + 1)
            
            self._log(f'Task {task.title} failed: {str(e)}')
            return {'error': str(e), 'task_id': task_id}
            
    async def _call_llm(self, model: str, prompt: str) -> str:
        """Chiama il modello LLM (Ollama o altro)."""
        # Placeholder - integrazione reale con Ollama
        if model.startswith('ollama/'):
            model_name = model.replace('ollama/', '')
            # Qui faresti la chiamata HTTP a Ollama
            return f"[Simulated response from {model_name}]\nGenerated content for: {prompt[:50]}..."
        return f"[Response from {model}]"
        
    def get_agent_for_role(self, role: AgentRole) -> Optional[str]:
        """Trova un agente disponibile per un ruolo."""
        for agent_id, agent in self.agents.items():
            if agent.role == role and agent.status == 'idle':
                return agent_id
        return None
        
    def auto_assign_tasks(self) -> int:
        """Assegna automaticamente task ad agenti disponibili."""
        assigned = 0
        for task_id, task in self.tasks.items():
            if task.status == TaskStatus.PENDING and not task.assigned_to:
                agent_id = self.get_agent_for_role(task.role_required)
                if agent_id:
                    self.assign_task(task_id, agent_id)
                    assigned += 1
        return assigned
        
    def get_crew_status(self) -> Dict:
        """Stato completo del crew."""
        return {
            'agents': len(self.agents),
            'tasks_total': len(self.tasks),
            'tasks_pending': sum(1 for t in self.tasks.values() if t.status == TaskStatus.PENDING),
            'tasks_in_progress': sum(1 for t in self.tasks.values() if t.status == TaskStatus.IN_PROGRESS),
            'tasks_completed': sum(1 for t in self.tasks.values() if t.status == TaskStatus.COMPLETED),
            'agents_idle': sum(1 for a in self.agents.values() if a.status == 'idle'),
            'agents_busy': sum(1 for a in self.agents.values() if a.status == 'busy')
        }
        
    def export_workflow(self, filename: str = None):
        """Esporta il workflow in JSON."""
        if filename is None:
            filename = f'crew_workflow_{datetime.now().strftime("%Y%m%d_%H%M%S")}.json'
            
        data = {
            'exported_at': datetime.now().isoformat(),
            'agents': [asdict(a) for a in self.agents.values()],
            'tasks': [asdict(t) for t in self.tasks.values()],
            'history': self.history
        }
        
        with open(filename, 'w', encoding='utf-8') as f:
            json.dump(data, f, indent=2, default=str)
            
        return filename
        
    def _log(self, message: str):
        """Log interno."""
        timestamp = datetime.now().isoformat()
        entry = f'[{timestamp}] {message}'
        self.history.append(entry)
        print(entry)

# Factory function per creare crew preconfigurato
def create_dev_crew() -> Gene1799Crew:
    """Crea un crew preconfigurato per sviluppo software."""
    crew = Gene1799Crew()
    
    # Crea agenti specializzati
    crew.create_agent('Archi', AgentRole.ARCHITECT, 'ollama/llama3.1', 
                    ['system-design', 'api-design', 'database'])
    crew.create_agent('Dev1', AgentRole.DEVELOPER, 'ollama/codellama', 
                    ['python', 'javascript', 'fastapi', 'react'])
    crew.create_agent('Dev2', AgentRole.DEVELOPER, 'ollama/codellama', 
                    ['python', 'blockchain', 'solana'])
    crew.create_agent('Review', AgentRole.REVIEWER, 'ollama/llama3.1', 
                    ['code-review', 'security', 'performance'])
    crew.create_agent('Test', AgentRole.TESTER, 'ollama/llama3.1', 
                    ['pytest', 'jest', 'integration-testing'])
    crew.create_agent('Ops', AgentRole.DEVOPS, 'ollama/llama3.1', 
                    ['docker', 'kubernetes', 'ci-cd', 'aws'])
    
    return crew

def main():
    """Demo del crew system."""
    print('=' * 70)
    print('GENE1799 CREW - AI Agent Swarm Manager')
    print('=' * 70)
    print()
    
    crew = create_dev_crew()
    
    print('Crew creato con:', crew.get_crew_status())
    print()
    print('Agenti disponibili:')
    for agent in crew.agents.values():
        print(f'  - {agent.name} ({agent.role.value}): {agent.skills}')
    print()
    
    # Crea task di esempio
    task1 = crew.create_task(
        'Design API REST',
        'Progettare API REST per gestione utenti con autenticazione JWT',
        AgentRole.ARCHITECT,
        priority=9
    )
    
    task2 = crew.create_task(
        'Implementare Database',
        'Creare schema SQLite e modelli SQLAlchemy',
        AgentRole.DEVELOPER,
        dependencies=[task1],
        priority=8
    )
    
    print('Task creati:', task1, task2)
    print()
    
    # Auto-assignment
    assigned = crew.auto_assign_tasks()
    print(f'Task assegnati automaticamente: {assigned}')
    print()
    
    # Stato finale
    print('Stato finale:', json.dumps(crew.get_crew_status(), indent=2))

if __name__ == '__main__':
    main()
