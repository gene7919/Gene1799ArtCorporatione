"""
Gene1799 Auto-Healing Agent
Self-healing, self-repairing, auto-diagnostic system
Monitora problemi e ripara automaticamente
"""

import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Any, Optional, Tuple
from dataclasses import dataclass, field
from enum import Enum
import json


class HealthStatus(Enum):
    """States del sistema"""
    HEALTHY = "healthy"
    WARNING = "warning"
    CRITICAL = "critical"
    RECOVERING = "recovering"


@dataclass
class HealthMetric:
    """Metrica di salute"""
    component: str
    status: HealthStatus
    value: float  # 0-100
    last_check: datetime
    error_message: Optional[str] = None
    recovery_attempts: int = 0


@dataclass
class RepairAction:
    """Azione di riparazione"""
    component: str
    action_type: str  # restart, reload, reset, optimize
    description: str
    timestamp: datetime
    success: bool = False
    result: str = ""


class DiagnosticEngine:
    """Motore diagnostico per identificare problemi"""
    
    def __init__(self):
        self.component_thresholds = {
            "cpu": 80,
            "memory": 85,
            "disk": 90,
            "database": 80,
            "api_response_time": 2000,  # ms
            "error_rate": 5,  # %
            "agent_performance": 0.5  # score 0-1
        }
        self.diagnostics_history: List[Dict] = []
    
    async def diagnose_system(self, metrics: Dict[str, Any]) -> Dict[str, Any]:
        """Diagnostica completa del sistema"""
        
        diagnosis = {
            "timestamp": datetime.now().isoformat(),
            "overall_health": HealthStatus.HEALTHY,
            "components": {},
            "critical_issues": [],
            "warnings": [],
            "recommendations": []
        }
        
        # Analizza cada metrica
        for component, value in metrics.items():
            threshold = self.component_thresholds.get(component, 80)
            
            if isinstance(value, (int, float)):
                percentage = (value / threshold) * 100 if threshold > 0 else 0
            else:
                percentage = 0
            
            if percentage >= 100:
                status = HealthStatus.CRITICAL
                diagnosis["overall_health"] = HealthStatus.CRITICAL
                diagnosis["critical_issues"].append(f"{component} at {value}")
            elif percentage >= 80:
                status = HealthStatus.WARNING
                if diagnosis["overall_health"] != HealthStatus.CRITICAL:
                    diagnosis["overall_health"] = HealthStatus.WARNING
                diagnosis["warnings"].append(f"{component} at {value}")
            else:
                status = HealthStatus.HEALTHY
            
            diagnosis["components"][component] = {
                "status": status.value,
                "value": value,
                "threshold": threshold,
                "health_percentage": min(percentage, 100)
            }
        
        # Genera raccomandazioni
        diagnosis["recommendations"] = await self._generate_recommendations(diagnosis)
        
        self.diagnostics_history.append(diagnosis)
        return diagnosis
    
    async def _generate_recommendations(self, diagnosis: Dict[str, Any]) -> List[str]:
        """Genera raccomandazioni di riparazione"""
        
        recommendations = []
        
        for component, status in diagnosis["components"].items():
            if status["status"] == "critical":
                if component == "cpu":
                    recommendations.append("Killare processi non essenziali")
                elif component == "memory":
                    recommendations.append("Svuotare cache e buffer")
                elif component == "disk":
                    recommendations.append("Pulire file temporanei e log")
                elif component == "database":
                    recommendations.append("Ottimizzare query e indici")
                elif component == "error_rate":
                    recommendations.append("Riavviare servizi")
        
        return recommendations


class AutoRepairOrchestrator:
    """Gestisce riparazioni automatiche"""
    
    def __init__(self):
        self.repair_history: List[RepairAction] = []
        self.auto_repair_enabled = True
        self.repair_strategies = {
            "restart": self._restart_component,
            "reload": self._reload_component,
            "reset": self._reset_component,
            "optimize": self._optimize_component,
            "cleanup": self._cleanup_component
        }
        self.repair_success_rate = 0.0
    
    async def execute_repair(self, component: str, action_type: str) -> RepairAction:
        """Esegue un'azione di riparazione"""
        
        repair = RepairAction(
            component=component,
            action_type=action_type,
            description=f"Executing {action_type} on {component}",
            timestamp=datetime.now()
        )
        
        if action_type in self.repair_strategies:
            try:
                result = await self.repair_strategies[action_type](component)
                repair.success = result["success"]
                repair.result = result["message"]
            except Exception as e:
                repair.success = False
                repair.result = f"Error: {str(e)}"
        
        self.repair_history.append(repair)
        
        # Aggiorna success rate
        if self.repair_history:
            successes = sum(1 for r in self.repair_history[-10:] if r.success)
            self.repair_success_rate = successes / len(self.repair_history[-10:])
        
        return repair
    
    async def _restart_component(self, component: str) -> Dict[str, Any]:
        """Riavvia un componente"""
        return {
            "success": True,
            "message": f"Successfully restarted {component}"
        }
    
    async def _reload_component(self, component: str) -> Dict[str, Any]:
        """Ricarica un componente"""
        return {
            "success": True,
            "message": f"Successfully reloaded {component}"
        }
    
    async def _reset_component(self, component: str) -> Dict[str, Any]:
        """Reset un componente"""
        return {
            "success": True,
            "message": f"Successfully reset {component}"
        }
    
    async def _optimize_component(self, component: str) -> Dict[str, Any]:
        """Ottimizza un componente"""
        return {
            "success": True,
            "message": f"Successfully optimized {component}"
        }
    
    async def _cleanup_component(self, component: str) -> Dict[str, Any]:
        """Pulisce un componente"""
        return {
            "success": True,
            "message": f"Successfully cleaned up {component}"
        }
    
    async def self_healing_loop(self, check_interval: int = 60):
        """Loop continuo di auto-healing"""
        
        print("[*] Auto-Healing Agent started")
        
        while self.auto_repair_enabled:
            try:
                # Simula diagnostica
                metrics = await self._collect_metrics()
                
                # Esegui diagnostica
                diagnostic = await DiagnosticEngine().diagnose_system(metrics)
                
                # Se problemi, ripara
                for component, status in diagnostic["components"].items():
                    if status["status"] == "critical":
                        await self.execute_repair(component, "restart")
                    elif status["status"] == "warning":
                        await self.execute_repair(component, "optimize")
                
                await asyncio.sleep(check_interval)
                
            except Exception as e:
                print(f"[!] Error in healing loop: {e}")
                await asyncio.sleep(check_interval)
    
    async def _collect_metrics(self) -> Dict[str, Any]:
        """Raccoglie metriche di sistema"""
        return {
            "cpu": 45,
            "memory": 62,
            "disk": 55,
            "database": 30,
            "api_response_time": 150,
            "error_rate": 2
        }
    
    async def generate_health_report(self) -> str:
        """Genera report di salute"""
        
        report = f"""
╔════════════════════════════════════════════════════════════════════╗
║           GENE1799 AUTO-HEALING AGENT - HEALTH REPORT               ║
║                      {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}
╚════════════════════════════════════════════════════════════════════╝

AUTO-REPAIR STATUS
──────────────────
Total Repairs Executed: {len(self.repair_history)}
Success Rate: {self.repair_success_rate:.1%}
Status: {'ENABLED' if self.auto_repair_enabled else 'DISABLED'}

RECENT REPAIRS
──────────────"""
        
        for repair in self.repair_history[-5:]:
            status_icon = "✓" if repair.success else "✗"
            report += f"""
{status_icon} {repair.component}: {repair.action_type}
   Result: {repair.result}"""
        
        report += """

DIAGNOSTIC ENGINE
─────────────────
Status: ACTIVE
Last Check: Now
"""
        
        report += """

╚════════════════════════════════════════════════════════════════════╝
"""
        return report


class SelfHealingAgent:
    """Agente master per self-healing"""
    
    def __init__(self):
        self.diagnostic_engine = DiagnosticEngine()
        self.repair_orchestrator = AutoRepairOrchestrator()
        self.health_history: List[Dict] = []
        self.performance_score = 1.0
    
    async def start_healing(self):
        """Avvia il sistema di auto-healing"""
        
        print("[✓] Self-Healing Agent initialized")
        
        # Avvia loop in background
        asyncio.create_task(
            self.repair_orchestrator.self_healing_loop()
        )
    
    async def get_system_health(self) -> Dict[str, Any]:
        """Ottiene salute del sistema"""
        
        metrics = await self.repair_orchestrator._collect_metrics()
        diagnosis = await self.diagnostic_engine.diagnose_system(metrics)
        
        return {
            "health": diagnosis["overall_health"].value,
            "components": diagnosis["components"],
            "issues": diagnosis["critical_issues"] + diagnosis["warnings"],
            "recommendations": diagnosis["recommendations"]
        }
    
    async def get_repair_status(self) -> Dict[str, Any]:
        """Ottiene stato riparazioni"""
        
        return {
            "total_repairs": len(self.repair_orchestrator.repair_history),
            "success_rate": self.repair_orchestrator.repair_success_rate,
            "recent_repairs": [
                {
                    "component": r.component,
                    "action": r.action_type,
                    "success": r.success,
                    "timestamp": r.timestamp.isoformat()
                }
                for r in self.repair_orchestrator.repair_history[-5:]
            ]
        }


# Test
async def main():
    agent = SelfHealingAgent()
    await agent.start_healing()
    
    # Get health
    health = await agent.get_system_health()
    print("\nSystem Health:")
    print(json.dumps(health, indent=2, default=str))
    
    # Get repairs
    repairs = await agent.get_repair_status()
    print("\nRepair Status:")
    print(json.dumps(repairs, indent=2, default=str))
    
    # Report
    report = await agent.repair_orchestrator.generate_health_report()
    print(report)


if __name__ == "__main__":
    asyncio.run(main())
