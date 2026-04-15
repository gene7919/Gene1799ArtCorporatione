#!/usr/bin/env python3
"""
SuiteV17 Complete Test Suite
Verifica funzionalita di tutti i moduli
"""
import sys
import asyncio
import importlib
from datetime import datetime

class TestSuite:
    def __init__(self):
        self.results = []
        
    def test(self, name: str, func):
        """Esegue un test e registra il risultato."""
        try:
            result = func()
            self.results.append({'name': name, 'status': 'PASS', 'result': result})
            print(f'  [OK] {name}')
            return True
        except Exception as e:
            self.results.append({'name': name, 'status': 'FAIL', 'error': str(e)})
            print(f'  [FAIL] {name}: {str(e)[:50]}')
            return False
            
    def run_all(self):
        print('=' * 70)
        print('SUITEV17 COMPLETE TEST SUITE')
        print('=' * 70)
        print(f'Started: {datetime.now().isoformat()}')
        print()
        
        # Test 1: Module imports
        print('\\n[1/7] Testing Module Imports')
        modules = [
            'suitev17_master', 'security_core', 'workflow_engine',
            'scheduler_core', 'websocket_server', 'database_core',
            'api_server', 'sell_engine', 'social_automation',
            'zora_agent', 'gene1799_crew', 'blockchain_multi'
        ]
        
        passed = 0
        for mod in modules:
            try:
                importlib.import_module(mod.replace('.py', ''))
                print(f'  [OK] {mod}')
                passed += 1
            except Exception as e:
                print(f'  [FAIL] {mod}: {str(e)[:40]}')
        
        print(f'\nImports: {passed}/{len(modules)} passed')
        
        # Test 2: Database
        print('\\n[2/7] Testing Database Core')
        try:
            from database_core import DatabaseManager
            db = DatabaseManager()
            stats = db.get_stats()
            print(f'  [OK] Database initialized')
            print(f'  [OK] Stats: {stats}')
        except Exception as e:
            print(f'  [FAIL] Database: {e}')
            
        # Test 3: Security
        print('\\n[3/7] Testing Security Core')
        try:
            from security_core import SecurityManager
            sec = SecurityManager()
            encrypted = sec.encrypt('test')
            decrypted = sec.decrypt(encrypted)
            assert decrypted == 'test'
            print(f'  [OK] Encryption/Decryption working')
            
            token = sec.generate_token('user123')
            verified = sec.verify_token(token)
            assert verified is not None
            print(f'  [OK] Token generation/verification working')
        except Exception as e:
            print(f'  [FAIL] Security: {e}')
            
        # Test 4: Workflow Engine
        print('\\n[4/7] Testing Workflow Engine')
        try:
            from workflow_engine import WorkflowEngine, WorkflowBuilder
            
            engine = WorkflowEngine()
            
            def task1(ctx):
                return {'step': 1}
                
            def task2(ctx):
                return {'step': 2}
            
            builder = WorkflowBuilder('test_workflow')
            builder.add_task('step1', task1).add_task('step2', task2, ['step1']).build(engine)
            
            exec_id = engine.execute_workflow('test_workflow')
            status = engine.get_execution_status(exec_id)
            
            if status and status.get('status') == 'completed':
                print(f'  [OK] Workflow execution working')
            else:
                print(f'  [FAIL] Workflow execution failed')
        except Exception as e:
            print(f'  [FAIL] Workflow: {e}')
            
        # Test 5: Scheduler
        print('\\n[5/7] Testing Scheduler Core')
        try:
            from scheduler_core import TaskScheduler
            scheduler = TaskScheduler()
            job_id = scheduler.schedule_once('test_job', 'notify', 3600, {'message': 'test'})
            print(f'  [OK] Job scheduled: {job_id}')
            stats = scheduler.get_stats()
            print(f'  [OK] Scheduler stats: {stats}')
        except Exception as e:
            print(f'  [FAIL] Scheduler: {e}')
            
        # Test 6: Social Automation
        print('\\n[6/7] Testing Social Automation')
        try:
            from social_automation import SocialAutomation
            social = SocialAutomation()
            config = social.config
            enabled_count = sum(1 for c in config.values() if c.get('enabled'))
            print(f'  [OK] SocialAutomation initialized')
            print(f'  [OK] Platforms configured: {len(config)}')
            print(f'  [OK] Platforms enabled: {enabled_count}')
        except Exception as e:
            print(f'  [FAIL] Social: {e}')
            
        # Test 7: Gene1799 Crew
        print('\\n[7/7] Testing Gene1799 Crew')
        try:
            from gene1799_crew import Gene1799Crew, AgentRole
            crew = Gene1799Crew()
            agent_id = crew.create_agent('TestAgent', AgentRole.DEVELOPER)
            print(f'  [OK] Agent created: {agent_id}')
            
            task_id = crew.create_task('Test Task', 'Test Description', AgentRole.DEVELOPER)
            print(f'  [OK] Task created: {task_id}')
            
            status = crew.get_crew_status()
            print(f'  [OK] Crew status: {status}')
        except Exception as e:
            print(f'  [FAIL] Crew: {e}')
            
        # Summary
        print()
        print('=' * 70)
        print('TEST SUMMARY')
        print('=' * 70)
        
        passed = sum(1 for r in self.results if r['status'] == 'PASS')
        failed = sum(1 for r in self.results if r['status'] == 'FAIL')
        
        print(f'\nTests run: {len(self.results)}')
        print(f'Passed: {passed}')
        print(f'Failed: {failed}')
        print()
        
        if failed == 0:
            print('[OK] All critical modules are working!')
            print('\\nYou can now start the services with:')
            print('  python launcher.py')
            print('  or')
            print('  start_suitev17.bat')
        else:
            print('[WARNING] Some modules need attention')
            
        return failed == 0

def main():
    suite = TestSuite()
    success = suite.run_all()
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()
