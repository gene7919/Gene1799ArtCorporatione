#!/usr/bin/env python3
"""
SuiteV17 Synaptic Agent Training System v3.0
Sistema di auto-addestramento e evoluzione agenti AI
"""
import os
import json
import time
import asyncio
import threading
from typing import Dict, List, Optional, Any, Callable
from dataclasses import dataclass, asdict
from datetime import datetime, timedelta
from collections import deque
import random
import numpy as np

@dataclass
class SynapticNode:
    """Nodo sinaptico rappresentante una capacità dell'agente"""
    id: str
    capability: str
    weight: float = 1.0
    activation_threshold: float = 0.5
    last_activated: Optional[datetime] = None
    success_count: int = 0
    failure_count: int = 0
    connections: List[str] = None
    
    def __post_init__(self):
        if self.connections is None:
            self.connections = []
            
    def activate(self, input_strength: float = 1.0) -> float:
        """Attiva il nodo sinaptico"""
        if input_strength >= self.activation_threshold:
            self.last_activated = datetime.now()
            return self.weight * input_strength
        return 0.0
        
    def strengthen(self, amount: float = 0.1):
        """Rafforza la connessione sinaptica"""
        self.weight = min(2.0, self.weight + amount)
        self.success_count += 1
        
    def weaken(self, amount: float = 0.05):
        """Indebolisce la connessione"""
        self.weight = max(0.1, self.weight - amount)
        self.failure_count += 1
        
    def get_efficiency(self) -> float:
        """Calcola efficienza del nodo"""
        total = self.success_count + self.failure_count
        if total == 0:
            return 0.5
        return self.success_count / total

@dataclass
class TrainingPattern:
    """Pattern di apprendimento"""
    id: str
    input_pattern: str
    output_pattern: str
    context: Dict[str, Any]
    success_rate: float = 0.0
    usage_count: int = 0
    created_at: datetime = None
    last_used: Optional[datetime] = None
    
    def __post_init__(self):
        if self.created_at is None:
            self.created_at = datetime.now()

class SynapticAgent:
    """Agente con capacità di auto-apprendimento sinaptico"""
    
    def __init__(self, agent_id: str, name: str, specialization: str = "general"):
        self.agent_id = agent_id
        self.name = name
        self.specialization = specialization
        self.nodes: Dict[str, SynapticNode] = {}
        self.patterns: Dict[str, TrainingPattern] = {}
        self.memory = deque(maxlen=1000)
        self.training_data = []
        self.performance_history = []
        self.evolution_level = 1
        self.created_at = datetime.now()
        self.last_training = None
        self.learning_rate = 0.1
        self.exploration_rate = 0.2
        
        # Inizializza nodi base
        self._init_base_nodes()
        
    def _init_base_nodes(self):
        """Inizializza nodi sinaptici base"""
        base_capabilities = [
            "text_generation", "code_generation", "analysis",
            "pattern_recognition", "decision_making", "memory_recall",
            "context_understanding", "error_correction", "optimization"
        ]
        
        for cap in base_capabilities:
            node_id = f"{self.agent_id}_{cap}"
            self.nodes[cap] = SynapticNode(
                id=node_id,
                capability=cap,
                weight=1.0,
                connections=random.sample(base_capabilities, min(3, len(base_capabilities)))
            )
            
    async def process(self, task: str, context: Dict = None) -> Dict[str, Any]:
        """Elabora un task con apprendimento sinaptico"""
        context = context or {}
        start_time = time.time()
        
        # Attiva nodi rilevanti
        activated_nodes = self._activate_relevant_nodes(task)
        
        # Cerca pattern esistenti
        matched_pattern = self._find_matching_pattern(task)
        
        if matched_pattern and random.random() > self.exploration_rate:
            # Usa pattern conosciuto
            result = await self._apply_pattern(matched_pattern, task, context)
        else:
            # Esplora nuova soluzione
            result = await self._explore_solution(task, context)
            
        processing_time = time.time() - start_time
        
        # Apprendimento sinaptico
        self._synaptic_learning(task, result, activated_nodes)
        
        # Salva in memoria
        self.memory.append({
            "task": task,
            "result": result,
            "nodes": [n.capability for n in activated_nodes],
            "timestamp": datetime.now().isoformat(),
            "processing_time": processing_time
        })
        
        return {
            "agent_id": self.agent_id,
            "result": result,
            "activated_capabilities": [n.capability for n in activated_nodes],
            "processing_time": processing_time,
            "evolution_level": self.evolution_level
        }
        
    def _activate_relevant_nodes(self, task: str) -> List[SynapticNode]:
        """Attiva nodi rilevanti per il task"""
        activated = []
        
        # Simple keyword matching per attivazione
        keywords = {
            "text_generation": ["write", "generate", "create", "compose"],
            "code_generation": ["code", "program", "function", "script", "implement"],
            "analysis": ["analyze", "study", "examine", "evaluate", "assess"],
            "pattern_recognition": ["pattern", "recognize", "identify", "detect"],
            "decision_making": ["decide", "choose", "select", "determine"],
            "optimization": ["optimize", "improve", "enhance", "better", "faster"]
        }
        
        task_lower = task.lower()
        for node in self.nodes.values():
            if node.capability in keywords:
                for keyword in keywords[node.capability]:
                    if keyword in task_lower:
                        activation = node.activate(0.8)
                        if activation > 0:
                            activated.append(node)
                        break
                        
        return activated
        
    def _find_matching_pattern(self, task: str) -> Optional[TrainingPattern]:
        """Trova pattern di training simile"""
        if not self.patterns:
            return None
            
        # Simple matching basato su similarità
        task_words = set(task.lower().split())
        best_match = None
        best_score = 0
        
        for pattern in self.patterns.values():
            pattern_words = set(pattern.input_pattern.lower().split())
            intersection = task_words.intersection(pattern_words)
            score = len(intersection) / max(len(task_words), len(pattern_words))
            
            if score > 0.6 and score > best_score:
                best_score = score
                best_match = pattern
                
        return best_match
        
    async def _apply_pattern(self, pattern: TrainingPattern, task: str, 
                            context: Dict) -> str:
        """Applica un pattern conosciuto"""
        pattern.usage_count += 1
        pattern.last_used = datetime.now()
        
        # Adatta output pattern al task specifico
        return pattern.output_pattern.replace("{task}", task)
        
    async def _explore_solution(self, task: str, context: Dict) -> str:
        """Esplora nuova soluzione"""
        # Simula esplorazione - in produzione userebbe AI Cloud
        await asyncio.sleep(0.1)
        return f"[Explored solution for: {task[:50]}...]"
        
    def _synaptic_learning(self, task: str, result: str, 
                          activated_nodes: List[SynapticNode]):
        """Apprendimento sinaptico basato su risultato"""
        
        # Valuta successo (semplificato)
        success = len(result) > 20 and "error" not in result.lower()
        
        # Aggiorna nodi attivati
        for node in activated_nodes:
            if success:
                node.strengthen(self.learning_rate)
            else:
                node.weaken(self.learning_rate * 0.5)
                
        # Crea nuovo pattern se successo
        if success and random.random() < 0.3:
            pattern_id = f"pattern_{len(self.patterns)}_{int(time.time())}"
            self.patterns[pattern_id] = TrainingPattern(
                id=pattern_id,
                input_pattern=task,
                output_pattern=result
            )
            
        # Evoluzione agente
        self._check_evolution()
        
    def _check_evolution(self):
        """Controlla se l'agente può evolvere"""
        total_efficiency = sum(n.get_efficiency() for n in self.nodes.values())
        avg_efficiency = total_efficiency / len(self.nodes)
        
        if avg_efficiency > 0.8 and len(self.patterns) > 10:
            self.evolution_level += 1
            self.learning_rate *= 0.95  # Apprendimento più fine
            self.exploration_rate *= 0.9  # Meno esplorazione
            
            # Aggiungi nuova capacità
            new_cap = f"advanced_cap_{self.evolution_level}"
            self.nodes[new_cap] = SynapticNode(
                id=f"{self.agent_id}_{new_cap}",
                capability=new_cap,
                weight=1.0
            )
            
    def get_stats(self) -> Dict:
        """Statistiche agente"""
        return {
            "agent_id": self.agent_id,
            "name": self.name,
            "evolution_level": self.evolution_level,
            "nodes_count": len(self.nodes),
            "patterns_count": len(self.patterns),
            "memory_size": len(self.memory),
            "avg_efficiency": sum(n.get_efficiency() for n in self.nodes.values()) / len(self.nodes),
            "learning_rate": self.learning_rate,
            "exploration_rate": self.exploration_rate,
            "created_at": self.created_at.isoformat(),
            "last_training": self.last_training.isoformat() if self.last_training else None
        }
        
    def export_knowledge(self) -> Dict:
        """Esporta conoscenza acquisita"""
        return {
            "agent_info": {
                "id": self.agent_id,
                "name": self.name,
                "specialization": self.specialization,
                "evolution_level": self.evolution_level
            },
            "nodes": {k: asdict(v) for k, v in self.nodes.items()},
            "patterns": {k: asdict(v) for k, v in self.patterns.items()},
            "exported_at": datetime.now().isoformat()
        }
        
    def import_knowledge(self, knowledge: Dict):
        """Importa conoscenza da altro agente"""
        # Importa patterns
        for pattern_data in knowledge.get("patterns", {}).values():
            pattern_id = f"imported_{pattern_data['id']}"
            self.patterns[pattern_id] = TrainingPattern(
                id=pattern_id,
                input_pattern=pattern_data["input_pattern"],
                output_pattern=pattern_data["output_pattern"],
                context=pattern_data.get("context", {})
            )

class SynapticAgentSwarm:
    """Sciame di agenti sinaptici collaboranti"""
    
    def __init__(self):
        self.agents: Dict[str, SynapticAgent] = {}
        self.shared_memory = deque(maxlen=5000)
        self.collaboration_graph = {}
        
    def create_agent(self, name: str, specialization: str = "general") -> SynapticAgent:
        """Crea nuovo agente"""
        agent_id = f"agent_{len(self.agents)}_{int(time.time())}"
        agent = SynapticAgent(agent_id, name, specialization)
        self.agents[agent_id] = agent
        return agent
        
    async def collaborative_task(self, task: str, 
                               agent_ids: Optional[List[str]] = None) -> Dict:
        """Esegue task collaborativo tra agenti"""
        
        if agent_ids is None:
            # Seleziona agenti più adatti
            agent_ids = self._select_best_agents(task, min(3, len(self.agents)))
            
        if not agent_ids:
            return {"error": "Nessun agente disponibile"}
            
        # Distribuisce sotto-task
        subtasks = self._decompose_task(task, len(agent_ids))
        
        # Esegui in parallelo
        tasks = []
        for i, agent_id in enumerate(agent_ids):
            if agent_id in self.agents:
                agent = self.agents[agent_id]
                t = asyncio.create_task(agent.process(subtasks[i]))
                tasks.append(t)
                
        results = await asyncio.gather(*tasks, return_exceptions=True)
        
        # Aggrega risultati
        aggregated = self._aggregate_results(results)
        
        return {
            "task": task,
            "subtasks": subtasks,
            "results": results,
            "aggregated": aggregated,
            "agents_used": agent_ids
        }
        
    def _select_best_agents(self, task: str, count: int) -> List[str]:
        """Seleziona migliori agenti per il task"""
        # Ranking semplificato per efficienza
        ranked = sorted(
            self.agents.items(),
            key=lambda x: x[1].get_stats()["avg_efficiency"],
            reverse=True
        )
        return [aid for aid, _ in ranked[:count]]
        
    def _decompose_task(self, task: str, parts: int) -> List[str]:
        """Scompone task in parti"""
        # Semplificazione - in produzione userebbe AI
        words = task.split()
        chunk_size = len(words) // parts
        return [
            " ".join(words[i * chunk_size:(i + 1) * chunk_size])
            for i in range(parts)
        ]
        
    def _aggregate_results(self, results: List) -> str:
        """Aggrega risultati da multipli agenti"""
        valid_results = [
            r["result"] for r in results 
            if isinstance(r, dict) and "result" in r
        ]
        return "\n\n".join(valid_results)
        
    def get_swarm_stats(self) -> Dict:
        """Statistiche sciame"""
        return {
            "agent_count": len(self.agents),
            "agents": {aid: agent.get_stats() for aid, agent in self.agents.items()},
            "shared_memory_size": len(self.shared_memory)
        }

# Singleton globale
synaptic_swarm = SynapticAgentSwarm()

if __name__ == "__main__":
    async def test():
        print("Testing Synaptic Agent System...")
        
        # Crea sciame
        swarm = SynapticAgentSwarm()
        
        # Crea agenti
        agent1 = swarm.create_agent("Alpha", "text_generation")
        agent2 = swarm.create_agent("Beta", "analysis")
        
        # Test task
        result = await swarm.collaborative_task(
            "Scrivi una poesia sull'intelligenza artificiale e analizza il suo impatto"
        )
        
        print(f"\nRisultato: {json.dumps(result, indent=2, default=str)}")
        print(f"\nStats swarm: {json.dumps(swarm.get_swarm_stats(), indent=2, default=str)}")
        
    asyncio.run(test())
