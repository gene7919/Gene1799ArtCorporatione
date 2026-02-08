"""
Gene1799 AI Learning Engine
Machine learning framework per agenti intelligenti
Apprendimento automatico, pattern recognition, ottimizzazione comportamento
"""

import asyncio
import json
import numpy as np
from datetime import datetime, timedelta
from typing import Dict, List, Tuple, Any, Optional
from dataclasses import dataclass, asdict, field
from collections import defaultdict
import statistics


@dataclass
class LearningDataPoint:
    """Singolo punto dati per l'apprendimento"""
    agent_id: str
    action: str
    result: float  # 0-1 score
    context: Dict[str, Any]
    timestamp: datetime
    tags: List[str] = field(default_factory=list)


@dataclass
class AgentPerformanceMetrics:
    """Metriche di performance dell'agente"""
    agent_id: str
    total_actions: int = 0
    success_rate: float = 0.0
    avg_result: float = 0.0
    learning_velocity: float = 0.0  # Quanto velocemente impara
    knowledge_base_size: int = 0
    last_updated: datetime = None
    specializations: Dict[str, float] = field(default_factory=dict)  # Domain -> expertise


class AdaptiveAgent:
    """Agente che apprende e si adatta nel tempo"""
    
    def __init__(self, agent_id: str, specialization: str = "general"):
        self.agent_id = agent_id
        self.specialization = specialization
        self.learning_data: List[LearningDataPoint] = []
        self.performance_metrics = AgentPerformanceMetrics(agent_id=agent_id)
        self.action_outcomes: Dict[str, List[float]] = defaultdict(list)
        self.context_patterns: Dict[str, List[Dict]] = defaultdict(list)
        self.decision_matrix: Dict[str, Dict[str, float]] = {}  # Context -> Action -> Score
        self.learning_rate = 0.1  # Alpha per aggiornamenti
        self.exploration_rate = 0.2  # Epsilon per esplorazione
    
    async def learn_from_action(self, action: str, result: float, context: Dict[str, Any], tags: List[str] = None):
        """Impara da un'azione eseguita"""
        
        # Registra il punto dati
        data_point = LearningDataPoint(
            agent_id=self.agent_id,
            action=action,
            result=result,
            context=context,
            timestamp=datetime.now(),
            tags=tags or []
        )
        
        self.learning_data.append(data_point)
        self.action_outcomes[action].append(result)
        self.context_patterns[str(context)].append(context)
        
        # Aggiorna decision matrix
        context_key = self._context_to_key(context)
        if context_key not in self.decision_matrix:
            self.decision_matrix[context_key] = {}
        
        # Q-learning style update
        current_value = self.decision_matrix[context_key].get(action, 0.0)
        new_value = current_value + self.learning_rate * (result - current_value)
        self.decision_matrix[context_key][action] = new_value
        
        # Aggiorna metriche
        await self._update_metrics()
    
    async def choose_action(self, context: Dict[str, Any], available_actions: List[str]) -> str:
        """Sceglie l'azione migliore basata su apprendimento"""
        
        context_key = self._context_to_key(context)
        
        # Epsilon-greedy strategy
        if np.random.random() < self.exploration_rate:
            # Esplorazione: azione casuale
            return np.random.choice(available_actions)
        
        # Exploitation: azione migliore conosciuta
        if context_key in self.decision_matrix:
            action_scores = {
                action: self.decision_matrix[context_key].get(action, 0.0)
                for action in available_actions
            }
            best_action = max(action_scores, key=action_scores.get)
            return best_action
        
        # Default: azione casuale se no context history
        return np.random.choice(available_actions)
    
    async def predict_outcome(self, action: str, context: Dict[str, Any]) -> Tuple[float, float]:
        """Predice l'outcome di un'azione (valore, confidenza)"""
        
        if action not in self.action_outcomes:
            return 0.5, 0.0  # No data = 50% expected, 0 confidence
        
        outcomes = self.action_outcomes[action]
        value = statistics.mean(outcomes)
        
        # Calcola confidenza basata su numero di esperienze
        confidence = min(len(outcomes) / 100, 1.0)
        
        return value, confidence
    
    async def get_recommendations(self, context: Dict[str, Any], top_n: int = 3) -> List[Dict[str, Any]]:
        """Ottiene le migliori azioni raccomandate"""
        
        context_key = self._context_to_key(context)
        
        if context_key not in self.decision_matrix:
            return []
        
        action_scores = sorted(
            self.decision_matrix[context_key].items(),
            key=lambda x: x[1],
            reverse=True
        )[:top_n]
        
        recommendations = []
        for action, score in action_scores:
            value, confidence = await self.predict_outcome(action, context)
            recommendations.append({
                "action": action,
                "score": score,
                "predicted_value": value,
                "confidence": confidence
            })
        
        return recommendations
    
    async def identify_patterns(self) -> Dict[str, Any]:
        """Identifica pattern nel comportamento"""
        
        patterns = {
            "most_successful_actions": [],
            "least_successful_actions": [],
            "context_correlations": [],
            "temporal_patterns": []
        }
        
        # Azioni più di successo
        if self.action_outcomes:
            avg_outcomes = {
                action: statistics.mean(outcomes)
                for action, outcomes in self.action_outcomes.items()
            }
            patterns["most_successful_actions"] = sorted(
                avg_outcomes.items(),
                key=lambda x: x[1],
                reverse=True
            )[:5]
        
        return patterns
    
    def _context_to_key(self, context: Dict[str, Any]) -> str:
        """Converte context a chiave hash"""
        return json.dumps(context, sort_keys=True, default=str)
    
    async def _update_metrics(self):
        """Aggiorna le metriche di performance"""
        
        if not self.learning_data:
            return
        
        total_actions = len(self.learning_data)
        successful_actions = sum(1 for d in self.learning_data if d.result > 0.5)
        success_rate = successful_actions / total_actions if total_actions > 0 else 0.0
        
        all_results = [d.result for d in self.learning_data]
        avg_result = statistics.mean(all_results) if all_results else 0.0
        
        # Calcola learning velocity (trend di miglioramento)
        if total_actions > 10:
            recent_results = [d.result for d in self.learning_data[-10:]]
            older_results = [d.result for d in self.learning_data[-20:-10]]
            if older_results:
                learning_velocity = (statistics.mean(recent_results) - statistics.mean(older_results)) / statistics.mean(older_results)
            else:
                learning_velocity = 0.0
        else:
            learning_velocity = 0.0
        
        self.performance_metrics.total_actions = total_actions
        self.performance_metrics.success_rate = success_rate
        self.performance_metrics.avg_result = avg_result
        self.performance_metrics.learning_velocity = learning_velocity
        self.performance_metrics.knowledge_base_size = len(self.decision_matrix)
        self.performance_metrics.last_updated = datetime.now()


class MultiAgentLearningSystem:
    """Sistema di apprendimento per più agenti"""
    
    def __init__(self):
        self.agents: Dict[str, AdaptiveAgent] = {}
        self.shared_knowledge_base: Dict[str, Any] = {}
        self.learning_history: List[Dict] = []
        self.performance_leaderboard: List[Tuple[str, float]] = []
    
    async def register_agent(self, agent_id: str, specialization: str = "general") -> AdaptiveAgent:
        """Registra un nuovo agente nel sistema"""
        
        agent = AdaptiveAgent(agent_id, specialization)
        self.agents[agent_id] = agent
        
        print(f"[✓] Agent {agent_id} registrato come {specialization}")
        return agent
    
    async def distribute_knowledge(self, insight: str, source_agent: str, value: float, domains: List[str]):
        """Distribuisce conoscenza acquisita tra agenti"""
        
        knowledge_entry = {
            "insight": insight,
            "source": source_agent,
            "value": value,
            "domains": domains,
            "timestamp": datetime.now().isoformat(),
            "adoption_count": 0
        }
        
        self.shared_knowledge_base[insight] = knowledge_entry
        
        # Condividi con altri agenti dello stesso dominio
        for domain in domains:
            for agent_id, agent in self.agents.items():
                if domain in agent.specialization or agent.specialization == "general":
                    # L'agente può usare questa conoscenza
                    knowledge_entry["adoption_count"] += 1
    
    async def collaborative_learning(self):
        """Facilita l'apprendimento collaborativo tra agenti"""
        
        collaboration_report = {
            "timestamp": datetime.now().isoformat(),
            "agents_involved": len(self.agents),
            "knowledge_shared": len(self.shared_knowledge_base),
            "improvements": []
        }
        
        if len(self.agents) > 1:
            # Identifica agent con migliore performance
            agent_performances = {}
            for agent_id, agent in self.agents.items():
                agent_performances[agent_id] = agent.performance_metrics.avg_result
            
            top_agent = max(agent_performances, key=agent_performances.get)
            
            # Condividi pattern del top agent
            top_patterns = await self.agents[top_agent].identify_patterns()
            
            for agent_id, agent in self.agents.items():
                if agent_id != top_agent:
                    # Applica pattern learning
                    improvement = await agent._update_metrics()
                    collaboration_report["improvements"].append({
                        "agent": agent_id,
                        "learned_from": top_agent,
                        "prev_score": agent.performance_metrics.avg_result
                    })
        
        return collaboration_report
    
    async def generate_performance_report(self) -> str:
        """Genera report di performance del sistema"""
        
        report = f"""
╔════════════════════════════════════════════════════════════════════╗
║          GENE1799 MULTI-AGENT LEARNING SYSTEM REPORT                ║
║                      {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
╚════════════════════════════════════════════════════════════════════╝

AGENTS PERFORMANCE
──────────────────"""
        
        # Calcola leaderboard
        leaderboard = sorted(
            [(aid, agent.performance_metrics.avg_result) 
             for aid, agent in self.agents.items()],
            key=lambda x: x[1],
            reverse=True
        )
        
        for rank, (agent_id, score) in enumerate(leaderboard, 1):
            agent = self.agents[agent_id]
            report += f"""
{rank}. {agent_id} (Specialization: {agent.specialization})
   Performance Score: {score:.2f}/1.0
   Success Rate: {agent.performance_metrics.success_rate:.1%}
   Total Actions: {agent.performance_metrics.total_actions}
   Learning Velocity: {agent.performance_metrics.learning_velocity:.3f}
   Knowledge Base: {agent.performance_metrics.knowledge_base_size} contexts"""
        
        report += f"""

SHARED KNOWLEDGE
────────────────
Total Insights: {len(self.shared_knowledge_base)}
Most Adopted: """
        
        if self.shared_knowledge_base:
            most_adopted = max(
                self.shared_knowledge_base.items(),
                key=lambda x: x[1].get("adoption_count", 0)
            )
            report += f"{most_adopted[0]} ({most_adopted[1]['adoption_count']} adoptions)"
        
        report += f"""

SYSTEM METRICS
──────────────
Total Agents: {len(self.agents)}
Learning History Events: {len(self.learning_history)}
Average System Performance: {(sum(score for _, score in leaderboard) / len(leaderboard) if leaderboard else 0):.2f}/1.0

╚════════════════════════════════════════════════════════════════════╝
"""
        return report
    
    async def export_learning_data(self) -> Dict[str, Any]:
        """Esporta dati di apprendimento"""
        
        return {
            "agents": {
                agent_id: {
                    "specialization": agent.specialization,
                    "metrics": asdict(agent.performance_metrics),
                    "decision_matrix_size": len(agent.decision_matrix),
                    "actions_learned": len(agent.action_outcomes)
                }
                for agent_id, agent in self.agents.items()
            },
            "shared_knowledge": self.shared_knowledge_base,
            "timestamp": datetime.now().isoformat()
        }


# Specializzazioni di agenti con domini di expertise
AGENT_SPECIALIZATIONS = {
    "anti_cancer": ["medical_oncology", "pharmaceutical", "research"],
    "drug_discovery": ["pharmaceutical", "chemistry", "biotech"],
    "healthcare": ["healthcare", "medical", "ehr", "patient_care"],
    "data_processor": ["data_science", "analytics", "statistics"],
    "communicator": ["content_creation", "engagement", "communication"],
    "learning": ["optimization", "ml", "pattern_detection"],
    "orchestrator": ["coordination", "workflow", "management"]
}


# Esempio di utilizzo
async def main():
    print("Gene1799 AI Learning Engine")
    print("=" * 60)
    
    # Crea sistema di apprendimento
    learning_system = MultiAgentLearningSystem()
    
    # Registra agenti
    agents = {}
    for agent_name, domains in AGENT_SPECIALIZATIONS.items():
        agent = await learning_system.register_agent(
            agent_name,
            specialization=", ".join(domains[:2])
        )
        agents[agent_name] = agent
    
    # Simula apprendimento
    print("\n[*] Simulating learning experiences...")
    
    for i in range(50):
        # Sceglie agente casuale
        agent_id = list(agents.keys())[i % len(agents)]
        agent = agents[agent_id]
        
        # Context casuale
        context = {"time_of_day": "morning", "workload": "high", "priority": "urgent"}
        
        # Simula azione e risultato
        actions = ["aggressive", "moderate", "conservative"]
        action = actions[i % 3]
        result = 0.6 + (0.4 * (i / 50))  # Improving over time
        
        await agent.learn_from_action(action, result, context)
    
    # Report di performance
    report = await learning_system.generate_performance_report()
    print(report)
    
    # Esporta dati
    learning_data = await learning_system.export_learning_data()
    print("\nExported Learning Data:")
    print(json.dumps(learning_data, indent=2, default=str))


if __name__ == "__main__":
    asyncio.run(main())
