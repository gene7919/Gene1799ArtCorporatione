#!/usr/bin/env python3
"""
SuiteV17 Orchestrator Integration Module
Connette Unified Orchestrator (9001) con Workflow Orchestrator (9002)
"""
import requests
import json
from typing import Dict, Optional, List
from datetime import datetime

class OrchestratorClient:
    """Client per comunicazione tra orchestratori."""
    
    def __init__(self, unified_port=9001, workflow_port=9002):
        self.unified_url = f'http://localhost:{unified_port}'
        self.workflow_url = f'http://localhost:{workflow_port}'
        
    def get_unified_status(self) -> Dict:
        """Stato orchestratore unificato."""
        try:
            resp = requests.get(f'{self.unified_url}/api/status', timeout=5)
            return resp.json() if resp.status_code == 200 else {'error': 'Unavailable'}
        except Exception as e:
            return {'error': str(e)}
            
    def get_workflow_status(self) -> Dict:
        """Stato workflow orchestrator."""
        try:
            resp = requests.get(f'{self.workflow_url}/api/status', timeout=5)
            return resp.json() if resp.status_code == 200 else {'error': 'Unavailable'}
        except Exception as e:
            return {'error': str(e)}
            
    def get_combined_status(self) -> Dict:
        """Stato combinato di entrambi gli orchestratori."""
        return {
            'timestamp': datetime.now().isoformat(),
            'unified_orchestrator': self.get_unified_status(),
            'workflow_orchestrator': self.get_workflow_status(),
            'system_healthy': True
        }
        
    def create_ai_workflow(self, prompt: str, system: str = None) -> Dict:
        """Crea workflow che usa AI e lo esegue."""
        try:
            # Crea workflow su orchestratore 2
            workflow_data = {
                'name': f'AI Generation Workflow',
                'steps': [{
                    'step_id': 'ai_gen_1',
                    'name': 'AI Text Generation',
                    'type': 'ai_generation',
                    'config': {'prompt': prompt, 'system': system},
                    'timeout_seconds': 60
                }]
            }
            resp = requests.post(f'{self.workflow_url}/api/workflows', 
                              json=workflow_data, timeout=10)
            if resp.status_code == 200:
                wf_id = resp.json().get('workflow_id')
                # Esegui workflow
                exec_resp = requests.post(f'{self.workflow_url}/api/workflows/{wf_id}/execute', timeout=120)
                return exec_resp.json() if exec_resp.status_code == 200 else {'error': 'Execution failed'}
            return {'error': 'Creation failed'}
        except Exception as e:
            return {'error': str(e)}
            
    def create_social_workflow(self, topic: str, platforms: List[str]) -> Dict:
        """Crea workflow per post social."""
        try:
            steps = []
            for i, platform in enumerate(platforms):
                steps.append({
                    'step_id': f'social_{platform}',
                    'name': f'Post su {platform}',
                    'type': 'social_post',
                    'config': {'topic': topic, 'platform': platform},
                    'depends_on': [steps[-1]['step_id']] if steps else []
                })
            
            workflow_data = {
                'name': f'Social Campaign: {topic}',
                'steps': steps
            }
            resp = requests.post(f'{self.workflow_url}/api/workflows', 
                              json=workflow_data, timeout=10)
            return resp.json() if resp.status_code == 200 else {'error': 'Failed'}
        except Exception as e:
            return {'error': str(e)}
            
    def trigger_notification(self, title: str, message: str, priority: str = 'normal') -> Dict:
        """Triggera notifica via workflow orchestrator."""
        try:
            workflow_data = {
                'name': 'Notification Workflow',
                'steps': [{
                    'step_id': 'notify_1',
                    'name': 'Send Notification',
                    'type': 'notification',
                    'config': {'title': title, 'message': message, 'priority': priority}
                }]
            }
            resp = requests.post(f'{self.workflow_url}/api/workflows', 
                              json=workflow_data, timeout=10)
            return resp.json() if resp.status_code == 200 else {'error': 'Failed'}
        except Exception as e:
            return {'error': str(e)}

# Singleton
orch_client = OrchestratorClient()

if __name__ == '__main__':
    print(json.dumps(orch_client.get_combined_status(), indent=2))
